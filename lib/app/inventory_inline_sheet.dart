import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_ui.dart';

/// Compact consultation sub-line under a tree row (DEV-24 / DEV-25).
///
/// Edit opens the existing creation/modification page via [onEdit].
class InventoryInlineSheet extends StatelessWidget {
  const InventoryInlineSheet({
    super.key,
    required this.node,
    required this.pathLabel,
    required this.onEdit,
  });

  final InventoryNode node;
  final String pathLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final priceOnLine = inventoryListPrice(node).isNotEmpty;
    final compact = !node.type.isItem ? '' : inventoryCompactValuation(node);
    final valuation = node.valuation;
    final quantity = node.quantity ?? 1;
    final quantityOnLine =
        valuation == null && quantity > 1 && compact.isNotEmpty;
    final sentimentalOnLine =
        valuation is SentimentalValuation && compact.isNotEmpty;

    final parts = <String>[];
    if (node.type.isItem && !quantityOnLine) {
      parts.add(AppStrings.qtyShort(quantity));
    }
    if (pathLabel.isNotEmpty && pathLabel != AppStrings.rootLocation) {
      parts.add(pathLabel);
    } else if (!node.type.isItem) {
      parts.add(AppStrings.labelForNodeType(node.type));
    }
    if (valuation is SentimentalValuation && !sentimentalOnLine) {
      parts.add(AppStrings.sentimentalRating(valuation.rating));
    }
    if (valuation is FinancialValuation &&
        !priceOnLine &&
        compact.isEmpty) {
      parts.add(
        AppStrings.cad(node.financialTotalCents ?? valuation.unitCents),
      );
    }

    final summary = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary.isEmpty
                  ? AppStrings.labelForNodeType(node.type)
                  : summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: InventoryColors.mutedText,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.edit,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: InventoryColors.petroleum,
            ),
          ),
        ],
      ),
    );
  }
}
