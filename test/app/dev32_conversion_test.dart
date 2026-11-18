import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/app_theme.dart';
import 'package:inventory/app/inventory_creation_screen.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:inventory/core/domain/inventory_name.dart';

void main() {
  late Directory directory;
  late InventoryDatabase database;
  late InventoryEngine engine;
  late InventoryTreeController controller;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_dev32_');
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
    'édition : conversion bien simple → contenant puis enfants',
    (tester) async {
      final home = await engine.createNode(
        name: 'maison',
        type: NodeType.location,
      );
      final desk = await engine.createNode(
        name: 'bureau assis debout',
        type: NodeType.item,
        parentId: home.id,
        valuation: const FinancialValuation(12000),
      );
      expect(desk.name, 'Bureau assis debout');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InventoryCreationScreen(
            controller: controller,
            type: NodeType.item,
            existing: desk,
            initialParent: home,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.itemKindLabel), findsOneWidget);
      await tester.tap(find.text(AppStrings.itemContainerType));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      final converted = await engine.getNode(desk.id);
      expect(converted.type, NodeType.itemContainer);
      expect(converted.financialTotalCents, 12000);

      await engine.createNode(
        name: 'moniteur 24 pouces tres long pour ellipsis',
        type: NodeType.item,
        parentId: converted.id,
        valuation: const FinancialValuation(25000),
      );
      final totals = await engine.getSubtreeFinancialTotals([converted.id]);
      expect(
        (totals[converted.id]! as SubtreeFinancialAmount).cents,
        37000,
      );
      expect(
        InventoryName.display('chambre'),
        'Chambre',
      );
    },
  );
}
