import 'inventory_exception.dart';

/// Visual remaining proportion for a Stock product (M2.1-C).
///
/// Stored in [nodes.quantity] as quarters of a single conceptual unit:
/// full=4, half=2, quarter=1, empty=0.
enum StockLevel {
  full(4, '1'),
  half(2, '½'),
  quarter(1, '¼'),
  empty(0, '0');

  const StockLevel(this.storageQuarters, this.label);

  final int storageQuarters;
  final String label;

  StockLevel get next => switch (this) {
    StockLevel.full => StockLevel.half,
    StockLevel.half => StockLevel.quarter,
    StockLevel.quarter => StockLevel.empty,
    StockLevel.empty => StockLevel.full,
  };

  /// Maps any legacy multi-quarter balance onto the four allowed states.
  static StockLevel fromStoredQuarters(int quarters) {
    if (quarters <= 0) return StockLevel.empty;
    if (quarters == 1) return StockLevel.quarter;
    if (quarters == 2 || quarters == 3) return StockLevel.half;
    return StockLevel.full;
  }

  static StockLevel parseLabel(String raw) {
    for (final value in StockLevel.values) {
      if (value.label == raw) return value;
    }
    throw const InventoryException(InventoryErrorCode.invalidQuantity);
  }
}

/// Sentinel persisted in [nodes.stock_unit] so existing NOT NULL CHECKs stay valid.
/// Never shown in the Stock UI.
const stockUnitSentinel = 'niveau';

enum StockMovementType {
  initial('initial'),
  supply('supply'),
  consume('consume'),
  correct('correct');

  const StockMovementType(this.storageValue);

  final String storageValue;

  static StockMovementType parse(String raw) {
    for (final value in StockMovementType.values) {
      if (value.storageValue == raw) return value;
    }
    throw const InventoryException(InventoryErrorCode.invalidStoredData);
  }
}

/// Domain ledger row for a Stock balance change (distinct from Drift row).
class StockLedgerEntry {
  const StockLedgerEntry({
    required this.id,
    required this.nodeId,
    required this.type,
    required this.deltaQuarters,
    required this.balanceAfterQuarters,
    required this.unit,
    required this.createdAt,
  });

  final String id;
  final String nodeId;
  final StockMovementType type;

  /// Signed delta in stored quarters (level change = new − old).
  final int deltaQuarters;
  final int balanceAfterQuarters;

  /// Snapshot label; for level changes stores the new level glyph.
  final String unit;
  final DateTime createdAt;

  StockLevel get levelAfter =>
      StockLevel.fromStoredQuarters(balanceAfterQuarters);

  StockLevel get levelBefore =>
      StockLevel.fromStoredQuarters(balanceAfterQuarters - deltaQuarters);
}

class StockLedgerEntryNamed {
  const StockLedgerEntryNamed({
    required this.entry,
    required this.productName,
  });

  final StockLedgerEntry entry;
  final String productName;
}
