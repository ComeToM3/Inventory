import '../database/inventory_database.dart';
import 'backup_candidate.dart';
import 'backup_contract.dart';
import 'backup_payload.dart';
import 'backup_restorer.dart';
import 'backup_snapshot_reader.dart';

/// Resolves interrupted restores before normal inventory use.
class RestorationRecovery {
  RestorationRecovery(this._db);

  final InventoryDatabase _db;

  Future<RestorationRecoveryState?> inspect() async {
    try {
      final journal = await BackupRestorer.currentJournal(_db);
      if (journal == null) {
        await assertSqliteHealthy(_db);
        return null;
      }

      await assertSqliteHealthy(_db);

      if (journal.status == RestorationJournalStatus.pending.storageValue) {
        final snapshot = await BackupSnapshotReader(_db).read();
        BackupPayload.validateBusinessRules(snapshot);
        return RestorationRecoveryState(
          status: RestorationJournalStatus.pending,
          operationId: journal.operationId,
          messageKind: RestorationRecoveryMessage.notApplied,
        );
      }

      if (journal.status == RestorationJournalStatus.dbReady.storageValue) {
        final completed =
            await BackupRestorer(_db).tryCompleteDbReady(journal.operationId);
        if (completed) {
          return RestorationRecoveryState(
            status: RestorationJournalStatus.committed,
            operationId: journal.operationId,
            messageKind: RestorationRecoveryMessage.completed,
          );
        }
        return RestorationRecoveryState(
          status: RestorationJournalStatus.dbReady,
          operationId: journal.operationId,
          messageKind: RestorationRecoveryMessage.unreliable,
        );
      }

      if (journal.status == RestorationJournalStatus.committed.storageValue) {
        final snapshot = await BackupSnapshotReader(_db).read();
        BackupPayload.validateBusinessRules(snapshot);
        try {
          await BackupRestorer.verifyActiveMediaConsistency(_db);
        } on BackupException {
          return RestorationRecoveryState(
            status: RestorationJournalStatus.committed,
            operationId: journal.operationId,
            messageKind: RestorationRecoveryMessage.unreliable,
          );
        }
        return RestorationRecoveryState(
          status: RestorationJournalStatus.committed,
          operationId: journal.operationId,
          messageKind: RestorationRecoveryMessage.completed,
        );
      }

      return RestorationRecoveryState(
        status: RestorationJournalStatus.pending,
        operationId: journal.operationId,
        messageKind: RestorationRecoveryMessage.unreliable,
      );
    } on BackupException {
      final journal = await BackupRestorer.currentJournal(_db).catchError(
        (_) => null,
      );
      return RestorationRecoveryState(
        status: RestorationJournalStatus.pending,
        operationId: journal?.operationId ?? 'unknown',
        messageKind: RestorationRecoveryMessage.unreliable,
      );
    } on Exception {
      return const RestorationRecoveryState(
        status: RestorationJournalStatus.pending,
        operationId: 'unknown',
        messageKind: RestorationRecoveryMessage.unreliable,
      );
    }
  }

  Future<void> acknowledge(RestorationRecoveryState state) async {
    if (state.messageKind == RestorationRecoveryMessage.unreliable) {
      throw const BackupException(BackupErrorCode.databaseUnreliable);
    }
    await BackupRestorer(_db).acknowledgeJournal();
  }
}
