import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_search_controller.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/main_navigation_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  test(
    'ignore les réponses et erreurs de recherche devenues obsolètes',
    () async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _DeferredSearchEngine(database);
      final tree = InventoryTreeController(engine);
      final search = InventorySearchController(tree);

      try {
        search.setType(NodeType.item);
        search.setType(NodeType.location);
        expect(engine.requests, hasLength(2));
        expect(search.loading, isTrue);
        engine.requests[1].complete(_response('récent'));
        await Future<void>.delayed(Duration.zero);
        expect(search.results.single.nodeId, 'récent');
        expect(search.loading, isFalse);

        engine.requests[0].completeError(
          const InventoryException(InventoryErrorCode.storageFailure),
        );
        await Future<void>.delayed(Duration.zero);
        expect(search.results.single.nodeId, 'récent');
        expect(search.readError, isNull);

        search.setType(NodeType.itemContainer);
        search.setType(null);
        expect(search.criteria.isEmpty, isTrue);
        expect(search.results, isEmpty);
        engine.requests[2].complete(_response('obsolète'));
        await Future<void>.delayed(Duration.zero);
        expect(search.results, isEmpty);
        expect(search.loading, isFalse);

        search.setType(NodeType.item);
        engine.requests[3].completeError(
          const InventoryException(InventoryErrorCode.storageFailure),
        );
        await Future<void>.delayed(Duration.zero);
        expect(search.readError, AppStrings.searchReadError);
        final retry = search.refresh();
        expect(search.loading, isTrue);
        engine.requests[4].complete(_response('réessai'));
        await retry;
        expect(search.readError, isNull);
        expect(search.results.single.nodeId, 'réessai');
      } finally {
        search.dispose();
        for (final request in engine.requests) {
          if (!request.isCompleted) request.complete(_response('fin'));
        }
        await tree.waitForPendingOperations();
        tree.dispose();
        await database.close();
      }
    },
  );

  testWidgets(
    'retourne à la recherche actualisée sans modifier les branches ouvertes',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = _NavigationEngine(database);
      final home = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final workshop = await engine.createNode(
        name: 'Atelier',
        type: NodeType.location,
      );
      final items = <InventoryNode>[];
      for (var index = 0; index < 24; index++) {
        items.add(
          await engine.createNode(
            name: 'Objet ${index.toString().padLeft(2, '0')}',
            type: NodeType.item,
            parentId: home.id,
          ),
        );
      }
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationScreen(
              engine: engine,
              database: database,
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Expand Maison on the live goods tree (owned by MainNavigationScreen).
        await tester.tap(find.text('Maison'));
        await tester.pumpAndSettle();
        expect(find.text('Objet 00'), findsOneWidget);

        await tester.tap(find.byTooltip(AppStrings.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'objet');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        final list = find.byKey(const PageStorageKey('search-results'));
        await tester.drag(list, const Offset(0, -550));
        await tester.pumpAndSettle();
        final scrollable = find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        );
        final offset = tester
            .state<ScrollableState>(scrollable)
            .position
            .pixels;
        expect(offset, greaterThan(0));
        await tester.scrollUntilVisible(
          find.text('Objet 10'),
          200,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        // Opening a result pops search and reveals the tree detail.
        await tester.tap(find.text('Objet 10'));
        await tester.pumpAndSettle();
        expect(find.text('Objet 10'), findsWidgets);
        // Maison expansion preserved under the search route.
        expect(find.text('Objet 00'), findsOneWidget);
        expect(find.text('Atelier'), findsWidgets);

        await engine.moveNode(items[10].id, workshop.id);
        expect((await engine.getNode(items[10].id)).parentId, workshop.id);

        await tester.tap(find.byTooltip(AppStrings.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'objet');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'objet',
        );
        final listMoved = find.byKey(const PageStorageKey('search-results'));
        final scrollMoved = find.descendant(
          of: listMoved,
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Objet 10'),
          200,
          scrollable: scrollMoved,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Objet 10'), findsWidgets);
        expect(find.textContaining('Atelier'), findsWidgets);

        await engine.withdrawItem(items[11].id, WithdrawalReason.loss);
        await tester.tap(find.text('Objet 11'));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.nodeUnavailable), findsOneWidget);

        await tester.tap(find.byTooltip(AppStrings.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'objet');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('Objet 11'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'objet',
        );

        engine.failSearch = true;
        await tester.enterText(find.byType(TextField), 'objet 1');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.searchReadError), findsOneWidget);
        engine.failSearch = false;
        await tester.tap(find.text(AppStrings.retry));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.searchReadError), findsNothing);
        final listAfter = find.byKey(const PageStorageKey('search-results'));
        await tester.drag(listAfter, const Offset(0, 1000));
        await tester.pumpAndSettle();
        expect(find.text('Objet 10'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      }
    },
  );
}

InventorySearchResponse _response(String id) => InventorySearchResponse(
  results: [
    InventorySearchResult(
      nodeId: id,
      name: id,
      type: NodeType.item,
      quantity: 1,
      path: 'Maison → $id',
    ),
  ],
  branchPath: null,
);

class _DeferredSearchEngine extends InventoryEngine {
  _DeferredSearchEngine(super.database);

  final requests = <Completer<InventorySearchResponse>>[];

  @override
  Future<InventorySearchResponse> searchNodes(
    InventorySearchCriteria criteria,
  ) {
    final request = Completer<InventorySearchResponse>();
    requests.add(request);
    return request.future;
  }
}

class _NavigationEngine extends InventoryEngine {
  _NavigationEngine(super.database);

  bool failSearch = false;

  @override
  Future<InventorySearchResponse> searchNodes(
    InventorySearchCriteria criteria,
  ) {
    if (failSearch) {
      throw const InventoryException(InventoryErrorCode.storageFailure);
    }
    return super.searchNodes(criteria);
  }
}
