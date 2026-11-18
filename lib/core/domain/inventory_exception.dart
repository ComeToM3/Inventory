enum InventoryErrorCode {
  inventoryUnavailable,
  nodeNotFound,
  parentNotFound,
  categoryNotFound,
  inventoryMismatch,
  spaceMismatch,
  emptyName,
  nameTooLong,
  parentRequired,
  parentCannotContain,
  parentInactive,
  nodeInactive,
  cycleDetected,
  invalidHierarchy,
  requiresItem,
  invalidQuantity,
  insufficientStock,
  invalidStockUnit,
  invalidFinancialValue,
  invalidSentimentalValue,
  financialTotalOverflow,
  categoryAlreadyAssigned,
  categoryNotAssigned,
  nodeHasChildren,
  invalidStoredData,
  constraintViolation,
  storageFailure,
}

/// Domain failure exposed to callers. [cause] keeps the technical error for
/// local diagnosis; [toString] deliberately omits it because it may contain
/// SQL or personal inventory data.
class InventoryException implements Exception {
  const InventoryException(this.code, {this.cause});

  final InventoryErrorCode code;
  final Object? cause;

  @override
  String toString() => 'InventoryException(${code.name})';
}
