import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_strings.dart';
import 'app_theme.dart';

enum InventoryValuationMode { none, financial, sentimental }

int? parseCadCents(String text) {
  final match = RegExp(r'^(\d+)(?:[,.](\d{1,2}))?$').firstMatch(text.trim());
  if (match == null) return null;
  final whole = BigInt.parse(match.group(1)!);
  final fractional = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * BigInt.from(100) + BigInt.parse(fractional);
  if (cents > BigInt.parse('9223372036854775807')) return null;
  return cents.toInt();
}

/// Compact `$` / heart / value row shared by creation and edit.
class InventoryValuationField extends StatelessWidget {
  const InventoryValuationField({
    super.key,
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    this.enabled = true,
    this.onChanged,
  });

  final InventoryValuationMode mode;
  final TextEditingController controller;
  final ValueChanged<InventoryValuationMode> onModeChanged;
  final bool enabled;
  final VoidCallback? onChanged;

  void _toggle(InventoryValuationMode next) {
    onModeChanged(mode == next ? InventoryValuationMode.none : next);
  }

  @override
  Widget build(BuildContext context) {
    final financial = mode == InventoryValuationMode.financial;
    final sentimental = mode == InventoryValuationMode.sentimental;
    final active = mode != InventoryValuationMode.none;
    return Row(
      children: [
        _ModeChip(
          selected: financial,
          enabled: enabled,
          tooltip: AppStrings.financialMode,
          onPressed: () => _toggle(InventoryValuationMode.financial),
          child: const Text(
            '\$',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          selected: sentimental,
          enabled: enabled,
          tooltip: AppStrings.sentimentalMode,
          onPressed: () => _toggle(InventoryValuationMode.sentimental),
          child: Icon(
            sentimental ? Icons.favorite : Icons.favorite_border,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled && active,
            keyboardType: financial
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters: sentimental
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ]
                : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              hintText: !active
                  ? AppStrings.valuationNone
                  : financial
                  ? AppStrings.financialInput
                  : AppStrings.sentimentalInput,
              isDense: true,
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.selected,
    required this.enabled,
    required this.onPressed,
    required this.child,
    required this.tooltip,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget child;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? InventoryColors.petroleum : InventoryColors.mintSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: selected ? Colors.white : InventoryColors.petroleumDark,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : InventoryColors.petroleumDark,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
