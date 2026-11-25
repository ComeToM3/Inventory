import 'dart:convert';

import 'backup_codec.dart';
import 'backup_contract.dart';
import 'backup_media.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _nodeTypes = {'location', 'container', 'item', 'item_container'};
const _itemTypes = {'item', 'item_container'};
const _containerTypes = {'location', 'container', 'item_container'};
const _withdrawalReasons = {'loss', 'donation', 'breakage', 'sale'};
const _spaces = {'goods', 'stock', 'to_buy'};
const _activeLike = {'active'};
const _terminalStatuses = {'withdrawn', 'acquired', 'abandoned'};

/// Parses a verified backup file into a typed snapshot and checks business rules.
abstract final class BackupPayload {
  static BackupSnapshot parseVerifiedFile(BackupFile file) {
    final decoded = jsonDecode(utf8.decode(file.jsonUtf8));
    if (decoded is! Map) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    final snapshot = fromJson(
      decoded.cast<String, Object?>(),
      dataSchemaVersion: file.header.dataSchemaVersion,
    );
    _validateMediaConsistency(snapshot, file.mediaBlobs.length);
    return snapshot;
  }

  static BackupSnapshot decodeBytes(List<int> bytes) =>
      parseVerifiedFile(BackupCodec.decodeAndVerify(bytes));

  static BackupSnapshot fromJson(
    Map<String, Object?> payload, {
    int dataSchemaVersion = backupDataSchemaVersion,
  }) {
    final inventoryRaw = payload['inventory'];
    final nodesRaw = payload['nodes'];
    final categoriesRaw = payload['categories'];
    final associationsRaw = payload['node_categories'];
    if (inventoryRaw is! Map ||
        nodesRaw is! List ||
        categoriesRaw is! List ||
        associationsRaw is! List) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }

    final inventory = _stringKeyed(inventoryRaw);
    final nodes = [
      for (final row in nodesRaw)
        if (row is Map)
          _stringKeyed(row)
        else
          throw const BackupException(BackupErrorCode.malformedPayload),
    ];
    for (final row in categoriesRaw) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
    }
    for (final row in associationsRaw) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
    }

    final stockMovements = _optionalMapList(payload['stock_movements']);
    final purchaseEvents = _optionalMapList(payload['purchase_events']);
    final appPreferences = _optionalMapList(payload['app_preferences']);
    final nodeDocuments = _optionalMapList(payload['node_documents']);
    final mediaFiles = <BackupMediaManifestEntry>[];
    final mediaRaw = payload['media_files'];
    if (mediaRaw is List) {
      for (final row in mediaRaw) {
        if (row is! Map) {
          throw const BackupException(BackupErrorCode.malformedPayload);
        }
        mediaFiles.add(
          BackupMediaManifestEntry.fromJson(row.cast<String, Object?>()),
        );
      }
    } else if (dataSchemaVersion >= 3) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }

    final normalizedNodes = [
      for (final node in nodes)
        normalizeLegacyNode(Map<String, Object?>.from(node)),
    ];
    final snapshot = BackupSnapshot(
      inventory: inventory,
      nodes: normalizedNodes,
      categories: const [],
      nodeCategories: const [],
      stockMovements: stockMovements,
      purchaseEvents: purchaseEvents,
      appPreferences: appPreferences,
      nodeDocuments: nodeDocuments,
      mediaFiles: mediaFiles,
    );
    validateBusinessRules(snapshot, requireMedia: true);
    return snapshot;
  }

  /// Maps legacy Contenant rows, clears abandoned fields, and ensures `space`.
  /// V1 backups (no `space`) and blank values become `goods`.
  static Map<String, Object?> normalizeLegacyNode(Map<String, Object?> node) {
    final type = node['node_type'];
    node['description'] = null;
    if (type == 'container') {
      node['node_type'] = 'item_container';
      node['quantity'] = 1;
      node['value_mode'] = null;
      node['financial_value_cents'] = null;
      node['sentimental_value'] = null;
    } else if (type == 'item' || type == 'item_container') {
      if (node['value_mode'] == 'financial' &&
          node['financial_value_cents'] == 0) {
        node['value_mode'] = null;
        node['financial_value_cents'] = null;
        node['sentimental_value'] = null;
      }
    }
    final space = node['space'];
    if (space == null || (space is String && space.isEmpty)) {
      node['space'] = 'goods';
    }
    node.putIfAbsent('stock_unit', () => null);
    node.putIfAbsent('unit_cost_cents', () => null);
    node.putIfAbsent('stock_reference', () => null);
    node.putIfAbsent('desired_quantity', () => null);
    node.putIfAbsent('target_price_cents', () => null);
    node.putIfAbsent('sibling_order', () => 0);
    node.putIfAbsent('show_advanced', () => false);
    node.putIfAbsent('barcode_ref', () => null);
    node.putIfAbsent('purchase_date', () => null);
    node.putIfAbsent('purchase_price_cents', () => null);
    node.putIfAbsent('purchase_place', () => null);
    node.putIfAbsent('objective', () => 'none');
    node.putIfAbsent('photo_rel_path', () => null);
    node.putIfAbsent('icon_key', () => null);
    return node;
  }

  static void validateBusinessRules(
    BackupSnapshot snapshot, {
    bool requireMedia = false,
  }) {
    final inventory = snapshot.inventory;
    final inventoryId = inventory['id'];
    final singleton = inventory['singleton_key'];
    _requireUuid(inventoryId);
    if (singleton != 1) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
    _requireNonEmptyString(inventory['created_at']);
    _requireNonEmptyString(inventory['updated_at']);

    final nodeIds = <String>{};
    final nodesById = <String, Map<String, Object?>>{};
    for (final node in snapshot.nodes) {
      final id = node['id'];
      _requireUuid(id);
      if (id is! String || !nodeIds.add(id)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (node['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      nodesById[id] = node;
      _validateNode(node);
    }

    for (final row in snapshot.stockMovements) {
      _requireUuid(row['id']);
      if (row['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final nodeId = row['node_id'];
      if (nodeId is! String || !nodeIds.contains(nodeId)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      _requireNonEmptyString(row['movement_type']);
      _requireNonEmptyString(row['unit']);
      _requireNonEmptyString(row['created_at']);
      if (row['delta_quarters'] is! int ||
          row['balance_after_quarters'] is! int) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    for (final row in snapshot.purchaseEvents) {
      _requireUuid(row['id']);
      if (row['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final needId = row['need_node_id'];
      if (needId is! String || !nodeIds.contains(needId)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      _requireNonEmptyString(row['event_type']);
      _requireNonEmptyString(row['created_at']);
      if (row['quantity'] is! int) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    for (final row in snapshot.appPreferences) {
      _requireNonEmptyString(row['key']);
      if (row['value'] is! String) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    final documentPaths = <String>{};
    for (final row in snapshot.nodeDocuments) {
      _requireUuid(row['id']);
      if (row['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final nodeId = row['node_id'];
      if (nodeId is! String || !nodeIds.contains(nodeId)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      _requireNonEmptyString(row['display_name']);
      _requireNonEmptyString(row['mime_type']);
      _requireNonEmptyString(row['created_at']);
      final relPath = row['rel_path'];
      if (relPath is! String || !BackupMedia.isSafeRelPath(relPath)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (row['byte_size'] is! int || (row['byte_size'] as int) <= 0) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      documentPaths.add(relPath);
    }

    final mediaPaths = <String>{};
    for (final entry in snapshot.mediaFiles) {
      BackupMedia.assertSafeRelPath(entry.relPath);
      if (entry.byteSize <= 0 || !_isHexSha256(entry.sha256)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (!mediaPaths.add(entry.relPath)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    for (final node in snapshot.nodes) {
      final photo = node['photo_rel_path'];
      if (photo != null) {
        if (photo is! String || !BackupMedia.isSafeRelPath(photo)) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        if (requireMedia && !mediaPaths.contains(photo)) {
          throw const BackupException(BackupErrorCode.mediaMissing);
        }
      }
    }
    for (final path in documentPaths) {
      if (requireMedia && !mediaPaths.contains(path)) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
    }
    if (requireMedia) {
      for (final path in mediaPaths) {
        final referenced = documentPaths.contains(path) ||
            snapshot.nodes.any((node) => node['photo_rel_path'] == path);
        if (!referenced) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
      }
    }

    for (final node in snapshot.nodes) {
      final parentId = node['parent_id'];
      final status = node['status'];
      if (_terminalStatuses.contains(status)) {
        if (parentId != null) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        continue;
      }
      if (parentId == null) {
        if (node['node_type'] != 'location') {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        continue;
      }
      if (parentId is! String ||
          parentId == node['id'] ||
          !nodesById.containsKey(parentId)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final parent = nodesById[parentId]!;
      if (!_activeLike.contains(parent['status']) ||
          !_containerTypes.contains(parent['node_type'])) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (parent['space'] != node['space']) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    for (final node in snapshot.nodes) {
      if (!_activeLike.contains(node['status'])) continue;
      final seen = <String>{};
      var current = node['id'] as String;
      while (true) {
        if (!seen.add(current)) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        final parentId = nodesById[current]?['parent_id'];
        if (parentId == null) break;
        if (parentId is! String || !nodesById.containsKey(parentId)) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        current = parentId;
      }
      final root = nodesById[current]!;
      if (root['parent_id'] != null || root['node_type'] != 'location') {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }
  }

  static BackupRestoreSummary summaryFor(
    BackupFile file,
    BackupSnapshot snapshot,
  ) {
    final withdrawn = snapshot.nodes
        .where((node) => node['status'] == 'withdrawn')
        .length;
    return BackupRestoreSummary(
      createdAtUtc: file.header.createdAtUtc,
      nodeCount: snapshot.nodes.length,
      withdrawnCount: withdrawn,
    );
  }

  static void _validateMediaConsistency(
    BackupSnapshot snapshot,
    int mediaBlobCount,
  ) {
    if (snapshot.mediaFiles.length != mediaBlobCount) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }
  }

  static void _validateNode(Map<String, Object?> node) {
    final type = node['node_type'];
    final status = node['status'];
    final name = node['name'];
    final space = node['space'];
    if (type is! String || !_nodeTypes.contains(type)) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
    if (status is! String ||
        (status != 'active' &&
            status != 'withdrawn' &&
            status != 'acquired' &&
            status != 'abandoned')) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
    if (space is! String || !_spaces.contains(space)) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
    _requireNonEmptyString(name);
    _requireNonEmptyString(node['created_at']);
    _requireNonEmptyString(node['updated_at']);
    _optionalString(node['description']);
    _optionalString(node['condition']);
    _optionalString(node['stock_unit']);
    _optionalString(node['barcode_ref']);
    _optionalString(node['purchase_date']);
    _optionalString(node['purchase_place']);
    _optionalString(node['objective']);
    _optionalString(node['photo_rel_path']);
    _optionalString(node['icon_key']);

    final isItem = _itemTypes.contains(type);
    final quantity = node['quantity'];
    final valueMode = node['value_mode'];
    final financial = node['financial_value_cents'];
    final sentimental = node['sentimental_value'];
    final reason = node['withdrawal_reason'];
    final withdrawnAt = node['withdrawn_at'];

    if (space == 'goods') {
      if (!isItem) {
        if (quantity != null ||
            valueMode != null ||
            financial != null ||
            sentimental != null) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
      } else {
        if (quantity is! int || quantity < 1) {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
        if (valueMode == null) {
          if (financial != null || sentimental != null) {
            throw const BackupException(BackupErrorCode.invalidBusinessData);
          }
        } else if (valueMode == 'financial') {
          if (financial is! int || financial < 0 || sentimental != null) {
            throw const BackupException(BackupErrorCode.invalidBusinessData);
          }
        } else if (valueMode == 'sentimental') {
          if (sentimental is! int ||
              sentimental < 1 ||
              sentimental > 5 ||
              financial != null) {
            throw const BackupException(BackupErrorCode.invalidBusinessData);
          }
        } else {
          throw const BackupException(BackupErrorCode.invalidBusinessData);
        }
      }
    }

    if (status == 'active') {
      if (reason != null || withdrawnAt != null) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    } else if (status == 'withdrawn') {
      if (!isItem ||
          space != 'goods' ||
          reason is! String ||
          !_withdrawalReasons.contains(reason) ||
          withdrawnAt is! String ||
          withdrawnAt.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    } else if (status == 'acquired' || status == 'abandoned') {
      if (!isItem || space != 'to_buy' || reason != null || withdrawnAt != null) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }
  }

  static List<Map<String, Object?>> _optionalMapList(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    return [
      for (final row in raw)
        if (row is Map)
          _stringKeyed(row)
        else
          throw const BackupException(BackupErrorCode.malformedPayload),
    ];
  }

  static Map<String, Object?> _stringKeyed(Map<dynamic, dynamic> raw) =>
      raw.map((key, value) => MapEntry(key.toString(), value));

  static void _requireUuid(Object? value) {
    if (value is! String || !_uuidPattern.hasMatch(value)) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
  }

  static void _requireNonEmptyString(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
  }

  static void _optionalString(Object? value) {
    if (value != null && value is! String) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
  }

  static bool _isHexSha256(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);
}
