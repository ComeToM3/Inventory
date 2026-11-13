import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'inventory_database.g.dart';

class LocalVerificationEntries extends Table {
  IntColumn get id => integer()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalVerificationEntries])
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'inventory',
              native: const DriftNativeOptions(
                databaseDirectory: getApplicationSupportDirectory,
              ),
            ),
      );

  static const _verificationId = 1;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> readVerificationValue() async {
    final entry = await (select(
      localVerificationEntries,
    )..where((entry) => entry.id.equals(_verificationId))).getSingleOrNull();
    return entry?.value;
  }

  Future<void> saveVerificationValue(String value) async {
    await into(localVerificationEntries).insertOnConflictUpdate(
      LocalVerificationEntriesCompanion(
        id: const Value(_verificationId),
        value: Value(value),
      ),
    );
  }
}
