import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_compact_roulette.dart';
import 'inventory_ui.dart' show InventorySquareIconButton;

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

/// Formats [cents] for the financial controller / parser (`12,50` or `0`).
String formatCadControllerText(int cents) {
  if (cents == 0) return '0';
  final dollars = cents ~/ 100;
  final frac = cents % 100;
  if (frac == 0) return '$dollars,00';
  return '$dollars,${frac.toString().padLeft(2, '0')}';
}

String _formatCadDisplay(int cents) {
  if (cents % 100 == 0) return AppStrings.listPrice(cents);
  final dollars = cents ~/ 100;
  final frac = (cents % 100).toString().padLeft(2, '0');
  return '$dollars,$frac \$';
}

/// Biens control reference height (chips, hearts, roulette, aligned neighbors).
const valuationControlHeight = compactRouletteHeight;

/// Financial step: 5 $ = 500 cents.
const financialStepCents = 500;

/// Technical scroll range: 0 $ … 100 000 $ by 5 $ (builder, not prebuilt list).
const financialMaxStepIndex = 20000;

/// Compact `$` / heart / tactile value row shared by creation and edit.
class InventoryValuationField extends StatefulWidget {
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

  @override
  State<InventoryValuationField> createState() =>
      _InventoryValuationFieldState();
}

class _InventoryValuationFieldState extends State<InventoryValuationField> {
  void _toggle(InventoryValuationMode next) {
    widget.onModeChanged(
      widget.mode == next ? InventoryValuationMode.none : next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final financial = widget.mode == InventoryValuationMode.financial;
    final sentimental = widget.mode == InventoryValuationMode.sentimental;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InventorySquareIconButton(
          selected: financial,
          tooltip: AppStrings.financialMode,
          onPressed: widget.enabled
              ? () => _toggle(InventoryValuationMode.financial)
              : null,
          child: const Text('\$'),
        ),
        const SizedBox(width: 8),
        InventorySquareIconButton(
          selected: sentimental,
          tooltip: AppStrings.sentimentalMode,
          onPressed: widget.enabled
              ? () => _toggle(InventoryValuationMode.sentimental)
              : null,
          child: Icon(
            sentimental ? Icons.favorite : Icons.favorite_border,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: valuationControlHeight,
            child: switch (widget.mode) {
              InventoryValuationMode.financial => _FinancialRoulette(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                ),
              InventoryValuationMode.sentimental => _SentimentalHearts(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                ),
              InventoryValuationMode.none => const _ValuationPlaceholder(
                  label: AppStrings.valuationNone,
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _ValuationPlaceholder extends StatelessWidget {
  const _ValuationPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InventoryColors.outline),
        color: InventoryColors.card,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InventoryColors.mutedText,
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialRoulette extends StatefulWidget {
  const _FinancialRoulette({
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  State<_FinancialRoulette> createState() => _FinancialRouletteState();
}

class _FinancialRouletteState extends State<_FinancialRoulette> {
  /// Non-multiple of 5 $ kept until the user scrolls to a step value.
  int? _offStepCents;
  var _cents = 0;

  @override
  void initState() {
    super.initState();
    _ingest(_readCents());
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant _FinancialRoulette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _ingest(_readCents());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  int _readCents() {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return 0;
    return parseCadCents(raw) ?? 0;
  }

  void _ingest(int cents) {
    _cents = cents;
    _offStepCents =
        cents % financialStepCents == 0 ? null : cents;
  }

  void _syncFromController() {
    final next = _readCents();
    if (next == _cents) return;
    setState(() => _ingest(next));
  }

  void _commitCents(int cents) {
    final clamped = cents.clamp(0, financialMaxStepIndex * financialStepCents);
    if (clamped == _cents) return;
    setState(() {
      _cents = clamped;
      _offStepCents =
          clamped % financialStepCents == 0 ? null : clamped;
    });
    final text = formatCadControllerText(clamped);
    if (widget.controller.text != text) {
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    widget.onChanged?.call();
  }

  /// Wheel indices: step amounts, with optional inserted off-step value.
  int get _itemCount =>
      financialMaxStepIndex + 1 + (_offStepCents != null ? 1 : 0);

  int _centsAt(int index) {
    final extra = _offStepCents;
    if (extra == null) return index * financialStepCents;
    final floorIdx = extra ~/ financialStepCents;
    if (index <= floorIdx) return index * financialStepCents;
    if (index == floorIdx + 1) return extra;
    return (index - 1) * financialStepCents;
  }

  int _indexForCents(int cents) {
    final extra = _offStepCents;
    if (extra == null) {
      return (cents ~/ financialStepCents).clamp(0, financialMaxStepIndex);
    }
    final floorIdx = extra ~/ financialStepCents;
    if (cents == extra) return floorIdx + 1;
    if (cents < extra) {
      return (cents ~/ financialStepCents).clamp(0, floorIdx);
    }
    return (cents ~/ financialStepCents) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return InventoryCompactRoulette(
      itemCount: _itemCount,
      selectedIndex: _indexForCents(_cents),
      enabled: widget.enabled,
      semanticsLabel: AppStrings.financialMode,
      semanticsValue: _formatCadDisplay(_cents),
      labelForIndex: (index) => _formatCadDisplay(_centsAt(index)),
      onSelectedIndexChanged: (index) => _commitCents(_centsAt(index)),
    );
  }
}

class _SentimentalHearts extends StatefulWidget {
  const _SentimentalHearts({
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  State<_SentimentalHearts> createState() => _SentimentalHeartsState();
}

class _SentimentalHeartsState extends State<_SentimentalHearts> {
  int? _rating;

  @override
  void initState() {
    super.initState();
    _rating = _readRating();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant _SentimentalHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _rating = _readRating();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  int? _readRating() {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return null;
    final value = int.tryParse(raw);
    if (value == null ||
        value < SentimentalValuation.minRating ||
        value > SentimentalValuation.maxRating) {
      return null;
    }
    return value;
  }

  void _syncFromController() {
    final next = _readRating();
    if (next == _rating) return;
    setState(() => _rating = next);
  }

  void _select(int rating) {
    if (!widget.enabled) return;
    setState(() => _rating = rating);
    final text = '$rating';
    if (widget.controller.text != text) {
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _rating;
    return Semantics(
      label: AppStrings.sentimentalMode,
      value: selected == null
          ? AppStrings.valuationNone
          : AppStrings.sentimentalRating(selected),
      child: SizedBox(
        height: valuationControlHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InventoryColors.outline),
            color: InventoryColors.card,
          ),
          child: Row(
            children: [
              for (var rating = SentimentalValuation.minRating;
                  rating <= SentimentalValuation.maxRating;
                  rating++)
                Expanded(
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      height: valuationControlHeight,
                    ),
                    tooltip: AppStrings.sentimentalRating(rating),
                    onPressed: widget.enabled ? () => _select(rating) : null,
                    icon: Icon(
                      selected != null && rating <= selected
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 22,
                      color: widget.enabled
                          ? InventoryColors.mintDeep
                          : InventoryColors.mutedText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

