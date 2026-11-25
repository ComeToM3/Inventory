import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:inventory/core/domain/stock_quantity.dart';

final _now = DateTime.utc(2026, 11, 18, 16);

void main() {
  late Directory directory;
  late String path;
  late InventoryDatabase database;
  late InventoryEngine engine;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_organize_');
    path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    database = InventoryDatabase(NativeDatabase(File(path)));
    engine = InventoryEngine(database, clock: () => _now);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('réordonne des frères et conserve l’ordre après réouverture', () async {
    final a = await engine.createNode(name: 'Cuisine', type: NodeType.location);
    final b = await engine.createNode(name: 'Salon', type: NodeType.location);
    final c = await engine.createNode(name: 'Chambre', type: NodeType.location);

    expect(
      (await engine.getRootLocations()).map((n) => n.name),
      ['Cuisine', 'Salon', 'Chambre'],
    );

    await engine.reorderSiblings(
      space: InventorySpace.goods,
      parentId: null,
      orderedIds: [c.id, a.id, b.id],
    );

    expect(
      (await engine.getRootLocations()).map((n) => n.name),
      ['Chambre', 'Cuisine', 'Salon'],
    );

    await database.close();
    database = InventoryDatabase(NativeDatabase(File(path)));
    engine = InventoryEngine(database, clock: () => _now);

    expect(
      (await engine.getRootLocations()).map((n) => n.name),
      ['Chambre', 'Cuisine', 'Salon'],
    );
  });

  test('déplace vers un parent valide et place en fin de liste', () async {
    final cuisine =
        await engine.createNode(name: 'Cuisine', type: NodeType.location);
    final cellier =
        await engine.createNode(name: 'Cellier', type: NodeType.location);
    final cafe = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      parentId: cuisine.id,
    );
    await engine.createNode(
      name: 'Farine',
      type: NodeType.item,
      parentId: cellier.id,
    );

    final moved = await engine.moveNode(cafe.id, cellier.id);
    expect(moved.parentId, cellier.id);

    final children = await engine.getChildren(cellier.id);
    expect(children.map((n) => n.name), ['Farine', 'Café']);
  });

  test('refuse un cycle et un parent incompatible', () async {
    final home =
        await engine.createNode(name: 'Maison', type: NodeType.location);
    final box = await engine.createNode(
      name: 'Boîte',
      type: NodeType.itemContainer,
      parentId: home.id,
    );
    final item = await engine.createNode(
      name: 'Câble',
      type: NodeType.item,
      parentId: box.id,
    );

    await expectLater(
      engine.moveNode(home.id, box.id),
      throwsA(
        isA<InventoryException>().having(
          (e) => e.code,
          'code',
          InventoryErrorCode.cycleDetected,
        ),
      ),
    );

    await expectLater(
      engine.moveNode(item.id, item.id),
      throwsA(isA<InventoryException>()),
    );
  });

  test('refuse un déplacement entre espaces', () async {
    final goods =
        await engine.createNode(name: 'Maison', type: NodeType.location);
    final stock = await engine.createNode(
      name: 'Cellier',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final cafe = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      parentId: goods.id,
    );

    await expectLater(
      engine.moveNode(cafe.id, stock.id),
      throwsA(
        isA<InventoryException>().having(
          (e) => e.code,
          'code',
          InventoryErrorCode.spaceMismatch,
        ),
      ),
    );
  });

  test('réordonner Stock préserve le niveau', () async {
    final root = await engine.createNode(
      name: 'Cellier',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final a = await engine.createNode(
      name: 'Riz',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: root.id,
    );
    final b = await engine.createNode(
      name: 'Pâtes',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: root.id,
    );
    await engine.setStockLevel(a.id, StockLevel.quarter);

    await engine.reorderSiblings(
      space: InventorySpace.stock,
      parentId: root.id,
      orderedIds: [b.id, a.id],
    );

    expect((await engine.getNode(a.id)).stockLevel, StockLevel.quarter);
    expect(
      (await engine.getChildren(root.id)).map((n) => n.name),
      ['Pâtes', 'Riz'],
    );
  });

  test('réordonner À acheter préserve quantités et prix cible', () async {
    final root = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final amp = await engine.createNode(
      name: 'Ampoule',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: root.id,
      quantity: 3,
      targetPriceCents: 499,
    );
    final cafe = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: root.id,
      quantity: 2,
    );

    await engine.reorderSiblings(
      space: InventorySpace.toBuy,
      parentId: root.id,
      orderedIds: [cafe.id, amp.id],
    );

    final again = await engine.getNode(amp.id);
    expect(again.quantity, 3);
    expect(again.desiredQuantity, 3);
    expect(again.targetPriceCents, 499);
    expect(
      (await engine.getChildren(root.id)).map((n) => n.name),
      ['Café', 'Ampoule'],
    );
  });
}
