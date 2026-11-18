import 'dart:convert';

import 'backup_codec.dart';
import 'backup_contract.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _nodeTypes = {'location', 'container', 'item', 'item_container'};
const _itemTypes = {'item', 'item_container'};
const _containerTypes = {'location', 'container', 'item_container'};
const _withdrawalReasons = {'loss', 'donation', 'breakage', 'sale'};
const _spaces = {'goods', 'stock', 'to_buy'};

/// Parses a verified backup file into a typed snapshot and checks business rules.
abstract final class BackupPayload {
  static BackupSnapshot parseVerifiedFile(BackupFile file) {
    final decoded = jsonDecode(utf8.decode(file.payloadUtf8));
    if (decoded is! Map) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    return fromJson(decoded.cast<String, Object?>());
  }

  static BackupSnapshot decodeBytes(List<int> bytes) =>
      parseVerifiedFile(BackupCodec.decodeAndVerify(bytes));

  static BackupSnapshot fromJson(Map<String, Object?> payload) {
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
    // Validate list shape; category data is abandoned (DEV-17).
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

    final normalizedNodes = [
      for (final node in nodes)
        normalizeLegacyNode(Map<String, Object?>.from(node)),
    ];
    // Categories are abandoned (DEV-17); keep empty lists for payload shape.
    validateBusinessRules(
      BackupSnapshot(
        inventory: inventory,
        nodes: normalizedNodes,
        categories: const [],
        nodeCategories: const [],
      ),
    );
    return BackupSnapshot(
      inventory: inventory,
      nodes: normalizedNodes,
      categories: const [],
      nodeCategories: const [],
    );
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
    return node;
  }

  static void validateBusinessRules(BackupSnapshot snapshot) {
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

    final categoryIds = <String>{};
    for (final category in snapshot.categories) {
      final id = category['id'];
      _requireUuid(id);
      if (id is! String || !categoryIds.add(id)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (category['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      _requireNonEmptyString(category['name']);
      _requireNonEmptyString(category['created_at']);
      _requireNonEmptyString(category['updated_at']);
    }

    final associationKeys = <String>{};
    for (final association in snapshot.nodeCategories) {
      if (association['inventory_id'] != inventoryId) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final nodeId = association['node_id'];
      final categoryId = association['category_id'];
      if (nodeId is! String ||
          categoryId is! String ||
          !nodeIds.contains(nodeId) ||
          !categoryIds.contains(categoryId)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final node = nodesById[nodeId]!;
      if (!_itemTypes.contains(node['node_type'])) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (!associationKeys.add('$nodeId::$categoryId')) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    for (final node in snapshot.nodes) {
      final parentId = node['parent_id'];
      final status = node['status'];
      if (status == 'withdrawn') {
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
      if (parent['status'] != 'active' ||
          !_containerTypes.contains(parent['node_type'])) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      if (parent['space'] != node['space']) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }

    // Children under plain items or withdrawn nodes are already rejected by
    // the parent capability check above. Detect cycles among active edges.
    for (final node in snapshot.nodes) {
      if (node['status'] != 'active') continue;
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
      // Active non-root chains must end on a location root.
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

  static void _validateNode(Map<String, Object?> node) {
    final type = node['node_type'];
    final status = node['status'];
    final name = node['name'];
    final space = node['space'];
    if (type is! String || !_nodeTypes.contains(type)) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
    if (status is! String || (status != 'active' && status != 'withdrawn')) {
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

    final isItem = _itemTypes.contains(type);
    final quantity = node['quantity'];
    final valueMode = node['value_mode'];
    final financial = node['financial_value_cents'];
    final sentimental = node['sentimental_value'];
    final reason = node['withdrawal_reason'];
    final withdrawnAt = node['withdrawn_at'];

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

    if (status == 'active') {
      if (reason != null || withdrawnAt != null) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    } else {
      if (!isItem ||
          reason is! String ||
          !_withdrawalReasons.contains(reason) ||
          withdrawnAt is! String ||
          withdrawnAt.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
    }
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
}
