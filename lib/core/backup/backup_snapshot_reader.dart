import 'package:drift/drift.dart';

import '../database/inventory_database.dart';
import 'backup_contract.dart';

/// Reads a transactionally consistent business snapshot for export.
class BackupSnapshotReader {
  BackupSnapshotReader(this._db);

  final InventoryDatabase _db;

  Future<BackupSnapshot> read() async {
    try {
      return await _db.transaction(() async {
        final inventory = await _db.select(_db.inventories).getSingleOrNull();
        if (inventory == null) {
          throw const BackupException(BackupErrorCode.snapshotFailed);
        }

        final nodes = await (_db.select(
          _db.nodes,
        )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
        final categories = await (_db.select(
          _db.categories,
        )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
        final associations =
            await (_db.select(_db.nodeCategories)..orderBy([
                  (row) => OrderingTerm.asc(row.nodeId),
                  (row) => OrderingTerm.asc(row.categoryId),
                ]))
                .get();

        if (nodes.length > backupMaxNodes) {
          throw const BackupException(BackupErrorCode.limitExceeded);
        }

        return BackupSnapshot(
          inventory: {
            'id': inventory.id,
            'singleton_key': inventory.singletonKey,
            'created_at': inventory.createdAt,
            'updated_at': inventory.updatedAt,
          },
          nodes: [
            for (final node in nodes)
              {
                'id': node.id,
                'inventory_id': node.inventoryId,
                'parent_id': node.parentId,
                'space': node.space,
                'name': node.name,
                'node_type': node.nodeType,
                'quantity': node.quantity,
                'description': node.description,
                'condition': node.condition,
                'value_mode': node.valueMode,
                'financial_value_cents': node.financialValueCents,
                'sentimental_value': node.sentimentalValue,
                'status': node.status,
                'withdrawal_reason': node.withdrawalReason,
                'withdrawn_at': node.withdrawnAt,
                'created_at': node.createdAt,
                'updated_at': node.updatedAt,
              },
          ],
          categories: [
            for (final category in categories)
              {
                'id': category.id,
                'inventory_id': category.inventoryId,
                'name': category.name,
                'created_at': category.createdAt,
                'updated_at': category.updatedAt,
              },
          ],
          nodeCategories: [
            for (final association in associations)
              {
                'inventory_id': association.inventoryId,
                'node_id': association.nodeId,
                'category_id': association.categoryId,
              },
          ],
        );
      });
    } on BackupException {
      rethrow;
    } on Exception {
      throw const BackupException(BackupErrorCode.snapshotFailed);
    }
  }
}
