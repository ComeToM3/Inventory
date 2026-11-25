import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:inventory/core/domain/purchase_models.dart';
import 'package:inventory/core/domain/stock_quantity.dart';

final _now = DateTime.utc(2026, 11, 18, 12);

void main() {
  late Directory directory;
  late String path;
  late InventoryDatabase database;
  late InventoryEngine engine;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_purchase_');
    path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    database = InventoryDatabase(NativeDatabase(File(path)));
    engine = InventoryEngine(database, clock: () => _now);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('crée un besoin isolé dans to_buy', () async {
    final root = await engine.createNode(
      name: 'Courses',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final need = await engine.createNode(
      name: 'Ampoule',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: root.id,
      quantity: 3,
      targetPriceCents: 499,
    );

    expect(need.space, InventorySpace.toBuy);
    expect(need.quantity, 3);
    expect(need.desiredQuantity, 3);
    expect(need.targetPriceCents, 499);
    expect(need.isToBuyNeed, isTrue);
    expect(need.isPartiallyAcquired, isFalse);

    final goodsRoots =
        await engine.getRootLocations(space: InventorySpace.goods);
    expect(goodsRoots, isEmpty);
  });

  test('acquisition partielle puis complète vers Biens', () async {
    final buyRoot = await engine.createNode(
      name: 'Magasin',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final need = await engine.createNode(
      name: 'Ampoule',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 3,
      targetPriceCents: 200,
    );
    final goodsRoot = await engine.createNode(
      name: 'Maison',
      type: NodeType.location,
      space: InventorySpace.goods,
    );

    final partial = await engine.acquireNeed(
      need.id,
      quantity: 1,
      destinationSpace: InventorySpace.goods,
      destinationParentId: goodsRoot.id,
      paidPriceCents: 250,
      goodsValuation: const FinancialValuation(100),
    );
    expect(partial.status, NodeStatus.active);
    expect(partial.quantity, 2);
    expect(partial.desiredQuantity, 3);
    expect(partial.isPartiallyAcquired, isTrue);
    expect(partial.parentId, buyRoot.id);

    final goodsChildren = await engine.getChildren(goodsRoot.id);
    expect(goodsChildren, hasLength(1));
    expect(goodsChildren.single.quantity, 1);
    expect(goodsChildren.single.valuation, const FinancialValuation(100));

    final complete = await engine.acquireNeed(
      need.id,
      quantity: 2,
      destinationSpace: InventorySpace.goods,
      destinationParentId: goodsRoot.id,
      goodsValuation: null,
    );
    expect(complete.status, NodeStatus.acquired);
    expect(complete.quantity, 0);
    expect(complete.parentId, isNull);

    final stillActive = await engine.getChildren(buyRoot.id);
    expect(stillActive, isEmpty);

    final events = await engine.getRecentPurchaseEvents();
    expect(events, hasLength(2));
    expect(events.every((e) => e.entry.type == PurchaseEventType.acquire), isTrue);
    expect(events.map((e) => e.entry.quantity), containsAll([1, 2]));
  });

  test('acquisition Stock nouveau produit à niveau 1 sans fusion auto', () async {
    final buyRoot = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final need = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 2,
    );
    final stockRoot = await engine.createNode(
      name: 'Garde-manger',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final existing = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: stockRoot.id,
    );
    await engine.setStockLevel(existing.id, StockLevel.half);

    final after = await engine.acquireNeed(
      need.id,
      quantity: 2,
      destinationSpace: InventorySpace.stock,
      destinationParentId: stockRoot.id,
      stockMode: StockAcquireMode.createNew,
    );
    expect(after.status, NodeStatus.acquired);

    final stockItems = await engine.getChildren(stockRoot.id);
    expect(stockItems, hasLength(2));
    final created = stockItems.where((n) => n.id != existing.id).single;
    expect(created.stockLevel, StockLevel.full);
    expect(
      (await engine.getNode(existing.id)).stockLevel,
      StockLevel.half,
    );
  });

  test('association Stock explicite conserve ou remet à 1', () async {
    final buyRoot = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final needA = await engine.createNode(
      name: 'Riz',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 1,
    );
    final needB = await engine.createNode(
      name: 'Riz bis',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 1,
    );
    final stockRoot = await engine.createNode(
      name: 'Cellier',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final product = await engine.createNode(
      name: 'Riz',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: stockRoot.id,
    );
    await engine.setStockLevel(product.id, StockLevel.quarter);

    await engine.acquireNeed(
      needA.id,
      quantity: 1,
      destinationSpace: InventorySpace.stock,
      existingStockProductId: product.id,
      stockMode: StockAcquireMode.keepLevel,
    );
    expect(
      (await engine.getNode(product.id)).stockLevel,
      StockLevel.quarter,
    );

    await engine.acquireNeed(
      needB.id,
      quantity: 1,
      destinationSpace: InventorySpace.stock,
      existingStockProductId: product.id,
      stockMode: StockAcquireMode.resetToFull,
    );
    expect(
      (await engine.getNode(product.id)).stockLevel,
      StockLevel.full,
    );
  });

  test('abandon distinct de l’achat et historique isolé', () async {
    final buyRoot = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final need = await engine.createNode(
      name: 'Thé',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 4,
    );

    final abandoned = await engine.abandonNeed(need.id);
    expect(abandoned.status, NodeStatus.abandoned);
    expect(abandoned.parentId, isNull);
    expect(await engine.getChildren(buyRoot.id), isEmpty);

    final events = await engine.getRecentPurchaseEvents();
    expect(events, hasLength(1));
    expect(events.single.entry.type, PurchaseEventType.abandon);
    expect(events.single.entry.quantity, 4);
    expect(events.single.entry.destinationSpace, isNull);

    expect(await engine.getRecentStockMovements(), isEmpty);
  });

  test('atomicité : destination invalide ne réduit pas le besoin', () async {
    final buyRoot = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    final need = await engine.createNode(
      name: 'Piles',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 5,
    );

    await expectLater(
      engine.acquireNeed(
        need.id,
        quantity: 2,
        destinationSpace: InventorySpace.goods,
      ),
      throwsA(
        isA<InventoryException>().having(
          (e) => e.code,
          'code',
          InventoryErrorCode.parentRequired,
        ),
      ),
    );

    final reloaded = await engine.getNode(need.id);
    expect(reloaded.quantity, 5);
    expect(reloaded.status, NodeStatus.active);
    expect(await engine.getRecentPurchaseEvents(), isEmpty);
  });

  test('recherche to_buy isolée des autres espaces', () async {
    final buyRoot = await engine.createNode(
      name: 'Liste',
      type: NodeType.location,
      space: InventorySpace.toBuy,
    );
    await engine.createNode(
      name: 'Ampoule',
      type: NodeType.item,
      space: InventorySpace.toBuy,
      parentId: buyRoot.id,
      quantity: 2,
    );
    final goodsRoot = await engine.createNode(
      name: 'Maison',
      type: NodeType.location,
      space: InventorySpace.goods,
    );
    await engine.createNode(
      name: 'Ampoule',
      type: NodeType.item,
      space: InventorySpace.goods,
      parentId: goodsRoot.id,
    );

    final toBuy = await engine.searchNodes(
      const InventorySearchCriteria(
        name: 'Ampoule',
        space: InventorySpace.toBuy,
      ),
    );
    expect(toBuy.results, hasLength(1));
    expect(toBuy.results.single.name, 'Ampoule');

    final goods = await engine.searchNodes(
      const InventorySearchCriteria(
        name: 'Ampoule',
        space: InventorySpace.goods,
      ),
    );
    expect(goods.results, hasLength(1));
  });
}
