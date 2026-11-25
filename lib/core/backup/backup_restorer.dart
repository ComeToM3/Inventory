import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/inventory_database.dart';
import '../domain/uuid_generator.dart';
import 'backup_candidate.dart';
import 'backup_codec.dart';
import 'backup_contract.dart';
import 'backup_data_writer.dart';
import 'backup_media.dart';
import 'backup_payload.dart';
import 'backup_snapshot_reader.dart';

/// Applies a validated snapshot to the active database with a recoverable journal.
class BackupRestorer {
  BackupRestorer(
    this._db, {
    DateTime Function()? clock,
    String Function()? generateId,
    Future<Directory> Function()? temporaryDirectory,
    this.debugAfterPending,
    this.debugBeforeDbReady,
    this.debugAfterDbReady,
    this.debugBeforeCommit,
  }) : _clock = clock ?? DateTime.now,
       _generateId = generateId ?? generateUuidV4,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final InventoryDatabase _db;
  final DateTime Function() _clock;
  final String Function() _generateId;
  final Future<Directory> Function() _temporaryDirectory;

  /// Test hook invoked after durable `pending` and before SQLite replacement.
  Future<void> Function()? debugAfterPending;

  /// Test hook inside the replacement transaction before `db_ready`.
  Future<void> Function()? debugBeforeDbReady;

  /// Test hook after `db_ready` and before media activation / `committed`.
  Future<void> Function()? debugAfterDbReady;

  /// Legacy alias used by older tests; treated as [debugBeforeDbReady].
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
    if (snapshot.mediaFiles.isNotEmpty) {
      await BackupMedia.clearStaging();
      for (var i = 0; i < snapshot.mediaFiles.length; i++) {
        final entry = snapshot.mediaFiles[i];
        final blob = file.mediaBlobs[i];
        final out = await BackupMedia.stagingFileFor(entry.relPath);
        await out.writeAsBytes(blob, flush: true);
      }
      await BackupMedia.verifyStagingMatches(snapshot.mediaFiles);
    }
    await BackupCandidate(snapshot).validateInTemporaryDatabase();
    return (
      summary: BackupPayload.summaryFor(file, snapshot),
      snapshot: snapshot,
    );
  }

  /// Prefers a file path so large backups are not held solely as MethodChannel
  /// byte arrays longer than necessary after the initial copy.
  Future<({BackupRestoreSummary summary, BackupSnapshot snapshot})>
      prepareFromPath(String path) async {
    final existing = await currentJournal(_db);
    if (existing != null) {
      throw const BackupException(BackupErrorCode.restoreBlocked);
    }
    final file = File(path);
    if (!await file.exists()) {
      throw const BackupException(BackupErrorCode.sourceUnavailable);
    }
    await BackupMedia.clearStaging();
    final staging = await BackupMedia.stagingRoot();
    final decoded = await BackupCodec.decodeFileToStaging(
      file,
      stagingDir: staging,
    );
    final snapshot = BackupPayload.parseVerifiedFile(decoded);
    await BackupMedia.verifyStagingMatches(snapshot.mediaFiles);
    await BackupCandidate(snapshot).validateInTemporaryDatabase();
    return (
      summary: BackupPayload.summaryFor(decoded, snapshot),
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
              status: RestorationJournalStatus.pending.storageValue,
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
        final beforeDbReady = debugBeforeDbReady ?? debugBeforeCommit;
        if (beforeDbReady != null) await beforeDbReady();
        await (_db.update(_db.restorationJournalEntries)
              ..where((row) => row.operationId.equals(operationId)))
            .write(
              RestorationJournalEntriesCompanion(
                status: Value(RestorationJournalStatus.dbReady.storageValue),
              ),
            );
        await _verifyMatchesSnapshot(snapshot);
      });
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }

    try {
      final afterDbReady = debugAfterDbReady;
      if (afterDbReady != null) await afterDbReady();

      if (snapshot.mediaFiles.isNotEmpty) {
        await BackupMedia.activateStaging();
        await BackupMedia.verifyLiveMatches(snapshot.mediaFiles);
      }

      await _db.transaction(() async {
        await (_db.update(_db.restorationJournalEntries)
              ..where((row) => row.operationId.equals(operationId)))
            .write(
              RestorationJournalEntriesCompanion(
                status: Value(RestorationJournalStatus.committed.storageValue),
              ),
            );
      });

      if (snapshot.mediaFiles.isNotEmpty) {
        await BackupMedia.discardPrevious();
      }
    } on BackupException {
      // Leave journal at db_ready when media failed: recovery can finish or
      // block. Do not restore previous media under the new SQLite inventory.
      rethrow;
    } catch (_) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }

    await assertSqliteHealthy(_db);
    await _verifyMatchesSnapshot(snapshot);
    await verifyActiveMediaConsistency(_db);
    final journal = await currentJournal(_db);
    if (journal?.status != RestorationJournalStatus.committed.storageValue ||
        journal?.operationId != operationId) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }
  }

  /// Finishes media activation for an interrupted `db_ready` restore when safe.
  /// Returns true when the journal reaches `committed`.
  Future<bool> tryCompleteDbReady(String operationId) async {
    final journal = await currentJournal(_db);
    if (journal == null ||
        journal.operationId != operationId ||
        journal.status != RestorationJournalStatus.dbReady.storageValue) {
      return false;
    }

    await assertSqliteHealthy(_db);
    final snapshot = await BackupSnapshotReader(_db).read();
    BackupPayload.validateBusinessRules(snapshot);

    final refs = await referencedMediaRelPaths(_db);
    if (refs.isNotEmpty) {
      final stagingOk = await BackupMedia.stagingContainsAll(refs);
      if (stagingOk) {
        await BackupMedia.activateStaging();
      }
      final liveOk = await BackupMedia.liveFilesExist(refs);
      if (!liveOk) {
        return false;
      }
    }

    await _db.transaction(() async {
      await (_db.update(_db.restorationJournalEntries)
            ..where((row) => row.operationId.equals(operationId)))
          .write(
            RestorationJournalEntriesCompanion(
              status: Value(RestorationJournalStatus.committed.storageValue),
            ),
          );
    });
    await BackupMedia.discardPrevious();
    return true;
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

  static Future<List<String>> referencedMediaRelPaths(
    InventoryDatabase database,
  ) async {
    final nodes = await database.select(database.nodes).get();
    final documents = await database.select(database.nodeDocuments).get();
    final paths = <String>{};
    for (final node in nodes) {
      final photo = node.photoRelPath;
      if (photo != null && photo.isNotEmpty) {
        BackupMedia.assertSafeRelPath(photo);
        paths.add(photo);
      }
    }
    for (final doc in documents) {
      BackupMedia.assertSafeRelPath(doc.relPath);
      paths.add(doc.relPath);
    }
    return paths.toList()..sort();
  }

  static Future<void> verifyActiveMediaConsistency(
    InventoryDatabase database,
  ) async {
    final refs = await referencedMediaRelPaths(database);
    if (!await BackupMedia.liveFilesExist(refs)) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }
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
        current.nodeCategories.length != snapshot.nodeCategories.length ||
        current.stockMovements.length != snapshot.stockMovements.length ||
        current.purchaseEvents.length != snapshot.purchaseEvents.length ||
        current.appPreferences.length != snapshot.appPreferences.length ||
        current.nodeDocuments.length != snapshot.nodeDocuments.length) {
      throw const BackupException(BackupErrorCode.restoreFailed);
    }
  }

  Future<File> copyImportTemp(List<int> bytes) async {
    final directory = await _temporaryDirectory();
    final file = File(
      p.join(
        directory.path,
        'inventory_import_${_clock().microsecondsSinceEpoch}.$backupFileExtension',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
