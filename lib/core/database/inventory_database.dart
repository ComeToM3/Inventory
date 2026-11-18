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

  /// Inventory space: goods (Biens), stock, or to_buy (À acheter).
  TextColumn get space =>
      text().withDefault(const Constant('goods'))();

  TextColumn get name => text()();

  TextColumn get nodeType => text()();

  /// Goods: piece count. Stock products: level storage 0/1/2/4 (M2.1-C).
  IntColumn get quantity =>
      integer().nullable().withDefault(const Constant(1))();

  TextColumn get description => text().nullable()();

  TextColumn get condition => text().nullable()();

  TextColumn get valueMode =>
      text().nullable().withDefault(const Constant('financial'))();

  IntColumn get financialValueCents =>
      integer().nullable().withDefault(const Constant(0))();

  IntColumn get sentimentalValue => integer().nullable()();

  /// Internal Stock sentinel / legacy unit label; null outside stock products.
  TextColumn get stockUnit => text().nullable()();

  /// Legacy optional unit cost; unused by M2.1-C UI.
  IntColumn get unitCostCents => integer().nullable()();

  /// Optional conceptual total for a Stock product (e.g. 10).
  IntColumn get stockReference => integer().nullable()();

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
    "CHECK (space IN ('goods', 'stock', 'to_buy'))",
    "CHECK (node_type IN ('location', 'item', 'item_container'))",
    "CHECK (status IN ('active', 'withdrawn'))",
    '''
    CHECK (
      (
        node_type = 'location'
        AND quantity IS NULL
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
      )
      OR
      (
        space IN ('goods', 'to_buy')
        AND node_type IN ('item', 'item_container')
        AND typeof(quantity) = 'integer'
        AND quantity >= 1
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
        AND (
          (
            value_mode IS NULL
            AND financial_value_cents IS NULL
            AND sentimental_value IS NULL
          )
          OR
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
      OR
      (
        space = 'stock'
        AND node_type = 'item_container'
        AND quantity IS NULL
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
      )
      OR
      (
        space = 'stock'
        AND node_type = 'item'
        AND typeof(quantity) = 'integer'
        AND quantity IN (0, 1, 2, 4)
        AND stock_unit IS NOT NULL
        AND length(stock_unit) > 0
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
        AND unit_cost_cents IS NULL
        AND (
          stock_reference IS NULL
          OR (
            typeof(stock_reference) = 'integer'
            AND stock_reference >= 1
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

@TableIndex(
  name: 'stock_movements_node_idx',
  columns: {#inventoryId, #nodeId, #createdAt},
)
class StockMovements extends Table {
  TextColumn get id => text()();

  TextColumn get inventoryId =>
      text().references(Inventories, #id, onDelete: KeyAction.restrict)();

  TextColumn get nodeId => text()();

  TextColumn get movementType => text()();

  IntColumn get deltaQuarters => integer()();

  IntColumn get balanceAfterQuarters => integer()();

  TextColumn get unit => text()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (inventory_id, node_id) '
        'REFERENCES nodes (inventory_id, id) ON DELETE CASCADE',
    "CHECK (movement_type IN ('initial', 'supply', 'consume', 'correct'))",
    'CHECK (typeof(delta_quarters) = \'integer\')',
    'CHECK (typeof(balance_after_quarters) = \'integer\')',
    'CHECK (balance_after_quarters >= 0)',
    'CHECK (length(unit) > 0)',
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

/// Internal restore journal; never exported. At most one row is kept by the
/// application (pending before replacement, committed with the new inventory).
class RestorationJournalEntries extends Table {
  TextColumn get operationId => text()();

  TextColumn get status => text()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {operationId};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('pending', 'committed'))",
  ];
}

@DriftDatabase(
  tables: [
    Inventories,
    Nodes,
    Categories,
    NodeCategories,
    LocalVerificationEntries,
    RestorationJournalEntries,
    StockMovements,
  ],
)
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase([QueryExecutor? executor, String name = 'inventory'])
    : super(
        executor ??
            driftDatabase(
              name: name,
              native: const DriftNativeOptions(
                databaseDirectory: getApplicationSupportDirectory,
              ),
            ),
      );

  static const _defaultInventoryId = '00000000-0000-4000-8000-000000000001';

  static const _verificationId = 1;

  @override
  int get schemaVersion => 7;

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
      if (from < 3 && to >= 3) {
        await m.createTable(restorationJournalEntries);
      }
      if (from < 4 && to >= 4) {
        await _migrateToV4();
      }
      if (from < 5 && to >= 5) {
        await _migrateToV5();
      }
      if (from < 6 && to >= 6) {
        await _migrateToV6();
      }
      if (from < 7 && to >= 7) {
        await _migrateToV7();
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// DEV-17: drop Contenant, abandon categories/descriptions, allow unset price.
  Future<void> _migrateToV4() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('''
UPDATE nodes
SET node_type = 'item_container',
    quantity = 1,
    value_mode = NULL,
    financial_value_cents = NULL,
    sentimental_value = NULL,
    description = NULL
WHERE node_type = 'container'
''');
    await customStatement('''
UPDATE nodes
SET value_mode = NULL,
    financial_value_cents = NULL,
    sentimental_value = NULL
WHERE node_type IN ('item', 'item_container')
  AND value_mode = 'financial'
  AND financial_value_cents = 0
''');
    await customStatement('UPDATE nodes SET description = NULL');
    await customStatement('DELETE FROM node_categories');
    await customStatement('DELETE FROM categories');
    await customStatement('ALTER TABLE nodes RENAME TO nodes_old_v3');
    await customStatement('''
CREATE TABLE nodes (
  id TEXT NOT NULL,
  inventory_id TEXT NOT NULL REFERENCES inventories (id) ON DELETE RESTRICT,
  parent_id TEXT NULL,
  name TEXT NOT NULL,
  node_type TEXT NOT NULL,
  quantity INTEGER NULL DEFAULT 1,
  description TEXT NULL,
  condition TEXT NULL,
  value_mode TEXT NULL DEFAULT 'financial',
  financial_value_cents INTEGER NULL DEFAULT 0,
  sentimental_value INTEGER NULL,
  status TEXT NOT NULL DEFAULT 'active',
  withdrawal_reason TEXT NULL,
  withdrawn_at TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (inventory_id, id),
  FOREIGN KEY (inventory_id, parent_id)
    REFERENCES nodes (inventory_id, id) ON DELETE RESTRICT,
  CHECK (id <> parent_id),
  CHECK (length(name) > 0),
  CHECK (node_type IN ('location', 'item', 'item_container')),
  CHECK (status IN ('active', 'withdrawn')),
  CHECK (
    (
      node_type = 'location'
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
          value_mode IS NULL
          AND financial_value_cents IS NULL
          AND sentimental_value IS NULL
        )
        OR
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
  ),
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
)
''');
    await customStatement('''
INSERT INTO nodes (
  id, inventory_id, parent_id, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value, status,
  withdrawal_reason, withdrawn_at, created_at, updated_at
)
SELECT
  id, inventory_id, parent_id, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value, status,
  withdrawal_reason, withdrawn_at, created_at, updated_at
FROM nodes_old_v3
''');
    await customStatement('DROP TABLE nodes_old_v3');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_parent_idx ON nodes (inventory_id, parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_active_name_idx '
      'ON nodes (inventory_id, status, name)',
    );
    await customStatement('PRAGMA foreign_keys = ON');
  }

  /// M1.1: additive `space` column; every existing node becomes goods.
  Future<void> _migrateToV5() async {
    await customStatement(
      "ALTER TABLE nodes ADD COLUMN space TEXT NOT NULL DEFAULT 'goods'",
    );
    // Defensive backfill if a future SQLite quirk left nulls (NOT NULL + DEFAULT
    // already covers normal upgrades).
    await customStatement(
      "UPDATE nodes SET space = 'goods' WHERE space IS NULL OR space = ''",
    );
  }

  /// M2.1: stock unit / unit cost columns, space-aware quantity CHECKs,
  /// stock_movements ledger.
  Future<void> _migrateToV6() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('ALTER TABLE nodes RENAME TO nodes_old_v5');
    await customStatement('''
CREATE TABLE nodes (
  id TEXT NOT NULL,
  inventory_id TEXT NOT NULL REFERENCES inventories (id) ON DELETE RESTRICT,
  parent_id TEXT NULL,
  space TEXT NOT NULL DEFAULT 'goods',
  name TEXT NOT NULL,
  node_type TEXT NOT NULL,
  quantity INTEGER NULL DEFAULT 1,
  description TEXT NULL,
  condition TEXT NULL,
  value_mode TEXT NULL DEFAULT 'financial',
  financial_value_cents INTEGER NULL DEFAULT 0,
  sentimental_value INTEGER NULL,
  stock_unit TEXT NULL,
  unit_cost_cents INTEGER NULL,
  status TEXT NOT NULL DEFAULT 'active',
  withdrawal_reason TEXT NULL,
  withdrawn_at TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (inventory_id, id),
  FOREIGN KEY (inventory_id, parent_id)
    REFERENCES nodes (inventory_id, id) ON DELETE RESTRICT,
  CHECK (id <> parent_id),
  CHECK (length(name) > 0),
  CHECK (space IN ('goods', 'stock', 'to_buy')),
  CHECK (node_type IN ('location', 'item', 'item_container')),
  CHECK (status IN ('active', 'withdrawn')),
  CHECK (
    (
      node_type = 'location'
      AND quantity IS NULL
      AND value_mode IS NULL
      AND financial_value_cents IS NULL
      AND sentimental_value IS NULL
      AND stock_unit IS NULL
      AND unit_cost_cents IS NULL
    )
    OR
    (
      space IN ('goods', 'to_buy')
      AND node_type IN ('item', 'item_container')
      AND typeof(quantity) = 'integer'
      AND quantity >= 1
      AND stock_unit IS NULL
      AND unit_cost_cents IS NULL
      AND (
        (
          value_mode IS NULL
          AND financial_value_cents IS NULL
          AND sentimental_value IS NULL
        )
        OR
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
    OR
    (
      space = 'stock'
      AND node_type = 'item_container'
      AND quantity IS NULL
      AND value_mode IS NULL
      AND financial_value_cents IS NULL
      AND sentimental_value IS NULL
      AND stock_unit IS NULL
      AND unit_cost_cents IS NULL
    )
    OR
    (
      space = 'stock'
      AND node_type = 'item'
      AND typeof(quantity) = 'integer'
      AND quantity >= 0
      AND stock_unit IS NOT NULL
      AND length(stock_unit) > 0
      AND value_mode IS NULL
      AND financial_value_cents IS NULL
      AND sentimental_value IS NULL
      AND (
        unit_cost_cents IS NULL
        OR (
          typeof(unit_cost_cents) = 'integer'
          AND unit_cost_cents >= 0
        )
      )
    )
  ),
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
)
''');
    await customStatement('''
INSERT INTO nodes (
  id, inventory_id, parent_id, space, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value,
  stock_unit, unit_cost_cents, status, withdrawal_reason,
  withdrawn_at, created_at, updated_at
)
SELECT
  id, inventory_id, parent_id, space, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value,
  NULL, NULL, status, withdrawal_reason, withdrawn_at,
  created_at, updated_at
FROM nodes_old_v5
''');
    await customStatement('DROP TABLE nodes_old_v5');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_parent_idx ON nodes (inventory_id, parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_active_name_idx '
      'ON nodes (inventory_id, status, name)',
    );
    await customStatement('''
CREATE TABLE stock_movements (
  id TEXT NOT NULL,
  inventory_id TEXT NOT NULL REFERENCES inventories (id) ON DELETE RESTRICT,
  node_id TEXT NOT NULL,
  movement_type TEXT NOT NULL,
  delta_quarters INTEGER NOT NULL,
  balance_after_quarters INTEGER NOT NULL,
  unit TEXT NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (inventory_id, node_id)
    REFERENCES nodes (inventory_id, id) ON DELETE CASCADE,
  CHECK (movement_type IN ('initial', 'supply', 'consume', 'correct')),
  CHECK (typeof(delta_quarters) = 'integer'),
  CHECK (typeof(balance_after_quarters) = 'integer'),
  CHECK (balance_after_quarters >= 0),
  CHECK (length(unit) > 0)
)
''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS stock_movements_node_idx '
      'ON stock_movements (inventory_id, node_id, created_at)',
    );
    await customStatement('PRAGMA foreign_keys = ON');
  }

  /// M2.1-C: optional stock_reference; normalize quarters → {0,1,2,4}; drop costs.
  Future<void> _migrateToV7() async {
    if (!await _nodesHasColumn('stock_reference')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN stock_reference INTEGER NULL',
      );
    }
    // Deterministic mapping of legacy multi-quarter balances → {0,1,2,4}.
    await customStatement('''
UPDATE nodes
SET quantity = CASE
  WHEN quantity IS NULL OR quantity <= 0 THEN 0
  WHEN quantity = 1 THEN 1
  WHEN quantity IN (2, 3) THEN 2
  ELSE 4
END
WHERE space = 'stock' AND node_type = 'item'
''');
    await customStatement('''
UPDATE nodes
SET unit_cost_cents = NULL,
    stock_unit = CASE
      WHEN stock_unit IS NULL OR stock_unit = '' THEN 'niveau'
      ELSE stock_unit
    END
WHERE space = 'stock' AND node_type = 'item'
''');
  }

  Future<bool> _nodesHasColumn(String column) async {
    final rows = await customSelect('PRAGMA table_info(nodes)').get();
    return rows.any((row) => row.read<String>('name') == column);
  }

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
