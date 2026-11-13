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
        type: 'container',
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
        2,
      );
      expect(await database.select(database.inventories).get(), hasLength(1));
      await database.close();
      database = null;

      database = InventoryDatabase(NativeDatabase(File(path)));
      expect(await database.readVerificationValue(), 'kept-from-v1');
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
