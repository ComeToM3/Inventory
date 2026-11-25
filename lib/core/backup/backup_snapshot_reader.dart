import 'dart:io';

import 'package:drift/drift.dart';

import '../database/inventory_database.dart';
import 'backup_contract.dart';
import 'backup_media.dart';

/// Reads a transactionally consistent business snapshot for export.
class BackupSnapshotReader {
  BackupSnapshotReader(this._db);

  final InventoryDatabase _db;

  /// Reads SQLite business data. Media bytes are resolved only via
  /// [readWithMediaFiles] (export path).
  Future<BackupSnapshot> read() async {
    final packed = await _readRows();
    return packed.snapshot;
  }

  /// Snapshot plus open media files for progressive encode.
  Future<
      ({
        BackupSnapshot snapshot,
        List<({BackupMediaManifestEntry entry, File file})> media,
      })> readWithMediaFiles() async {
    final packed = await _readRows();
    final media = await BackupMedia.collectReferenced(
      photoRelPaths: [
        for (final node in packed.snapshot.nodes)
          node['photo_rel_path'] as String?,
      ],
      documentRelPaths: [
        for (final doc in packed.snapshot.nodeDocuments)
          doc['rel_path']! as String,
      ],
    );
    final snapshot = BackupSnapshot(
      inventory: packed.snapshot.inventory,
      nodes: packed.snapshot.nodes,
      categories: packed.snapshot.categories,
      nodeCategories: packed.snapshot.nodeCategories,
      stockMovements: packed.snapshot.stockMovements,
      purchaseEvents: packed.snapshot.purchaseEvents,
      appPreferences: packed.snapshot.appPreferences,
      nodeDocuments: packed.snapshot.nodeDocuments,
      mediaFiles: [for (final item in media) item.entry],
    );
    return (snapshot: snapshot, media: media);
  }

  Future<
      ({
        BackupSnapshot snapshot,
        List<({BackupMediaManifestEntry entry, File file})> media,
      })> _readRows() async {
    try {
      final rows = await _db.transaction(() async {
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
        final stockMovements =
            await (_db.select(_db.stockMovements)..orderBy([
                  (row) => OrderingTerm.asc(row.createdAt),
                  (row) => OrderingTerm.asc(row.id),
                ]))
                .get();
        final purchaseEvents =
            await (_db.select(_db.purchaseEvents)..orderBy([
                  (row) => OrderingTerm.asc(row.createdAt),
                  (row) => OrderingTerm.asc(row.id),
                ]))
                .get();
        final preferences = await (_db.select(
          _db.appPreferences,
        )..orderBy([(row) => OrderingTerm.asc(row.key)])).get();
        final documents =
            await (_db.select(_db.nodeDocuments)..orderBy([
                  (row) => OrderingTerm.asc(row.nodeId),
                  (row) => OrderingTerm.asc(row.sortIndex),
                  (row) => OrderingTerm.asc(row.id),
                ]))
                .get();

        if (nodes.length > backupMaxNodes) {
          throw const BackupException(BackupErrorCode.limitExceeded);
        }

        return (
          inventory: inventory,
          nodes: nodes,
          categories: categories,
          associations: associations,
          stockMovements: stockMovements,
          purchaseEvents: purchaseEvents,
          preferences: preferences,
          documents: documents,
        );
      });

      final snapshot = BackupSnapshot(
        inventory: {
          'id': rows.inventory.id,
          'singleton_key': rows.inventory.singletonKey,
          'created_at': rows.inventory.createdAt,
          'updated_at': rows.inventory.updatedAt,
        },
        nodes: [
          for (final node in rows.nodes)
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
              'stock_unit': node.stockUnit,
              'unit_cost_cents': node.unitCostCents,
              'stock_reference': node.stockReference,
              'desired_quantity': node.desiredQuantity,
              'target_price_cents': node.targetPriceCents,
              'sibling_order': node.siblingOrder,
              'show_advanced': node.showAdvanced,
              'barcode_ref': node.barcodeRef,
              'purchase_date': node.purchaseDate,
              'purchase_price_cents': node.purchasePriceCents,
              'purchase_place': node.purchasePlace,
              'objective': node.objective,
              'photo_rel_path': node.photoRelPath,
              'icon_key': node.iconKey,
              'status': node.status,
              'withdrawal_reason': node.withdrawalReason,
              'withdrawn_at': node.withdrawnAt,
              'created_at': node.createdAt,
              'updated_at': node.updatedAt,
            },
        ],
        categories: [
          for (final category in rows.categories)
            {
              'id': category.id,
              'inventory_id': category.inventoryId,
              'name': category.name,
              'created_at': category.createdAt,
              'updated_at': category.updatedAt,
            },
        ],
        nodeCategories: [
          for (final association in rows.associations)
            {
              'inventory_id': association.inventoryId,
              'node_id': association.nodeId,
              'category_id': association.categoryId,
            },
        ],
        stockMovements: [
          for (final row in rows.stockMovements)
            {
              'id': row.id,
              'inventory_id': row.inventoryId,
              'node_id': row.nodeId,
              'movement_type': row.movementType,
              'delta_quarters': row.deltaQuarters,
              'balance_after_quarters': row.balanceAfterQuarters,
              'unit': row.unit,
              'created_at': row.createdAt,
            },
        ],
        purchaseEvents: [
          for (final row in rows.purchaseEvents)
            {
              'id': row.id,
              'inventory_id': row.inventoryId,
              'need_node_id': row.needNodeId,
              'event_type': row.eventType,
              'quantity': row.quantity,
              'target_price_cents': row.targetPriceCents,
              'paid_price_cents': row.paidPriceCents,
              'destination_space': row.destinationSpace,
              'destination_node_id': row.destinationNodeId,
              'destination_parent_id': row.destinationParentId,
              'created_at': row.createdAt,
            },
        ],
        appPreferences: [
          for (final row in rows.preferences)
            {
              'key': row.key,
              'value': row.value,
            },
        ],
        nodeDocuments: [
          for (final row in rows.documents)
            {
              'id': row.id,
              'inventory_id': row.inventoryId,
              'node_id': row.nodeId,
              'display_name': row.displayName,
              'rel_path': row.relPath,
              'mime_type': row.mimeType,
              'byte_size': row.byteSize,
              'sort_index': row.sortIndex,
              'created_at': row.createdAt,
            },
        ],
        mediaFiles: const [],
      );
      return (
        snapshot: snapshot,
        media: <({BackupMediaManifestEntry entry, File file})>[],
      );
    } on BackupException {
      rethrow;
    } on Exception {
      throw const BackupException(BackupErrorCode.snapshotFailed);
    }
  }
}
