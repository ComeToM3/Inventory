import 'package:flutter/foundation.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

typedef QuantityFeedback = ({int? value, int? totalCents, String? error});
typedef FinancialFeedback = ({int? cents, String? error});

class NodeDetailsController extends ChangeNotifier {
  NodeDetailsController(this._inventory, this.nodeId);

  final InventoryTreeController _inventory;
  final String nodeId;
  InventoryNodeDetails? _details;
  bool _loading = false;
  bool _disposed = false;
  String? _readError;
  Future<void>? _saveRequest;

  InventoryNodeDetails? get details => _details;
  bool get loading => _loading;
  bool get saving => _saveRequest != null;
  String? get readError => _readError;

  Future<void> load() async {
    if (_disposed || _loading || saving) return;
    _loading = true;
    _readError = null;
    notifyListeners();
    try {
      final details = await _inventory.readNodeDetails(nodeId);
      if (!_disposed) _details = details;
    } on InventoryException catch (error) {
      if (!_disposed) {
        _readError = switch (error.code) {
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
          _ => AppStrings.detailsReadError,
        };
      }
    } on Exception {
      if (!_disposed) _readError = AppStrings.detailsReadError;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<InventoryCategory>> readCategories() =>
      _inventory.readCategories();

  FinancialFeedback financialFeedback(String text) {
    final match = RegExp(r'^(\d+)(?:[,.](\d{1,2}))?$').firstMatch(text.trim());
    if (match == null) return (cents: null, error: AppStrings.financialInvalid);
    final whole = BigInt.parse(match.group(1)!);
    final fractional = (match.group(2) ?? '').padRight(2, '0');
    final cents = whole * BigInt.from(100) + BigInt.parse(fractional);
    if (cents > BigInt.parse('9223372036854775807')) {
      return (cents: null, error: AppStrings.financialInvalid);
    }
    return (cents: cents.toInt(), error: null);
  }

  QuantityFeedback quantityFeedback(String text, {NodeValuation? valuation}) {
    final value = int.tryParse(text.trim());
    if (value == null || value < 1) {
      return (value: null, totalCents: null, error: AppStrings.quantityInvalid);
    }
    valuation ??= _details?.node.valuation;
    try {
      return (
        value: value,
        totalCents: valuation is FinancialValuation
            ? valuation.totalForQuantity(value)
            : null,
        error: null,
      );
    } on InventoryException catch (error) {
      if (error.code != InventoryErrorCode.financialTotalOverflow) rethrow;
      return (
        value: value,
        totalCents: null,
        error: AppStrings.financialTotalOverflow,
      );
    }
  }

  String? valuationText(String quantityText, {NodeValuation? valuation}) {
    valuation ??= _details?.node.valuation;
    if (valuation is SentimentalValuation) {
      return '${AppStrings.sentimentalValue} : '
          '${AppStrings.sentimentalRating(valuation.rating)}';
    }
    if (valuation is! FinancialValuation) return null;
    final feedback = quantityFeedback(quantityText, valuation: valuation);
    final unit =
        '${AppStrings.financialUnitValue} : '
        '${AppStrings.cad(valuation.unitCents)}';
    if (feedback.error == AppStrings.financialTotalOverflow) {
      return '$unit\n${AppStrings.financialTotalOverflow}';
    }
    final total = feedback.totalCents;
    if (total != null && feedback.value! > 1) {
      return '$unit\n${AppStrings.financialTotalValue} : ${AppStrings.cad(total)}';
    }
    return unit;
  }

  Future<void> save({
    required String name,
    String? description,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    Iterable<String>? categoryIds,
    Iterable<String> newCategoryNames = const [],
  }) {
    if (_disposed) throw StateError('The node controller is disposed.');
    if ((valuation == null) != (categoryIds == null) ||
        (valuation != null && quantity == null) ||
        (categoryIds == null && newCategoryNames.isNotEmpty)) {
      throw ArgumentError('Incomplete item update.');
    }
    final pending = _saveRequest;
    if (pending != null) return pending;
    final previous = _details;
    if (previous == null || _loading) {
      throw StateError('The node details have not been loaded.');
    }
    _saveRequest = _finishSave(
      _save(
        previous,
        name: name,
        description: description,
        condition: condition,
        quantity: quantity,
        valuation: valuation,
        categoryIds: categoryIds,
        newCategoryNames: newCategoryNames,
      ),
    );
    notifyListeners();
    return _saveRequest!;
  }

  Future<void> _save(
    InventoryNodeDetails previous, {
    required String name,
    String? description,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    Iterable<String>? categoryIds,
    required Iterable<String> newCategoryNames,
  }) async {
    late final InventoryNode node;
    var categories = previous.categories;
    if (valuation != null && quantity != null && categoryIds != null) {
      final result = await _inventory.updateItemDetails(
        nodeId,
        name: name,
        description: description,
        condition: condition,
        quantity: quantity,
        valuation: valuation,
        categoryIds: categoryIds,
        newCategoryNames: newCategoryNames,
      );
      node = result.node;
      categories = result.categories;
    } else {
      node = await _inventory.updateNodeDetails(
        nodeId,
        name: name,
        description: description,
        condition: condition,
        quantity: quantity,
      );
    }
    if (_disposed) return;
    final path = [...previous.path];
    path[path.length - 1] = node;
    _details = InventoryNodeDetails(
      node: node,
      path: path,
      categories: categories,
    );
    _readError = null;
  }

  Future<void> _finishSave(Future<void> request) async {
    try {
      await request;
    } finally {
      _saveRequest = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
