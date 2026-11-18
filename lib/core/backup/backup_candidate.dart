import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../database/inventory_database.dart';
import 'backup_contract.dart';
import 'backup_data_writer.dart';
import 'backup_payload.dart';
import 'backup_snapshot_reader.dart';

/// Loads a snapshot into an isolated SQLite database and verifies it.
class BackupCandidate {
  BackupCandidate(this.snapshot);

  final BackupSnapshot snapshot;

  Future<void> validateInTemporaryDatabase() async {
    // Isolated in-memory DB; intentional second InventoryDatabase instance.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = InventoryDatabase(NativeDatabase.memory());
    try {
      await BackupDataWriter.clearBusinessData(database);
      await BackupDataWriter.insertSnapshot(database, snapshot);
      await assertSqliteHealthy(database);
      final reloaded = await BackupSnapshotReader(database).read();
      if (reloaded.nodes.length != snapshot.nodes.length ||
          reloaded.categories.length != snapshot.categories.length ||
          reloaded.nodeCategories.length != snapshot.nodeCategories.length ||
          reloaded.inventory['id'] != snapshot.inventory['id']) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      BackupPayload.validateBusinessRules(reloaded);
    } on BackupException {
      rethrow;
    } on Exception {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    } finally {
      await database.close();
    }
  }
}

Future<void> assertSqliteHealthy(InventoryDatabase database) async {
  final integrity = await database.customSelect('PRAGMA integrity_check').get();
  if (integrity.length != 1 ||
      integrity.single.read<String>('integrity_check') != 'ok') {
    throw const BackupException(BackupErrorCode.databaseUnreliable);
  }
  final foreignKeys = await database
      .customSelect('PRAGMA foreign_key_check')
      .get();
  if (foreignKeys.isNotEmpty) {
    throw const BackupException(BackupErrorCode.databaseUnreliable);
  }
}
