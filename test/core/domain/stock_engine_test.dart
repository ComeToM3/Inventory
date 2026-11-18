import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:inventory/core/domain/stock_quantity.dart';

void main() {
  late InventoryDatabase database;
  late InventoryEngine engine;

  setUp(() {
    database = InventoryDatabase(NativeDatabase.memory());
    engine = InventoryEngine(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('new stock product starts full and cycles independently', () async {
    final kitchen = await engine.createNode(
      name: 'Cuisine',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final coffee = await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: kitchen.id,
      stockReference: 10,
    );
    expect(coffee.stockLevel, StockLevel.full);
    expect(coffee.quantity, StockLevel.full.storageQuarters);
    expect(coffee.stockReference, 10);
    expect(coffee.unitCostCents, isNull);

    var current = await engine.cycleStockLevel(coffee.id);
    expect(current.stockLevel, StockLevel.half);
    current = await engine.cycleStockLevel(coffee.id);
    expect(current.stockLevel, StockLevel.quarter);
    current = await engine.cycleStockLevel(coffee.id);
    expect(current.stockLevel, StockLevel.empty);
    current = await engine.cycleStockLevel(coffee.id);
    expect(current.stockLevel, StockLevel.full);

    final oil = await engine.createNode(
      name: 'Huile',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: kitchen.id,
    );
    await engine.cycleStockLevel(oil.id);
    expect((await engine.getNode(oil.id)).stockLevel, StockLevel.half);
    expect((await engine.getNode(coffee.id)).stockLevel, StockLevel.full);

    final movements = await engine.getStockMovements(coffee.id);
    expect(movements.length, 5); // initial + 4 cycles
    expect(movements.last.type, StockMovementType.initial);
    expect(movements.first.levelAfter, StockLevel.full);
    expect(movements.first.levelBefore, StockLevel.empty);
  });

  test('stock search does not leak goods', () async {
    final goodsRoot = await engine.createNode(
      name: 'Maison',
      type: NodeType.location,
    );
    await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.goods,
      parentId: goodsRoot.id,
    );
    final stockRoot = await engine.createNode(
      name: 'Cuisine',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    await engine.createNode(
      name: 'Café',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: stockRoot.id,
    );

    final stockHits = await engine.searchNodes(
      const InventorySearchCriteria(
        name: 'Café',
        space: InventorySpace.stock,
      ),
    );
    expect(stockHits.results, hasLength(1));
    expect(stockHits.results.single.path, contains('Cuisine'));

    final goodsHits = await engine.searchNodes(
      const InventorySearchCriteria(
        name: 'Café',
        space: InventorySpace.goods,
      ),
    );
    expect(goodsHits.results, hasLength(1));
    expect(goodsHits.results.single.path, contains('Maison'));
  });

  test('setStockLevel records a coherent history entry', () async {
    final root = await engine.createNode(
      name: 'Garde-manger',
      type: NodeType.location,
      space: InventorySpace.stock,
    );
    final eggs = await engine.createNode(
      name: 'Œufs',
      type: NodeType.item,
      space: InventorySpace.stock,
      parentId: root.id,
    );
    final updated = await engine.setStockLevel(eggs.id, StockLevel.quarter);
    expect(updated.stockLevel, StockLevel.quarter);
    final movements = await engine.getStockMovements(eggs.id);
    expect(movements.first.levelBefore, StockLevel.full);
    expect(movements.first.levelAfter, StockLevel.quarter);
  });
}
