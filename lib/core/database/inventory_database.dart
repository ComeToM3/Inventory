import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'inventory_database.g.dart';

class Inventories extends Table {
  TextColumn get id => text()();

  IntColumn get singletonKey =>
      integer().withDefault(const Constant(1)).unique()();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (singleton_key = 1)'];
}

@TableIndex(name: 'nodes_parent_idx', columns: {#inventoryId, #parentId})
@TableIndex(
  name: 'nodes_active_name_idx',
  columns: {#inventoryId, #status, #name},
)
class Nodes extends Table {
  TextColumn get id => text()();

  TextColumn get inventoryId =>
      text().references(Inventories, #id, onDelete: KeyAction.restrict)();

  TextColumn get parentId => text().nullable()();

  TextColumn get name => text()();

  TextColumn get nodeType => text()();

  IntColumn get quantity =>
      integer().nullable().withDefault(const Constant(1))();

  TextColumn get description => text().nullable()();

  TextColumn get condition => text().nullable()();

  TextColumn get valueMode =>
      text().nullable().withDefault(const Constant('financial'))();

  IntColumn get financialValueCents =>
      integer().nullable().withDefault(const Constant(0))();

  IntColumn get sentimentalValue => integer().nullable()();

  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get withdrawalReason => text().nullable()();

  TextColumn get withdrawnAt => text().nullable()();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {inventoryId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (inventory_id, parent_id) '
        'REFERENCES nodes (inventory_id, id) ON DELETE RESTRICT',
    'CHECK (id <> parent_id)',
    'CHECK (length(name) > 0)',
    "CHECK (node_type IN ('location', 'container', 'item', 'item_container'))",
    "CHECK (status IN ('active', 'withdrawn'))",
    '''
    CHECK (
      (
        node_type IN ('location', 'container')
        AND quantity IS NULL
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
      )
      OR
      (
        node_type IN ('item', 'item_container')
        AND typeof(quantity) = 'integer'
        AND quantity >= 1
        AND (
          (
            value_mode = 'financial'
            AND typeof(financial_value_cents) = 'integer'
            AND financial_value_cents >= 0
            AND sentimental_value IS NULL
          )
          OR
          (
            value_mode = 'sentimental'
            AND financial_value_cents IS NULL
            AND typeof(sentimental_value) = 'integer'
            AND sentimental_value BETWEEN 1 AND 5
          )
        )
      )
    )
    ''',
    '''
    CHECK (
      (
        status = 'active'
        AND (parent_id IS NOT NULL OR node_type = 'location')
        AND withdrawal_reason IS NULL
        AND withdrawn_at IS NULL
      )
      OR
      (
        status = 'withdrawn'
        AND node_type IN ('item', 'item_container')
        AND parent_id IS NULL
        AND withdrawal_reason IN ('loss', 'donation', 'breakage', 'sale')
        AND withdrawn_at IS NOT NULL
      )
    )
    ''',
  ];
}

class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get inventoryId =>
      text().references(Inventories, #id, onDelete: KeyAction.restrict)();

  TextColumn get name => text()();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {inventoryId, id},
  ];

  @override
  List<String> get customConstraints => ['CHECK (length(name) > 0)'];
}

@TableIndex(
  name: 'node_categories_category_idx',
  columns: {#inventoryId, #categoryId},
)
class NodeCategories extends Table {
  TextColumn get inventoryId => text()();

  TextColumn get nodeId => text()();

  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {nodeId, categoryId};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (inventory_id, node_id) '
        'REFERENCES nodes (inventory_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (inventory_id, category_id) '
        'REFERENCES categories (inventory_id, id) ON DELETE CASCADE',
  ];
}

class LocalVerificationEntries extends Table {
  IntColumn get id => integer()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Inventories,
    Nodes,
    Categories,
    NodeCategories,
    LocalVerificationEntries,
  ],
)
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

  static const _defaultInventoryId = '00000000-0000-4000-8000-000000000001';

  static const _verificationId = 1;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultInventory();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) {
        await m.createTable(inventories);
        await m.createTable(nodes);
        await m.createTable(categories);
        await m.createTable(nodeCategories);
        await m.createIndex(nodesParentIdx);
        await m.createIndex(nodesActiveNameIdx);
        await m.createIndex(nodeCategoriesCategoryIdx);
        await _insertDefaultInventory();
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _insertDefaultInventory() {
    final now = DateTime.now().toUtc().toIso8601String();
    return into(inventories).insert(
      InventoriesCompanion.insert(
        id: _defaultInventoryId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

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
