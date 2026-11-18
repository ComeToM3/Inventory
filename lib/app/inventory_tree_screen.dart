import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/stock_quantity.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_creation_screen.dart';
import 'inventory_inline_sheet.dart';
import 'inventory_messages.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';

/// Compact hierarchy indent (DEV-33): enough to read levels, more width for names.
const _indentPerLevel = 8.0;
const _maxVisualIndent = 48.0;
/// Zone B — shared right-aligned price column (fits e.g. `1 000 $`).
const _priceColumnWidth = 72.0;
/// Zone C — Stock level circle or `+` (empty when neither applies).
const _actionColumnWidth = 48.0;
const _expandHoverDelay = Duration(milliseconds: 650);
const _autoScrollEdge = 56.0;
const _autoScrollStep = 28.0;
/// Shorter than DEV-26: users often start moving before 450 ms elapses.
const _longPressDelay = Duration(milliseconds: 320);
/// Extra tolerance so finger tremor does not cancel the long-press in a ScrollView.
const _dragTouchSlop = 40.0;

/// Progressive row expansion (DEV-26): closed → children → info → childrenKeep → closed.
enum _RowPhase { closed, children, info, childrenKeep }

class InventoryTreeScreen extends StatefulWidget {
  const InventoryTreeScreen({
    super.key,
    required this.controller,
    this.onAddRoot,
    this.onAddChild,
  });

  final InventoryTreeController controller;
  final VoidCallback? onAddRoot;
  final ValueChanged<InventoryNode>? onAddChild;

  @override
  State<InventoryTreeScreen> createState() => InventoryTreeScreenState();
}

class InventoryTreeScreenState extends State<InventoryTreeScreen> {
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final _phase = <String, _RowPhase>{};
  InventoryNode? _dragging;
  String? _hoverTargetId;
  var _hoverRoot = false;
  var _moving = false;
  Timer? _expandTimer;
  Timer? _scrollTimer;
  int _scrollDirection = 0;

  _RowPhase _phaseOf(String id) => _phase[id] ?? _RowPhase.closed;

  bool _infoOpen(String id) => _phaseOf(id) == _RowPhase.info;

  @override
  void dispose() {
    _expandTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Reveals [nodeId] and opens its info sub-line (search entry only).
  Future<void> openDetailFor(String nodeId) async {
    await widget.controller.revealNode(nodeId);
    if (!mounted) return;
    final node = widget.controller.findCachedNode(nodeId);
    if (node == null) return;
    if (node.type.canContain) {
      await widget.controller.expandAndLoadChildren(node);
      if (!mounted) return;
    }
    setState(() => _phase[nodeId] = _RowPhase.info);
  }

  /// After create/edit: never leave detail info open; keep useful expansion.
  ///
  /// Creating or saving is not an implicit request to open consultation.
  void settleAfterMutation({String? nodeId, String? parentId}) {
    if (!mounted) return;
    setState(() {
      void settle(String id) {
        final expanded = widget.controller.isExpanded(id);
        final phase = _phaseOf(id);
        if (phase == _RowPhase.info) {
          _phase[id] = expanded ? _RowPhase.childrenKeep : _RowPhase.closed;
        } else if (expanded && phase == _RowPhase.closed) {
          // Parent expanded programmatically after create — align cycle phase.
          _phase[id] = _RowPhase.children;
        }
      }

      if (nodeId != null) settle(nodeId);
      if (parentId != null && parentId != nodeId) settle(parentId);
    });
  }

  void _clearDragUi() {
    _expandTimer?.cancel();
    _expandTimer = null;
    _stopAutoScroll();
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _hoverTargetId = null;
      _hoverRoot = false;
    });
  }

  void _onDragStarted(InventoryNode node) {
    setState(() {
      _dragging = node;
      _hoverTargetId = null;
      _hoverRoot = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _stopAutoScroll();
      return;
    }
    final local = box.globalToLocal(details.globalPosition);
    if (local.dy < _autoScrollEdge) {
      _startAutoScroll(-1);
    } else if (local.dy > box.size.height - _autoScrollEdge) {
      _startAutoScroll(1);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(int direction) {
    if (_scrollDirection == direction && _scrollTimer != null) return;
    _scrollDirection = direction;
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_scrollController.hasClients) return;
      final next = (_scrollController.offset + direction * _autoScrollStep)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      if (next == _scrollController.offset) {
        _stopAutoScroll();
        return;
      }
      _scrollController.jumpTo(next);
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollDirection = 0;
  }

  void _scheduleExpand(InventoryNode target) {
    if (widget.controller.isExpanded(target.id)) return;
    if (_expandTimer != null && _hoverTargetId == target.id) return;
    _expandTimer?.cancel();
    _expandTimer = Timer(_expandHoverDelay, () {
      if (!mounted || _dragging == null) return;
      if (_hoverTargetId != target.id) return;
      widget.controller.expand(target);
    });
  }

  void _setHoverTarget(InventoryNode? target, {required bool root}) {
    final nextId = target?.id;
    if (_hoverTargetId == nextId && _hoverRoot == root) {
      if (target != null) _scheduleExpand(target);
      return;
    }
    _expandTimer?.cancel();
    setState(() {
      _hoverTargetId = nextId;
      _hoverRoot = root;
    });
    if (target != null) _scheduleExpand(target);
  }

  Future<void> _commitMove(InventoryNode dragged, String? newParentId) async {
    _clearDragUi();
    if (_moving) return;
    if (dragged.parentId == newParentId) return;
    setState(() => _moving = true);
    try {
      await widget.controller.moveNode(dragged.id, newParentId);
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.moveSuccess);
    } on InventoryException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        InventoryErrorCode.cycleDetected => AppStrings.cyclicDestination,
        InventoryErrorCode.parentNotFound ||
        InventoryErrorCode.parentInactive ||
        InventoryErrorCode.parentCannotContain ||
        InventoryErrorCode.parentRequired ||
        InventoryErrorCode.invalidHierarchy => AppStrings.invalidDestination,
        InventoryErrorCode.nodeNotFound ||
        InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
        _ => AppStrings.moveError,
      };
      showInventoryMessage(context, message);
    } catch (_) {
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.moveError);
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Future<void> _cycleExpand(InventoryNode node) async {
    if (_moving || _dragging != null) return;
    final phase = _phaseOf(node.id);

    if (!node.type.canContain) {
      setState(() {
        _phase[node.id] = phase == _RowPhase.info
            ? _RowPhase.closed
            : _RowPhase.info;
      });
      return;
    }

    switch (phase) {
      case _RowPhase.closed:
        await widget.controller.expandAndLoadChildren(node);
        if (!mounted) return;
        final count = widget.controller.loadedChildCount(node.id) ?? 0;
        if (count == 0) {
          widget.controller.collapse(node);
          setState(() => _phase[node.id] = _RowPhase.info);
        } else {
          setState(() => _phase[node.id] = _RowPhase.children);
        }
      case _RowPhase.children:
        setState(() => _phase[node.id] = _RowPhase.info);
      case _RowPhase.info:
        // Keep children visible; only hide the consultation sub-line.
        setState(() => _phase[node.id] = _RowPhase.childrenKeep);
      case _RowPhase.childrenKeep:
        widget.controller.collapse(node);
        setState(() => _phase[node.id] = _RowPhase.closed);
    }
  }

  Future<void> _openEdit(InventoryNode node) async {
    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => InventoryCreationScreen(
          controller: widget.controller,
          type: node.type,
          existing: node,
        ),
      ),
    );
    if (!mounted || saved == null || saved == false) return;
    if (saved == 'deleted' || saved == 'withdrawn') {
      setState(() => _phase.remove(node.id));
    } else {
      settleAfterMutation(nodeId: node.id, parentId: node.parentId);
    }
    final message = switch (saved) {
      'withdrawn' => AppStrings.withdrawSuccess,
      'deleted' => AppStrings.deleteSuccess,
      _ => AppStrings.editSuccess,
    };
    showInventoryMessage(context, message);
  }

  Future<void> _cycleStockLevel(InventoryNode node) async {
    if (_moving || _dragging != null || !node.isStockProduct) return;
    try {
      await widget.controller.cycleStockLevel(node.id);
    } on InventoryException {
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.saveError);
    } catch (_) {
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.saveError);
    }
  }

  String _pathLabelFor(InventoryTreeEntry entry, List<InventoryTreeEntry> all) {
    if (entry.depth == 0) return AppStrings.rootLocation;
    final index = all.indexWhere((e) => e.node.id == entry.node.id);
    if (index <= 0) return AppStrings.rootLocation;
    final parts = <String>[];
    var depth = entry.depth;
    for (var i = index - 1; i >= 0 && depth > 0; i--) {
      final candidate = all[i];
      if (candidate.depth == depth - 1) {
        parts.insert(0, inventoryDisplayName(candidate.node.name));
        depth = candidate.depth;
      }
    }
    return parts.isEmpty ? AppStrings.rootLocation : parts.join(' → ');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final roots = controller.roots;
        if (roots == null) {
          if (controller.rootError) {
            return _CenteredMessage(
              message: AppStrings.inventoryReadError,
              action: TextButton(
                onPressed: controller.loadRoots,
                child: const Text(AppStrings.retry),
              ),
            );
          }
          if (!controller.loadingRoots) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final current = widget.controller;
              if (current.roots == null &&
                  !current.loadingRoots &&
                  !current.rootError) {
                current.loadRoots();
              }
            });
          }
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: AppStrings.inventoryLoading,
            ),
          );
        }
        if (controller.rootError && roots.isEmpty) {
          return _CenteredMessage(
            message: AppStrings.inventoryReadError,
            action: TextButton(
              onPressed: controller.loadRoots,
              child: const Text(AppStrings.retry),
            ),
          );
        }
        if (roots.isEmpty) {
          return _CenteredMessage(
            message: AppStrings.emptyMessageForSpace(controller.space),
            action: widget.onAddRoot == null
                ? null
                : FilledButton.icon(
                    onPressed: widget.onAddRoot,
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addRootLocation),
                  ),
          );
        }

        final entries = controller.visibleEntries;
        controller.ensureSubtreeTotals([
          for (final entry in entries)
            if (entry.node.type.canContain) entry.node.id,
        ]);
        final dragging = _dragging;
        final showRootDrop =
            dragging != null && dragging.type.canBeRoot && !_moving;

        return Column(
          children: [
            if (controller.rootError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(child: Text(AppStrings.inventoryReadError)),
                    TextButton(
                      onPressed: controller.loadRoots,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            if (dragging != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  AppStrings.dragHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: InventoryColors.mutedText,
                  ),
                ),
              ),
            if (showRootDrop)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _RootDropTarget(
                  highlighted: _hoverRoot,
                  enabled: !_moving,
                  onWillAccept: () {
                    _setHoverTarget(null, root: true);
                    return true;
                  },
                  onLeave: () {
                    if (_hoverRoot) setState(() => _hoverRoot = false);
                  },
                  onAccept: (dragged) => unawaited(_commitMove(dragged, null)),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const padding = EdgeInsets.fromLTRB(8, 8, 8, 88);
                  final rows = <Widget>[
                    for (final entry in entries)
                      _TreeItem(
                        entry: entry,
                        pathLabel: _pathLabelFor(entry, entries),
                        controller: controller,
                        infoOpen: _infoOpen(entry.node.id),
                        dragging: dragging,
                        hoverTargetId: _hoverTargetId,
                        enabled: !_moving,
                        onAddChild: widget.onAddChild,
                        onCycleExpand: () =>
                            unawaited(_cycleExpand(entry.node)),
                        onCycleStockLevel: entry.node.isStockProduct
                            ? () => unawaited(_cycleStockLevel(entry.node))
                            : null,
                        onEdit: () => unawaited(_openEdit(entry.node)),
                        onDragStarted: _onDragStarted,
                        onDragUpdate: _onDragUpdate,
                        onDragEnded: _clearDragUi,
                        onHover: (target) =>
                            _setHoverTarget(target, root: false),
                        onHoverLeave: (targetId) {
                          if (_hoverTargetId == targetId) {
                            _expandTimer?.cancel();
                            setState(() => _hoverTargetId = null);
                          }
                        },
                        onAccept: (dragged, target) =>
                            unawaited(_commitMove(dragged, target.id)),
                      ),
                  ];
                  // Larger touchSlop + scroll lock while dragging: default
                  // ScrollView competition cancels LongPressDraggable when the
                  // finger moves slightly during the hold (ADB stays perfectly still).
                  final gestureSettings = MediaQuery.gestureSettingsOf(context);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      gestureSettings: DeviceGestureSettings(
                        touchSlop: math.max(
                          _dragTouchSlop,
                          gestureSettings.touchSlop ?? kTouchSlop,
                        ),
                      ),
                    ),
                    child: KeyedSubtree(
                      key: _listKey,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: dragging != null
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        padding: padding,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight - padding.vertical,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: rows,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RootDropTarget extends StatelessWidget {
  const _RootDropTarget({
    required this.highlighted,
    required this.enabled,
    required this.onWillAccept,
    required this.onLeave,
    required this.onAccept,
  });

  final bool highlighted;
  final bool enabled;
  final bool Function() onWillAccept;
  final VoidCallback onLeave;
  final ValueChanged<InventoryNode> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<InventoryNode>(
      onWillAcceptWithDetails: enabled
          ? (details) {
              if (!details.data.type.canBeRoot) return false;
              return onWillAccept();
            }
          : null,
      onLeave: (_) => onLeave(),
      onAcceptWithDetails: enabled
          ? (details) => onAccept(details.data)
          : null,
      builder: (context, candidate, rejected) {
        final active = highlighted || candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? InventoryColors.mintSoft : InventoryColors.chipFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? InventoryColors.mintDeep : InventoryColors.outline,
              width: active ? 2 : 1,
            ),
          ),
          child: const Text(
            AppStrings.dropToRoot,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: InventoryColors.petroleumDark,
            ),
          ),
        );
      },
    );
  }
}

class _TreeItem extends StatelessWidget {
  const _TreeItem({
    required this.entry,
    required this.pathLabel,
    required this.controller,
    required this.infoOpen,
    required this.dragging,
    required this.hoverTargetId,
    required this.enabled,
    required this.onCycleExpand,
    this.onCycleStockLevel,
    required this.onEdit,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
    required this.onHover,
    required this.onHoverLeave,
    required this.onAccept,
    this.onAddChild,
  });

  final InventoryTreeEntry entry;
  final String pathLabel;
  final InventoryTreeController controller;
  final bool infoOpen;
  final InventoryNode? dragging;
  final String? hoverTargetId;
  final bool enabled;
  final VoidCallback onCycleExpand;
  final VoidCallback? onCycleStockLevel;
  final VoidCallback onEdit;
  final ValueChanged<InventoryNode> onDragStarted;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnded;
  final ValueChanged<InventoryNode> onHover;
  final ValueChanged<String> onHoverLeave;
  final void Function(InventoryNode dragged, InventoryNode target) onAccept;
  final ValueChanged<InventoryNode>? onAddChild;

  @override
  Widget build(BuildContext context) {
    final node = entry.node;
    final depth = entry.depth;
    final expanded = controller.isExpanded(node.id);
    final loading = expanded && controller.isLoadingChildren(node.id);
    final error = expanded && controller.hasChildError(node.id);
    final indent = (depth * _indentPerLevel).clamp(0.0, _maxVisualIndent);
    final childCount = controller.loadedChildCount(node.id);
    final price = inventoryListPrice(node);
    final branchTotal = node.type.canContain
        ? inventorySubtreeTotalLabel(
            controller.subtreeFinancialTotal(node.id),
          )
        : '';
    // Trailing [price] already shows the financial total — avoid a second
    // CAD string in the subtitle (UI-002 / UI-008). Keep qty when > 1.
    // Stock level lives in Zone C circle — never duplicate as subtitle.
    final String itemSubtitle;
    if (!node.type.isItem) {
      itemSubtitle = '';
    } else if (node.isStockProduct) {
      itemSubtitle = '';
    } else if (price.isNotEmpty) {
      final quantity = node.quantity ?? 1;
      itemSubtitle = quantity > 1 ? AppStrings.quantity(quantity) : '';
    } else {
      itemSubtitle = inventoryCompactValuation(node);
    }
    final subtitle = error
        ? AppStrings.branchReadError
        : branchTotal.isNotEmpty
        ? branchTotal
        : itemSubtitle;
    final isDragSource = dragging?.id == node.id;
    final canAccept = dragging != null &&
        enabled &&
        controller.canAcceptDrop(dragged: dragging!, target: node);
    final highlighted = canAccept && hoverTargetId == node.id;

    final textScaler = MediaQuery.textScalerOf(context);
    final priceColumnWidth = textScaler.scale(_priceColumnWidth);
    // Zone C stays a fixed touch slot so missing "+" never shifts Zone B.
    const actionColumnWidth = _actionColumnWidth;

    // GestureDetector (not InkWell/IconButton) inside the draggable: competing
    // tap recognizers on chevron/+ cancelled long-press for real fingers.
    // Layout: Zone A (flex) | Zone B (fixed price) — Zone C sits outside drag.
    final dragChild = Material(
      color: highlighted ? InventoryColors.mintSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Semantics(
        expanded: node.type.canContain ? expanded : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && dragging == null ? onCycleExpand : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indent applies only to Zone A so B/C stay on a screen-wide axis.
                SizedBox(width: indent),
                SizedBox(
                  width: 28,
                  child: node.type.canContain
                      ? Icon(
                          expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          color: InventoryColors.petroleum,
                        )
                      : const SizedBox.shrink(),
                ),
                Icon(
                  inventoryNodeIcon(node.type),
                  size: 22,
                  color: InventoryColors.petroleum,
                  semanticLabel: AppStrings.labelForNodeType(node.type),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: inventoryDisplayName(node.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: InventoryColors.petroleumDark,
                              ),
                            ),
                            if (childCount != null && node.type.canContain)
                              TextSpan(
                                text:
                                    ' ${AppStrings.contentCount(childCount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: InventoryColors.mutedText,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (error)
                        const Text(
                          AppStrings.branchReadError,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        )
                      else if (subtitle.isNotEmpty && subtitle != price)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                controller.subtreeFinancialTotal(node.id)
                                    is SubtreeFinancialOverflow
                                ? Colors.redAccent
                                : InventoryColors.mutedText,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: AppStrings.branchLoading,
                      ),
                    ),
                  )
                else if (error)
                  GestureDetector(
                    onTap: () => controller.retryChildren(node.id),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.refresh, size: 22),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final feedback = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: InventoryColors.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                inventoryNodeIcon(node.type),
                color: InventoryColors.petroleum,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  inventoryDisplayName(node.name),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: InventoryColors.petroleumDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Screen-wide grid: Zone A (indented, flex) | Zone B (price) | Zone C (+).
    // Indent must not shift B/C — amounts share one X axis at every depth.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DragTarget<InventoryNode>(
          onWillAcceptWithDetails: (details) {
            if (!enabled) return false;
            final ok = controller.canAcceptDrop(
              dragged: details.data,
              target: node,
            );
            if (ok) onHover(node);
            return ok;
          },
          onMove: (details) {
            if (!enabled) return;
            if (controller.canAcceptDrop(
              dragged: details.data,
              target: node,
            )) {
              onHover(node);
            }
          },
          onLeave: (_) => onHoverLeave(node.id),
          onAcceptWithDetails: enabled
              ? (details) {
                  if (controller.canAcceptDrop(
                    dragged: details.data,
                    target: node,
                  )) {
                    onAccept(details.data, node);
                  }
                }
              : null,
          builder: (context, candidate, rejected) {
            final accepting = highlighted || candidate.isNotEmpty;
            final draggable = LongPressDraggable<InventoryNode>(
              data: node,
              delay: _longPressDelay,
              maxSimultaneousDrags: enabled ? 1 : 0,
              hapticFeedbackOnStart: true,
              rootOverlay: true,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              onDragStarted: () => onDragStarted(node),
              onDragUpdate: onDragUpdate,
              onDragEnd: (_) => onDragEnded(),
              onDraggableCanceled: (_, _) => onDragEnded(),
              feedback: feedback,
              childWhenDragging: Opacity(opacity: 0.35, child: dragChild),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: accepting
                    ? const EdgeInsets.symmetric(vertical: 2)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: accepting ? InventoryColors.mintSoft : null,
                  borderRadius: BorderRadius.circular(10),
                  border: accepting
                      ? Border.all(
                          color: InventoryColors.mintDeep,
                          width: 2,
                        )
                      : null,
                ),
                child: isDragSource
                    ? Opacity(opacity: 0.85, child: dragChild)
                    : dragChild,
              ),
            );
            // Zone C always reserved: missing "+" must not shift Zone B.
            // Keep actions outside the draggable so they never steal long-press.
            // Stock products: level circle. Containers/locations: + Ajouter.
            final showLevel =
                node.isStockProduct && onCycleStockLevel != null;
            final showAdd = !showLevel &&
                node.type.canContain &&
                onAddChild != null;
            final level = node.stockLevel ?? StockLevel.full;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: draggable),
                // Zone B — shared financial column (right-aligned, fixed width).
                SizedBox(
                  width: priceColumnWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: price.isNotEmpty
                        ? Text(
                            price,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: InventoryColors.petroleumDark,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(
                  width: actionColumnWidth,
                  child: showLevel
                      ? Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: enabled && dragging == null
                                  ? onCycleStockLevel
                                  : null,
                              customBorder: const CircleBorder(),
                              child: Ink(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: InventoryColors.mintDeep,
                                    width: 2,
                                  ),
                                  color: InventoryColors.mintSoft,
                                ),
                                child: Center(
                                  child: Text(
                                    level.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: InventoryColors.petroleumDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : showAdd
                      ? IconButton(
                          onPressed: enabled && dragging == null
                              ? () => onAddChild!(node)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: AppStrings.addInside(
                            inventoryDisplayName(node.name),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: _actionColumnWidth,
                            minHeight: 40,
                          ),
                          color: InventoryColors.mintDeep,
                        )
                      : null,
                ),
              ],
            );
          },
        ),
        if (infoOpen)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: indent + 28,
              end: actionColumnWidth + priceColumnWidth,
              bottom: 2,
            ),
            child: InventoryInlineSheet(
              node: node,
              pathLabel: pathLabel,
              onEdit: onEdit,
            ),
          ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action case final button?) ...[
              const SizedBox(height: 16),
              button,
            ],
          ],
        );
        if (constraints.maxHeight > 480) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                content,
                const SizedBox(height: 48),
              ],
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        );
      },
    );
  }
}
