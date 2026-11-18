import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_messages.dart';
import 'inventory_search_controller.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';

class InventorySearchScreen extends StatefulWidget {
  const InventorySearchScreen({
    super.key,
    required this.inventory,
    required this.active,
    required this.onOpenNode,
  });

  final InventoryTreeController inventory;
  final bool active;
  final Future<void> Function(String nodeId) onOpenNode;

  @override
  State<InventorySearchScreen> createState() => _InventorySearchScreenState();
}

class _InventorySearchScreenState extends State<InventorySearchScreen> {
  late final InventorySearchController _controller;
  final _name = TextEditingController();
  final _scrollController = ScrollController();
  bool _opening = false;
  bool _pickingBranch = false;

  @override
  void initState() {
    super.initState();
    _controller = InventorySearchController(widget.inventory);
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(covariant InventorySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _activate();
  }

  void _activate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      unawaited(_controller.refresh());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openResult(InventorySearchResult result) async {
    if (_opening) return;
    FocusScope.of(context).unfocus();
    setState(() => _opening = true);
    try {
      await widget.onOpenNode(result.nodeId);
    } on InventoryException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        InventoryErrorCode.nodeInactive ||
        InventoryErrorCode.nodeNotFound =>
          AppStrings.nodeUnavailable,
        _ => AppStrings.searchReadError,
      };
      showInventoryMessage(context, message);
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        unawaited(_controller.refresh());
      }
    }
  }

  Future<void> _chooseBranch() async {
    if (_pickingBranch) return;
    FocusScope.of(context).unfocus();
    setState(() => _pickingBranch = true);
    try {
      final path = await Navigator.of(context).push<List<InventoryNode>>(
        MaterialPageRoute(
          builder: (_) => _SearchBranchPicker(inventory: widget.inventory),
        ),
      );
      if (mounted && path != null) _controller.setBranch(path);
    } finally {
      if (mounted) setState(() => _pickingBranch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final branchPath = _controller.branchPath;
        final branchLabel = branchPath == null
            ? AppStrings.allBranches
            : branchPath
                .map((node) => inventoryDisplayName(node.name))
                .join(' → ');
        final summary = <String>[
          if (_controller.type case final type?)
            AppStrings.labelForNodeType(type),
          if (branchPath != null) branchLabel,
        ];
        final hasFilters =
            _controller.type != null || branchPath != null;
        final showResults =
            !_controller.loading &&
            _controller.readError == null &&
            !_controller.criteria.isEmpty &&
            _controller.results.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.65,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: TextField(
                          controller: _name,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchByName,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _controller.name.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: AppStrings.clearSearch,
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _name.clear();
                                      _controller.setName('');
                                    },
                                  ),
                            filled: true,
                            fillColor: InventoryColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: InventoryColors.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: InventoryColors.mintDeep,
                                width: 1.5,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: _controller.setName,
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                            unawaited(_controller.refresh());
                          },
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
                        child: Row(
                          children: [
                            InventoryFilterChip(
                              label: AppStrings.filterAll,
                              selected: _controller.type == null,
                              onSelected: (_) => _controller.setType(null),
                            ),
                            const SizedBox(width: 8),
                            InventoryFilterChip(
                              label: AppStrings.filterItems,
                              selected: _controller.type == NodeType.item,
                              onSelected: (_) =>
                                  _controller.setType(NodeType.item),
                            ),
                            const SizedBox(width: 8),
                            InventoryFilterChip(
                              label: AppStrings.filterItemContainers,
                              selected:
                                  _controller.type == NodeType.itemContainer,
                              onSelected: (_) =>
                                  _controller.setType(NodeType.itemContainer),
                            ),
                            const SizedBox(width: 8),
                            InventoryFilterChip(
                              label: AppStrings.filterLocations,
                              selected: _controller.type == NodeType.location,
                              onSelected: (_) =>
                                  _controller.setType(NodeType.location),
                            ),
                          ],
                        ),
                      ),
                      ExpansionTile(
                        title: const Text(AppStrings.moreFilters),
                        subtitle: Text(
                          summary.isEmpty
                              ? AppStrings.searchNoFilters
                              : summary.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(AppStrings.searchFiltersHelp),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<NodeType>(
                                  key: ValueKey('type-${_controller.type}'),
                                  initialValue: _controller.type,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.nodeType,
                                  ),
                                  items: [
                                    const DropdownMenuItem<NodeType>(
                                      value: null,
                                      child: Text(AppStrings.allNodeTypes),
                                    ),
                                    for (final type in NodeType.values)
                                      DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          AppStrings.labelForNodeType(type),
                                        ),
                                      ),
                                  ],
                                  onChanged: _controller.setType,
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    AppStrings.chooseSearchBranch,
                                  ),
                                  subtitle: Text(branchLabel),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _pickingBranch
                                      ? null
                                      : () => unawaited(_chooseBranch()),
                                ),
                                TextButton(
                                  onPressed: hasFilters
                                      ? _controller.resetFilters
                                      : null,
                                  child: const Text(AppStrings.resetFilters),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      excluding: !showResults,
                      child: IgnorePointer(
                        ignoring: !showResults || _opening,
                        child: ListView.builder(
                          key: const PageStorageKey('search-results'),
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: _controller.results.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  AppStrings.searchResultCount(
                                    _controller.results.length,
                                  ),
                                  style: const TextStyle(
                                    color: InventoryColors.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            final result = _controller.results[index - 1];
                            final badge = inventorySearchValuationBadge(
                              type: result.type,
                              quantity: result.quantity,
                              valuation: result.valuation,
                            );
                            final location = _ancestorPathLabel(
                              result.path,
                              result.name,
                            );
                            return InventoryResultCard(
                              title: inventoryDisplayName(result.name),
                              subtitle:
                                  '${AppStrings.labelForNodeType(result.type)}\n$location',
                              badge: badge.isEmpty ? null : badge,
                              onTap: () => unawaited(_openResult(result)),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!showResults)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _resultState(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resultState() {
    if (_controller.loading) {
      return const CircularProgressIndicator(
        semanticsLabel: AppStrings.searchLoading,
      );
    }
    if (_controller.readError case final error?) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => unawaited(_controller.refresh()),
            child: const Text(AppStrings.retry),
          ),
        ],
      );
    }
    return Text(
      _controller.criteria.isEmpty
          ? AppStrings.searchInitial
          : AppStrings.searchEmpty,
      textAlign: TextAlign.center,
    );
  }

  /// Drop the leaf name from the engine path when the card title already shows it.
  static String _ancestorPathLabel(String path, String name) {
    final parts = path.split(' → ');
    if (parts.isNotEmpty && parts.last == name) {
      parts.removeLast();
    }
    if (parts.isEmpty) return AppStrings.inventoryRoot;
    return parts.map(inventoryDisplayName).join(' → ');
  }
}

class _SearchBranchPicker extends StatefulWidget {
  const _SearchBranchPicker({required this.inventory});

  final InventoryTreeController inventory;

  @override
  State<_SearchBranchPicker> createState() => _SearchBranchPickerState();
}

class _SearchBranchPickerState extends State<_SearchBranchPicker> {
  late final SearchBranchController _controller;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = SearchBranchController(widget.inventory);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(List<InventoryNode>? path) {
    if (_finishing) return;
    _finishing = true;
    Navigator.pop(context, path);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final path = _controller.path;
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.chooseSearchBranch)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(AppStrings.searchBranchHelp),
                      const SizedBox(height: 16),
                      Text(
                        path.isEmpty
                            ? AppStrings.inventoryRoot
                            : path
                                .map((node) => inventoryDisplayName(node.name))
                                .join(' → '),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_controller.canGoUp)
                        ListTile(
                          leading: const Icon(Icons.arrow_upward),
                          title: const Text(AppStrings.parentLevel),
                          onTap: _controller.loading
                              ? null
                              : () => unawaited(_controller.goUp()),
                        ),
                      const Divider(),
                      if (_controller.loading)
                        const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: AppStrings.branchLoading,
                          ),
                        )
                      else if (_controller.readError case final error?) ...[
                        Text(error),
                        TextButton(
                          onPressed: () => unawaited(_controller.load()),
                          child: const Text(AppStrings.retry),
                        ),
                      ] else if (_controller.children.isEmpty)
                        const Text(AppStrings.noSearchBranches)
                      else
                        for (final node in _controller.children)
                          ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(inventoryDisplayName(node.name)),
                            subtitle: Text(
                              AppStrings.labelForNodeType(node.type),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => unawaited(_controller.enter(node)),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _controller.canChoose && !_finishing
                            ? () => _finish(path)
                            : null,
                        child: const Text(AppStrings.searchHere),
                      ),
                      TextButton(
                        onPressed: _finishing ? null : () => _finish(null),
                        child: const Text(AppStrings.cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
