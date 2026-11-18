import 'package:drift/drift.dart';

import '../database/inventory_database.dart';
import '../domain/uuid_generator.dart';
import 'backup_candidate.dart';
import 'backup_codec.dart';
import 'backup_contract.dart';
import 'backup_data_writer.dart';
import 'backup_payload.dart';
import 'backup_snapshot_reader.dart';

/// Applies a validated snapshot to the active database with a recoverable journal.
class BackupRestorer {
  BackupRestorer(
    this._db, {
    DateTime Function()? clock,
    String Function()? generateId,
    this.debugAfterPending,
    this.debugBeforeCommit,
  }) : _clock = clock ?? DateTime.now,
       _generateId = generateId ?? generateUuidV4;

  final InventoryDatabase _db;
  final DateTime Function() _clock;
  final String Function() _generateId;

  /// Test hook invoked after durable `pending` and before replacement.
  Future<void> Function()? debugAfterPending;

  /// Test hook invoked inside the replacement transaction before `committed`.
  Future<void> Function()? debugBeforeCommit;

  Future<({BackupRestoreSummary summary, BackupSnapshot snapshot})> prepare(
    List<int> bytes,
  ) async {
    final existing = await currentJournal(_db);
    if (existing != null) {
      throw const BackupException(BackupErrorCode.restoreBlocked);
    }
    final file = BackupCodec.decodeAndVerify(bytes);
    final snapshot = BackupPayload.parseVerifiedFile(file);
    await BackupCandidate(snapshot).validateInTemporaryDatabase();
    return (
      summary: BackupPayload.summaryFor(file, snapshot),
      snapshot: snapshot,
    );
  }

  Future<void> apply(BackupSnapshot snapshot) async {
    final existing = await currentJournal(_db);
    if (existing != null) {
      throw const BackupException(BackupErrorCode.restoreBlocked);
    }

    await _ensureSynchronousFull();
    final operationId = _generateId();
    final now = _clock().toUtc().toIso8601String();

    await _db.transaction(() async {
      await _db.delete(_db.restorationJournalEntries).go();
      await _db
          .into(_db.restorationJournalEntries)
          .insert(
            RestorationJournalEntriesCompanion.insert(
              operationId: operationId,
              status: RestorationJournalStatus.pending.name,
              createdAt: now,
            ),
          );
    });

    try {
      final afterPending = debugAfterPending;
      if (afterPending != null) await afterPending();

      await _db.transaction(() async {
        await BackupDataWriter.clearBusinessData(_db);
        await BackupDataWriter.insertSnapshot(_db, snapshot);
        final beforeCommit = debugBeforeCommit;
        if (beforeCommit != null) await beforeCommit();
        await (_db.update(_db.restorationJournalEntries)
              ..where((row) => row.operationId.equals(operationId)))
            .write(
              RestorationJournalEntriesCompanion(
                status: Value(RestorationJournalStatus.committed.name),
              ),
            );
        await _verifyMatchesSnapshot(snapshot);
      });
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }

    await assertSqliteHealthy(_db);
    await _verifyMatchesSnapshot(snapshot);
    final journal = await currentJournal(_db);
    if (journal?.status != RestorationJournalStatus.committed.name ||
        journal?.operationId != operationId) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }
  }

  Future<void> acknowledgeJournal() async {
    await _db.transaction(() async {
      await _db.delete(_db.restorationJournalEntries).go();
    });
  }

  static Future<RestorationJournalEntry?> currentJournal(
    InventoryDatabase database,
  ) async {
    final rows = await database.select(database.restorationJournalEntries).get();
    if (rows.isEmpty) return null;
    if (rows.length > 1) {
      throw const BackupException(BackupErrorCode.databaseUnreliable);
    }
    return rows.single;
  }

  Future<void> _ensureSynchronousFull() async {
    await _db.customStatement('PRAGMA synchronous = FULL');
    final row = await _db.customSelect('PRAGMA synchronous').getSingle();
    final value = row.data.values.first;
    if (value != 2 && value != '2') {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }
  }

  Future<void> _verifyMatchesSnapshot(BackupSnapshot snapshot) async {
    final current = await BackupSnapshotReader(_db).read();
    if (current.inventory['id'] != snapshot.inventory['id'] ||
        current.nodes.length != snapshot.nodes.length ||
        current.categories.length != snapshot.categories.length ||
        current.nodeCategories.length != snapshot.nodeCategories.length) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }
  }
}
