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
import 'purchase_history_screen.dart';
import 'settings_screen.dart';
import 'stock_history_screen.dart';

const _spaces = [
  InventorySpace.goods,
  InventorySpace.stock,
  InventorySpace.toBuy,
];

/// Ignore horizontal swipes that start near the screen edge (system back).
const _edgeBackGuard = 28.0;
const _swipeVelocity = 280.0;

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
  late final Map<InventorySpace, GlobalKey<NavigatorState>> _navKeys;
  /// When true, form routes stay mounted but the tree is shown (UX-03 §4).
  final _parkedForms = <InventorySpace, bool>{};
  var _spaceIndex = 0;
  double? _swipeStartX;

  InventorySpace get _space => _spaces[_spaceIndex];

  InventoryTreeController get _activeController => _controllers[_space]!;

  InventoryTreeController get _goodsController =>
      _controllers[InventorySpace.goods]!;

  InventoryTreeController get _stockController =>
      _controllers[InventorySpace.stock]!;

  bool get _isStock => _space == InventorySpace.stock;

  bool get _isToBuy => _space == InventorySpace.toBuy;

  bool get _canMutateSpace => true;

  bool _navCanPop(InventorySpace space) =>
      _navKeys[space]?.currentState?.canPop() ?? false;

  bool _formsVisible(InventorySpace space) =>
      _navCanPop(space) && !(_parkedForms[space] ?? false);

  bool get _spaceHasOverlay => _formsVisible(_space);

  void _syncOverlayChrome() {
    if (mounted) setState(() {});
  }

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
    _navKeys = {
      for (final space in _spaces) space: GlobalKey<NavigatorState>(),
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
    _parkedForms.clear();
    if (mounted) setState(() {});
  }

  Future<void> _openNodeInTree(String nodeId) async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
    }
    _parkedForms[_space] = true;
    final nav = _navKeys[_space]?.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    _parkedForms[_space] = false;
    _syncOverlayChrome();
    await _treeKeys[_space]?.currentState?.openDetailFor(nodeId);
  }

  Future<void> _openSearch() async {
    if (!_canMutateSpace) return;
    final controller = _activeController;
    await Navigator.of(context, rootNavigator: true).push<void>(
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
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (_isStock) {
      await rootNav.push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.history)),
            body: StockHistoryScreen(controller: _stockController),
          ),
        ),
      );
      return;
    }
    if (_isToBuy) {
      await rootNav.push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.history)),
            body: PurchaseHistoryScreen(
              controller: _controllers[InventorySpace.toBuy]!,
            ),
          ),
        ),
      );
      return;
    }
    await rootNav.push<void>(
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
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          database: widget.database,
          onInventoryRestored: _handleInventoryRestored,
        ),
      ),
    );
  }

  Future<void> _openHelp() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  List<NodeType> _creatableTypesFor(InventorySpace space) {
    // Biens / Stock / À acheter : Emplacement + item unifié.
    // Contenant = bascule dans le formulaire Biens (pas d’option séparée).
    return const [NodeType.location, NodeType.item];
  }

  /// Resumes a parked creation stack, or starts a fresh one.
  Future<void> _startCreation({
    required InventorySpace space,
    InventoryNode? initialParent,
  }) async {
    if (!_canMutateSpace) return;
    final nav = _navKeys[space]?.currentState;
    if (nav == null) return;

    if (nav.canPop()) {
      setState(() => _parkedForms[space] = false);
      return;
    }

    // Contextual + supplies a parent; menu Ajouter defaults to permanent root.
    final parent = initialParent ??
        await _controllers[space]!.ensurePermanentRootNode();
    if (!mounted) return;

    final pending = nav.push<Object?>(
      MaterialPageRoute(
        builder: (pickerContext) => _TypePickerScreen(
          allowedTypes: _creatableTypesFor(space),
          stockLabels: space == InventorySpace.stock,
          toBuyLabels: space == InventorySpace.toBuy,
          unifyGoodsItem: space == InventorySpace.goods,
          onTypeSelected: (type) async {
            final formPending = Navigator.of(pickerContext).push<Object?>(
              MaterialPageRoute(
                builder: (_) => InventoryCreationScreen(
                  controller: _controllers[space]!,
                  type: type,
                  initialParent: parent,
                  goodsController: _goodsController,
                  stockController: _stockController,
                ),
              ),
            );
            _syncOverlayChrome();
            final result = await formPending;
            _syncOverlayChrome();
            if (result != null && pickerContext.mounted) {
              Navigator.of(pickerContext).pop(result);
            }
          },
        ),
      ),
    );
    setState(() => _parkedForms[space] = false);
    _syncOverlayChrome();
    final created = await pending;
    _syncOverlayChrome();
    if (!mounted || created == null || created == false) return;
    final parentId = created is InventoryNode
        ? created.parentId
        : initialParent?.id;
    _treeKeys[space]?.currentState?.settleAfterMutation(parentId: parentId);
    showInventoryMessage(context, AppStrings.creationSuccess);
  }

  Future<void> _startEdit({
    required InventorySpace space,
    required InventoryNode node,
  }) async {
    if (!_canMutateSpace) return;
    final nav = _navKeys[space]?.currentState;
    if (nav == null) return;
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    final controller = _controllers[space]!;
    final pending = nav.push<Object?>(
      MaterialPageRoute(
        builder: (_) => InventoryCreationScreen(
          controller: controller,
          type: node.type,
          existing: node,
          goodsController: _goodsController,
          stockController: _stockController,
        ),
      ),
    );
    setState(() => _parkedForms[space] = false);
    _syncOverlayChrome();
    final saved = await pending;
    _syncOverlayChrome();
    if (!mounted || saved == null || saved == false) return;
    if (saved == 'deleted' ||
        saved == 'withdrawn' ||
        saved == 'abandoned' ||
        saved == 'acquired') {
      _treeKeys[space]?.currentState?.clearPhase(node.id);
    } else {
      _treeKeys[space]?.currentState?.settleAfterMutation(
        nodeId: node.id,
        parentId: node.parentId,
      );
    }
    final message = switch (saved) {
      'withdrawn' => AppStrings.withdrawSuccess,
      'abandoned' => AppStrings.abandonSuccess,
      'acquired' => AppStrings.purchaseSuccess,
      'deleted' => AppStrings.deleteSuccess,
      _ => AppStrings.editSuccess,
    };
    showInventoryMessage(context, message);
  }

  void _onSpaceSelected(int index) {
    if (index == _spaceIndex) {
      if (_navCanPop(_space) && !(_parkedForms[_space] ?? false)) {
        setState(() => _parkedForms[_space] = true);
      }
      return;
    }
    setState(() => _spaceIndex = index);
  }

  void _swipeSpace(int delta) {
    final next = (_spaceIndex + delta) % _spaces.length;
    final index = next < 0 ? next + _spaces.length : next;
    if (index == _spaceIndex) return;
    setState(() => _spaceIndex = index);
  }

  void _onSwipeStart(DragStartDetails details) {
    _swipeStartX = details.globalPosition.dx;
  }

  void _onSwipeEnd(DragEndDetails details) {
    final startX = _swipeStartX;
    _swipeStartX = null;
    if (startX == null) return;
    final width = MediaQuery.sizeOf(context).width;
    // Avoid fighting the system predictive-back / edge gesture.
    if (startX <= _edgeBackGuard || startX >= width - _edgeBackGuard) {
      return;
    }
    if (_treeKeys[_space]?.currentState?.isDragging ?? false) return;
    final vx = details.primaryVelocity ?? 0;
    if (vx <= -_swipeVelocity) {
      _swipeSpace(1);
    } else if (vx >= _swipeVelocity) {
      _swipeSpace(-1);
    }
  }

  Widget _buildSpaceBody(InventorySpace space) {
    final formsVisible = _formsVisible(space);
    return Stack(
      fit: StackFit.expand,
      children: [
        InventoryTreeScreen(
          key: _treeKeys[space],
          controller: _controllers[space]!,
          onAddRoot: () => unawaited(_startCreation(space: space)),
          onAddChild: (node) => unawaited(
            _startCreation(space: space, initialParent: node),
          ),
          onEditNode: (node) => unawaited(_startEdit(space: space, node: node)),
          goodsController: _goodsController,
          stockController: _stockController,
        ),
        Offstage(
          offstage: !formsVisible,
          child: TickerMode(
            enabled: formsVisible,
            child: Navigator(
              key: _navKeys[space],
              onGenerateInitialRoutes: (navigator, initialRoute) {
                return [
                  PageRouteBuilder<void>(
                    opaque: false,
                    settings: const RouteSettings(name: '/'),
                    pageBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ];
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_spaceHasOverlay,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _navKeys[_space]?.currentState?.maybePop();
        _syncOverlayChrome();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.view_in_ar, size: 22),
              const SizedBox(width: 10),
              Text(AppStrings.appTitle),
              const SizedBox(width: 10),
              Text(
                '· ${AppStrings.labelForSpace(_space)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            if (_canMutateSpace && !_spaceHasOverlay)
              IconButton(
                tooltip: AppStrings.search,
                onPressed: () => unawaited(_openSearch()),
                icon: const Icon(Icons.search),
              ),
            if (!_spaceHasOverlay)
              PopupMenuButton<String>(
                tooltip: AppStrings.moreActions,
                onSelected: (value) {
                  switch (value) {
                    case 'root':
                      unawaited(_startCreation(space: _space));
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
                  const PopupMenuItem(
                    value: 'help',
                    child: Text(AppStrings.help),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text(AppStrings.settings),
                  ),
                ],
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onSwipeStart,
          onHorizontalDragEnd: _onSwipeEnd,
          child: IndexedStack(
            index: _spaceIndex,
            children: [
              for (final space in _spaces) _buildSpaceBody(space),
            ],
          ),
        ),
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
      ),
    );
  }
}

class _TypePickerScreen extends StatelessWidget {
  const _TypePickerScreen({
    required this.allowedTypes,
    required this.onTypeSelected,
    this.stockLabels = false,
    this.toBuyLabels = false,
    this.unifyGoodsItem = false,
  });

  final List<NodeType> allowedTypes;
  final ValueChanged<NodeType> onTypeSelected;
  final bool stockLabels;
  final bool toBuyLabels;
  final bool unifyGoodsItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text(AppStrings.createTitle)),
      body: SafeArea(
        child: InventoryThumbBody(
          children: [
            for (final type in allowedTypes) ...[
              InventoryTypeChoiceCard(
                type: type,
                labelOverride: stockLabels && type == NodeType.item
                    ? AppStrings.stockProductType
                    : (toBuyLabels && type == NodeType.item
                          ? AppStrings.needType
                          : (unifyGoodsItem && type == NodeType.item
                                ? AppStrings.goodsItemType
                                : null)),
                exampleOverride: unifyGoodsItem && type == NodeType.item
                    ? AppStrings.goodsItemExample
                    : null,
                onTap: () => onTypeSelected(type),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
