import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_compact_roulette.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'inventory_valuation_field.dart' show valuationControlHeight;

/// In-form parent selector. Optional `+` for quick location.
///
/// [compactRoulette] (UX-CORR-06 Biens): shared tactile wheel with the
/// next label peeking below — same pattern as the financial roulette.
class InventoryParentField extends StatefulWidget {
  const InventoryParentField({
    super.key,
    required this.controller,
    required this.allowRoot,
    required this.selected,
    required this.onChanged,
    this.excludingSubtreeRootId,
    this.enabled = true,
    this.showQuickAdd = false,
    this.onQuickAdd,
    this.compactRoulette = false,
    this.trailingWidth,
  });

  final InventoryTreeController controller;
  final bool allowRoot;
  final InventoryNode? selected;
  final ValueChanged<InventoryNode?> onChanged;
  final String? excludingSubtreeRootId;
  final bool enabled;
  final bool showQuickAdd;
  final Future<void> Function()? onQuickAdd;
  /// Biens: compact vertical roulette instead of [DropdownMenu].
  final bool compactRoulette;
  /// When set with [showQuickAdd], sizes the `+` slot (column alignment).
  final double? trailingWidth;

  @override
  State<InventoryParentField> createState() => _InventoryParentFieldState();
}

class _InventoryParentFieldState extends State<InventoryParentField> {
  static const _rootValue = '';
  static const _indentPerLevel = 16.0;
  var _loading = true;
  String? _loadError;
  List<({InventoryNode node, String pathLabel, int depth})> _candidates =
      const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void didUpdateWidget(covariant InventoryParentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do not reload on selected change: that tore down the roulette during
    // scroll (_loading → progress → new ListWheel) and caused the visual zap.
    // Candidates depend on controller / exclusion, not on the current pick.
    if (oldWidget.excludingSubtreeRootId != widget.excludingSubtreeRootId ||
        oldWidget.controller != widget.controller) {
      unawaited(_reload());
    }
  }

  Future<void> reload() => _reload();

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final candidates = await widget.controller.listContainmentCandidates(
        excludingSubtreeRootId: widget.excludingSubtreeRootId,
      );
      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loadError = AppStrings.parentUnavailable;
        _loading = false;
      });
    }
  }

  String? get _selectedValue {
    final selectedId = widget.selected?.id;
    if (selectedId == null) {
      return widget.allowRoot ? _rootValue : null;
    }
    return selectedId;
  }

  int _visualDepth(int depth) => depth + (widget.allowRoot ? 1 : 0);

  /// Entries for roulette / menu: optional root + candidates.
  List<({String id, String label, InventoryNode? node})> get _options {
    final nameCounts = <String, int>{};
    for (final c in _candidates) {
      final name = inventoryDisplayName(c.node.name);
      nameCounts[name] = (nameCounts[name] ?? 0) + 1;
    }
    return [
      if (widget.allowRoot)
        (
          id: _rootValue,
          label: AppStrings.rootLocation,
          node: null,
        ),
      for (final c in _candidates)
        (
          id: c.node.id,
          label: (nameCounts[inventoryDisplayName(c.node.name)] ?? 0) > 1
              ? c.pathLabel
              : inventoryDisplayName(c.node.name),
          node: c.node,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final value = _selectedValue;
    final knownIds = {for (final c in _candidates) c.node.id};
    final menuMaxHeight = (MediaQuery.sizeOf(context).height * 0.4).clamp(
      180.0,
      360.0,
    );
    final enabled = widget.enabled && _loadError == null && !_loading;
    final trailingW = widget.trailingWidth;
    final trailingH = widget.compactRoulette
        ? compactRouletteHeight
        : valuationControlHeight;

    final selector = _loading
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: LinearProgressIndicator(minHeight: 2),
          )
        : widget.compactRoulette
        ? _ParentRoulette(
            options: _options,
            selectedId: value,
            enabled: enabled,
            onSelect: (id) {
              if (id == _rootValue) {
                widget.onChanged(null);
                return;
              }
              for (final c in _candidates) {
                if (c.node.id == id) {
                  widget.onChanged(c.node);
                  return;
                }
              }
            },
          )
        : _buildDropdown(enabled, value, knownIds, menuMaxHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: selector),
            if (widget.showQuickAdd) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: trailingW ?? valuationControlHeight,
                height: trailingH,
                child: Align(
                  alignment: Alignment.center,
                  child: InventorySquareIconButton(
                    tooltip: AppStrings.quickAddLocation,
                    onPressed: !widget.enabled || widget.onQuickAdd == null
                        ? null
                        : () async {
                            await widget.onQuickAdd!();
                            if (mounted) await _reload();
                          },
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 6),
          Text(
            _loadError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown(
    bool enabled,
    String? value,
    Set<String> knownIds,
    double menuMaxHeight,
  ) {
    final entries = <DropdownMenuEntry<String>>[
      if (widget.allowRoot)
        const DropdownMenuEntry(
          value: _rootValue,
          label: AppStrings.rootLocation,
        ),
      for (final c in _candidates)
        DropdownMenuEntry(
          value: c.node.id,
          label: inventoryDisplayName(c.node.name),
          leadingIcon: SizedBox(
            width: _visualDepth(c.depth) * _indentPerLevel,
          ),
          style: MenuItemButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      if (value != null &&
          value != _rootValue &&
          !knownIds.contains(value) &&
          widget.selected != null)
        DropdownMenuEntry(
          value: value,
          label: inventoryDisplayName(widget.selected!.name),
        ),
    ];

    return DropdownMenu<String>(
      key: ValueKey('parent-${value ?? 'none'}-${_candidates.length}'),
      enabled: enabled,
      initialSelection: entries.any((e) => e.value == value) ? value : null,
      expandedInsets: EdgeInsets.zero,
      menuHeight: menuMaxHeight,
      hintText: AppStrings.chooseParent,
      requestFocusOnTap: false,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dropdownMenuEntries: entries,
      onSelected: !enabled
          ? null
          : (next) {
              if (next == null) return;
              if (next == _rootValue) {
                widget.onChanged(null);
                return;
              }
              for (final c in _candidates) {
                if (c.node.id == next) {
                  widget.onChanged(c.node);
                  return;
                }
              }
            },
    );
  }
}

/// Compact vertical picker via shared [InventoryCompactRoulette].
class _ParentRoulette extends StatelessWidget {
  const _ParentRoulette({
    required this.options,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  final List<({String id, String label, InventoryNode? node})> options;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelect;

  int _indexOf(String? id) {
    if (options.isEmpty) return 0;
    if (id == null) {
      final root = options.indexWhere((o) => o.id == '');
      return root < 0 ? 0 : root;
    }
    final i = options.indexWhere((o) => o.id == id);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexOf(selectedId);
    final label = options.isEmpty
        ? AppStrings.chooseParent
        : options[index].label;
    return InventoryCompactRoulette(
      itemCount: options.length,
      selectedIndex: index,
      enabled: enabled && options.isNotEmpty,
      semanticsLabel: AppStrings.hierarchyPosition,
      semanticsValue: label,
      labelForIndex: (i) => options[i].label,
      onSelectedIndexChanged: (i) {
        if (i < 0 || i >= options.length) return;
        onSelect(options[i].id);
      },
    );
  }
}
