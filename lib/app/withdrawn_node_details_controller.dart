import 'package:flutter/foundation.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

class WithdrawnNodeDetailsController extends ChangeNotifier {
  WithdrawnNodeDetailsController(this._inventory, this.nodeId);

  final InventoryTreeController _inventory;
  final String nodeId;
  InventoryNode? _node;
  bool _loading = false;
  bool _disposed = false;
  String? _readError;

  InventoryNode? get node => _node;
  bool get loading => _loading;
  String? get readError => _readError;

  Future<void> load() async {
    if (_disposed || _loading) return;
    _loading = true;
    _readError = null;
    notifyListeners();
    try {
      final node = await _inventory.readWithdrawnNodeDetails(nodeId);
      if (!_disposed) _node = node;
    } on InventoryException catch (error) {
      if (!_disposed) {
        _readError = switch (error.code) {
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.historyUnavailable,
          _ => AppStrings.historyDetailsReadError,
        };
      }
    } on Exception {
      if (!_disposed) _readError = AppStrings.historyDetailsReadError;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  String? valuationText() {
    final node = _node;
    if (node == null) return null;
    final valuation = node.valuation;
    if (valuation is SentimentalValuation) {
      return '${AppStrings.sentimentalValue} : '
          '${AppStrings.sentimentalRating(valuation.rating)}';
    }
    if (valuation is! FinancialValuation) return null;
    final unit =
        '${AppStrings.financialUnitValue} : '
        '${AppStrings.cad(valuation.unitCents)}';
    final quantity = node.quantity;
    if (quantity != null && quantity > 1) {
      try {
        final total = valuation.totalForQuantity(quantity);
        return '$unit\n${AppStrings.financialTotalValue} : '
            '${AppStrings.cad(total)}';
      } on InventoryException {
        return '$unit\n${AppStrings.financialTotalOverflow}';
      }
    }
    return unit;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
