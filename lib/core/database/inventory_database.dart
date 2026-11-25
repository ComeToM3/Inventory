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

  /// To-buy: wished quantity; null outside to-buy needs.
  IntColumn get desiredQuantity => integer().nullable()();

  /// To-buy: optional target unit price in CAD cents.
  IntColumn get targetPriceCents => integer().nullable()();

  /// Manual display order among active siblings (same parent + space).
  IntColumn get siblingOrder =>
      integer().withDefault(const Constant(0))();

  /// Snapshot of advanced-section expansion at creation (or later toggles).
  /// Independent of the global default preference after the node exists.
  BoolColumn get showAdvanced =>
      boolean().withDefault(const Constant(false))();

  /// Optional barcode / reference (goods advanced fields, M4.1-B).
  TextColumn get barcodeRef => text().nullable()();

  /// Optional purchase date as `yyyy-MM-dd` (goods only).
  TextColumn get purchaseDate => text().nullable()();

  /// Optional amount paid in CAD cents (independent of valuation).
  IntColumn get purchasePriceCents => integer().nullable()();

  /// Optional seller / place of purchase.
  TextColumn get purchasePlace => text().nullable()();

  /// Goods objective: none | sell | repair.
  TextColumn get objective =>
      text().withDefault(const Constant('none'))();

  /// Relative path to the optional main photo WebP (`photos/….webp`).
  TextColumn get photoRelPath => text().nullable()();

  /// Manual icon catalog key; null = resolve automatically from the name.
  TextColumn get iconKey => text().nullable()();

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
    "CHECK (status IN ('active', 'withdrawn', 'acquired', 'abandoned'))",
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
        AND desired_quantity IS NULL
        AND target_price_cents IS NULL
      )
      OR
      (
        space = 'goods'
        AND node_type IN ('item', 'item_container')
        AND typeof(quantity) = 'integer'
        AND quantity >= 1
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
        AND desired_quantity IS NULL
        AND target_price_cents IS NULL
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
        space = 'to_buy'
        AND node_type = 'item_container'
        AND quantity IS NULL
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
        AND desired_quantity IS NULL
        AND target_price_cents IS NULL
      )
      OR
      (
        space = 'to_buy'
        AND node_type = 'item'
        AND typeof(quantity) = 'integer'
        AND quantity >= 0
        AND typeof(desired_quantity) = 'integer'
        AND desired_quantity >= 1
        AND desired_quantity >= quantity
        AND stock_unit IS NULL
        AND unit_cost_cents IS NULL
        AND stock_reference IS NULL
        AND value_mode IS NULL
        AND financial_value_cents IS NULL
        AND sentimental_value IS NULL
        AND (
          target_price_cents IS NULL
          OR (
            typeof(target_price_cents) = 'integer'
            AND target_price_cents >= 0
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
        AND desired_quantity IS NULL
        AND target_price_cents IS NULL
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
        AND desired_quantity IS NULL
        AND target_price_cents IS NULL
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
        AND space = 'goods'
        AND node_type IN ('item', 'item_container')
        AND parent_id IS NULL
        AND withdrawal_reason IN ('loss', 'donation', 'breakage', 'sale')
        AND withdrawn_at IS NOT NULL
      )
      OR
      (
        status IN ('acquired', 'abandoned')
        AND space = 'to_buy'
        AND node_type = 'item'
        AND parent_id IS NULL
        AND withdrawal_reason IS NULL
        AND withdrawn_at IS NULL
      )
    )
    ''',
  ];
}

@TableIndex(
  name: 'purchase_events_need_idx',
  columns: {#inventoryId, #needNodeId, #createdAt},
)
class PurchaseEvents extends Table {
  TextColumn get id => text()();

  TextColumn get inventoryId =>
      text().references(Inventories, #id, onDelete: KeyAction.restrict)();

  TextColumn get needNodeId => text()();

  TextColumn get eventType => text()();

  IntColumn get quantity => integer()();

  IntColumn get targetPriceCents => integer().nullable()();

  IntColumn get paidPriceCents => integer().nullable()();

  TextColumn get destinationSpace => text().nullable()();

  TextColumn get destinationNodeId => text().nullable()();

  TextColumn get destinationParentId => text().nullable()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (inventory_id, need_node_id) '
        'REFERENCES nodes (inventory_id, id) ON DELETE CASCADE',
    "CHECK (event_type IN ('acquire', 'abandon'))",
    "CHECK (typeof(quantity) = 'integer' AND quantity >= 0)",
    '''
    CHECK (
      paid_price_cents IS NULL
      OR (typeof(paid_price_cents) = 'integer' AND paid_price_cents >= 0)
    )
    ''',
    '''
    CHECK (
      target_price_cents IS NULL
      OR (typeof(target_price_cents) = 'integer' AND target_price_cents >= 0)
    )
    ''',
    '''
    CHECK (
      (
        event_type = 'abandon'
        AND destination_space IS NULL
        AND destination_node_id IS NULL
      )
      OR
      (
        event_type = 'acquire'
        AND destination_space IN ('goods', 'stock')
        AND destination_node_id IS NOT NULL
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

/// Key/value app settings persisted with the inventory (backup-ready later).
class AppPreferences extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Supporting documents attached to a goods item (M4.2-B). Files stay on disk.
@DataClassName('NodeDocumentRow')
@TableIndex(
  name: 'node_documents_node_idx',
  columns: {#inventoryId, #nodeId, #sortIndex},
)
class NodeDocuments extends Table {
  TextColumn get id => text()();

  TextColumn get inventoryId =>
      text().references(Inventories, #id, onDelete: KeyAction.restrict)();

  TextColumn get nodeId => text()();

  /// Original display name when available.
  TextColumn get displayName => text()();

  /// Relative path under app support (`documents/….ext`).
  TextColumn get relPath => text()();

  TextColumn get mimeType => text()();

  IntColumn get byteSize => integer()();

  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (inventory_id, node_id) '
        'REFERENCES nodes (inventory_id, id) ON DELETE CASCADE',
    'CHECK (length(display_name) > 0)',
    'CHECK (length(rel_path) > 0)',
    'CHECK (typeof(byte_size) = \'integer\' AND byte_size > 0)',
  ];
}

/// Internal restore journal; never exported. At most one row is kept by the
/// application (`pending` → `db_ready` → `committed`).
class RestorationJournalEntries extends Table {
  TextColumn get operationId => text()();

  TextColumn get status => text()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {operationId};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('pending', 'db_ready', 'committed'))",
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
    PurchaseEvents,
    AppPreferences,
    NodeDocuments,
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

  /// Global default for new fiches only (M4.1-A).
  static const showAdvancedByDefaultKey = 'show_advanced_by_default';

  /// One-shot: clear goods `sell` written before Objectif was separated from qty taps.
  static const objectiveNoneRepairKey = 'ux_arb_02_objective_none_repair';

  @override
  int get schemaVersion => 15;

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
      if (from < 8 && to >= 8) {
        await _migrateToV8();
      }
      if (from < 9 && to >= 9) {
        await _migrateToV9();
      }
      if (from < 10 && to >= 10) {
        await _migrateToV10();
      }
      if (from < 11 && to >= 11) {
        await _migrateToV11();
      }
      if (from < 12 && to >= 12) {
        await _migrateToV12();
      }
      if (from < 13 && to >= 13) {
        await _migrateToV13(m);
      }
      if (from < 14 && to >= 14) {
        await _migrateToV14();
      }
      if (from < 15 && to >= 15) {
        await _migrateToV15();
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

  /// M2.2: to-buy need fields + purchase_events ledger; status acquired/abandoned.
  Future<void> _migrateToV8() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('ALTER TABLE nodes RENAME TO nodes_old_v7');
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
  stock_reference INTEGER NULL,
  desired_quantity INTEGER NULL,
  target_price_cents INTEGER NULL,
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
  CHECK (status IN ('active', 'withdrawn', 'acquired', 'abandoned'))
)
''');
    // Full CHECKs match onCreate; keep migration INSERT permissive then rely on
    // engine for new writes. Existing rows are goods/stock only.
    await customStatement('''
INSERT INTO nodes (
  id, inventory_id, parent_id, space, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value,
  stock_unit, unit_cost_cents, stock_reference, desired_quantity,
  target_price_cents, status, withdrawal_reason, withdrawn_at,
  created_at, updated_at
)
SELECT
  id, inventory_id, parent_id, space, name, node_type, quantity, description,
  condition, value_mode, financial_value_cents, sentimental_value,
  stock_unit, unit_cost_cents, stock_reference, NULL, NULL,
  status, withdrawal_reason, withdrawn_at, created_at, updated_at
FROM nodes_old_v7
''');
    await customStatement('DROP TABLE nodes_old_v7');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_parent_idx ON nodes (inventory_id, parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS nodes_active_name_idx '
      'ON nodes (inventory_id, status, name)',
    );
    await customStatement('''
CREATE TABLE purchase_events (
  id TEXT NOT NULL,
  inventory_id TEXT NOT NULL REFERENCES inventories (id) ON DELETE RESTRICT,
  need_node_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  target_price_cents INTEGER NULL,
  paid_price_cents INTEGER NULL,
  destination_space TEXT NULL,
  destination_node_id TEXT NULL,
  destination_parent_id TEXT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (inventory_id, need_node_id)
    REFERENCES nodes (inventory_id, id) ON DELETE CASCADE,
  CHECK (event_type IN ('acquire', 'abandon')),
  CHECK (typeof(quantity) = 'integer' AND quantity >= 0)
)
''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS purchase_events_need_idx '
      'ON purchase_events (inventory_id, need_node_id, created_at)',
    );
    await customStatement('PRAGMA foreign_keys = ON');
  }

  /// M3.1: persistent sibling display order (D09).
  Future<void> _migrateToV9() async {
    if (!await _nodesHasColumn('sibling_order')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN sibling_order INTEGER NOT NULL DEFAULT 0',
      );
    }
    // Seed from previous display order: items before locations, then name, id.
    final rows = await customSelect(
      '''
SELECT id, inventory_id, parent_id, space, status, node_type, name
FROM nodes
WHERE status = 'active'
ORDER BY inventory_id,
         space,
         CASE WHEN parent_id IS NULL THEN 0 ELSE 1 END,
         parent_id,
         CASE WHEN node_type = 'location' THEN 1 ELSE 0 END,
         name COLLATE NOCASE,
         id
''',
      readsFrom: {nodes},
    ).get();

    String? groupKey;
    var index = 0;
    for (final row in rows) {
      final inventoryId = row.read<String>('inventory_id');
      final space = row.read<String>('space');
      final parentId = row.readNullable<String>('parent_id');
      final key = '$inventoryId|$space|${parentId ?? ''}';
      if (key != groupKey) {
        groupKey = key;
        index = 0;
      }
      final id = row.read<String>('id');
      await customStatement(
        'UPDATE nodes SET sibling_order = ? WHERE id = ?',
        [index, id],
      );
      index += 1;
    }
  }

  /// M4.1-A: per-node advanced expansion + global default preference.
  Future<void> _migrateToV10() async {
    if (!await _nodesHasColumn('show_advanced')) {
      // Existing fiches stay collapsed; global preference never rewrites them.
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN show_advanced INTEGER NOT NULL DEFAULT 0',
      );
    }
    await customStatement('''
CREATE TABLE IF NOT EXISTS app_preferences (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
)
''');
  }

  /// M4.1-B: optional goods advanced fields (barcode, purchase, objective).
  Future<void> _migrateToV11() async {
    if (!await _nodesHasColumn('barcode_ref')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN barcode_ref TEXT NULL',
      );
    }
    if (!await _nodesHasColumn('purchase_date')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN purchase_date TEXT NULL',
      );
    }
    if (!await _nodesHasColumn('purchase_price_cents')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN purchase_price_cents INTEGER NULL',
      );
    }
    if (!await _nodesHasColumn('purchase_place')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN purchase_place TEXT NULL',
      );
    }
    if (!await _nodesHasColumn('objective')) {
      await customStatement(
        "ALTER TABLE nodes ADD COLUMN objective TEXT NOT NULL DEFAULT 'none'",
      );
    }
  }

  /// M4.2-A: optional main photo reference (file on disk, not BLOB).
  Future<void> _migrateToV12() async {
    if (!await _nodesHasColumn('photo_rel_path')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN photo_rel_path TEXT NULL',
      );
    }
  }

  /// M4.2-B: supporting documents table (refs only; files on disk).
  Future<void> _migrateToV13(Migrator m) async {
    await m.createTable(nodeDocuments);
    await m.createIndex(nodeDocumentsNodeIdx);
  }

  /// M5.1: optional manual icon key (auto icons stay computed from name).
  Future<void> _migrateToV14() async {
    if (!await _nodesHasColumn('icon_key')) {
      await customStatement(
        'ALTER TABLE nodes ADD COLUMN icon_key TEXT NULL',
      );
    }
  }

  /// M5.3-A: journal status `db_ready` between SQLite replace and media commit.
  Future<void> _migrateToV15() async {
    await customStatement('''
CREATE TABLE restoration_journal_entries_new (
  operation_id TEXT NOT NULL PRIMARY KEY,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  CHECK (status IN ('pending', 'db_ready', 'committed'))
)
''');
    await customStatement('''
INSERT INTO restoration_journal_entries_new (operation_id, status, created_at)
SELECT operation_id, status, created_at FROM restoration_journal_entries
''');
    await customStatement('DROP TABLE restoration_journal_entries');
    await customStatement(
      'ALTER TABLE restoration_journal_entries_new '
      'RENAME TO restoration_journal_entries',
    );
  }

  Future<bool> readShowAdvancedByDefault() async {
    final row =
        await (select(appPreferences)..where(
              (pref) => pref.key.equals(showAdvancedByDefaultKey),
            ))
            .getSingleOrNull();
    return row?.value == '1';
  }

  Future<void> writeShowAdvancedByDefault(bool value) {
    return into(appPreferences).insertOnConflictUpdate(
      AppPreferencesCompanion.insert(
        key: showAdvancedByDefaultKey,
        value: value ? '1' : '0',
      ),
    );
  }

  /// UX-ARB-02: default objective is Aucun — reset prior accidental `sell` once.
  Future<void> repairAccidentalSellObjectivesOnce() async {
    final done =
        await (select(appPreferences)..where(
              (pref) => pref.key.equals(objectiveNoneRepairKey),
            ))
            .getSingleOrNull();
    if (done?.value == '1') return;
    final now = DateTime.now().toUtc().toIso8601String();
    await (update(nodes)..where(
          (node) =>
              node.space.equals('goods') & node.objective.equals('sell'),
        ))
        .write(
          NodesCompanion(
            objective: const Value('none'),
            updatedAt: Value(now),
          ),
        );
    await into(appPreferences).insertOnConflictUpdate(
      AppPreferencesCompanion.insert(
        key: objectiveNoneRepairKey,
        value: '1',
      ),
    );
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
