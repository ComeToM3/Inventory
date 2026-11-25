import 'package:flutter/material.dart';

import 'app_strings.dart';

/// Collapsible advanced block for inventory fiches (M4.1-A / M4.1-B).
///
/// Renders nothing when [children] is empty so the form never shows a
/// deceptive empty panel.
class InventoryAdvancedSection extends StatelessWidget {
  const InventoryAdvancedSection({
    super.key,
    required this.expanded,
    required this.onExpansionChanged,
    required this.children,
  });

  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        AppStrings.advancedInformation,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: [
        for (final child in children) ...[
          child,
          if (child != children.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
