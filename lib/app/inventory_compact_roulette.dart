import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared compact tactile roulette (UX-CORR-06).
///
/// Selected value at the geometric center of the 48 dp viewport. Previous is
/// paint-masked only (no Transform). Next peeks in the lower half.
const compactRouletteHeight = 48.0;
/// Half the viewport: selected fills the middle band; next peeks below.
const compactRouletteItemExtent = 24.0;

/// Vertical wheel with native fling + snap; no keyboard, no chrome buttons.
class InventoryCompactRoulette extends StatefulWidget {
  const InventoryCompactRoulette({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelForIndex,
    required this.onSelectedIndexChanged,
    this.enabled = true,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelForIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final bool enabled;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  State<InventoryCompactRoulette> createState() =>
      _InventoryCompactRouletteState();
}

class _InventoryCompactRouletteState extends State<InventoryCompactRoulette> {
  late FixedExtentScrollController _controller;
  var _syncing = false;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _clampedIndex(widget.selectedIndex),
    );
  }

  @override
  void didUpdateWidget(covariant InventoryCompactRoulette oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _clampedIndex(widget.selectedIndex);
    if (oldWidget.itemCount != widget.itemCount) {
      final old = _controller;
      _controller = FixedExtentScrollController(initialItem: next);
      old.dispose();
      return;
    }
    if (!_controller.hasClients) return;
    if (_controller.selectedItem == next) return;
    _syncing = true;
    _controller.jumpToItem(next);
    _syncing = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _clampedIndex(int index) {
    if (widget.itemCount <= 0) return 0;
    return index.clamp(0, widget.itemCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled || count <= 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InventoryColors.outline),
              color: InventoryColors.card,
            ),
            child: SizedBox(
              height: compactRouletteHeight,
              width: double.infinity,
              child: count <= 0
                  ? const SizedBox.expand()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) {
                          // Opaque from the top of the selected row downward.
                          final selectedTop = bounds.height / 2 -
                              compactRouletteItemExtent / 2;
                          final t = bounds.height <= 0
                              ? 0.0
                              : (selectedTop / bounds.height).clamp(0.0, 1.0);
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0xFFFFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, t, t, 1.0],
                          ).createShader(bounds);
                        },
                        child: ListWheelScrollView.useDelegate(
                          controller: _controller,
                          itemExtent: compactRouletteItemExtent,
                          // Flat wheel: avoids perspective lifting the selection.
                          diameterRatio: 4.0,
                          perspective: 0.001,
                          overAndUnderCenterOpacity: 0.65,
                          clipBehavior: Clip.none,
                          physics: const FixedExtentScrollPhysics(
                            parent: BouncingScrollPhysics(
                              decelerationRate: ScrollDecelerationRate.normal,
                            ),
                          ),
                          onSelectedItemChanged: (index) {
                            if (_syncing) return;
                            widget.onSelectedIndexChanged(index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: count,
                            builder: (context, index) {
                              if (index < 0 || index >= count) {
                                return const SizedBox.shrink();
                              }
                              final selected =
                                  index == _clampedIndex(widget.selectedIndex);
                              return Align(
                                alignment: Alignment.center,
                                child: Text(
                                  widget.labelForIndex(index),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: selected ? 15 : 12,
                                    height: 1.0,
                                    color: selected
                                        ? InventoryColors.petroleumDark
                                        : InventoryColors.mutedText,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
