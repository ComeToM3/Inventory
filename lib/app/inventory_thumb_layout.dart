import 'package:flutter/material.dart';

/// Thumb-friendly body: fields sit low when space allows; footer stays docked.
///
/// Important: the field subtree keeps a stable structure when the IME opens
/// (always [Align], sticky footer outside the scroll view) so text focus is
/// not dismissed by a layout swap.
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

  @override
  Widget build(BuildContext context) {
    // Scaffold already resizes for the IME — do not add viewInsets again.
    // Keep a fixed Align.bottomCenter so focus is not lost when the IME opens.
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
              return SingleChildScrollView(
                padding: padding,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - padding.vertical,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: fields,
                  ),
                ),
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
