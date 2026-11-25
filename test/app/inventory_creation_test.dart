import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/inventory_creation_screen.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  test(
    'une lecture commencée avant la création ne masque pas le nouveau bien',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _ControlledEngine(database);
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final controller = InventoryTreeController(engine);
      final releaseRead = Completer<void>();
      final capturedRead = Completer<void>();
      final committed = Completer<void>();

      try {
        controller.loadRoots();
        await controller.waitForPendingOperations();
        engine.holdChildren = releaseRead;
        engine.childrenCaptured = capturedRead;
        engine.creationCommitted = committed;

        controller.toggle(root);
        await capturedRead.future;
        final creation = controller.createNode(
          name: 'Livre',
          type: NodeType.item,
          parentId: root.id,
        );
        await committed.future;
        releaseRead.complete();
        await creation;

        expect(controller.visibleEntries.map((entry) => entry.node.name), [
          'Maison',
          'Livre',
        ]);
      } finally {
        if (!releaseRead.isCompleted) releaseRead.complete();
        controller.dispose();
        await controller.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'une erreur de rafraîchissement ne présente pas la création comme échouée',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _ControlledEngine(database);
      final root = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final controller = InventoryTreeController(engine);

      try {
        controller.loadRoots();
        await controller.waitForPendingOperations();
        engine.failChildren = true;

        await controller.createNode(
          name: 'Livre',
          type: NodeType.item,
          parentId: root.id,
        );

        expect(controller.hasChildError(root.id), isTrue);
        expect(
          (await InventoryEngine(database).getChildren(root.id)).single.name,
          'Livre',
        );
        engine.failChildren = false;
        controller.retryChildren(root.id);
        await controller.waitForPendingOperations();
        expect(controller.visibleEntries.map((entry) => entry.node.name), [
          'Maison',
          'Livre',
        ]);
      } finally {
        controller.dispose();
        await controller.waitForPendingOperations();
        await database.close();
      }
    },
  );

  testWidgets('deux soumissions rapprochées ne créent qu’un nœud', (
    tester,
  ) async {
    final database = InventoryDatabase(NativeDatabase.memory());
    final engine = _ControlledEngine(database);
    final controller = InventoryTreeController(engine);
    final releaseCreation = Completer<void>();
    engine.holdCreation = releaseCreation;

    try {
      await _openRootCreation(tester, controller);
      await tester.enterText(find.byType(TextFormField), 'Maison');

      final submit = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Créer'))
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(engine.creationCalls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      releaseCreation.complete();
      await controller.waitForPendingOperations();
      await tester.pumpAndSettle();
      expect(await engine.getRootLocations(), hasLength(1));
    } finally {
      if (!releaseCreation.isCompleted) releaseCreation.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await controller.waitForPendingOperations();
      await database.close();
    }
  });

  testWidgets('un échec d’enregistrement conserve la saisie sans création', (
    tester,
  ) async {
    final database = InventoryDatabase(NativeDatabase.memory());
    final engine = _ControlledEngine(database)..failCreation = true;
    final controller = InventoryTreeController(engine);

    try {
      await _openRootCreation(tester, controller);
      await tester.enterText(find.byType(TextFormField), 'Maison');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible d’ajouter cet élément. Réessayez.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Maison',
      );
      expect(await engine.getRootLocations(), isEmpty);

      engine.failCreation = false;
      await tester.tap(find.text('Créer'));
      await controller.waitForPendingOperations();
      await tester.pumpAndSettle();
      expect(await engine.getRootLocations(), hasLength(1));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await controller.waitForPendingOperations();
      await database.close();
    }
  });

  testWidgets(
    'la création et la modification d’une racine conservent l’expansion',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _ControlledEngine(database);
      for (var index = 0; index < 8; index++) {
        await engine.createNode(
          name: 'Lieu ${index.toString().padLeft(2, '0')}',
          type: NodeType.location,
        );
      }
      final controller = InventoryTreeController(engine);
      final releaseRead = Completer<void>();
      final capturedRead = Completer<void>();
      Future<void>? creation;

      try {
        controller.loadRoots();
        await controller.waitForPendingOperations();
        final editedRoot = controller.roots!.firstWhere(
          (node) => node.name == 'Lieu 03',
        );
        controller.toggle(editedRoot);
        await controller.waitForPendingOperations();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: InventoryTreeScreen(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.isExpanded(editedRoot.id), isTrue);

        engine.holdRoots = releaseRead;
        engine.rootsCaptured = capturedRead;
        creation = controller.createNode(
          name: 'Nouvelle racine',
          type: NodeType.location,
        );
        await capturedRead.future;
        await tester.pump();
        expect(find.byType(SingleChildScrollView), findsWidgets);

        releaseRead.complete();
        await creation;
        await tester.pumpAndSettle();
        expect(controller.isExpanded(editedRoot.id), isTrue);
        expect(
          controller.roots!.map((node) => node.name),
          contains('Nouvelle racine'),
        );

        await controller.updateNodeDetails(
          editedRoot.id,
          name: 'Lieu 03 renommé',
        );
        await tester.pumpAndSettle();
        expect(controller.isExpanded(editedRoot.id), isTrue);
        expect(
          controller.roots!.map((node) => node.name),
          contains('Lieu 03 renommé'),
        );

        engine.failRoots = true;
        await controller.createNode(
          name: 'Autre racine',
          type: NodeType.location,
        );
        await tester.pump();
        expect(
          find.text('Impossible de charger l’inventaire.'),
          findsOneWidget,
        );

        engine.failRoots = false;
        await tester.tap(find.text('Réessayer'));
        await controller.waitForPendingOperations();
        await tester.pumpAndSettle();
        expect(
          controller.roots!.map((node) => node.name),
          contains('Autre racine'),
        );
        expect(controller.isExpanded(editedRoot.id), isTrue);
      } finally {
        if (!releaseRead.isCompleted) releaseRead.complete();
        if (creation != null) await creation;
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        await controller.waitForPendingOperations();
        await database.close();
      }
    },
  );
}

Future<void> _openRootCreation(
  WidgetTester tester,
  InventoryTreeController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.push<Object?>(
              context,
              MaterialPageRoute<Object?>(
                builder: (_) => InventoryCreationScreen(
                  controller: controller,
                  type: NodeType.location,
                ),
              ),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

class _ControlledEngine extends InventoryEngine {
  _ControlledEngine(super.database);

  Completer<void>? holdChildren;
  Completer<void>? childrenCaptured;
  Completer<void>? holdRoots;
  Completer<void>? rootsCaptured;
  Completer<void>? holdCreation;
  Completer<void>? creationCommitted;
  bool failCreation = false;
  bool failRoots = false;
  bool failChildren = false;
  int creationCalls = 0;

  @override
  Future<List<InventoryNode>> getRootLocations({
    InventorySpace space = InventorySpace.goods,
  }) async {
    if (failRoots) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    final roots = await super.getRootLocations(space: space);
    final hold = holdRoots;
    if (hold != null) {
      holdRoots = null;
      rootsCaptured?.complete();
      await hold.future;
    }
    return roots;
  }

  @override
  Future<List<InventoryNode>> getChildren(String parentId) async {
    if (failChildren) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    final children = await super.getChildren(parentId);
    final hold = holdChildren;
    if (hold != null) {
      holdChildren = null;
      childrenCaptured?.complete();
      await hold.future;
    }
    return children;
  }

  @override
  Future<InventoryNode> createNode({
    required String name,
    required NodeType type,
    InventorySpace space = InventorySpace.goods,
    String? parentId,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    int? stockReference,
    int? targetPriceCents,
  }) async {
    creationCalls++;
    if (failCreation) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    final hold = holdCreation;
    if (hold != null) await hold.future;
    final result = await super.createNode(
      name: name,
      type: type,
      space: space,
      parentId: parentId,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
      stockReference: stockReference,
      targetPriceCents: targetPriceCents,
    );
    creationCommitted?.complete();
    return result;
  }
}
