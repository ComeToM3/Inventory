import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';

/// In-form parent selector (no separate page). Optional `+` for quick location.
///
/// Uses Material 3 [DropdownMenu] instead of [DropdownButtonFormField]: the
/// legacy menu opened upward over the « Position » label and could not show
/// depth indentation reliably (UI-001).
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
  });

  final InventoryTreeController controller;
  final bool allowRoot;
  final InventoryNode? selected;
  final ValueChanged<InventoryNode?> onChanged;
  final String? excludingSubtreeRootId;
  final bool enabled;
  final bool showQuickAdd;
  final Future<void> Function()? onQuickAdd;

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
    if (oldWidget.excludingSubtreeRootId != widget.excludingSubtreeRootId ||
        oldWidget.controller != widget.controller ||
        oldWidget.selected?.id != widget.selected?.id) {
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

  @override
  Widget build(BuildContext context) {
    final value = _selectedValue;
    final knownIds = {for (final c in _candidates) c.node.id};
    final menuMaxHeight = (MediaQuery.sizeOf(context).height * 0.4).clamp(
      180.0,
      360.0,
    );
    final enabled = widget.enabled && _loadError == null && !_loading;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : DropdownMenu<String>(
                      key: ValueKey(
                        'parent-${value ?? 'none'}-${_candidates.length}',
                      ),
                      enabled: enabled,
                      initialSelection: entries.any((e) => e.value == value)
                          ? value
                          : null,
                      expandedInsets: EdgeInsets.zero,
                      menuHeight: menuMaxHeight,
                      hintText: AppStrings.chooseParent,
                      requestFocusOnTap: false,
                      inputDecorationTheme: const InputDecorationTheme(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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
                    ),
            ),
            if (widget.showQuickAdd) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: AppStrings.quickAddLocation,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: !widget.enabled || widget.onQuickAdd == null
                    ? null
                    : () async {
                        await widget.onQuickAdd!();
                        if (mounted) await _reload();
                      },
                icon: const Icon(Icons.add),
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
}
