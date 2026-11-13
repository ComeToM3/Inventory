import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/node_details_controller.dart';
import 'package:inventory/app/node_details_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  testWidgets(
    'la fiche bloque les doubles soumissions et conserve la saisie après échec',
    (tester) async {
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
      final category = await engine.createCategory('Lecture');
      await engine.assignCategory(item.id, category.id);
      final tree = InventoryTreeController(engine);
      final releaseWrite = Completer<void>();

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();
        await tester.pumpWidget(
          MaterialApp(
            home: NodeDetailsScreen(inventory: tree, nodeId: item.id),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Maison → Livre'), findsOneWidget);
        expect(find.text('Lecture'), findsOneWidget);
        expect(
          find.text(
            'Valeur financière par unité : 12,50 \$ CAD\n'
            'Total financier : 25,00 \$ CAD',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text(AppStrings.edit));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), 'Livre bleu');
        await tester.enterText(find.byType(TextFormField).at(1), 'Papier');
        await tester.enterText(find.byType(TextFormField).at(2), 'Bon');
        await tester.enterText(find.byType(TextFormField).at(3), '3');
        await tester.pump();
        expect(
          find.text(
            'Valeur financière par unité : 12,50 \$ CAD\n'
            'Total financier : 37,50 \$ CAD',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byType(TextFormField).at(4));
        await tester.enterText(find.byType(TextFormField).at(4), 'Art');
        await tester.ensureVisible(find.text(AppStrings.addCategory));
        await tester.tap(find.text(AppStrings.addCategory));
        await tester.pump();
        await tester.ensureVisible(find.byType(TextFormField).at(5));
        await tester.enterText(find.byType(TextFormField).at(5), '99,50');
        await tester.pump();
        engine
          ..holdWrite = releaseWrite
          ..failWrite = true;
        final submit = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.save),
            )
            .onPressed!;
        submit();
        submit();
        await tester.pump();
        expect(engine.writeCalls, 1);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .enabled,
          isFalse,
        );

        releaseWrite.complete();
        await tree.waitForPendingOperations();
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.editError), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Livre bleu',
        );
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(3))
              .controller!
              .text,
          '3',
        );
        expect((await engine.getNode(item.id)).name, 'Livre');
        expect((await engine.getNode(item.id)).quantity, 2);
        expect(
          (await engine.getNode(item.id)).valuation,
          const FinancialValuation(1250),
        );
        expect(
          (await engine.getCategories()).map((category) => category.name),
          ['Lecture'],
        );
        expect(find.text('Art'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(5))
              .controller!
              .text,
          '99,50',
        );

        engine.failWrite = false;
        await tester.ensureVisible(find.text(AppStrings.save));
        await tester.tap(find.text(AppStrings.save));
        await tree.waitForPendingOperations();
        await tester.pumpAndSettle();
        expect(find.text('Livre bleu'), findsOneWidget);
        expect(find.text('Maison → Livre bleu'), findsOneWidget);
        expect(find.text('Papier'), findsOneWidget);
        expect(find.text(AppStrings.editSuccess), findsOneWidget);
        final cached = tree.visibleEntries
            .singleWhere((entry) => entry.node.id == item.id)
            .node;
        expect(cached.name, 'Livre bleu');
        expect(cached.quantity, 3);
        expect(
          (await engine.getNode(item.id)).valuation,
          const FinancialValuation(9950),
        );
        expect(
          (await engine.getNodeCategories(
            item.id,
          )).map((category) => category.name),
          unorderedEquals(['Art', 'Lecture']),
        );
        expect(tree.isExpanded(root.id), isTrue);
        expect(engine.rootReads, 1);
        expect(engine.childReads, [root.id, root.id]);
      } finally {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
        await tester.pumpWidget(const SizedBox.shrink());
        tree.dispose();
        await tree.waitForPendingOperations();
        await database.close();
      }
    },
  );

  test(
    'la fiche distingue écriture confirmée, relecture et indisponibilité',
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
      final souvenir = await engine.createNode(
        name: 'Souvenir',
        type: NodeType.item,
        parentId: root.id,
        valuation: const SentimentalValuation(4),
      );
      final tree = InventoryTreeController(engine);
      final details = NodeDetailsController(tree, item.id);
      final sentimental = NodeDetailsController(tree, souvenir.id);
      final missing = NodeDetailsController(tree, 'missing-node');

      try {
        tree.loadRoots();
        await tree.waitForPendingOperations();
        tree.toggle(root);
        await tree.waitForPendingOperations();
        await details.load();
        expect(details.quantityFeedback('0').error, AppStrings.quantityInvalid);
        expect(details.quantityFeedback('3').totalCents, 3750);
        expect(details.financialFeedback('12,3').cents, 1230);
        expect(
          details.financialFeedback('92233720368547758,07').cents,
          0x7FFFFFFFFFFFFFFF,
        );
        expect(
          details.financialFeedback('92233720368547758,08').error,
          AppStrings.financialInvalid,
        );
        expect(
          details.financialFeedback('12.345').error,
          AppStrings.financialInvalid,
        );
        expect(
          details.quantityFeedback('9223372036854775807').error,
          AppStrings.financialTotalOverflow,
        );
        engine.failChildren = true;
        await details.save(
          name: 'Livre bleu',
          quantity: 3,
          valuation: const FinancialValuation(2500),
          categoryIds: [],
        );
        expect(details.details!.node.name, 'Livre bleu');
        expect(details.details!.node.valuation, const FinancialValuation(2500));
        expect(details.details!.path.last.name, 'Livre bleu');
        expect((await engine.getNode(item.id)).quantity, 3);
        expect(tree.hasChildError(root.id), isTrue);
        final cached = tree.visibleEntries
            .singleWhere((entry) => entry.node.id == item.id)
            .node;
        expect(cached.name, 'Livre bleu');
        expect(cached.quantity, 3);
        expect(cached.valuation, const FinancialValuation(2500));

        engine.failChildren = false;
        tree.retryChildren(root.id);
        await tree.waitForPendingOperations();
        expect(
          tree.visibleEntries.map((entry) => entry.node.name),
          contains('Livre bleu'),
        );
        await sentimental.load();
        expect(sentimental.valuationText('1'), 'Valeur sentimentale : 4 / 5');
        await missing.load();
        expect(missing.readError, AppStrings.nodeUnavailable);
        expect(missing.details, isNull);
      } finally {
        details.dispose();
        sentimental.dispose();
        missing.dispose();
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
  Future<({InventoryNode node, List<InventoryCategory> categories})>
  updateItemDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    required int quantity,
    required NodeValuation valuation,
    required Iterable<String> categoryIds,
    Iterable<String> newCategoryNames = const [],
  }) async {
    writeCalls++;
    await holdWrite?.future;
    if (failWrite) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return super.updateItemDetails(
      nodeId,
      name: name,
      description: description,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
      categoryIds: categoryIds,
      newCategoryNames: newCategoryNames,
    );
  }

  @override
  Future<InventoryNode> updateDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    int? quantity,
  }) async {
    writeCalls++;
    await holdWrite?.future;
    if (failWrite) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return super.updateDetails(
      nodeId,
      name: name,
      description: description,
      condition: condition,
      quantity: quantity,
    );
  }

  @override
  Future<List<InventoryNode>> getRootLocations() {
    rootReads++;
    return super.getRootLocations();
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
