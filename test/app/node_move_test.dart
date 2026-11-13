import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
import 'package:inventory/app/node_details_screen.dart';
import 'package:inventory/app/node_move_controller.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  test(
    'le déplacement invalide les anciennes lectures des deux branches',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _MoveEngine(database);
      final source = await engine.createNode(
        name: 'Source',
        type: NodeType.location,
      );
      final destination = await engine.createNode(
        name: 'Cible',
        type: NodeType.location,
      );
      final other = await engine.createNode(
        name: 'Autre',
        type: NodeType.location,
      );
      final moving = await engine.createNode(
        name: 'Valise',
        type: NodeType.itemContainer,
        parentId: source.id,
      );
      final child = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: moving.id,
      );
      final tree = InventoryTreeController(engine);
      final releaseSource = Completer<void>();
      final releaseDestination = Completer<void>();
      final sourceCaptured = Completer<void>();
      final destinationCaptured = Completer<void>();
      final committed = Completer<void>();
      Future<InventoryNode>? movement;

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        for (final node in [source, moving, other]) {
          tree.toggle(node);
          await tree.waitForPendingOperations();
        }
        engine.holdChildren[source.id] = releaseSource;
        engine.holdChildren[destination.id] = releaseDestination;
        engine.childrenCaptured[source.id] = sourceCaptured;
        engine.childrenCaptured[destination.id] = destinationCaptured;
        tree.retryChildren(source.id);
        tree.toggle(destination);
        await Future.wait([sourceCaptured.future, destinationCaptured.future]);
        engine
          ..movementCommitted = committed
          ..failChildren.addAll([source.id, destination.id]);
        movement = tree.moveNode(moving.id, destination.id);
        await committed.future;
        await Future<void>.delayed(Duration.zero);
        releaseSource.complete();
        releaseDestination.complete();
        await movement;

        expect(tree.hasChildError(source.id), isTrue);
        expect(tree.hasChildError(destination.id), isTrue);
        expect(
          tree.visibleEntries.any((entry) => entry.node.id == moving.id),
          isFalse,
        );
        expect((await engine.getNode(moving.id)).parentId, destination.id);

        engine.failChildren.clear();
        tree.retryChildren(source.id);
        tree.retryChildren(destination.id);
        await tree.waitForPendingOperations();
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == moving.id),
          hasLength(1),
        );
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == child.id),
          hasLength(1),
        );
        expect(tree.isExpanded(other.id), isTrue);
        expect(tree.isExpanded(moving.id), isTrue);
        expect(engine.rootReads, 1);
        expect(engine.childReads.where((id) => id == moving.id), hasLength(1));
      } finally {
        if (!releaseSource.isCompleted) releaseSource.complete();
        if (!releaseDestination.isCompleted) releaseDestination.complete();
        if (movement != null) await movement;
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  testWidgets(
    'le déplacement vers et depuis les racines conserve le défilement',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _MoveEngine(database);
      final roots = <InventoryNode>[];
      for (var index = 0; index < 24; index++) {
        roots.add(
          await engine.createNode(
            name: 'Lieu ${index.toString().padLeft(2, '0')}',
            type: NodeType.location,
          ),
        );
      }
      final moving = roots[8];
      final destination = roots[12];
      final tree = InventoryTreeController(engine);
      final releaseRoots = Completer<void>();
      final captured = Completer<void>();
      final committed = Completer<void>();
      NodeMoveController? selector;
      Future<InventoryNode>? movement;

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(roots[5]);
        await tree.waitForPendingOperations();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: InventoryTreeScreen(controller: tree)),
          ),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        final offset = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .pixels;
        expect(offset, greaterThan(0));
        engine
          ..holdRoots = releaseRoots
          ..rootsCaptured = captured
          ..movementCommitted = committed;
        tree.loadRoots();
        await captured.future;
        engine.failRoots = true;
        movement = tree.moveNode(moving.id, destination.id);
        await committed.future;
        releaseRoots.complete();
        final moved = await movement;
        await tester.pumpAndSettle();
        expect(tree.rootError, isTrue);
        expect(tree.roots!.any((node) => node.id == moving.id), isFalse);
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == moving.id),
          hasLength(1),
        );
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .pixels,
          offset,
        );

        engine.failRoots = false;
        tree.loadRoots();
        await tree.waitForPendingOperations();
        selector = NodeMoveController(tree, moved);
        await selector.load();
        expect(selector.canChoose, isTrue);
        expect(selector.destinationPath, AppStrings.inventoryRoot);
        expect(await selector.move(), isTrue);
        await tester.pumpAndSettle();
        expect(tree.roots!.where((node) => node.id == moving.id), hasLength(1));
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == moving.id),
          hasLength(1),
        );
        expect(tree.isExpanded(roots[5].id), isTrue);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .pixels,
          offset,
        );
      } finally {
        if (!releaseRoots.isCompleted) releaseRoots.complete();
        if (movement != null) await movement;
        selector?.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'le sélecteur exclut le sous-arbre et ignore une navigation obsolète',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _MoveEngine(database);
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final moving = await engine.createNode(
        name: 'Valise',
        type: NodeType.itemContainer,
        parentId: root.id,
      );
      await engine.createNode(
        name: 'Intérieur',
        type: NodeType.container,
        parentId: moving.id,
      );
      await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: root.id,
      );
      final withdrawn = await engine.createNode(
        name: 'Ancien',
        type: NodeType.itemContainer,
        parentId: root.id,
      );
      await engine.withdrawItem(withdrawn.id, WithdrawalReason.donation);
      final destination = await engine.createNode(
        name: 'Cible',
        type: NodeType.container,
        parentId: root.id,
      );
      final tree = InventoryTreeController(engine);
      final selector = NodeMoveController(tree, moving);
      final noDestination = NodeMoveController(tree, root);
      final release = Completer<void>();
      final captured = Completer<void>();
      Future<void>? entering;

      try {
        await selector.load();
        expect(selector.canChoose, isFalse);
        await selector.enter(root);
        expect(selector.children.map((node) => node.id), [destination.id]);
        expect(selector.isCurrentParent, isTrue);
        expect(selector.canChoose, isFalse);
        engine.holdChildren[destination.id] = release;
        engine.childrenCaptured[destination.id] = captured;
        entering = selector.enter(destination);
        await captured.future;
        await selector.goUp();
        release.complete();
        await entering;
        expect(selector.destinationPath, 'Maison');
        expect(selector.children.map((node) => node.id), [destination.id]);
        expect(selector.loading, isFalse);

        await noDestination.load();
        expect(noDestination.children, isEmpty);
        expect(noDestination.canChoose, isFalse);
        expect(noDestination.readError, isNull);
      } finally {
        if (!release.isCompleted) release.complete();
        if (entering != null) await entering;
        selector.dispose();
        noDestination.dispose();
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  testWidgets(
    'le déplacement bloque une double confirmation et permet un nouvel essai',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _MoveEngine(database);
      final source = await engine.createNode(
        name: 'Source',
        type: NodeType.location,
      );
      final destination = await engine.createNode(
        name: 'Cible',
        type: NodeType.location,
      );
      final item = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: source.id,
      );
      final tree = InventoryTreeController(engine);
      final release = Completer<void>();

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: NodeDetailsScreen(inventory: tree, nodeId: item.id),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.move));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cible'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.moveHere));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.moveTo('Livre', 'Cible')), findsOneWidget);
        engine
          ..holdMove = release
          ..failMove = true;
        final confirm = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.move),
            )
            .onPressed!;
        confirm();
        confirm();
        await tester.pumpAndSettle();
        expect(engine.moveCalls, 1);
        expect(find.text(AppStrings.chooseDestination), findsOneWidget);
        expect(find.text(AppStrings.moveSuccess), findsNothing);
        release.complete();
        await tree.waitForPendingOperations();
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.moveError), findsOneWidget);
        expect(find.text('Cible'), findsOneWidget);
        expect((await engine.getNode(item.id)).parentId, source.id);

        engine.failMove = false;
        await tester.tap(find.text(AppStrings.moveHere));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.move));
        await tree.waitForPendingOperations();
        await tester.pumpAndSettle();
        expect(find.text('Cible → Livre'), findsOneWidget);
        expect(find.text(AppStrings.moveSuccess), findsOneWidget);
        expect((await engine.getNode(item.id)).parentId, destination.id);
        expect(engine.moveCalls, 2);
      } finally {
        if (!release.isCompleted) release.complete();
        await tree.waitForPendingOperations();
        await tester.pumpWidget(const SizedBox.shrink());
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );
}

class _MoveEngine extends InventoryEngine {
  _MoveEngine(super.database);

  final holdChildren = <String, Completer<void>>{};
  final childrenCaptured = <String, Completer<void>>{};
  final failChildren = <String>{};
  final childReads = <String>[];
  Completer<void>? holdRoots;
  Completer<void>? rootsCaptured;
  Completer<void>? holdMove;
  Completer<void>? movementCommitted;
  bool failRoots = false;
  bool failMove = false;
  int rootReads = 0;
  int moveCalls = 0;

  @override
  Future<List<InventoryNode>> getRootLocations() async {
    rootReads++;
    final hold = holdRoots;
    holdRoots = null;
    final roots = await super.getRootLocations();
    rootsCaptured?.complete();
    rootsCaptured = null;
    if (hold != null) {
      await hold.future;
    } else if (failRoots) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return roots;
  }

  @override
  Future<List<InventoryNode>> getChildren(String parentId) async {
    childReads.add(parentId);
    final hold = holdChildren.remove(parentId);
    final children = await super.getChildren(parentId);
    childrenCaptured.remove(parentId)?.complete();
    if (hold != null) {
      await hold.future;
    } else if (failChildren.contains(parentId)) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return children;
  }

  @override
  Future<InventoryNode> moveNode(String nodeId, String? newParentId) async {
    moveCalls++;
    await holdMove?.future;
    if (failMove) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    final moved = await super.moveNode(nodeId, newParentId);
    movementCommitted?.complete();
    movementCommitted = null;
    return moved;
  }
}
