import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import '../core/domain/inventory_name.dart';
import '../core/domain/stock_quantity.dart';
import 'app_strings.dart';
import 'app_theme.dart';

/// Presentation-only name (sentence first letter); storage stays unchanged.
String inventoryDisplayName(String name) => InventoryName.display(name);

IconData inventoryNodeIcon(NodeType type) => switch (type) {
  NodeType.location => Icons.apartment_outlined,
  NodeType.item => Icons.view_in_ar_outlined,
  NodeType.itemContainer => Icons.luggage_outlined,
};

/// Own financial total for list trailing; empty when unset.
String inventoryListPrice(InventoryNode node) {
  if (node.isStockProduct) return '';
  final total = node.financialTotalCents;
  if (total == null) return '';
  return AppStrings.listPrice(total);
}

String inventoryCompactValuation(InventoryNode node) {
  if (node.isStockProduct) {
    return node.stockLevel?.label ?? '';
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

class InventoryValuationBanner extends StatelessWidget {
  const InventoryValuationBanner({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: InventoryColors.mintSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.attach_money,
            color: InventoryColors.petroleum,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: InventoryColors.petroleumDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      children: [
        _StepButton(
          icon: Icons.remove,
          tooltip: AppStrings.decreaseQuantity,
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: AppStrings.increaseQuantity,
          onPressed: enabled ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InventoryColors.mintSoft,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: InventoryColors.petroleum),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class InventoryTypeChoiceCard extends StatelessWidget {
  const InventoryTypeChoiceCard({
    super.key,
    required this.type,
    required this.onTap,
    this.labelOverride,
  });

  final NodeType type;
  final VoidCallback onTap;
  final String? labelOverride;

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
                      AppStrings.exampleForNodeType(type),
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
