import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;

import '../database/inventory_database.dart';
import 'inventory_exception.dart';
import 'inventory_models.dart';
import 'uuid_generator.dart';

/// Single entry point for every inventory change. Each public operation runs
/// in one SQLite transaction: a domain or SQL failure leaves data unchanged.
class InventoryEngine {
  InventoryEngine(
    this._db, {
    DateTime Function()? clock,
    String Function()? generateId,
  }) : _clock = clock ?? DateTime.now,
       _generateId = generateId ?? generateUuidV4;

  static const defaultItemQuantity = 1;
  static const defaultFinancialCents = 0;
  static const _sqliteConstraintResultCode = 19;

  final InventoryDatabase _db;
  final DateTime Function() _clock;
  final String Function() _generateId;

  // Hierarchy reads.

  Future<InventoryNode> getNode(String nodeId) =>
      _run(() async => _toNode(await _requireNode(nodeId)));

  Future<List<InventoryNode>> getRootLocations() => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows =
        await (_db.select(_db.nodes)
              ..where(
                (node) =>
                    node.inventoryId.equals(inventoryId) &
                    node.parentId.isNull() &
                    node.nodeType.equals(NodeType.location.storageValue) &
                    node.status.equals(NodeStatus.active.storageValue),
              )
              ..orderBy(_byName))
            .get();
    return rows.map(_toNode).toList();
  });

  Future<List<InventoryNode>> getChildren(String parentId) => _run(() async {
    final parent = await _requireNode(parentId);
    _requireActive(parent);
    final rows =
        await (_db.select(_db.nodes)
              ..where(
                (node) =>
                    node.inventoryId.equals(parent.inventoryId) &
                    node.parentId.equals(parentId) &
                    node.status.equals(NodeStatus.active.storageValue),
              )
              ..orderBy(_byName))
            .get();
    return rows.map(_toNode).toList();
  });

  /// Ancestors ordered from the root location to the direct parent.
  Future<List<InventoryNode>> getAncestors(String nodeId) => _run(() async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    final chain = await _validatedChain(node);
    return chain.skip(1).toList().reversed.map(_toNode).toList();
  });

  /// Full physical path ordered from the root location to [nodeId].
  Future<List<InventoryNode>> getPath(String nodeId) => _run(() async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    final chain = await _validatedChain(node);
    return chain.reversed.map(_toNode).toList();
  });

  /// Finds active nodes using intersecting filters. A branch includes its
  /// descendants, not the branch node itself.
  Future<InventorySearchResponse> searchNodes(
    InventorySearchCriteria criteria,
  ) => _run(() async {
    final inventoryId = await _requireInventoryId();
    final branchId = criteria.branchId;
    List<InventoryNode>? branchPath;
    if (branchId != null) {
      final branch = await _requireNode(branchId);
      if (branch.inventoryId != inventoryId) {
        throw const InventoryException(InventoryErrorCode.inventoryMismatch);
      }
      _requireActive(branch);
      if (!_nodeType(branch).canContain) {
        throw const InventoryException(InventoryErrorCode.parentCannotContain);
      }
      branchPath = (await _validatedChain(
        branch,
      )).reversed.map(_toNode).toList();
    }
    if (criteria.categoryId case final categoryId?) {
      await _requireCategory(categoryId, inventoryId);
    }

    final variables = <Variable>[];
    final branchCte = branchId == null
        ? ''
        : '''
          descendants(id) AS (
            SELECT id FROM nodes
            WHERE inventory_id = ? AND parent_id = ? AND status = 'active'
            UNION
            SELECT child.id FROM nodes AS child
            JOIN descendants AS d ON child.parent_id = d.id
            WHERE child.inventory_id = ? AND child.status = 'active'
          ),
        ''';
    if (branchId != null) {
      variables.addAll([
        Variable.withString(inventoryId),
        Variable.withString(branchId),
        Variable.withString(inventoryId),
      ]);
    }
    final filters = <String>['n.inventory_id = ?', "n.status = 'active'"];
    variables.add(Variable.withString(inventoryId));
    final name = criteria.name.trim();
    if (name.isNotEmpty) {
      filters.add('moor_contains(n.name, ?, 0) = 1');
      variables.add(Variable.withString(name));
    }
    if (criteria.type case final type?) {
      filters.add('n.node_type = ?');
      variables.add(Variable.withString(type.storageValue));
    }
    if (criteria.categoryId case final categoryId?) {
      filters.add('''
        EXISTS (
          SELECT 1 FROM node_categories AS nc
          WHERE nc.inventory_id = n.inventory_id
            AND nc.node_id = n.id AND nc.category_id = ?
        )
      ''');
      variables.add(Variable.withString(categoryId));
    }
    if (branchId != null) {
      filters.add('n.id IN (SELECT id FROM descendants)');
    }
    variables.add(Variable.withString(inventoryId));

    final rows = await _db
        .customSelect(
          '''
      WITH RECURSIVE
      $branchCte
      matches AS (
        SELECT n.id, n.name, n.node_type, n.quantity, n.parent_id
        FROM nodes AS n
        WHERE ${filters.join(' AND ')}
      ),
      paths(target_id, parent_id, node_type, full_path, visited) AS (
        SELECT m.id, m.parent_id, m.node_type, m.name,
               '|' || hex(CAST(m.id AS BLOB)) || '|'
        FROM matches AS m
        UNION ALL
        SELECT p.target_id, parent.parent_id, parent.node_type,
               parent.name || ' → ' || p.full_path,
               p.visited || hex(CAST(parent.id AS BLOB)) || '|'
        FROM paths AS p
        JOIN nodes AS parent ON parent.id = p.parent_id
          AND parent.inventory_id = ?
        WHERE parent.status = 'active'
          AND parent.node_type IN ('location', 'container', 'item_container')
          AND instr(p.visited, '|' || hex(CAST(parent.id AS BLOB)) || '|') = 0
      )
      SELECT m.id, m.name, m.node_type, m.quantity, p.full_path
      FROM matches AS m
      LEFT JOIN paths AS p ON p.target_id = m.id
        AND p.parent_id IS NULL AND p.node_type = 'location'
      ORDER BY m.name COLLATE NOCASE, m.id
      ''',
          variables: variables,
          readsFrom: {_db.nodes, _db.nodeCategories},
        )
        .get();
    final results = <InventorySearchResult>[];
    for (final row in rows) {
      final path = row.readNullable<String>('full_path');
      if (path == null) {
        throw const InventoryException(InventoryErrorCode.invalidHierarchy);
      }
      results.add(
        InventorySearchResult(
          nodeId: row.read<String>('id'),
          name: row.read<String>('name'),
          type: _parse(
            NodeType.values,
            (type) => type.storageValue,
            row.read<String>('node_type'),
          ),
          quantity: row.readNullable<int>('quantity'),
          path: path,
        ),
      );
    }
    return InventorySearchResponse(results: results, branchPath: branchPath);
  });

  /// Minimal history of withdrawn items, most recent first.
  Future<List<InventoryNode>> getWithdrawnItems() => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows =
        await (_db.select(_db.nodes)
              ..where(
                (node) =>
                    node.inventoryId.equals(inventoryId) &
                    node.status.equals(NodeStatus.withdrawn.storageValue),
              )
              ..orderBy([
                (node) => OrderingTerm.desc(node.withdrawnAt),
                (node) => OrderingTerm.asc(node.id),
              ]))
            .get();
    return rows.map(_toNode).toList();
  });

  // Node writes.

  /// Creates a node. Item types default to quantity 1 and a 0 $ financial
  /// value. Categories, when given, are associated in the same transaction.
  Future<InventoryNode> createNode({
    required String name,
    required NodeType type,
    String? parentId,
    String? description,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    Iterable<String> categoryIds = const [],
  }) => _run(() async {
    final normalizedName = _normalizeName(name);
    final categories = categoryIds.toSet();
    if (!type.isItem &&
        (quantity != null || valuation != null || categories.isNotEmpty)) {
      throw const InventoryException(InventoryErrorCode.requiresItem);
    }
    final itemQuantity = type.isItem ? (quantity ?? defaultItemQuantity) : null;
    final itemValuation = type.isItem
        ? (valuation ?? const FinancialValuation(defaultFinancialCents))
        : null;
    if (itemQuantity != null) _validateQuantity(itemQuantity);
    if (itemValuation != null) _validateValuation(itemValuation);
    if (itemQuantity != null && itemValuation != null) {
      _validateFinancialTotal(itemValuation, itemQuantity);
    }

    final inventoryId = await _requireInventoryId();
    if (parentId == null) {
      if (!type.canBeRoot) {
        throw const InventoryException(InventoryErrorCode.parentRequired);
      }
    } else {
      await _requireValidParent(parentId, inventoryId);
    }

    final id = _generateId();
    final now = _timestamp();
    await _db
        .into(_db.nodes)
        .insert(
          NodesCompanion.insert(
            id: id,
            inventoryId: inventoryId,
            parentId: Value(parentId),
            name: normalizedName,
            nodeType: type.storageValue,
            quantity: Value(itemQuantity),
            description: Value(_normalizeOptional(description)),
            condition: Value(_normalizeOptional(condition)),
            valueMode: Value(_valueMode(itemValuation)),
            financialValueCents: Value(_financialCents(itemValuation)),
            sentimentalValue: Value(_sentimentalRating(itemValuation)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final categoryId in categories) {
      await _requireCategory(categoryId, inventoryId);
      await _insertAssociation(inventoryId, id, categoryId);
    }
    return _toNode(await _requireNode(id));
  });

  /// Replaces general properties and an optional item quantity atomically.
  Future<InventoryNode> updateDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    int? quantity,
  }) => _run(() async {
    final normalizedName = _normalizeName(name);
    final node = await _requireNode(nodeId);
    _requireActive(node);
    if (quantity != null) {
      // The outer transaction also rolls back this quantity if the text fails.
      await updateQuantity(nodeId, quantity);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(
        name: Value(normalizedName),
        description: Value(_normalizeOptional(description)),
        condition: Value(_normalizeOptional(condition)),
      ),
    );
    return _toNode(await _requireNode(nodeId));
  });

  Future<InventoryNode> updateQuantity(String nodeId, int quantity) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        _validateQuantity(quantity);
        _validateFinancialTotal(_toValuation(node), quantity);
        await _writeNode(node.id, NodesCompanion(quantity: Value(quantity)));
        return _toNode(await _requireNode(nodeId));
      });

  /// Sets the single active valuation; the other mode is always cleared.
  Future<InventoryNode> setValuation(String nodeId, NodeValuation valuation) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        _validateValuation(valuation);
        _validateFinancialTotal(valuation, node.quantity!);
        await _writeNode(
          node.id,
          NodesCompanion(
            valueMode: Value(_valueMode(valuation)),
            financialValueCents: Value(_financialCents(valuation)),
            sentimentalValue: Value(_sentimentalRating(valuation)),
          ),
        );
        return _toNode(await _requireNode(nodeId));
      });

  /// Saves all item fields and category changes in one transaction.
  Future<({InventoryNode node, List<InventoryCategory> categories})>
  updateItemDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    required int quantity,
    required NodeValuation valuation,
    required Iterable<String> categoryIds,
    Iterable<String> newCategoryNames = const [],
  }) => _run(() async {
    final normalizedName = _normalizeName(name);
    final node = await _requireActiveItem(nodeId);
    _validateQuantity(quantity);
    _validateValuation(valuation);
    _validateFinancialTotal(valuation, quantity);
    final selected = categoryIds.toSet();
    for (final id in selected) {
      await _requireCategory(id, node.inventoryId);
    }
    for (final name in newCategoryNames) {
      final category = await createCategory(name);
      selected.add(category.id);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(
        name: Value(normalizedName),
        description: Value(_normalizeOptional(description)),
        condition: Value(_normalizeOptional(condition)),
        quantity: Value(quantity),
        valueMode: Value(_valueMode(valuation)),
        financialValueCents: Value(_financialCents(valuation)),
        sentimentalValue: Value(_sentimentalRating(valuation)),
      ),
    );
    final previous = (await getNodeCategories(
      nodeId,
    )).map((category) => category.id).toSet();
    for (final id in previous.difference(selected)) {
      await unassignCategory(nodeId, id);
    }
    for (final id in selected.difference(previous)) {
      await assignCategory(nodeId, id);
    }
    return (
      node: _toNode(await _requireNode(nodeId)),
      categories: await getNodeCategories(nodeId),
    );
  });

  /// Moves [nodeId] with all its descendants by changing only its parent.
  /// A null [newParentId] is accepted only for a location becoming a root.
  Future<InventoryNode> moveNode(String nodeId, String? newParentId) =>
      _run(() async {
        final node = await _requireNode(nodeId);
        _requireActive(node);
        final type = _nodeType(node);
        if (newParentId == null) {
          if (!type.canBeRoot) {
            throw const InventoryException(InventoryErrorCode.parentRequired);
          }
        } else {
          if (newParentId == nodeId) {
            throw const InventoryException(InventoryErrorCode.cycleDetected);
          }
          await _requireValidParent(
            newParentId,
            node.inventoryId,
            movingNodeId: nodeId,
          );
        }
        await _writeNode(nodeId, NodesCompanion(parentId: Value(newParentId)));
        return _toNode(await _requireNode(nodeId));
      });

  /// Withdraws an empty item from the active inventory while keeping its
  /// information, categories, reason and date as minimal history (D07).
  Future<InventoryNode> withdrawItem(String nodeId, WithdrawalReason reason) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        await _requireNoChildren(node);
        await _writeNode(
          nodeId,
          NodesCompanion(
            status: Value(NodeStatus.withdrawn.storageValue),
            withdrawalReason: Value(reason.storageValue),
            withdrawnAt: Value(_timestamp()),
            parentId: const Value(null),
          ),
        );
        return _toNode(await _requireNode(nodeId));
      });

  /// Permanently deletes an active node created by mistake, without history.
  /// Only its category associations are removed with it (D02, D07).
  Future<void> deleteNodePermanently(String nodeId) => _run(() async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    await _requireNoChildren(node);
    await (_db.delete(_db.nodes)..where((row) => row.id.equals(nodeId))).go();
  });

  // Categories.

  Future<List<InventoryCategory>> getCategories() => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows =
        await (_db.select(_db.categories)
              ..where((category) => category.inventoryId.equals(inventoryId))
              ..orderBy([
                (category) => OrderingTerm.asc(category.name),
                (category) => OrderingTerm.asc(category.id),
              ]))
            .get();
    return rows.map(_toCategory).toList();
  });

  Future<InventoryCategory> createCategory(String name) => _run(() async {
    final normalizedName = _normalizeName(name);
    final inventoryId = await _requireInventoryId();
    final id = _generateId();
    final now = _timestamp();
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            inventoryId: inventoryId,
            name: normalizedName,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toCategory(await _requireCategory(id, inventoryId));
  });

  Future<InventoryCategory> renameCategory(String categoryId, String name) =>
      _run(() async {
        final normalizedName = _normalizeName(name);
        final inventoryId = await _requireInventoryId();
        await _requireCategory(categoryId, inventoryId);
        await (_db.update(
          _db.categories,
        )..where((category) => category.id.equals(categoryId))).write(
          CategoriesCompanion(
            name: Value(normalizedName),
            updatedAt: Value(_timestamp()),
          ),
        );
        return _toCategory(await _requireCategory(categoryId, inventoryId));
      });

  /// Deletes a category and only its associations; items are never touched.
  Future<void> deleteCategory(String categoryId) => _run(() async {
    final inventoryId = await _requireInventoryId();
    await _requireCategory(categoryId, inventoryId);
    await (_db.delete(
      _db.categories,
    )..where((category) => category.id.equals(categoryId))).go();
  });

  Future<List<InventoryCategory>> getNodeCategories(String nodeId) =>
      _run(() async {
        final node = await _requireNode(nodeId);
        final query =
            _db.select(_db.categories).join([
                innerJoin(
                  _db.nodeCategories,
                  _db.nodeCategories.categoryId.equalsExp(_db.categories.id) &
                      _db.nodeCategories.inventoryId.equalsExp(
                        _db.categories.inventoryId,
                      ),
                ),
              ])
              ..where(
                _db.nodeCategories.nodeId.equals(node.id) &
                    _db.nodeCategories.inventoryId.equals(node.inventoryId),
              )
              ..orderBy([
                OrderingTerm.asc(_db.categories.name),
                OrderingTerm.asc(_db.categories.id),
              ]);
        final rows = await query.get();
        return rows
            .map((row) => _toCategory(row.readTable(_db.categories)))
            .toList();
      });

  Future<void> assignCategory(String nodeId, String categoryId) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        await _requireCategory(categoryId, node.inventoryId);
        if (await _findAssociation(nodeId, categoryId) != null) {
          throw const InventoryException(
            InventoryErrorCode.categoryAlreadyAssigned,
          );
        }
        await _insertAssociation(node.inventoryId, nodeId, categoryId);
      });

  Future<void> unassignCategory(String nodeId, String categoryId) => _run(
    () async {
      final node = await _requireActiveItem(nodeId);
      await _requireCategory(categoryId, node.inventoryId);
      final deleted =
          await (_db.delete(_db.nodeCategories)..where(
                (association) =>
                    association.nodeId.equals(nodeId) &
                    association.categoryId.equals(categoryId),
              ))
              .go();
      if (deleted == 0) {
        throw const InventoryException(InventoryErrorCode.categoryNotAssigned);
      }
    },
  );

  // Transaction and error boundary.

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await _db.transaction(action);
    } on InventoryException {
      rethrow;
    } on SqliteException catch (error) {
      throw InventoryException(
        error.resultCode == _sqliteConstraintResultCode
            ? InventoryErrorCode.constraintViolation
            : InventoryErrorCode.storageFailure,
        cause: error,
      );
    } on CouldNotRollBackException catch (error) {
      throw InventoryException(InventoryErrorCode.storageFailure, cause: error);
    }
  }

  // Validation helpers.

  Future<String> _requireInventoryId() async {
    final inventory = await _db.select(_db.inventories).getSingleOrNull();
    if (inventory == null) {
      throw const InventoryException(InventoryErrorCode.inventoryUnavailable);
    }
    return inventory.id;
  }

  Future<Node?> _findNode(String nodeId) => (_db.select(
    _db.nodes,
  )..where((node) => node.id.equals(nodeId))).getSingleOrNull();

  Future<Node> _requireNode(String nodeId) async {
    final node = await _findNode(nodeId);
    if (node == null) {
      throw const InventoryException(InventoryErrorCode.nodeNotFound);
    }
    return node;
  }

  void _requireActive(Node node) {
    if (node.status != NodeStatus.active.storageValue) {
      throw const InventoryException(InventoryErrorCode.nodeInactive);
    }
  }

  Future<Node> _requireActiveItem(String nodeId) async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    if (!_nodeType(node).isItem) {
      throw const InventoryException(InventoryErrorCode.requiresItem);
    }
    return node;
  }

  Future<void> _requireNoChildren(Node node) async {
    final child =
        await (_db.select(_db.nodes)
              ..where((row) => row.parentId.equals(node.id))
              ..limit(1))
            .getSingleOrNull();
    if (child != null) {
      throw const InventoryException(InventoryErrorCode.nodeHasChildren);
    }
  }

  /// Checks that [parentId] can receive a child of [inventoryId] and that its
  /// existing chain is sound. When moving, [movingNodeId] must not be found
  /// among the parent and its ancestors.
  Future<void> _requireValidParent(
    String parentId,
    String inventoryId, {
    String? movingNodeId,
  }) async {
    final parent = await _findNode(parentId);
    if (parent == null) {
      throw const InventoryException(InventoryErrorCode.parentNotFound);
    }
    if (parent.inventoryId != inventoryId) {
      throw const InventoryException(InventoryErrorCode.inventoryMismatch);
    }
    if (parent.status != NodeStatus.active.storageValue) {
      throw const InventoryException(InventoryErrorCode.parentInactive);
    }
    if (!_nodeType(parent).canContain) {
      throw const InventoryException(InventoryErrorCode.parentCannotContain);
    }
    await _validatedChain(parent, movingNodeId: movingNodeId);
  }

  /// Returns [node] followed by its ancestors up to the root. Every ancestor
  /// must be active, in the same inventory and able to contain; the chain
  /// must end at an active root location without looping.
  Future<List<Node>> _validatedChain(Node node, {String? movingNodeId}) async {
    final chain = <Node>[];
    final visited = <String>{};
    Node current = node;
    while (true) {
      if (current.id == movingNodeId) {
        throw const InventoryException(InventoryErrorCode.cycleDetected);
      }
      if (!visited.add(current.id) ||
          current.inventoryId != node.inventoryId ||
          current.status != NodeStatus.active.storageValue ||
          (chain.isNotEmpty && !_nodeType(current).canContain)) {
        throw const InventoryException(InventoryErrorCode.invalidHierarchy);
      }
      chain.add(current);
      final parentId = current.parentId;
      if (parentId == null) {
        if (!_nodeType(current).canBeRoot) {
          throw const InventoryException(InventoryErrorCode.invalidHierarchy);
        }
        return chain;
      }
      final parent = await _findNode(parentId);
      if (parent == null) {
        throw const InventoryException(InventoryErrorCode.invalidHierarchy);
      }
      current = parent;
    }
  }

  Future<Category> _requireCategory(
    String categoryId,
    String inventoryId,
  ) async {
    final category =
        await (_db.select(_db.categories)..where(
              (row) =>
                  row.id.equals(categoryId) &
                  row.inventoryId.equals(inventoryId),
            ))
            .getSingleOrNull();
    if (category == null) {
      throw const InventoryException(InventoryErrorCode.categoryNotFound);
    }
    return category;
  }

  Future<NodeCategory?> _findAssociation(String nodeId, String categoryId) =>
      (_db.select(_db.nodeCategories)..where(
            (row) =>
                row.nodeId.equals(nodeId) & row.categoryId.equals(categoryId),
          ))
          .getSingleOrNull();

  Future<void> _insertAssociation(
    String inventoryId,
    String nodeId,
    String categoryId,
  ) => _db
      .into(_db.nodeCategories)
      .insert(
        NodeCategoriesCompanion.insert(
          inventoryId: inventoryId,
          nodeId: nodeId,
          categoryId: categoryId,
        ),
      );

  Future<void> _writeNode(String nodeId, NodesCompanion changes) =>
      (_db.update(_db.nodes)..where((node) => node.id.equals(nodeId))).write(
        changes.copyWith(updatedAt: Value(_timestamp())),
      );

  static String _normalizeName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const InventoryException(InventoryErrorCode.emptyName);
    }
    return normalized;
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static void _validateQuantity(int quantity) {
    if (quantity < 1) {
      throw const InventoryException(InventoryErrorCode.invalidQuantity);
    }
  }

  static void _validateFinancialTotal(NodeValuation valuation, int quantity) {
    if (valuation is FinancialValuation) {
      valuation.totalForQuantity(quantity);
    }
  }

  static void _validateValuation(NodeValuation valuation) {
    switch (valuation) {
      case FinancialValuation(:final unitCents) when unitCents < 0:
        throw const InventoryException(
          InventoryErrorCode.invalidFinancialValue,
        );
      case SentimentalValuation(:final rating)
          when rating < SentimentalValuation.minRating ||
              rating > SentimentalValuation.maxRating:
        throw const InventoryException(
          InventoryErrorCode.invalidSentimentalValue,
        );
      case FinancialValuation() || SentimentalValuation():
        return;
    }
  }

  static String? _valueMode(NodeValuation? valuation) => switch (valuation) {
    FinancialValuation() => 'financial',
    SentimentalValuation() => 'sentimental',
    null => null,
  };

  static int? _financialCents(NodeValuation? valuation) =>
      valuation is FinancialValuation ? valuation.unitCents : null;

  static int? _sentimentalRating(NodeValuation? valuation) =>
      valuation is SentimentalValuation ? valuation.rating : null;

  String _timestamp() => _clock().toUtc().toIso8601String();

  static List<OrderClauseGenerator<$NodesTable>> get _byName => [
    (node) => OrderingTerm.asc(node.name),
    (node) => OrderingTerm.asc(node.id),
  ];

  // Mapping from storage rows; unknown stored values are reported, never
  // silently replaced.

  static NodeType _nodeType(Node node) =>
      _parse(NodeType.values, (type) => type.storageValue, node.nodeType);

  static InventoryNode _toNode(Node node) {
    final type = _nodeType(node);
    return InventoryNode(
      id: node.id,
      parentId: node.parentId,
      name: node.name,
      type: type,
      description: node.description,
      condition: node.condition,
      quantity: type.isItem ? node.quantity : null,
      valuation: type.isItem ? _toValuation(node) : null,
      status: _parse(
        NodeStatus.values,
        (status) => status.storageValue,
        node.status,
      ),
      withdrawalReason: node.withdrawalReason == null
          ? null
          : _parse<WithdrawalReason>(
              WithdrawalReason.values,
              (reason) => reason.storageValue,
              node.withdrawalReason!,
            ),
      withdrawnAt: node.withdrawnAt == null
          ? null
          : _parseDate(node.withdrawnAt!),
      createdAt: _parseDate(node.createdAt),
      updatedAt: _parseDate(node.updatedAt),
    );
  }

  static NodeValuation _toValuation(Node node) {
    switch (node.valueMode) {
      case 'financial' when node.financialValueCents != null:
        return FinancialValuation(node.financialValueCents!);
      case 'sentimental' when node.sentimentalValue != null:
        return SentimentalValuation(node.sentimentalValue!);
      default:
        throw const InventoryException(InventoryErrorCode.invalidStoredData);
    }
  }

  static InventoryCategory _toCategory(Category category) => InventoryCategory(
    id: category.id,
    name: category.name,
    createdAt: _parseDate(category.createdAt),
    updatedAt: _parseDate(category.updatedAt),
  );

  static T _parse<T>(
    List<T> values,
    String Function(T value) storageValue,
    String raw,
  ) {
    for (final value in values) {
      if (storageValue(value) == raw) return value;
    }
    throw const InventoryException(InventoryErrorCode.invalidStoredData);
  }

  static DateTime _parseDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) {
      throw const InventoryException(InventoryErrorCode.invalidStoredData);
    }
    return date;
  }
}
