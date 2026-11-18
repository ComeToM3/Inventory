import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inventory/app/app_strings.dart';
import 'package:inventory/app/inventory_app.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEV-17 parcours création / prix / fiche sur Android', (
    tester,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(
      '${dir.path}${Platform.pathSeparator}dev17_smoke.sqlite',
    );
    if (await dbFile.exists()) await dbFile.delete();
    final database = InventoryDatabase(NativeDatabase(dbFile));

    await tester.pumpWidget(InventoryApp(database: database));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text(AppStrings.inventoryEmpty), findsOneWidget);
    expect(find.text('Contenant'), findsNothing);
    expect(find.textContaining('Catégorie'), findsNothing);

    Future<void> createFromFab(String typeLabel, String name) async {
      await tester.tap(find.byTooltip(AppStrings.add));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.locationType), findsOneWidget);
      expect(find.text(AppStrings.itemType), findsOneWidget);
      expect(find.text(AppStrings.itemContainerType), findsOneWidget);
      expect(find.text('Contenant'), findsNothing);
      await tester.tap(find.text(typeLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.hierarchyPosition), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await createFromFab(AppStrings.locationType, 'Maison');
    expect(find.text('Maison'), findsWidgets);

    await tester.tap(find.byTooltip(AppStrings.addInside('Maison')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.locationType));
    await tester.pumpAndSettle();
    expect(find.text('Maison'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).first, 'Bureau');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.create));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byTooltip(AppStrings.addInside('Maison')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.itemType));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Livre');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.create));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(AppStrings.listPrice(2500)), findsNothing);

    await tester.tap(find.byTooltip(AppStrings.addInside('Maison')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.itemType));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cable');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '25');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.create));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Trailing own price + optional parent subtree total may both show `25 $`.
    expect(find.text(AppStrings.listPrice(2500)), findsWidgets);

    await tester.tap(find.byTooltip(AppStrings.addInside('Maison')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.itemContainerType));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Armoire');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.create));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Armoire'), findsWidgets);

    await tester.tap(find.text('Livre'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Description'), findsNothing);
    expect(find.textContaining('Catégorie'), findsNothing);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.maybePop();
    await tester.pumpAndSettle();

    await database.close();
  });
}
