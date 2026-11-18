import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/app_theme.dart';
import 'package:inventory/app/inventory_tree_controller.dart';
import 'package:inventory/app/inventory_tree_screen.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:path_provider/path_provider.dart';

/// Seeds a DEV-34 tree on-device, asserts shared price axis, writes PNG shots.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEV-34 arbre aligné pour captures', (tester) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(
      '${dir.path}${Platform.pathSeparator}dev34_align.sqlite',
    );
    if (await dbFile.exists()) await dbFile.delete();
    final database = InventoryDatabase(NativeDatabase(dbFile));
    final engine = InventoryEngine(database);
    final controller = InventoryTreeController(engine);

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
      name: 'Ampoule led tres longue pour ellipsis',
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

    final shotKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Inventory'),
            backgroundColor: const Color(0xFF1B4D46),
          ),
          body: RepaintBoundary(
            key: shotKey,
            child: InventoryTreeScreen(
              controller: controller,
              onAddChild: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.listPrice(12000)), findsWidgets);
    expect(find.text(AppStrings.listPrice(25000)), findsWidgets);
    expect(find.text(AppStrings.listPrice(100000)), findsWidgets);
    expect(find.byIcon(Icons.add_circle_outline), findsWidgets);

    final labels = [
      AppStrings.listPrice(12000),
      AppStrings.listPrice(25000),
      AppStrings.listPrice(500),
      AppStrings.listPrice(1500),
      AppStrings.listPrice(1000),
      AppStrings.listPrice(100000),
    ];
    final rights = <double>[];
    for (final label in labels) {
      var maxRight = -1.0;
      for (final el in find.text(label).evaluate()) {
        final box = el.renderObject! as RenderBox;
        final right = box.localToGlobal(Offset.zero).dx + box.size.width;
        if (right > maxRight) maxRight = right;
      }
      rights.add(maxRight);
    }
    final ref = rights.first;
    for (final r in rights) {
      expect((r - ref).abs(), lessThanOrEqualTo(1.5));
    }

    final shot02 = File('${dir.path}/dev34_02_after_align.png');
    await _writeShot(tester, shotKey, shot02);
    // ignore: avoid_print
    print('DEV34_SHOT:${shot02.path}');

    await tester.tap(find.text('Moniteur'));
    await tester.pumpAndSettle();
    final shot03 = File('${dir.path}/dev34_03_info_modifier.png');
    await _writeShot(tester, shotKey, shot03);
    // ignore: avoid_print
    print('DEV34_SHOT:${shot03.path}');

    // Keep package installed briefly for host `run-as` pull.
    await Future<void>.delayed(const Duration(seconds: 8));
  });
}

Future<void> _writeShot(
  WidgetTester tester,
  GlobalKey key,
  File file,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
