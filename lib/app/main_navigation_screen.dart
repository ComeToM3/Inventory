import 'dart:async';

import 'package:flutter/material.dart';

import '../core/database/inventory_database.dart';
import '../core/domain/inventory_engine.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'help_screen.dart';
import 'inventory_creation_screen.dart';
import 'inventory_history_screen.dart';
import 'inventory_messages.dart';
import 'inventory_search_screen.dart';
import 'inventory_thumb_layout.dart';
import 'inventory_tree_controller.dart';
import 'inventory_tree_screen.dart';
import 'inventory_ui.dart';
import 'settings_screen.dart';
import 'stock_history_screen.dart';

const _creatableTypes = [
  NodeType.location,
  NodeType.item,
  NodeType.itemContainer,
];

const _spaces = [
  InventorySpace.goods,
  InventorySpace.stock,
  InventorySpace.toBuy,
];

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.engine,
    required this.database,
    this.onInventoryRestored,
  });

  final InventoryEngine engine;
  final InventoryDatabase database;
  final Future<void> Function()? onInventoryRestored;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final Map<InventorySpace, InventoryTreeController> _controllers;
  late final Map<InventorySpace, GlobalKey<InventoryTreeScreenState>> _treeKeys;
  var _spaceIndex = 0;
  bool _creationRouteOpen = false;

  InventorySpace get _space => _spaces[_spaceIndex];

  InventoryTreeController get _activeController => _controllers[_space]!;

  InventoryTreeController get _goodsController =>
      _controllers[InventorySpace.goods]!;

  InventoryTreeController get _stockController =>
      _controllers[InventorySpace.stock]!;

  bool get _isGoods => _space == InventorySpace.goods;

  bool get _isStock => _space == InventorySpace.stock;

  bool get _canMutateSpace => _isGoods || _isStock;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final space in _spaces)
        space: InventoryTreeController(widget.engine, space: space),
    };
    _treeKeys = {
      for (final space in _spaces)
        space: GlobalKey<InventoryTreeScreenState>(),
    };
    for (final controller in _controllers.values) {
      controller.loadRoots();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleInventoryRestored() async {
    final callback = widget.onInventoryRestored;
    if (callback != null) await callback();
    for (final controller in _controllers.values) {
      controller.resetAfterRestore();
    }
  }

  Future<void> _openNodeInTree(String nodeId) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    await _treeKeys[_space]?.currentState?.openDetailFor(nodeId);
  }

  Future<void> _openSearch() async {
    if (!_canMutateSpace) return;
    final controller = _activeController;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text(AppStrings.search)),
          body: InventorySearchScreen(
            inventory: controller,
            active: true,
            onOpenNode: _openNodeInTree,
          ),
        ),
      ),
    );
  }

  Future<void> _openHistory() async {
    if (!_canMutateSpace) return;
    if (_isStock) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.history)),
            body: StockHistoryScreen(controller: _stockController),
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text(AppStrings.history)),
          body: InventoryHistoryScreen(
            inventory: _goodsController,
            active: true,
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          database: widget.database,
          onInventoryRestored: _handleInventoryRestored,
        ),
      ),
    );
  }

  Future<void> _openHelp() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  Future<void> _openCreation({
    required NodeType type,
    InventoryNode? initialParent,
  }) async {
    if (!_canMutateSpace || _creationRouteOpen) return;
    _creationRouteOpen = true;
    final controller = _activeController;
    final space = _space;
    try {
      final created = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => InventoryCreationScreen(
            controller: controller,
            type: type,
            initialParent: initialParent,
          ),
        ),
      );
      if (!mounted || created == null || created == false) return;
      final parentId = created is InventoryNode
          ? created.parentId
          : initialParent?.id;
      _treeKeys[space]?.currentState?.settleAfterMutation(parentId: parentId);
      showInventoryMessage(context, AppStrings.creationSuccess);
    } finally {
      _creationRouteOpen = false;
    }
  }

  Future<void> _addRoot() async {
    if (!_canMutateSpace) return;
    final type = await _pickType();
    if (!mounted || type == null) return;
    await _openCreation(type: type);
  }

  Future<void> _addChild(InventoryNode parent) async {
    if (!_canMutateSpace) return;
    final type = await _pickType();
    if (!mounted || type == null) return;
    await _openCreation(type: type, initialParent: parent);
  }

  Future<NodeType?> _pickType() {
    return Navigator.of(context).push<NodeType>(
      MaterialPageRoute(
        builder: (_) => _TypePickerScreen(
          allowedTypes: _creatableTypes,
          stockLabels: _isStock,
        ),
      ),
    );
  }

  Future<void> _quickAdd() async {
    if (!_canMutateSpace) return;
    final type = await _pickType();
    if (!mounted || type == null) return;
    await _openCreation(type: type);
  }

  void _onSpaceSelected(int index) {
    if (index == _spaceIndex) return;
    setState(() => _spaceIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.view_in_ar, size: 22),
            const SizedBox(width: 10),
            Text(AppStrings.appTitle),
            const SizedBox(width: 10),
            Text(
              '· ${AppStrings.labelForSpace(_space)}',
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
            ),
          ],
        ),
        actions: [
          if (_canMutateSpace)
            IconButton(
              tooltip: AppStrings.search,
              onPressed: () => unawaited(_openSearch()),
              icon: const Icon(Icons.search),
            ),
          PopupMenuButton<String>(
            tooltip: AppStrings.moreActions,
            onSelected: (value) {
              switch (value) {
                case 'root':
                  unawaited(_addRoot());
                case 'history':
                  unawaited(_openHistory());
                case 'help':
                  unawaited(_openHelp());
                case 'settings':
                  unawaited(_openSettings());
              }
            },
            itemBuilder: (context) => [
              if (_canMutateSpace)
                const PopupMenuItem(
                  value: 'root',
                  child: Text(AppStrings.add),
                ),
              if (_canMutateSpace)
                const PopupMenuItem(
                  value: 'history',
                  child: Text(AppStrings.history),
                ),
              const PopupMenuItem(value: 'help', child: Text(AppStrings.help)),
              const PopupMenuItem(
                value: 'settings',
                child: Text(AppStrings.settings),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_space == InventorySpace.toBuy)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        AppStrings.spaceComingSoon,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _spaceIndex,
              children: [
                for (final space in _spaces)
                  InventoryTreeScreen(
                    key: _treeKeys[space],
                    controller: _controllers[space]!,
                    onAddRoot: space == InventorySpace.goods ||
                            space == InventorySpace.stock
                        ? () => unawaited(_addRoot())
                        : null,
                    onAddChild: space == InventorySpace.goods ||
                            space == InventorySpace.stock
                        ? (node) => unawaited(_addChild(node))
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _canMutateSpace
          ? FloatingActionButton(
              onPressed: () => unawaited(_quickAdd()),
              tooltip: AppStrings.add,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _spaceIndex,
        onDestinationSelected: _onSpaceSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.spaceGoods,
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: AppStrings.spaceStock,
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: AppStrings.spaceToBuy,
          ),
        ],
      ),
    );
  }
}

class _TypePickerScreen extends StatelessWidget {
  const _TypePickerScreen({
    required this.allowedTypes,
    this.stockLabels = false,
  });

  final List<NodeType> allowedTypes;
  final bool stockLabels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createTitle)),
      body: SafeArea(
        child: InventoryThumbBody(
          children: [
            for (final type in allowedTypes) ...[
              InventoryTypeChoiceCard(
                type: type,
                labelOverride: stockLabels && type == NodeType.item
                    ? AppStrings.stockProductType
                    : null,
                onTap: () => Navigator.pop(context, type),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
