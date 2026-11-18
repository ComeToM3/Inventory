import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_history_controller.dart';
import 'package:inventory/app/inventory_history_screen.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/withdrawn_node_details_controller.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  test(
    'le retrait retire le bien de l’arbre et le conserve dans l’historique',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = InventoryEngine(database);
      final tree = InventoryTreeController(engine);
      final history = InventoryHistoryController(tree);

      try {
        final root = await engine.createNode(
          name: 'Maison',
          type: NodeType.location,
        );
        final item = await engine.createNode(
          name: 'Lampe',
          type: NodeType.item,
          parentId: root.id,
          valuation: const SentimentalValuation(4),
        );

        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();
        expect(
          tree.visibleEntries.any((entry) => entry.node.id == item.id),
          isTrue,
        );

        final withdrawn = await tree.withdrawItem(
          item.id,
          WithdrawalReason.donation,
        );
        expect(withdrawn.status, NodeStatus.withdrawn);
        expect(withdrawn.withdrawalReason, WithdrawalReason.donation);
        expect(withdrawn.parentId, isNull);
        expect(
          tree.visibleEntries.any((entry) => entry.node.id == item.id),
          isFalse,
        );

        await history.refresh();
        expect(history.items, hasLength(1));
        expect(history.items.single.name, 'Lampe');
        expect(
          history.items.single.withdrawalReason,
          WithdrawalReason.donation,
        );

        final details = await tree.readWithdrawnNodeDetails(item.id);
        expect(details.name, 'Lampe');
        expect(details.valuation, const SentimentalValuation(4));
      } finally {
        history.dispose();
        tree.dispose();
        await database.close();
      }
    },
  );

  test(
    'la suppression définitive retire le nœud sans laisser de trace historique',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = InventoryEngine(database);
      final tree = InventoryTreeController(engine);

      try {
        final root = await engine.createNode(
          name: 'Atelier',
          type: NodeType.location,
        );
        final mistake = await engine.createNode(
          name: 'Erreur',
          type: NodeType.item,
          parentId: root.id,
        );
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();

        await tree.deleteNodePermanently(mistake.id);
        expect(
          tree.visibleEntries.any((entry) => entry.node.id == mistake.id),
          isFalse,
        );
        expect(
          () => engine.getNode(mistake.id),
          throwsA(
            isA<InventoryException>().having(
              (error) => error.code,
              'code',
              InventoryErrorCode.nodeNotFound,
            ),
          ),
        );
        expect(await engine.getWithdrawnItems(space: InventorySpace.goods), isEmpty);
        expect(
          tree.visibleEntries.any((entry) => entry.node.id == root.id),
          isTrue,
        );
      } finally {
        tree.dispose();
        await database.close();
      }
    },
  );

  test(
    'un contenant non vide refuse retrait et suppression sans modifier la base',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = InventoryEngine(database);
      final tree = InventoryTreeController(engine);

      try {
        final root = await engine.createNode(
          name: 'Maison',
          type: NodeType.location,
        );
        final bag = await engine.createNode(
          name: 'Sac',
          type: NodeType.itemContainer,
          parentId: root.id,
        );
        await engine.createNode(
          name: 'Clé',
          type: NodeType.item,
          parentId: bag.id,
        );
        final before = await engine.getNode(bag.id);

        await expectLater(
          engine.withdrawItem(bag.id, WithdrawalReason.loss),
          throwsA(
            isA<InventoryException>().having(
              (e) => e.code,
              'code',
              InventoryErrorCode.nodeHasChildren,
            ),
          ),
        );
        expect((await engine.getNode(bag.id)).updatedAt, before.updatedAt);

        await expectLater(
          engine.deleteNodePermanently(bag.id),
          throwsA(
            isA<InventoryException>().having(
              (e) => e.code,
              'code',
              InventoryErrorCode.nodeHasChildren,
            ),
          ),
        );
        expect((await engine.getNode(bag.id)).parentId, root.id);
        expect(await engine.getChildren(bag.id), hasLength(1));
      } finally {
        tree.dispose();
        await database.close();
      }
    },
  );

  test(
    'les lectures d’historique obsolètes et les doubles sorties sont ignorées',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _HistoryEngine(database);
      final tree = InventoryTreeController(engine);
      final history = InventoryHistoryController(tree);
      final release = Completer<void>();
      final captured = Completer<void>();

      try {
        final root = await engine.createNode(
          name: 'Maison',
          type: NodeType.location,
        );
        final first = await engine.createNode(
          name: 'Ancien',
          type: NodeType.item,
          parentId: root.id,
        );
        await engine.withdrawItem(first.id, WithdrawalReason.sale);
        final second = await engine.createNode(
          name: 'Récent',
          type: NodeType.item,
          parentId: root.id,
        );
        await engine.withdrawItem(second.id, WithdrawalReason.breakage);

        engine.holdWithdrawn = release;
        engine.withdrawnCaptured = captured;
        final stale = history.refresh();
        await captured.future;
        engine.holdWithdrawn = null;
        await history.refresh();
        expect(history.items.map((item) => item.name), ['Récent', 'Ancien']);
        release.complete();
        await stale;
        expect(history.items.map((item) => item.name), ['Récent', 'Ancien']);

        final item = await engine.createNode(
          name: 'Livre',
          type: NodeType.item,
          parentId: root.id,
        );
        final withdrawn = await tree.withdrawItem(
          item.id,
          WithdrawalReason.loss,
        );
        expect(withdrawn.withdrawalReason, WithdrawalReason.loss);
        await expectLater(
          tree.withdrawItem(item.id, WithdrawalReason.sale),
          throwsA(
            isA<InventoryException>().having(
              (e) => e.code,
              'code',
              InventoryErrorCode.nodeInactive,
            ),
          ),
        );
      } finally {
        history.dispose();
        tree.dispose();
        await database.close();
      }
    },
  );

  testWidgets(
    'la fiche historique reste consultable sans actions d’édition',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = InventoryEngine(
        database,
        clock: () => DateTime.utc(2026, 11, 14, 15, 30),
      );
      final tree = InventoryTreeController(engine);

      try {
        final root = await engine.createNode(
          name: 'Maison',
          type: NodeType.location,
        );
        final item = await engine.createNode(
          name: 'Vase',
          type: NodeType.item,
          parentId: root.id,
        );
        await engine.withdrawItem(item.id, WithdrawalReason.breakage);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InventoryHistoryScreen(inventory: tree, active: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Vase'), findsOneWidget);
        expect(
          find.textContaining(AppStrings.withdrawalReasonBreakage),
          findsOneWidget,
        );
        await tester.tap(find.text('Vase'));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.historyDetailsTitle), findsOneWidget);
        expect(find.text(AppStrings.withdrawalReasonBreakage), findsWidgets);
        expect(find.text(AppStrings.edit), findsNothing);
        expect(find.text(AppStrings.move), findsNothing);
      } finally {
        tree.dispose();
        await database.close();
      }
    },
  );

  test('une fiche historique refuse un nœud encore actif', () async {
    final database = InventoryDatabase(NativeDatabase.memory());
    final engine = InventoryEngine(database);
    final tree = InventoryTreeController(engine);

    try {
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final item = await engine.createNode(
        name: 'Actif',
        type: NodeType.item,
        parentId: root.id,
      );
      final controller = WithdrawnNodeDetailsController(tree, item.id);
      await controller.load();
      expect(controller.readError, AppStrings.historyUnavailable);
      expect(controller.node, isNull);
      controller.dispose();
    } finally {
      tree.dispose();
      await database.close();
    }
  });
}

class _HistoryEngine extends InventoryEngine {
  _HistoryEngine(super.db);

  Completer<void>? holdWithdrawn;
  Completer<void>? withdrawnCaptured;
  Completer<void>? holdWithdrawWrite;

  @override
  Future<List<InventoryNode>> getWithdrawnItems({
    InventorySpace space = InventorySpace.goods,
  }) async {
    final captured = withdrawnCaptured;
    withdrawnCaptured = null;
    captured?.complete();
    final hold = holdWithdrawn;
    if (hold != null) await hold.future;
    return super.getWithdrawnItems(space: space);
  }

  @override
  Future<InventoryNode> withdrawItem(
    String nodeId,
    WithdrawalReason reason,
  ) async {
    final hold = holdWithdrawWrite;
    if (hold != null) await hold.future;
    return super.withdrawItem(nodeId, reason);
  }
}
