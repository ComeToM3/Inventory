import 'inventory_models.dart';

/// Well-known permanent root location ids per space (no schema migration).
///
/// One active location with [parentId] null is guaranteed per space; its id is
/// stable so ensure/reparent stays idempotent across launches and restores.
abstract final class PermanentRoots {
  static const goodsId = '00000000-0000-4000-8000-000000000010';
  static const stockId = '00000000-0000-4000-8000-000000000011';
  static const toBuyId = '00000000-0000-4000-8000-000000000012';

  /// Default display/storage name for a newly created permanent root.
  static const defaultName = 'Inventaire';

  static String idFor(InventorySpace space) => switch (space) {
    InventorySpace.goods => goodsId,
    InventorySpace.stock => stockId,
    InventorySpace.toBuy => toBuyId,
  };

  static bool isPermanentId(String id) =>
      id == goodsId || id == stockId || id == toBuyId;

  static bool isPermanentNode(InventoryNode node) =>
      isPermanentId(node.id) &&
      node.type == NodeType.location &&
      node.parentId == null;
}
