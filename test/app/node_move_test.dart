import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
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
    'le déplacement vers et depuis les racines conserve l’expansion',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _MoveEngine(database);
      final roots = <InventoryNode>[];
      for (var index = 0; index < 8; index++) {
        roots.add(
          await engine.createNode(
            name: 'Lieu ${index.toString().padLeft(2, '0')}',
            type: NodeType.location,
          ),
        );
      }
      final moving = roots[2];
      final destination = roots[4];
      final tree = InventoryTreeController(engine);
      final releaseRoots = Completer<void>();
      final captured = Completer<void>();
      final committed = Completer<void>();
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
        await tester.pumpAndSettle();
        expect(tree.isExpanded(roots[5].id), isTrue);

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
        await movement;
        await tester.pumpAndSettle();
        expect(tree.rootError, isTrue);
        expect(tree.roots!.any((node) => node.id == moving.id), isFalse);
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == moving.id),
          hasLength(1),
        );
        expect(tree.isExpanded(roots[5].id), isTrue);

        engine.failRoots = false;
        tree.loadRoots();
        await tree.waitForPendingOperations();
        await tree.moveNode(moving.id, null);
        await tester.pumpAndSettle();
        expect(tree.roots!.where((node) => node.id == moving.id), hasLength(1));
        expect(
          tree.visibleEntries.where((entry) => entry.node.id == moving.id),
          hasLength(1),
        );
        expect(tree.isExpanded(roots[5].id), isTrue);
      } finally {
        if (!releaseRoots.isCompleted) releaseRoots.complete();
        if (movement != null) await movement;
        await tester.pumpWidget(const SizedBox.shrink());
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'le dépôt exclut le sous-arbre et refuse une cible non contenante',
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
      final inner = await engine.createNode(
        name: 'Intérieur',
        type: NodeType.itemContainer,
        parentId: moving.id,
      );
      final book = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: root.id,
      );
      final destination = await engine.createNode(
        name: 'Cible',
        type: NodeType.itemContainer,
        parentId: root.id,
      );
      final tree = InventoryTreeController(engine);

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();
        tree.toggle(moving);
        await tree.waitForPendingOperations();

        expect(
          tree.canAcceptDrop(dragged: moving, target: destination),
          isTrue,
        );
        expect(
          tree.canAcceptDrop(dragged: moving, target: inner),
          isFalse,
        );
        expect(
          tree.canAcceptDrop(dragged: moving, target: book),
          isFalse,
        );
        expect(
          tree.canAcceptDrop(dragged: moving, target: moving),
          isFalse,
        );
      } finally {
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'le déplacement bloque une double confirmation et permet un nouvel essai',
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
      final item = await engine.createNode(
        name: 'Livre',
        type: NodeType.item,
        parentId: source.id,
      );
      final tree = InventoryTreeController(engine);
      final release = Completer<void>();

      try {
        engine
          ..holdMove = release
          ..failMove = true;
        final first = tree.moveNode(item.id, destination.id);
        final second = tree.moveNode(item.id, destination.id);
        await Future<void>.delayed(Duration.zero);
        expect(engine.moveCalls, lessThanOrEqualTo(2));
        release.complete();
        await expectLater(first, throwsA(isA<InventoryException>()));
        await expectLater(second, throwsA(isA<InventoryException>()));
        expect((await engine.getNode(item.id)).parentId, source.id);

        engine.failMove = false;
        await tree.moveNode(item.id, destination.id);
        expect((await engine.getNode(item.id)).parentId, destination.id);
      } finally {
        if (!release.isCompleted) release.complete();
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
  Future<List<InventoryNode>> getRootLocations({
    InventorySpace space = InventorySpace.goods,
  }) async {
    rootReads++;
    final hold = holdRoots;
    holdRoots = null;
    final roots = await super.getRootLocations(space: space);
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
