import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/permanent_roots.dart';
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
/// Zone B — financial / heart / stock level (centered axis).
const _priceColumnWidth = 56.0;
/// Zone C — `+` add / edit pencil (centered axis, 40 dp touch).
const _actionColumnWidth = 40.0;
/// Heart glyph size in the valuation column (stroke thickened in painter).
const _heartGlyphSize = 20.0;
const _expandHoverDelay = Duration(milliseconds: 650);
const _autoScrollEdge = 56.0;
const _autoScrollStep = 28.0;
/// Shorter than DEV-26: users often start moving before 450 ms elapses.
const _longPressDelay = Duration(milliseconds: 320);
/// Lock scroll before long-press fires so finger tremor does not lose the arena.
const _scrollArmDelay = Duration(milliseconds: 180);
/// Extra tolerance so finger tremor does not cancel the long-press in a ScrollView.
const _dragTouchSlop = 56.0;

class InventoryTreeScreen extends StatefulWidget {
  const InventoryTreeScreen({
    super.key,
    required this.controller,
    this.onAddRoot,
    this.onAddChild,
    this.onEditNode,
    this.goodsController,
    this.stockController,
  });

  final InventoryTreeController controller;
  final VoidCallback? onAddRoot;
  final ValueChanged<InventoryNode>? onAddChild;
  /// When set, edit is handled by the parent (keeps bottom navigation visible).
  final ValueChanged<InventoryNode>? onEditNode;
  final InventoryTreeController? goodsController;
  final InventoryTreeController? stockController;

  @override
  State<InventoryTreeScreen> createState() => InventoryTreeScreenState();
}

class InventoryTreeScreenState extends State<InventoryTreeScreen> {
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final _contentKey = GlobalKey();
  /// Independent of children expansion (UX-ARB-02).
  final _infoOpenIds = <String>{};
  InventoryNode? _dragging;
  String? _hoverTargetId;
  OrganizeDropKind? _hoverKind;
  var _hoverRoot = false;
  var _moving = false;
  /// Pointer held long enough that scroll must yield to the upcoming drag.
  var _pressArmed = false;
  Timer? _expandTimer;
  Timer? _scrollTimer;
  Timer? _pressArmTimer;
  int _scrollDirection = 0;

  /// One-shot vertical start inset for short trees (UX-ARB-02). Never recomputed
  /// on expand/collapse — avoids bottom/center Align jumps.
  double _initialTopInset = 0;
  var _initialTopInsetLocked = false;
  var _insetMeasureScheduled = false;
  var _insetMeasureAttempts = 0;
  final _rowKeys = <String, GlobalKey>{};

  /// True while a long-press drag (or its arming) is active (blocks space swipe).
  bool get isDragging => _dragging != null || _pressArmed;

  bool _infoOpen(String id) => _infoOpenIds.contains(id);

  GlobalKey _rowKeyFor(String id) =>
      _rowKeys.putIfAbsent(id, GlobalKey.new);

  double? _rowYInList(String nodeId) {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    final rowBox =
        _rowKeys[nodeId]?.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || rowBox == null || !rowBox.hasSize) return null;
    return rowBox.localToGlobal(Offset.zero, ancestor: listBox).dy;
  }

  void _correctRowY(String nodeId, double yBefore) {
    if (!_scrollController.hasClients) return;
    final yAfter = _rowYInList(nodeId);
    if (yAfter == null) return;
    final delta = yAfter - yBefore;
    if (delta.abs() < 0.5) return;
    final pos = _scrollController.position;
    final target = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if ((target - pos.pixels).abs() < 0.5) return;
    pos.jumpTo(target);
  }

  /// Keeps the main row at the same list-local Y across expand/collapse layout.
  Future<void> _runKeepingRowY(
    String nodeId,
    Future<void> Function() action,
  ) async {
    final yBefore = _rowYInList(nodeId);
    await action();
    if (!mounted || yBefore == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _correctRowY(nodeId, yBefore);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _correctRowY(nodeId, yBefore);
  }

  void _toggleInfo(String id) {
    unawaited(
      _runKeepingRowY(id, () async {
        setState(() {
          if (_infoOpenIds.contains(id)) {
            _infoOpenIds.remove(id);
          } else {
            _infoOpenIds.add(id);
          }
        });
      }),
    );
  }

  void _scheduleInitialTopInset(double viewportHeight) {
    if (_initialTopInsetLocked || _insetMeasureScheduled) return;
    _insetMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insetMeasureScheduled = false;
      if (!mounted || _initialTopInsetLocked) return;
      _insetMeasureAttempts++;
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      final contentHeight =
          (box != null && box.hasSize) ? box.size.height : 0.0;
      // Wait until default location expand has settled and rows are laid out.
      if (!widget.controller.isInitialLocationsExpandDone ||
          contentHeight < 8) {
        if (_insetMeasureAttempts < 120) {
          _scheduleInitialTopInset(viewportHeight);
        } else {
          _initialTopInsetLocked = true;
        }
        return;
      }
      final inset = contentHeight < viewportHeight
          ? (viewportHeight - contentHeight) / 2
          : 0.0;
      setState(() {
        _initialTopInset = inset;
        _initialTopInsetLocked = true;
      });
    });
  }

  @override
  void dispose() {
    _expandTimer?.cancel();
    _scrollTimer?.cancel();
    _pressArmTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _armPressForDrag() {
    _pressArmTimer?.cancel();
    _pressArmTimer = Timer(_scrollArmDelay, () {
      if (!mounted || _dragging != null || _moving) return;
      setState(() => _pressArmed = true);
    });
  }

  void _disarmPressForDrag() {
    _pressArmTimer?.cancel();
    _pressArmTimer = null;
    if (!_pressArmed) return;
    if (!mounted) {
      _pressArmed = false;
      return;
    }
    setState(() => _pressArmed = false);
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
    setState(() => _infoOpenIds.add(nodeId));
  }

  void clearPhase(String nodeId) {
    if (!mounted) return;
    setState(() => _infoOpenIds.remove(nodeId));
  }

  /// After create/edit: close detail info on the mutated node only.
  /// Children expansion of parents is never collapsed here.
  void settleAfterMutation({String? nodeId, String? parentId}) {
    if (!mounted) return;
    if (nodeId == null) return;
    setState(() => _infoOpenIds.remove(nodeId));
  }

  void _clearDragUi() {
    _expandTimer?.cancel();
    _expandTimer = null;
    _pressArmTimer?.cancel();
    _pressArmTimer = null;
    _stopAutoScroll();
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _pressArmed = false;
      _hoverTargetId = null;
      _hoverKind = null;
      _hoverRoot = false;
    });
  }

  void _onDragStarted(InventoryNode node) {
    _pressArmTimer?.cancel();
    _pressArmTimer = null;
    setState(() {
      _dragging = node;
      _pressArmed = true;
      _hoverTargetId = null;
      _hoverKind = null;
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

  void _setHoverTarget(
    InventoryNode? target, {
    required bool root,
    OrganizeDropKind? kind,
  }) {
    final nextId = target?.id;
    if (_hoverTargetId == nextId &&
        _hoverRoot == root &&
        _hoverKind == kind) {
      if (target != null && kind == OrganizeDropKind.nest) {
        _scheduleExpand(target);
      }
      return;
    }
    _expandTimer?.cancel();
    setState(() {
      _hoverTargetId = nextId;
      _hoverKind = kind;
      _hoverRoot = root;
    });
    if (target != null && kind == OrganizeDropKind.nest) {
      _scheduleExpand(target);
    }
  }

  Future<void> _applyOrganizeDrop({
    required InventoryNode dragged,
    required InventoryNode target,
    required OrganizeDropKind kind,
  }) async {
    switch (kind) {
      case OrganizeDropKind.reorderBefore:
        await _reorderRelative(dragged, anchor: target, after: false);
      case OrganizeDropKind.reorderAfter:
        await _reorderRelative(dragged, anchor: target, after: true);
      case OrganizeDropKind.nest:
        await _commitMove(dragged, target.id);
      case OrganizeDropKind.none:
        _clearDragUi();
    }
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

  Future<void> _reorderRelative(
    InventoryNode dragged, {
    required InventoryNode anchor,
    required bool after,
  }) async {
    _clearDragUi();
    if (_moving) return;
    setState(() => _moving = true);
    try {
      if (after) {
        await widget.controller.placeSiblingAfter(
          nodeId: dragged.id,
          afterId: anchor.id,
        );
      } else {
        await widget.controller.placeSiblingBefore(
          nodeId: dragged.id,
          beforeId: anchor.id,
        );
      }
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.organizeReorderSuccess);
    } on InventoryException {
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.organizeReorderError);
    } catch (_) {
      if (!mounted) return;
      showInventoryMessage(context, AppStrings.organizeReorderError);
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Future<void> _toggleChildren(InventoryNode node) async {
    if (_moving || _dragging != null || !node.type.canContain) return;
    await _runKeepingRowY(node.id, () async {
      if (widget.controller.isExpanded(node.id)) {
        widget.controller.collapse(node);
        return;
      }
      await widget.controller.expandAndLoadChildren(node);
    });
  }

  /// Row body tap (not chevron / trailing actions).
  Future<void> _onRowTap(InventoryNode node) async {
    if (_moving || _dragging != null) return;
    // Locations / non-item containers: explore children only.
    if (node.type.canContain && !node.type.isItem) {
      await _toggleChildren(node);
      return;
    }
    // Goods / Stock / À acheter items (simple or container): toggle details.
    if (node.type.isItem) {
      _toggleInfo(node.id);
    }
  }

  Future<void> _openEdit(InventoryNode node) async {
    final external = widget.onEditNode;
    if (external != null) {
      external(node);
      return;
    }
    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => InventoryCreationScreen(
          controller: widget.controller,
          type: node.type,
          existing: node,
          goodsController: widget.goodsController,
          stockController: widget.stockController,
        ),
      ),
    );
    if (!mounted || saved == null || saved == false) return;
    if (saved == 'deleted' ||
        saved == 'withdrawn' ||
        saved == 'abandoned' ||
        saved == 'acquired') {
      clearPhase(node.id);
    } else {
      settleAfterMutation(nodeId: node.id, parentId: node.parentId);
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
                        key: _rowKeyFor(entry.node.id),
                        entry: entry,
                        pathLabel: _pathLabelFor(entry, entries),
                        controller: controller,
                        infoOpen: _infoOpen(entry.node.id),
                        dragging: dragging,
                        hoverTargetId: _hoverTargetId,
                        hoverKind: _hoverKind,
                        enabled: !_moving,
                        onAddChild: widget.onAddChild,
                        onRowTap: () => unawaited(_onRowTap(entry.node)),
                        onToggleChildren: entry.node.type.canContain
                            ? () => unawaited(_toggleChildren(entry.node))
                            : null,
                        onCycleStockLevel: entry.node.isStockProduct
                            ? () => unawaited(_cycleStockLevel(entry.node))
                            : null,
                        onEdit: () => unawaited(_openEdit(entry.node)),
                        onDragStarted: _onDragStarted,
                        onDragUpdate: _onDragUpdate,
                        onDragEnded: _clearDragUi,
                        onHover: (target, kind) => _setHoverTarget(
                          target,
                          root: false,
                          kind: kind,
                        ),
                        onHoverLeave: (targetId) {
                          if (_hoverTargetId == targetId) {
                            _expandTimer?.cancel();
                            setState(() {
                              _hoverTargetId = null;
                              _hoverKind = null;
                            });
                          }
                        },
                        onAccept: (dragged, target, kind) {
                          unawaited(
                            _applyOrganizeDrop(
                              dragged: dragged,
                              target: target,
                              kind: kind,
                            ),
                          );
                        },
                      ),
                  ];
                  // Larger touchSlop + early scroll lock while the finger is
                  // held: ScrollView otherwise wins the arena on real devices
                  // before LongPressDraggable can start (ADB stays still).
                  final gestureSettings = MediaQuery.gestureSettingsOf(context);
                  final lockScroll = dragging != null || _pressArmed;
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      gestureSettings: DeviceGestureSettings(
                        touchSlop: math.max(
                          _dragTouchSlop,
                          gestureSettings.touchSlop ?? kTouchSlop,
                        ),
                      ),
                    ),
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (_) => _armPressForDrag(),
                      onPointerUp: (_) {
                        if (_dragging == null) _disarmPressForDrag();
                      },
                      onPointerCancel: (_) {
                        if (_dragging == null) _disarmPressForDrag();
                      },
                      child: KeyedSubtree(
                        key: _listKey,
                        child: NotificationListener<UserScrollNotification>(
                          onNotification: (notification) {
                            // User scroll becomes the reference; never re-center.
                            if (!_initialTopInsetLocked) {
                              _initialTopInsetLocked = true;
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: lockScroll
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            padding: padding,
                            child: Builder(
                              builder: (context) {
                                final viewport =
                                    constraints.maxHeight - padding.vertical;
                                _scheduleInitialTopInset(viewport);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: _initialTopInset),
                                    Column(
                                      key: _contentKey,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: rows,
                                    ),
                                  ],
                                );
                              },
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

class _TreeItem extends StatefulWidget {
  const _TreeItem({
    super.key,
    required this.entry,
    required this.pathLabel,
    required this.controller,
    required this.infoOpen,
    required this.dragging,
    required this.hoverTargetId,
    required this.hoverKind,
    required this.enabled,
    required this.onRowTap,
    this.onToggleChildren,
    this.onCycleStockLevel,
    this.onEdit,
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
  final OrganizeDropKind? hoverKind;
  final bool enabled;
  final VoidCallback onRowTap;
  final VoidCallback? onToggleChildren;
  final VoidCallback? onCycleStockLevel;
  final VoidCallback? onEdit;
  final ValueChanged<InventoryNode> onDragStarted;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnded;
  final void Function(InventoryNode target, OrganizeDropKind kind) onHover;
  final ValueChanged<String> onHoverLeave;
  final void Function(
    InventoryNode dragged,
    InventoryNode target,
    OrganizeDropKind kind,
  ) onAccept;
  final ValueChanged<InventoryNode>? onAddChild;

  @override
  State<_TreeItem> createState() => _TreeItemState();
}

class _TreeItemState extends State<_TreeItem> {
  final _rowKey = GlobalKey();

  double _verticalRatio(Offset global) {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.height <= 0) return 0.5;
    final local = box.globalToLocal(global);
    return (local.dy / box.size.height).clamp(0.0, 1.0);
  }

  OrganizeDropKind _resolve(InventoryNode dragged, Offset global) =>
      widget.controller.resolveOrganizeDrop(
        dragged: dragged,
        target: widget.entry.node,
        verticalRatio: _verticalRatio(global),
      );

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final controller = widget.controller;
    final dragging = widget.dragging;
    final hoverTargetId = widget.hoverTargetId;
    final hoverKind = widget.hoverKind;
    final enabled = widget.enabled;
    final onRowTap = widget.onRowTap;
    final onToggleChildren = widget.onToggleChildren;
    final onCycleStockLevel = widget.onCycleStockLevel;
    final onEdit = widget.onEdit;
    final onDragStarted = widget.onDragStarted;
    final onDragUpdate = widget.onDragUpdate;
    final onDragEnded = widget.onDragEnded;
    final onHover = widget.onHover;
    final onHoverLeave = widget.onHoverLeave;
    final onAccept = widget.onAccept;
    final onAddChild = widget.onAddChild;
    final infoOpen = widget.infoOpen;
    final pathLabel = widget.pathLabel;
    final node = entry.node;
    final depth = entry.depth;
    final expanded = controller.isExpanded(node.id);
    final loading = expanded && controller.isLoadingChildren(node.id);
    final error = expanded && controller.hasChildError(node.id);
    final indent = (depth * _indentPerLevel).clamp(0.0, _maxVisualIndent);
    final childCount = controller.loadedChildCount(node.id);
    final price = inventoryListPrice(node);
    final sentimentalRating = node.valuation is SentimentalValuation
        ? (node.valuation! as SentimentalValuation).rating
        : null;
    final branchTotal = node.type.canContain
        ? inventorySubtreeTotalLabel(
            controller.subtreeFinancialTotal(node.id),
          )
        : '';
    // Goods / À acheter: × N on main line from stored quantity (not Stock level).
    final quantity = node.quantity ?? 1;
    final showQuantityOnLine =
        node.type.isItem && !node.isStockProduct && quantity > 1;
    // Branch financial total under containers only (not the detail sub-line).
    final subtitle = error
        ? AppStrings.branchReadError
        : branchTotal.isNotEmpty
        ? branchTotal
        : '';
    final isDragSource = dragging?.id == node.id;
    final activeKind =
        hoverTargetId == node.id ? hoverKind : null;
    final nestHighlight = activeKind == OrganizeDropKind.nest;
    final insertBefore = activeKind == OrganizeDropKind.reorderBefore;
    final insertAfter = activeKind == OrganizeDropKind.reorderAfter;

    final textScaler = MediaQuery.textScalerOf(context);
    final priceColumnWidth = textScaler.scale(_priceColumnWidth);
    const actionColumnWidth = _actionColumnWidth;

    final dragChild = Material(
      color: nestHighlight ? InventoryColors.mintSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Semantics(
        expanded: node.type.canContain ? expanded : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && dragging == null ? onRowTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: indent),
                SizedBox(
                  width: 36,
                  child: node.type.canContain
                      ? IconButton(
                          // Absorbs the tap — children only; never toggles details.
                          tooltip: expanded
                              ? AppStrings.collapseBranch
                              : AppStrings.expandBranch,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 40,
                          ),
                          onPressed: enabled &&
                                  dragging == null &&
                                  onToggleChildren != null
                              ? onToggleChildren
                              : null,
                          icon: Icon(
                            expanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            color: InventoryColors.petroleum,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Icon(
                  inventoryIconForNode(node),
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
                            if (showQuantityOnLine)
                              TextSpan(
                                text: ' ${AppStrings.quantity(quantity)}',
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
                inventoryIconForNode(node),
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
    final showLevel = node.isStockProduct && onCycleStockLevel != null;
    final showAdd = node.type.canContain && onAddChild != null;
    final level = node.stockLevel ?? StockLevel.full;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (insertBefore) _InsertIndicator(indent: indent),
        Builder(
          builder: (_) {
            final nesting = nestHighlight;
            final canDrag =
                enabled && !PermanentRoots.isPermanentId(node.id);
            final draggable = LongPressDraggable<InventoryNode>(
              data: node,
              delay: _longPressDelay,
              maxSimultaneousDrags: canDrag ? 1 : 0,
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
                padding: nesting
                    ? const EdgeInsets.symmetric(vertical: 2)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: nesting ? InventoryColors.mintSoft : null,
                  borderRadius: BorderRadius.circular(10),
                  border: nesting
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

            return DragTarget<InventoryNode>(
              onWillAcceptWithDetails: (details) {
                if (!enabled) return false;
                final kind = _resolve(details.data, details.offset);
                if (kind != OrganizeDropKind.none) onHover(node, kind);
                return kind != OrganizeDropKind.none;
              },
              onMove: (details) {
                if (!enabled) return;
                final kind = _resolve(details.data, details.offset);
                if (kind == OrganizeDropKind.none) {
                  onHoverLeave(node.id);
                  return;
                }
                onHover(node, kind);
              },
              onLeave: (_) => onHoverLeave(node.id),
              onAcceptWithDetails: enabled
                  ? (details) {
                      final kind = _resolve(details.data, details.offset);
                      if (kind != OrganizeDropKind.none) {
                        onAccept(details.data, node, kind);
                      }
                    }
                  : null,
              builder: (context, _, _) {
                return Row(
                  key: _rowKey,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: draggable),
                    SizedBox(
                      width: priceColumnWidth,
                      child: Center(
                        child: showLevel
                            ? _TrailingCircleButton(
                                onPressed: enabled && dragging == null
                                    ? onCycleStockLevel
                                    : null,
                                child: Text(
                                  level.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: InventoryColors.petroleumDark,
                                  ),
                                ),
                              )
                            : sentimentalRating != null
                            ? SentimentalHeartIndicator(
                                rating: sentimentalRating,
                                size: _heartGlyphSize,
                              )
                            : (price.isNotEmpty
                                  ? Text(
                                      price,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: InventoryColors.petroleumDark,
                                      ),
                                    )
                                  : null),
                      ),
                    ),
                    SizedBox(
                      width: actionColumnWidth,
                      child: showAdd
                          ? Center(
                              child: _TrailingCircleButton(
                                tooltip: AppStrings.addInside(
                                  inventoryDisplayName(node.name),
                                ),
                                onPressed: enabled &&
                                        dragging == null &&
                                        onAddChild != null
                                    ? () => onAddChild(node)
                                    : null,
                                child: const _TreeStrokePlusIcon(),
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              },
            );
          },
        ),
        if (insertAfter) _InsertIndicator(indent: indent),
        if (infoOpen)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: indent + 28),
                    child: InventoryInlineSheet(
                      node: node,
                      pathLabel: pathLabel,
                      onEdit: onEdit,
                      showEditButton: false,
                      loadHasDocuments: node.space == InventorySpace.goods &&
                              node.type.isItem
                          ? () => controller.nodeHasDocuments(node.id)
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: priceColumnWidth),
                SizedBox(
                  width: actionColumnWidth,
                  child: onEdit == null
                      ? null
                      : Center(
                          child: _TrailingCircleButton(
                            tooltip: AppStrings.edit,
                            onPressed: onEdit,
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: InventoryColors.petroleum,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InsertIndicator extends StatelessWidget {
  const _InsertIndicator({required this.indent});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent + 28, end: 8),
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: InventoryColors.mintDeep,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Trailing tree control (`+`, Stock level, edit) — no circle chrome.
class _TrailingCircleButton extends StatelessWidget {
  const _TrailingCircleButton({
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: _actionColumnWidth,
          height: 40,
          child: Center(child: child),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Plus mark drawn with stroke weight comparable to financial amounts / heart.
class _TreeStrokePlusIcon extends StatelessWidget {
  const _TreeStrokePlusIcon();

  static const _size = 18.0;
  static const _stroke = 2.2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _TreeStrokePlusPainter(
          color: InventoryColors.mintDeep,
          strokeWidth: _stroke,
        ),
      ),
    );
  }
}

class _TreeStrokePlusPainter extends CustomPainter {
  const _TreeStrokePlusPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.shortestSide * 0.38;
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), paint);
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), paint);
  }

  @override
  bool shouldRepaint(covariant _TreeStrokePlusPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
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
