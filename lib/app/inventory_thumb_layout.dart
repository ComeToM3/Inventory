import 'package:flutter/material.dart';

/// Form / picker body: short content sits in the thumb-friendly mid band;
/// long content scrolls. Footer stays docked.
///
/// UX-02: vertical offset is derived from the **pre-IME** viewport height
/// (`maxHeight + viewInsets.bottom`), so opening the keyboard does not flip
/// or re-centre the field block (keeps UX-01-C stability).
class InventoryThumbBody extends StatelessWidget {
  const InventoryThumbBody({
    super.key,
    required this.children,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });

  final List<Widget> children;
  final Widget? footer;
  final EdgeInsets padding;

  /// Fraction of the stable (keyboard-closed) body height left empty above
  /// short content — places selectors near the middle, reachable by thumb.
  static const _topBandFraction = 0.30;

  @override
  Widget build(BuildContext context) {
    final imeBottom = MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fields = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children,
              );
              // Reconstruct the closed-keyboard body height so top spacing
              // stays constant when the IME resizes the scaffold.
              final stableHeight = constraints.maxHeight + imeBottom;
              final topGap = (stableHeight * _topBandFraction)
                  .clamp(0.0, constraints.maxHeight * 0.45);
              return SingleChildScrollView(
                padding: padding.copyWith(top: padding.top + topGap),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: fields,
              );
            },
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              0,
              padding.right,
              padding.bottom + 8,
            ),
            child: footer,
          ),
      ],
    );
  }
}
