import 'package:drift/drift.dart';

import '../database/inventory_database.dart';
import 'backup_contract.dart';

/// Shared insert/delete helpers for candidate validation and active replacement.
abstract final class BackupDataWriter {
  static Future<void> clearBusinessData(InventoryDatabase database) async {
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
              space: Value(node['space']! as String),
              name: node['name']! as String,
              nodeType: node['node_type']! as String,
              quantity: Value(node['quantity'] as int?),
              description: Value(node['description'] as String?),
              condition: Value(node['condition'] as String?),
              valueMode: Value(node['value_mode'] as String?),
              financialValueCents: Value(node['financial_value_cents'] as int?),
              sentimentalValue: Value(node['sentimental_value'] as int?),
              status: Value(node['status']! as String),
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
          }).toList()..sort();
      if (ready.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      ordered.addAll(ready);
      remaining.removeAll(ready);
    }
    return ordered;
  }
}
