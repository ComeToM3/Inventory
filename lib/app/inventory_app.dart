import 'dart:async';

import 'package:flutter/material.dart';

import '../core/database/inventory_database.dart';
import 'app_strings.dart';
import 'persistence_check_controller.dart';
import 'persistence_check_screen.dart';

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  late final PersistenceCheckController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistenceCheckController(InventoryDatabase());
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      home: PersistenceCheckScreen(controller: _controller),
    );
  }
}
