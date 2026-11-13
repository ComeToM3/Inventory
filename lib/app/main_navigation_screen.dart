import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_creation_screen.dart';
import 'inventory_search_screen.dart';
import 'inventory_tree_controller.dart';
import 'inventory_tree_screen.dart';
import 'node_details_screen.dart';

enum _QuickAdd { item, container }

enum _Destination {
  inventory(
    title: AppStrings.inventory,
    message: AppStrings.inventoryEmpty,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  search(
    title: AppStrings.search,
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  history(
    title: AppStrings.history,
    message: AppStrings.historyComingSoon,
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  ),
  settings(
    title: AppStrings.settings,
    message: AppStrings.settingsComingSoon,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const _Destination({
    required this.title,
    this.message,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final String? message;
  final IconData icon;
  final IconData selectedIcon;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required this.treeController});

  final InventoryTreeController treeController;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  _Destination _selected = _Destination.inventory;
  bool _nodeRouteOpen = false;

  Future<void> _openNode(String nodeId, {bool revealMovedNode = true}) async {
    if (_nodeRouteOpen) return;
    _nodeRouteOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => NodeDetailsScreen(
            inventory: widget.treeController,
            nodeId: nodeId,
            revealMovedNode: revealMovedNode,
          ),
        ),
      );
    } finally {
      _nodeRouteOpen = false;
    }
  }

  Future<void> _openCreation({
    required InventoryNode? parent,
    required List<NodeType> allowedTypes,
    required NodeType initialType,
  }) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InventoryCreationScreen(
          controller: widget.treeController,
          parent: parent,
          allowedTypes: allowedTypes,
          initialType: initialType,
        ),
      ),
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.creationSuccess)));
  }

  Future<void> _addRoot() => _openCreation(
    parent: null,
    allowedTypes: const [NodeType.location],
    initialType: NodeType.location,
  );

  Future<void> _addChild(InventoryNode parent) => _openCreation(
    parent: parent,
    allowedTypes: NodeType.values,
    initialType: NodeType.item,
  );

  Future<void> _quickAdd() async {
    final choice = await showModalBottomSheet<_QuickAdd>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.view_in_ar_outlined),
              title: const Text(AppStrings.addItem),
              onTap: () => Navigator.pop(context, _QuickAdd.item),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text(AppStrings.addContainer),
              onTap: () => Navigator.pop(context, _QuickAdd.container),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    final parent = await Navigator.of(context).push<InventoryNode>(
      MaterialPageRoute(
        builder: (_) => _ParentPickerScreen(controller: widget.treeController),
      ),
    );
    if (!mounted || parent == null) return;
    await _openCreation(
      parent: parent,
      allowedTypes: switch (choice) {
        _QuickAdd.item => const [NodeType.item, NodeType.itemContainer],
        _QuickAdd.container => const [NodeType.container],
      },
      initialType: switch (choice) {
        _QuickAdd.item => NodeType.item,
        _QuickAdd.container => NodeType.container,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _selected == _Destination.inventory,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selected != _Destination.inventory) {
          setState(() => _selected = _Destination.inventory);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selected.title),
          actions: [
            if (_selected == _Destination.inventory)
              IconButton(
                onPressed: () => unawaited(_addRoot()),
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: AppStrings.addRootLocationTooltip,
              ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _selected.index,
            children: [
              InventoryTreeScreen(
                controller: widget.treeController,
                onAddRoot: () => unawaited(_addRoot()),
                onAddChild: (node) => unawaited(_addChild(node)),
                onOpenNode: (node) => unawaited(_openNode(node.id)),
              ),
              InventorySearchScreen(
                inventory: widget.treeController,
                active: _selected == _Destination.search,
                onOpenNode: (id) => _openNode(id, revealMovedNode: false),
              ),
              for (final destination in _Destination.values.skip(2))
                _PlaceholderScreen(destination: destination),
            ],
          ),
        ),
        floatingActionButton: _selected == _Destination.inventory
            ? AnimatedBuilder(
                animation: widget.treeController,
                builder: (context, _) {
                  final controller = widget.treeController;
                  if (controller.roots?.isNotEmpty != true ||
                      controller.rootError) {
                    return const SizedBox.shrink();
                  }
                  return FloatingActionButton(
                    onPressed: () => unawaited(_quickAdd()),
                    tooltip: AppStrings.add,
                    child: const Icon(Icons.add),
                  );
                },
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected.index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() => _selected = _Destination.values[index]);
          },
          destinations: [
            for (final destination in _Destination.values)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.title,
              ),
          ],
        ),
      ),
    );
  }
}

class _ParentPickerScreen extends StatelessWidget {
  const _ParentPickerScreen({required this.controller});

  final InventoryTreeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.chooseParent)),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(AppStrings.chooseParentHelp),
            ),
            Expanded(
              child: InventoryTreeScreen(
                controller: controller,
                onChooseParent: (node) => Navigator.pop(context, node),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: 48),
              const SizedBox(height: 16),
              Text(
                destination.message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
