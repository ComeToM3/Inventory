import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';

const _timestamp = '2026-01-01T00:00:00.000Z';

void main() {
  test('conserve la valeur après deux fermetures et réouvertures', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_persistence_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), isNull);
      expect(
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .read<int>('foreign_keys'),
        1,
      );
      await database.saveVerificationValue('Première vérification');
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'Première vérification');
      await database.saveVerificationValue('Deuxième vérification');
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'Deuxième vérification');
    } finally {
      await database?.close();
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final file = File('$path$suffix');
        if (await file.exists()) await file.delete();
      }
      await directory.delete();
    }
  });

  test('applique les relations et contraintes SQLite du modèle', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_schema_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      database = InventoryDatabase(NativeDatabase(File(path)));
      final inventory = await database.select(database.inventories).getSingle();

      await _insertNode(
        database,
        inventoryId: inventory.id,
        id: 'root',
        type: 'location',
      );
      await _insertNode(
        database,
        inventoryId: inventory.id,
        id: 'container',
        type: 'item_container',
        parentId: 'root',
      );
      await _insertNode(
        database,
        inventoryId: inventory.id,
        id: 'item',
        type: 'item',
        parentId: 'container',
      );
      await _insertNode(
        database,
        inventoryId: inventory.id,
        id: 'item-container',
        type: 'item_container',
        parentId: 'root',
      );

      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'category',
              inventoryId: inventory.id,
              name: 'Électronique',
              createdAt: _timestamp,
              updatedAt: _timestamp,
            ),
          );
      await database
          .into(database.nodeCategories)
          .insert(
            NodeCategoriesCompanion.insert(
              inventoryId: inventory.id,
              nodeId: 'item',
              categoryId: 'category',
            ),
          );
      expect(await database.select(database.nodes).get(), hasLength(4));
      expect(
        await database.select(database.nodeCategories).get(),
        hasLength(1),
      );

      await expectLater(
        database
            .into(database.nodeCategories)
            .insert(
              NodeCategoriesCompanion.insert(
                inventoryId: inventory.id,
                nodeId: 'item',
                categoryId: 'category',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        _insertNode(
          database,
          inventoryId: inventory.id,
          id: 'legacy-container',
          type: 'container',
          parentId: 'root',
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        _insertNode(
          database,
          inventoryId: inventory.id,
          id: 'orphan',
          type: 'item',
          parentId: 'missing-parent',
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        _insertNode(
          database,
          inventoryId: 'missing-inventory',
          id: 'wrong-inventory',
          type: 'location',
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        _insertNode(
          database,
          inventoryId: inventory.id,
          id: 'zero-quantity',
          type: 'item',
          quantity: 0,
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'both-value-modes',
                inventoryId: inventory.id,
                parentId: const Value('root'),
                name: 'Both modes',
                nodeType: 'item',
                quantity: const Value(1),
                valueMode: const Value('financial'),
                financialValueCents: const Value(100),
                sentimentalValue: const Value(3),
                createdAt: _timestamp,
                updatedAt: _timestamp,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        _insertNode(
          database,
          inventoryId: inventory.id,
          id: 'invalid-rating',
          type: 'item',
          valueMode: 'sentimental',
          sentimentalValue: 6,
        ),
        throwsA(isA<SqliteException>()),
      );

      await expectLater(
        (database.delete(
          database.nodes,
        )..where((node) => node.id.equals('container'))).go(),
        throwsA(isA<SqliteException>()),
      );

      await (database.delete(
        database.categories,
      )..where((category) => category.id.equals('category'))).go();
      expect(await database.select(database.nodeCategories).get(), isEmpty);
      expect(
        await (database.select(
          database.nodes,
        )..where((node) => node.id.equals('item'))).getSingleOrNull(),
        isNotNull,
      );
    } finally {
      await database?.close();
      await _removeDatabase(path, directory);
    }
  });

  test('annule toute la transaction après une erreur SQLite', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_transaction_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      final db = InventoryDatabase(NativeDatabase(File(path)));
      database = db;
      final inventory = await db.select(db.inventories).getSingle();

      await expectLater(
        db.transaction(() async {
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'rollback',
                  inventoryId: inventory.id,
                  name: 'Rollback',
                  createdAt: _timestamp,
                  updatedAt: _timestamp,
                ),
              );
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: 'rollback',
                  inventoryId: inventory.id,
                  name: 'Duplicate',
                  createdAt: _timestamp,
                  updatedAt: _timestamp,
                ),
              );
        }),
        throwsA(isA<SqliteException>()),
      );

      expect(
        await (db.select(
          db.categories,
        )..where((category) => category.id.equals('rollback'))).get(),
        isEmpty,
      );
    } finally {
      await database?.close();
      await _removeDatabase(path, directory);
    }
  });

  test('migre une vraie base version 1 sans perdre sa valeur', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_migration_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      database = InventoryDatabase(
        NativeDatabase(
          File(path),
          setup: (rawDatabase) {
            rawDatabase.execute(
              'CREATE TABLE local_verification_entries '
              '(id INTEGER NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
            );
            rawDatabase.execute(
              "INSERT INTO local_verification_entries (id, value) "
              "VALUES (1, 'kept-from-v1')",
            );
            rawDatabase.execute('PRAGMA user_version = 1');
          },
        ),
      );

      expect(await database.readVerificationValue(), 'kept-from-v1');
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        7,
      );
      expect(await database.select(database.inventories).get(), hasLength(1));
      final columns = await database.customSelect('PRAGMA table_info(nodes)').get();
      expect(
        columns.any((row) => row.read<String>('name') == 'stock_reference'),
        isTrue,
      );
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'kept-from-v1');
    } finally {
      await database?.close();
      await _removeDatabase(path, directory);
    }
  });

  test('migre v6→v7 sans dupliquer stock_reference et normalise le Stock', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inventory_migration_v6_',
    );
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    InventoryDatabase? database;

    try {
      database = InventoryDatabase(
        NativeDatabase(
          File(path),
          setup: (raw) {
            raw.execute('''
CREATE TABLE inventories (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
            raw.execute('''
CREATE TABLE nodes (
  id TEXT NOT NULL PRIMARY KEY,
  inventory_id TEXT NOT NULL,
  parent_id TEXT NULL,
  space TEXT NOT NULL DEFAULT 'goods',
  name TEXT NOT NULL,
  node_type TEXT NOT NULL,
  quantity INTEGER NULL DEFAULT 1,
  description TEXT NULL,
  condition TEXT NULL,
  value_mode TEXT NULL,
  financial_value_cents INTEGER NULL,
  sentimental_value INTEGER NULL,
  stock_unit TEXT NULL,
  unit_cost_cents INTEGER NULL,
  status TEXT NOT NULL DEFAULT 'active',
  withdrawal_reason TEXT NULL,
  withdrawn_at TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
            raw.execute(
              "INSERT INTO inventories (id, name, created_at, updated_at) "
              "VALUES ('inv-1', 'Principal', '2024-01-01T00:00:00.000Z', "
              "'2024-01-01T00:00:00.000Z')",
            );
            raw.execute(
              "INSERT INTO nodes (id, inventory_id, parent_id, space, name, "
              "node_type, quantity, stock_unit, unit_cost_cents, status, "
              "created_at, updated_at) VALUES "
              "('loc-1', 'inv-1', NULL, 'stock', 'Cuisine', 'location', NULL, "
              "NULL, NULL, 'active', '2024-01-01T00:00:00.000Z', "
              "'2024-01-01T00:00:00.000Z')",
            );
            raw.execute(
              "INSERT INTO nodes (id, inventory_id, parent_id, space, name, "
              "node_type, quantity, stock_unit, unit_cost_cents, status, "
              "created_at, updated_at) VALUES "
              "('item-1', 'inv-1', 'loc-1', 'stock', 'Cafe', 'item', 8, "
              "'paquet', 250, 'active', '2024-01-01T00:00:00.000Z', "
              "'2024-01-01T00:00:00.000Z')",
            );
            raw.execute('PRAGMA user_version = 6');
          },
        ),
      );

      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        7,
      );
      final columns =
          await database.customSelect('PRAGMA table_info(nodes)').get();
      expect(
        columns.where((row) => row.read<String>('name') == 'stock_reference'),
        hasLength(1),
      );
      final cafe = await (database.select(database.nodes)
            ..where((n) => n.id.equals('item-1')))
          .getSingle();
      expect(cafe.quantity, 4); // 8 quarts → niveau 1
      expect(cafe.unitCostCents, isNull);
      expect(cafe.stockUnit, 'paquet');
      expect(cafe.stockReference, isNull);

      // Re-open: must not fail with duplicate column.
      await database.close();
      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        7,
      );
      final again = await (database.select(database.nodes)
            ..where((n) => n.id.equals('item-1')))
          .getSingle();
      expect(again.quantity, 4);
    } finally {
      await database?.close();
      await _removeDatabase(path, directory);
    }
  });
}

Future<void> _insertNode(
  InventoryDatabase database, {
  required String inventoryId,
  required String id,
  required String type,
  String? parentId,
  int quantity = 1,
  String valueMode = 'financial',
  int financialValueCents = 0,
  int? sentimentalValue,
}) {
  final isItem = type == 'item' || type == 'item_container';
  return database
      .into(database.nodes)
      .insert(
        NodesCompanion.insert(
          id: id,
          inventoryId: inventoryId,
          parentId: Value(parentId),
          name: id,
          nodeType: type,
          quantity: Value(isItem ? quantity : null),
          valueMode: Value(isItem ? valueMode : null),
          financialValueCents: Value(
            isItem && valueMode == 'financial' ? financialValueCents : null,
          ),
          sentimentalValue: Value(
            isItem && valueMode == 'sentimental' ? sentimentalValue : null,
          ),
          createdAt: _timestamp,
          updatedAt: _timestamp,
        ),
      );
}

Future<void> _removeDatabase(String path, Directory directory) async {
  for (final suffix in ['', '-journal', '-wal', '-shm']) {
    final file = File('$path$suffix');
    if (await file.exists()) await file.delete();
  }
  await directory.delete();
}
