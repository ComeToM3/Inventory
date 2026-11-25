import 'package:drift/drift.dart';

import '../database/inventory_database.dart';
import 'backup_contract.dart';
import 'backup_media.dart';

/// Shared insert/delete helpers for candidate validation and active replacement.
abstract final class BackupDataWriter {
  static Future<void> clearBusinessData(InventoryDatabase database) async {
    await database.delete(database.nodeDocuments).go();
    await database.delete(database.stockMovements).go();
    await database.delete(database.purchaseEvents).go();
    await database.delete(database.nodeCategories).go();
    // Delete nodes child-before-parent to satisfy ON DELETE RESTRICT parents.
    final nodes = await database.select(database.nodes).get();
    final rows = [
      for (final node in nodes)
        {
          'id': node.id,
          'parent_id': node.parentId,
        },
    ];
    for (final id in parentBeforeChildOrder(rows).reversed) {
      await (database.delete(
        database.nodes,
      )..where((row) => row.id.equals(id))).go();
    }
    await database.delete(database.categories).go();
    await database.delete(database.inventories).go();
    await database.delete(database.appPreferences).go();
  }

  static Future<void> insertSnapshot(
    InventoryDatabase database,
    BackupSnapshot snapshot,
  ) async {
    final inventory = snapshot.inventory;
    await database
        .into(database.inventories)
        .insert(
          InventoriesCompanion.insert(
            id: inventory['id']! as String,
            singletonKey: Value(inventory['singleton_key']! as int),
            createdAt: inventory['created_at']! as String,
            updatedAt: inventory['updated_at']! as String,
          ),
        );

    for (final category in snapshot.categories) {
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: category['id']! as String,
              inventoryId: category['inventory_id']! as String,
              name: category['name']! as String,
              createdAt: category['created_at']! as String,
              updatedAt: category['updated_at']! as String,
            ),
          );
    }

    for (final nodeId in parentBeforeChildOrder(snapshot.nodes)) {
      final node = snapshot.nodes.firstWhere((row) => row['id'] == nodeId);
      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: node['id']! as String,
              inventoryId: node['inventory_id']! as String,
              parentId: Value(node['parent_id'] as String?),
              space: Value(_stringOr(node['space'], 'goods')),
              name: node['name']! as String,
              nodeType: node['node_type']! as String,
              quantity: Value(node['quantity'] as int?),
              description: Value(node['description'] as String?),
              condition: Value(node['condition'] as String?),
              valueMode: Value(node['value_mode'] as String?),
              financialValueCents: Value(node['financial_value_cents'] as int?),
              sentimentalValue: Value(node['sentimental_value'] as int?),
              stockUnit: Value(node['stock_unit'] as String?),
              unitCostCents: Value(node['unit_cost_cents'] as int?),
              stockReference: Value(node['stock_reference'] as int?),
              desiredQuantity: Value(node['desired_quantity'] as int?),
              targetPriceCents: Value(node['target_price_cents'] as int?),
              siblingOrder: Value((node['sibling_order'] as int?) ?? 0),
              showAdvanced: Value((node['show_advanced'] as bool?) ?? false),
              barcodeRef: Value(node['barcode_ref'] as String?),
              purchaseDate: Value(node['purchase_date'] as String?),
              purchasePriceCents: Value(node['purchase_price_cents'] as int?),
              purchasePlace: Value(node['purchase_place'] as String?),
              objective: Value(_stringOr(node['objective'], 'none')),
              photoRelPath: Value(node['photo_rel_path'] as String?),
              iconKey: Value(node['icon_key'] as String?),
              status: Value(_stringOr(node['status'], 'active')),
              withdrawalReason: Value(node['withdrawal_reason'] as String?),
              withdrawnAt: Value(node['withdrawn_at'] as String?),
              createdAt: node['created_at']! as String,
              updatedAt: node['updated_at']! as String,
            ),
          );
    }

    for (final association in snapshot.nodeCategories) {
      await database
          .into(database.nodeCategories)
          .insert(
            NodeCategoriesCompanion.insert(
              inventoryId: association['inventory_id']! as String,
              nodeId: association['node_id']! as String,
              categoryId: association['category_id']! as String,
            ),
          );
    }

    for (final row in snapshot.stockMovements) {
      await database
          .into(database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: row['id']! as String,
              inventoryId: row['inventory_id']! as String,
              nodeId: row['node_id']! as String,
              movementType: row['movement_type']! as String,
              deltaQuarters: row['delta_quarters']! as int,
              balanceAfterQuarters: row['balance_after_quarters']! as int,
              unit: row['unit']! as String,
              createdAt: row['created_at']! as String,
            ),
          );
    }

    for (final row in snapshot.purchaseEvents) {
      await database
          .into(database.purchaseEvents)
          .insert(
            PurchaseEventsCompanion.insert(
              id: row['id']! as String,
              inventoryId: row['inventory_id']! as String,
              needNodeId: row['need_node_id']! as String,
              eventType: row['event_type']! as String,
              quantity: row['quantity']! as int,
              targetPriceCents: Value(row['target_price_cents'] as int?),
              paidPriceCents: Value(row['paid_price_cents'] as int?),
              destinationSpace: Value(row['destination_space'] as String?),
              destinationNodeId: Value(row['destination_node_id'] as String?),
              destinationParentId:
                  Value(row['destination_parent_id'] as String?),
              createdAt: row['created_at']! as String,
            ),
          );
    }

    for (final row in snapshot.appPreferences) {
      await database
          .into(database.appPreferences)
          .insert(
            AppPreferencesCompanion.insert(
              key: row['key']! as String,
              value: row['value']! as String,
            ),
          );
    }

    for (final row in snapshot.nodeDocuments) {
      final relPath = row['rel_path']! as String;
      BackupMedia.assertSafeRelPath(relPath);
      await database
          .into(database.nodeDocuments)
          .insert(
            NodeDocumentsCompanion.insert(
              id: row['id']! as String,
              inventoryId: row['inventory_id']! as String,
              nodeId: row['node_id']! as String,
              displayName: row['display_name']! as String,
              relPath: relPath,
              mimeType: row['mime_type']! as String,
              byteSize: row['byte_size']! as int,
              sortIndex: Value((row['sort_index'] as int?) ?? 0),
              createdAt: row['created_at']! as String,
            ),
          );
    }
  }

  static List<String> parentBeforeChildOrder(List<Map<String, Object?>> nodes) {
    final byId = {
      for (final node in nodes) node['id']! as String: node,
    };
    final remaining = byId.keys.toSet();
    final ordered = <String>[];
    while (remaining.isNotEmpty) {
      final ready =
          remaining.where((id) {
            final parentId = byId[id]!['parent_id'];
            return parentId == null || !remaining.contains(parentId);
          }).toList()
            ..sort();
      if (ready.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      ordered.addAll(ready);
      remaining.removeAll(ready);
    }
    return ordered;
  }

  static String _stringOr(Object? value, String fallback) =>
      value is String && value.isNotEmpty ? value : fallback;
}
