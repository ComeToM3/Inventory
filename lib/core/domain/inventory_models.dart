import 'inventory_exception.dart';

enum NodeType {
  location('location', canContain: true, isItem: false),
  container('container', canContain: true, isItem: false),
  item('item', canContain: false, isItem: true),
  itemContainer('item_container', canContain: true, isItem: true);

  const NodeType(
    this.storageValue, {
    required this.canContain,
    required this.isItem,
  });

  final String storageValue;
  final bool canContain;
  final bool isItem;

  bool get canBeRoot => this == NodeType.location;
}

enum NodeStatus {
  active('active'),
  withdrawn('withdrawn');

  const NodeStatus(this.storageValue);

  final String storageValue;
}

enum WithdrawalReason {
  loss('loss'),
  donation('donation'),
  breakage('breakage'),
  sale('sale');

  const WithdrawalReason(this.storageValue);

  final String storageValue;
}

sealed class NodeValuation {
  const NodeValuation();
}

/// Unit amount in CAD cents; the lot total is derived from the quantity.
final class FinancialValuation extends NodeValuation {
  const FinancialValuation(this.unitCents);

  final int unitCents;

  int totalForQuantity(int quantity) {
    if (unitCents != 0 && quantity > _maxInt64 ~/ unitCents) {
      throw const InventoryException(InventoryErrorCode.financialTotalOverflow);
    }
    return unitCents * quantity;
  }

  @override
  bool operator ==(Object other) =>
      other is FinancialValuation && other.unitCents == unitCents;

  @override
  int get hashCode => Object.hash(FinancialValuation, unitCents);
}

final class SentimentalValuation extends NodeValuation {
  const SentimentalValuation(this.rating);

  static const minRating = 1;
  static const maxRating = 5;

  final int rating;

  @override
  bool operator ==(Object other) =>
      other is SentimentalValuation && other.rating == rating;

  @override
  int get hashCode => Object.hash(SentimentalValuation, rating);
}

const _maxInt64 = 0x7FFFFFFFFFFFFFFF;

class InventoryNode {
  const InventoryNode({
    required this.id,
    required this.parentId,
    required this.name,
    required this.type,
    required this.description,
    required this.condition,
    required this.quantity,
    required this.valuation,
    required this.status,
    required this.withdrawalReason,
    required this.withdrawnAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? parentId;
  final String name;
  final NodeType type;
  final String? description;
  final String? condition;

  /// Present only for item types.
  final int? quantity;

  /// Present only for item types.
  final NodeValuation? valuation;
  final NodeStatus status;
  final WithdrawalReason? withdrawalReason;
  final DateTime? withdrawnAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == NodeStatus.active;

  /// Informative lot total (`quantity × unit amount`); null when the node is
  /// not financially valued.
  int? get financialTotalCents {
    final value = valuation;
    final count = quantity;
    if (value is! FinancialValuation || count == null) return null;
    return value.totalForQuantity(count);
  }
}

class InventoryNodeDetails {
  const InventoryNodeDetails({
    required this.node,
    required this.path,
    required this.categories,
  });

  final InventoryNode node;
  final List<InventoryNode> path;
  final List<InventoryCategory> categories;
}

class InventorySearchCriteria {
  const InventorySearchCriteria({
    this.name = '',
    this.type,
    this.categoryId,
    this.branchId,
  });

  final String name;
  final NodeType? type;
  final String? categoryId;
  final String? branchId;

  bool get isEmpty =>
      name.trim().isEmpty &&
      type == null &&
      categoryId == null &&
      branchId == null;
}

class InventorySearchResult {
  const InventorySearchResult({
    required this.nodeId,
    required this.name,
    required this.type,
    required this.quantity,
    required this.path,
  });

  final String nodeId;
  final String name;
  final NodeType type;
  final int? quantity;
  final String path;
}

class InventorySearchResponse {
  const InventorySearchResponse({
    required this.results,
    required this.branchPath,
  });

  final List<InventorySearchResult> results;
  final List<InventoryNode>? branchPath;
}

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}
