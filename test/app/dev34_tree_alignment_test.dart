import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/app_theme.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  late Directory directory;
  late InventoryDatabase database;
  late InventoryEngine engine;
  late InventoryTreeController controller;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_dev34_');
    final path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    database = InventoryDatabase(NativeDatabase(File(path)));
    engine = InventoryEngine(database);
    controller = InventoryTreeController(engine);
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'DEV-34 : montants partagent le même bord droit avec ou sans +',
    (tester) async {
      final home = await controller.createNodeAt(
        name: 'Maison',
        type: NodeType.location,
      );
      final desk = await controller.createNodeAt(
        name: 'Bureau',
        type: NodeType.itemContainer,
        parentId: home.id,
        valuation: const FinancialValuation(12000),
      );
      await controller.createNodeAt(
        name: 'Moniteur',
        type: NodeType.item,
        parentId: desk.id,
        valuation: const FinancialValuation(25000),
      );
      await controller.createNodeAt(
        name: 'Clavier',
        type: NodeType.item,
        parentId: desk.id,
        valuation: const FinancialValuation(500),
      );
      await controller.createNodeAt(
        name: 'Ampoule led tres longue pour ellipsis test',
        type: NodeType.item,
        parentId: desk.id,
        valuation: const FinancialValuation(1500),
      );
      final box = await controller.createNodeAt(
        name: 'Boite',
        type: NodeType.itemContainer,
        parentId: desk.id,
        valuation: const FinancialValuation(1000),
      );
      await controller.createNodeAt(
        name: 'Cable',
        type: NodeType.item,
        parentId: box.id,
        valuation: const FinancialValuation(100000),
      );

      await controller.expandAndLoadChildren(home);
      await controller.expandAndLoadChildren(desk);
      await controller.expandAndLoadChildren(box);

      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InventoryTreeScreen(
              controller: controller,
              onAddChild: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final prices = <String>[
        AppStrings.listPrice(12000), // 120 $
        AppStrings.listPrice(25000), // 250 $
        AppStrings.listPrice(500), // 5 $
        AppStrings.listPrice(1500), // 15 $
        AppStrings.listPrice(1000), // 10 $
        AppStrings.listPrice(100000), // 1 000 $
      ];

      final rights = <double>[];
      for (final label in prices) {
        final finder = find.text(label);
        expect(finder, findsWidgets, reason: 'prix visible: $label');
        // Prefer the trailing (main-line) occurrence: take the rightmost.
        final candidates = finder.evaluate().toList();
        var maxRight = -1.0;
        for (final el in candidates) {
          final box = el.renderObject! as RenderBox;
          final topLeft = box.localToGlobal(Offset.zero);
          final right = topLeft.dx + box.size.width;
          if (right > maxRight) maxRight = right;
        }
        rights.add(maxRight);
      }

      final reference = rights.first;
      for (var i = 0; i < rights.length; i++) {
        expect(
          (rights[i] - reference).abs(),
          lessThanOrEqualTo(1.0),
          reason:
              'prix ${prices[i]} right=${rights[i]} vs ref=$reference '
              '(écarts: $rights)',
        );
      }

      expect(find.byIcon(Icons.add_circle_outline), findsWidgets);

      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: InventoryTreeScreen(
                controller: controller,
                onAddChild: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.listPrice(100000)), findsWidgets);
    },
  );
}
