import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_valuation_field.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  test(
    'la sauvegarde bloque une double écriture et conserve l’état après échec',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _EditEngine(database);
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final item = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: root.id,
        quantity: 2,
        valuation: const FinancialValuation(1250),
      );
      final tree = InventoryTreeController(engine);
      final releaseWrite = Completer<void>();

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();

        engine
          ..holdWrite = releaseWrite
          ..failWrite = true;
        final first = tree.saveEditedNode(
          nodeId: item.id,
          name: 'Livre bleu',
          condition: null,
          quantity: 3,
          valuation: const FinancialValuation(9950),
          isItem: true,
          newParentId: root.id,
          move: false,
        );
        for (var i = 0; i < 20 && engine.writeCalls < 1; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(engine.writeCalls, 1);
        final second = tree.saveEditedNode(
          nodeId: item.id,
          name: 'Livre bleu',
          condition: null,
          quantity: 3,
          valuation: const FinancialValuation(9950),
          isItem: true,
          newParentId: root.id,
          move: false,
        );
        // Second call stays queued while the first write is held.
        expect(engine.writeCalls, 1);
        releaseWrite.complete();
        await expectLater(first, throwsA(isA<InventoryException>()));
        await expectLater(second, throwsA(isA<InventoryException>()));
        expect((await engine.getNode(item.id)).name, 'Livre');
        expect((await engine.getNode(item.id)).quantity, 2);

        engine.failWrite = false;
        await tree.saveEditedNode(
          nodeId: item.id,
          name: 'Livre bleu',
          condition: null,
          quantity: 3,
          valuation: const FinancialValuation(9950),
          isItem: true,
          newParentId: root.id,
          move: false,
        );
        expect((await engine.getNode(item.id)).name, 'Livre bleu');
        expect((await engine.getNode(item.id)).quantity, 3);
        expect(
          (await engine.getNode(item.id)).valuation,
          const FinancialValuation(9950),
        );
      } finally {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'la sauvegarde distingue écriture confirmée, cache arbre et indisponibilité',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _EditEngine(database);
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final item = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: root.id,
        valuation: const FinancialValuation(1250),
      );
      final tree = InventoryTreeController(engine);

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();

        expect(parseCadCents('12,3'), 1230);
        expect(parseCadCents('12.345'), isNull);
        expect(parseCadCents('92233720368547758,08'), isNull);

        engine.failChildren = true;
        await tree.saveEditedNode(
          nodeId: item.id,
          name: 'Livre bleu',
          condition: null,
          quantity: 3,
          valuation: const FinancialValuation(2500),
          isItem: true,
          newParentId: root.id,
          move: false,
        );
        expect((await engine.getNode(item.id)).name, 'Livre bleu');
        expect((await engine.getNode(item.id)).quantity, 3);
        expect(tree.hasChildError(root.id), isTrue);
        final cached = tree.visibleEntries
            .singleWhere((entry) => entry.node.id == item.id)
            .node;
        expect(cached.name, 'Livre bleu');
        expect(cached.quantity, 3);

        engine.failChildren = false;
        tree.retryChildren(root.id);
        await tree.waitForPendingOperations();
        expect(
          tree.visibleEntries.map((entry) => entry.node.name),
          contains('Livre bleu'),
        );

        await expectLater(
          tree.readNodeDetails('missing-node'),
          throwsA(
            isA<InventoryException>().having(
              (e) => e.code,
              'code',
              InventoryErrorCode.nodeNotFound,
            ),
          ),
        );
      } finally {
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );
}

class _EditEngine extends InventoryEngine {
  _EditEngine(super.database);

  Completer<void>? holdWrite;
  bool failWrite = false;
  bool failChildren = false;
  int writeCalls = 0;
  int rootReads = 0;
  final childReads = <String>[];

  @override
  Future<InventoryNode> updateAndOptionallyMove(
    String nodeId, {
    required String name,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    required bool isItem,
    NodeType? itemKind,
    String? newParentId,
    required bool move,
  }) async {
    writeCalls++;
    await holdWrite?.future;
    if (failWrite) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return super.updateAndOptionallyMove(
      nodeId,
      name: name,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
      isItem: isItem,
      itemKind: itemKind,
      newParentId: newParentId,
      move: move,
    );
  }

  @override
  Future<List<InventoryNode>> getRootLocations({
    InventorySpace space = InventorySpace.goods,
  }) {
    rootReads++;
    return super.getRootLocations(space: space);
  }

  @override
  Future<List<InventoryNode>> getChildren(String parentId) {
    childReads.add(parentId);
    if (failChildren) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return super.getChildren(parentId);
  }
}
