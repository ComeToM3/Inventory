import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import '../core/domain/inventory_name.dart';
import '../core/domain/stock_quantity.dart';
import '../core/icons/inventory_icon_catalog.dart';
import '../core/icons/inventory_icon_resolver.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_compact_roulette.dart' show compactRouletteHeight;

/// Shared square icon control (UX-CORR-06) — same chrome as valorisation `$` / heart.
class InventorySquareIconButton extends StatelessWidget {
  const InventorySquareIconButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool selected;

  static const borderRadius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: selected ? InventoryColors.petroleum : InventoryColors.mintSoft,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: SizedBox(
              width: compactRouletteHeight,
              height: compactRouletteHeight,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    size: 22,
                    color: selected
                        ? Colors.white
                        : InventoryColors.petroleumDark,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
      ),
    );
  }
}

/// Outlined action style shared by media buttons and Objectif choices.
ButtonStyle inventoryGoodsOutlinedStyle({bool selected = false}) {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return InventoryColors.card;
      }
      return selected ? InventoryColors.mintSoft : InventoryColors.card;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return InventoryColors.mutedText;
      }
      return InventoryColors.petroleumDark;
    }),
    minimumSize: const WidgetStatePropertyAll(Size(0, compactRouletteHeight)),
    maximumSize: const WidgetStatePropertyAll(
      Size(double.infinity, compactRouletteHeight),
    ),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    side: WidgetStatePropertyAll(
      BorderSide(
        color: selected ? InventoryColors.petroleum : InventoryColors.outline,
        width: selected ? 1.5 : 1,
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Presentation-only name (sentence first letter); storage stays unchanged.
String inventoryDisplayName(String name) => InventoryName.display(name);

IconData inventoryNodeIcon(NodeType type) =>
    InventoryIconCatalog.genericFor(type);

/// Resolved pictogram for a node (manual key wins, else dictionary, else type).
IconData inventoryIconForNode(InventoryNode node) =>
    InventoryIconResolver.iconForNode(node);

IconData inventoryIconForName({
  required String name,
  required NodeType type,
  String? manualKey,
}) => InventoryIconResolver.resolve(
  name: name,
  type: type,
  manualKey: manualKey,
);

/// Own financial total for list trailing; empty when unset.
/// To-buy: optional target unit price (not a goods valuation).
String inventoryListPrice(InventoryNode node) {
  if (node.isStockProduct) return '';
  if (node.isToBuyNeed) {
    final target = node.targetPriceCents;
    if (target == null) return '';
    return AppStrings.listPrice(target);
  }
  final total = node.financialTotalCents;
  if (total == null) return '';
  return AppStrings.listPrice(total);
}

String inventoryCompactValuation(InventoryNode node) {
  if (node.isStockProduct) {
    return node.stockLevel?.label ?? '';
  }
  if (node.isToBuyNeed) {
    final remaining = node.quantity ?? 0;
    return remaining > 0 ? AppStrings.quantity(remaining) : '';
  }
  final quantity = node.quantity ?? 1;
  final valuation = node.valuation;
  if (valuation is FinancialValuation) {
    return AppStrings.compactFinancial(quantity, valuation.unitCents);
  }
  if (valuation is SentimentalValuation) {
    return AppStrings.compactSentimental(quantity, valuation.rating);
  }
  if (quantity > 1) return AppStrings.quantity(quantity);
  return '';
}

String inventorySearchValuationBadgeStock({
  required int? quantityQuarters,
  required String? unit,
  required int? unitCostCents,
}) {
  final level = StockLevel.fromStoredQuarters(quantityQuarters ?? 0);
  return level.label;
}

String inventorySearchValuationBadge({
  required NodeType type,
  required int? quantity,
  required NodeValuation? valuation,
}) {
  if (!type.isItem) return '';
  final count = quantity ?? 1;
  if (valuation is FinancialValuation) {
    return AppStrings.listPrice(
      FinancialValuation(valuation.unitCents).totalForQuantity(count),
    );
  }
  if (valuation is SentimentalValuation) {
    return AppStrings.compactSentimental(count, valuation.rating);
  }
  return count > 1 ? AppStrings.quantity(count) : '';
}

String inventorySubtreeTotalLabel(SubtreeFinancialTotal? total) {
  return switch (total) {
    SubtreeFinancialAmount(:final cents) when cents > 0 =>
      AppStrings.listPrice(cents),
    SubtreeFinancialOverflow() => AppStrings.subtreeFinancialOverflowShort,
    _ => '',
  };
}

/// Sentimental rating 1–5 as a heart filled from bottom to top (UX-03).
class SentimentalHeartIndicator extends StatelessWidget {
  const SentimentalHeartIndicator({
    super.key,
    required this.rating,
    this.size = 22,
  });

  /// Stored sentimental value in `1…5`.
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(1, 5);
    return Semantics(
      label: AppStrings.sentimentalRating(clamped),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SentimentalHeartPainter(
            fillFraction: clamped / 5,
            fillColor: InventoryColors.mintDeep,
            strokeColor: InventoryColors.petroleum,
          ),
        ),
      ),
    );
  }
}

class _SentimentalHeartPainter extends CustomPainter {
  const _SentimentalHeartPainter({
    required this.fillFraction,
    required this.fillColor,
    required this.strokeColor,
  });

  final double fillFraction;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _heartPath(size);
    final fraction = fillFraction.clamp(0.0, 1.0);
    // Clip a rising band then fill the heart — readable at ~20 dp.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, size.height * (1 - fraction), size.width, size.height),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor,
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        // Match financial amount weight (~w600) via stroke, not glyph size.
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor,
    );
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.28)
      ..cubicTo(w * 0.5, h * 0.12, w * 0.28, h * 0.02, w * 0.12, h * 0.18)
      ..cubicTo(w * -0.02, h * 0.36, w * 0.08, h * 0.62, w * 0.5, h * 0.95)
      ..cubicTo(w * 0.92, h * 0.62, w * 1.02, h * 0.36, w * 0.88, h * 0.18)
      ..cubicTo(w * 0.72, h * 0.02, w * 0.5, h * 0.12, w * 0.5, h * 0.28)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SentimentalHeartPainter oldDelegate) =>
      oldDelegate.fillFraction != fillFraction ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor;
}

class InventoryQuantityStepper extends StatelessWidget {
  const InventoryQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InventorySquareIconButton(
          tooltip: AppStrings.decreaseQuantity,
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
          child: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
        InventorySquareIconButton(
          tooltip: AppStrings.increaseQuantity,
          onPressed: enabled ? () => onChanged(value + 1) : null,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Stock remaining level as − / glyph / +, stepping by one quarter.
///
/// Same square chrome as quantity; values stay in [StockLevel] quarters.
class InventoryStockLevelStepper extends StatelessWidget {
  const InventoryStockLevelStepper({
    super.key,
    required this.level,
    required this.onChanged,
    this.enabled = true,
  });

  final StockLevel level;
  final ValueChanged<StockLevel> onChanged;
  final bool enabled;

  static StockLevel? _lower(StockLevel level) => switch (level) {
    StockLevel.full => StockLevel.half,
    StockLevel.half => StockLevel.quarter,
    StockLevel.quarter => StockLevel.empty,
    StockLevel.empty => null,
  };

  static StockLevel? _higher(StockLevel level) => switch (level) {
    StockLevel.empty => StockLevel.quarter,
    StockLevel.quarter => StockLevel.half,
    StockLevel.half => StockLevel.full,
    StockLevel.full => null,
  };

  @override
  Widget build(BuildContext context) {
    final lower = _lower(level);
    final higher = _higher(level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InventorySquareIconButton(
          tooltip: AppStrings.decreaseQuantity,
          onPressed: enabled && lower != null ? () => onChanged(lower) : null,
          child: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            level.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: InventoryColors.petroleumDark,
            ),
          ),
        ),
        InventorySquareIconButton(
          tooltip: AppStrings.increaseQuantity,
          onPressed: enabled && higher != null ? () => onChanged(higher) : null,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class InventoryTypeChoiceCard extends StatelessWidget {
  const InventoryTypeChoiceCard({
    super.key,
    required this.type,
    required this.onTap,
    this.labelOverride,
    this.exampleOverride,
  });

  final NodeType type;
  final VoidCallback onTap;
  final String? labelOverride;
  final String? exampleOverride;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(
                inventoryNodeIcon(type),
                size: 32,
                color: InventoryColors.petroleum,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelOverride ?? AppStrings.labelForNodeType(type),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InventoryColors.petroleumDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exampleOverride ?? AppStrings.exampleForNodeType(type),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: InventoryColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: InventoryColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryFilterChip extends StatelessWidget {
  const InventoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: InventoryColors.mint,
      labelStyle: TextStyle(
        color: selected ? Colors.white : InventoryColors.petroleumDark,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: InventoryColors.card,
      side: BorderSide(
        color: selected ? InventoryColors.mint : InventoryColors.outline,
      ),
    );
  }
}

class InventoryResultCard extends StatelessWidget {
  const InventoryResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: InventoryColors.petroleumDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: InventoryColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                    if (badge != null && badge!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryColors.mintSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: InventoryColors.petroleumDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: InventoryColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
