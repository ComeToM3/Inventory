import 'package:flutter/material.dart';

/// Shared horizontal action row for forms and detail sheets (DEV-20).
enum InventoryActionStyle { text, tonalIcon, outlined, filled, destructive }

class InventoryBarAction {
  const InventoryBarAction({
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
    this.style = InventoryActionStyle.outlined,
    this.expanded = true,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final String? tooltip;
  final InventoryActionStyle style;
  final bool expanded;
}

class InventoryActionBar extends StatelessWidget {
  const InventoryActionBar({
    super.key,
    required this.actions,
    this.errorMessage,
  });

  final List<InventoryBarAction> actions;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage case final message?) ...[
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              if (actions[i].expanded)
                Expanded(child: _buildAction(context, actions[i]))
              else
                _buildAction(context, actions[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context, InventoryBarAction action) {
    final child = switch (action.style) {
      InventoryActionStyle.text => TextButton(
        onPressed: action.onPressed,
        child: Text(action.label ?? ''),
      ),
      InventoryActionStyle.tonalIcon => IconButton.filledTonal(
        tooltip: action.tooltip ?? action.label,
        onPressed: action.onPressed,
        icon: action.onPressed == null && action.icon == Icons.add
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(action.icon ?? Icons.add),
      ),
      InventoryActionStyle.outlined => action.icon == null
          ? OutlinedButton(
              onPressed: action.onPressed,
              child: Text(action.label ?? ''),
            )
          : OutlinedButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label ?? ''),
            ),
      InventoryActionStyle.filled => action.icon == null
          ? FilledButton(
              onPressed: action.onPressed,
              child: Text(action.label ?? ''),
            )
          : FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label ?? ''),
            ),
      InventoryActionStyle.destructive => TextButton(
        onPressed: action.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(action.label ?? ''),
      ),
    };
    if (action.tooltip != null && action.style != InventoryActionStyle.tonalIcon) {
      return Tooltip(message: action.tooltip!, child: child);
    }
    return child;
  }
}
