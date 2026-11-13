import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/database/inventory_database.dart';
import '../core/domain/inventory_engine.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_tree_controller.dart';
import 'main_navigation_screen.dart';

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key, required this.database});

  final InventoryDatabase database;

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  late final InventoryDatabase _database;
  late final InventoryTreeController _treeController;

  @override
  void initState() {
    super.initState();
    _database = widget.database;
    _treeController = InventoryTreeController(InventoryEngine(_database));
    _treeController.loadRoots();
  }

  @override
  void dispose() {
    _treeController.dispose();
    unawaited(_closeDatabase());
    super.dispose();
  }

  Future<void> _closeDatabase() async {
    try {
      await _treeController.waitForPendingOperations();
    } finally {
      try {
        await _database.close();
      } on Exception {
        debugPrint('Impossible de fermer la base locale.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MainNavigationScreen(treeController: _treeController),
    );
  }
}
