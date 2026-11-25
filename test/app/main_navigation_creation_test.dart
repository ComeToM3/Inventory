import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
import 'package:inventory/app/main_navigation_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  testWidgets(
    'le FAB propose Emplacement et Bien puis ouvre la fiche de création',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final engine = InventoryEngine(database);
      await engine.createNode(name: 'Maison', type: NodeType.location);

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

        await tester.tap(find.byTooltip(AppStrings.add));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.locationType), findsOneWidget);
        expect(find.text(AppStrings.goodsItemType), findsOneWidget);
        expect(find.text(AppStrings.itemContainerType), findsNothing);

        await tester.tap(find.text(AppStrings.locationType));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.hierarchyPosition), findsOneWidget);
        expect(find.text(AppStrings.rootLocation), findsOneWidget);
        expect(
          (await engine.getRootLocations()).map((n) => n.name),
          ['Maison'],
        );

        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
        // Back from form → type picker still open; cancel/back again to tree.
        final back = find.byTooltip('Back');
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back);
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byTooltip(AppStrings.add));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.goodsItemType));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.chooseParent), findsOneWidget);
        expect(find.text(AppStrings.isContainerLabel), findsOneWidget);
        expect(find.text(AppStrings.rootLocation), findsNothing);
        expect(
          (await engine.getRootLocations()).map((n) => n.name),
          ['Maison'],
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      }
    },
  );

  testWidgets(
    'un arbre sans racines chargées se répare vers l’état vide, sans liste blanche',
    (tester) async {
      final database = InventoryDatabase(NativeDatabase.memory());
      final controller = InventoryTreeController(InventoryEngine(database));

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InventoryTreeScreen(controller: controller),
            ),
          ),
        );
        // Self-heal via post-frame loadRoots — never leave a blank node ListView.
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.inventoryEmpty), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        await controller.waitForPendingOperations();
        await database.close();
      }
    },
  );
}
