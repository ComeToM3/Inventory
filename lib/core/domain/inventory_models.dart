import 'inventory_exception.dart';
import 'stock_quantity.dart';

/// Inventory navigation space (V2). V1 data maps to [goods].
enum InventorySpace {
  goods('goods'),
  stock('stock'),
  toBuy('to_buy');

  const InventorySpace(this.storageValue);

  final String storageValue;

  static InventorySpace parse(String raw) {
    for (final value in InventorySpace.values) {
      if (value.storageValue == raw) return value;
    }
    throw const InventoryException(InventoryErrorCode.invalidStoredData);
  }
}

enum NodeType {
  location('location', canContain: true, isItem: false),
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
    required this.space,
    required this.name,
    required this.type,
    required this.condition,
    required this.quantity,
    required this.valuation,
    this.stockUnit,
    this.unitCostCents,
    this.stockReference,
    required this.status,
    required this.withdrawalReason,
    required this.withdrawnAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? parentId;
  final InventorySpace space;
  final String name;
  final NodeType type;
  final String? condition;

  /// Goods items: piece count (≥ 1). Stock products: level storage (0/1/2/4).
  final int? quantity;

  /// Goods valuation only; always null for Stock products.
  final NodeValuation? valuation;

  /// Internal Stock sentinel / legacy unit label; not shown in M2.1-C UI.
  final String? stockUnit;

  /// Legacy optional unit cost; unused in M2.1-C UI.
  final int? unitCostCents;

  /// Optional conceptual total (e.g. 10); not shown in the tree.
  final int? stockReference;
  final NodeStatus status;
  final WithdrawalReason? withdrawalReason;
  final DateTime? withdrawnAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == NodeStatus.active;

  bool get isStockProduct =>
      space == InventorySpace.stock && type == NodeType.item;

  StockLevel? get stockLevel =>
      isStockProduct && quantity != null
          ? StockLevel.fromStoredQuarters(quantity!)
          : null;

  /// Informative lot total (`quantity × unit amount`); null when the node is
  /// not financially valued as a Biens item.
  int? get financialTotalCents {
    if (space != InventorySpace.goods) return null;
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
  });

  final InventoryNode node;
  final List<InventoryNode> path;
}

class InventorySearchCriteria {
  const InventorySearchCriteria({
    this.name = '',
    this.type,
    this.branchId,
    this.space = InventorySpace.goods,
  });

  final String name;
  final NodeType? type;
  final String? branchId;
  final InventorySpace space;

  bool get isEmpty =>
      name.trim().isEmpty && type == null && branchId == null;
}

class InventorySearchResult {
  const InventorySearchResult({
    required this.nodeId,
    required this.name,
    required this.type,
    required this.quantity,
    required this.path,
    this.valuation,
  });

  final String nodeId;
  final String name;
  final NodeType type;
  final int? quantity;
  final String path;

  /// Present only for item types when a valuation is stored.
  final NodeValuation? valuation;
}

/// Cumulative financial total for a node and its active descendants.
sealed class SubtreeFinancialTotal {
  const SubtreeFinancialTotal();
}

/// At least one active financial item contributes; [cents] may be 0.
final class SubtreeFinancialAmount extends SubtreeFinancialTotal {
  const SubtreeFinancialAmount(this.cents);

  final int cents;
}

/// No active financial valuation in the subtree (empty or sentimental only).
final class SubtreeFinancialNone extends SubtreeFinancialTotal {
  const SubtreeFinancialNone();
}

/// Sum exceeded the signed 64-bit integer domain limit.
final class SubtreeFinancialOverflow extends SubtreeFinancialTotal {
  const SubtreeFinancialOverflow();
}

class InventorySearchResponse {
  const InventorySearchResponse({
    required this.results,
    required this.branchPath,
  });

  final List<InventorySearchResult> results;
  final List<InventoryNode>? branchPath;
}
