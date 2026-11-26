import 'inventory_exception.dart';
import 'inventory_models.dart';

enum PurchaseEventType {
  acquire('acquire'),
  abandon('abandon');

  const PurchaseEventType(this.storageValue);

  final String storageValue;

  static PurchaseEventType parse(String raw) {
    for (final value in PurchaseEventType.values) {
      if (value.storageValue == raw) return value;
    }
    throw const InventoryException(InventoryErrorCode.invalidStoredData);
  }
}

/// How an acquisition lands in Stock (M2.1-C / D03).
enum StockAcquireMode {
  /// Create a new Stock product at level 1.
  createNew,

  /// Link to an existing product and leave its level unchanged.
  keepLevel,

  /// Link to an existing product and reset its level to 1.
  resetToFull,
}

class PurchaseLedgerEntry {
  const PurchaseLedgerEntry({
    required this.id,
    required this.needNodeId,
    required this.type,
    required this.quantity,
    required this.targetPriceCents,
    required this.paidPriceCents,
    required this.destinationSpace,
    required this.destinationNodeId,
    required this.destinationParentId,
    required this.createdAt,
  });

  final String id;
  final String needNodeId;
  final PurchaseEventType type;

  /// Acquired quantity, or remaining quantity when abandoning.
  final int quantity;
  final int? targetPriceCents;
  final int? paidPriceCents;
  final InventorySpace? destinationSpace;
  final String? destinationNodeId;
  final String? destinationParentId;
  final DateTime createdAt;
}

class PurchaseLedgerEntryNamed {
  const PurchaseLedgerEntryNamed({
    required this.entry,
    required this.needName,
  });

  final PurchaseLedgerEntry entry;
  final String needName;
}
