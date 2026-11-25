import '../domain/inventory_models.dart';

/// One dictionary association (static, local).
class InventoryIconEntry {
  const InventoryIconEntry({
    required this.iconKey,
    required this.term,
    required this.priority,
    this.preferredType,
  });

  final String iconKey;
  final String term;
  final int priority;

  /// When set, preferred for that node type (still usable elsewhere).
  final NodeType? preferredType;
}
