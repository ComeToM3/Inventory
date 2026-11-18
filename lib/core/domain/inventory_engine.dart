import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;

import '../database/inventory_database.dart';
import 'inventory_exception.dart';
import 'inventory_models.dart';
import 'inventory_name.dart';
import 'stock_quantity.dart';
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
  static const maxNameLength = InventoryName.maxLength;
  static const _sqliteConstraintResultCode = 19;

  final InventoryDatabase _db;
  final DateTime Function() _clock;
  final String Function() _generateId;

  // Hierarchy reads.

  Future<InventoryNode> getNode(String nodeId) =>
      _run(() async => _toNode(await _requireNode(nodeId)));

  /// Active root locations. Defaults to [InventorySpace.goods] so V1 callers
  /// keep seeing the Biens hierarchy after migration.
  Future<List<InventoryNode>> getRootLocations({
    InventorySpace space = InventorySpace.goods,
  }) => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows =
        await (_db.select(_db.nodes)
              ..where(
                (node) =>
                    node.inventoryId.equals(inventoryId) &
                    node.parentId.isNull() &
                    node.space.equals(space.storageValue) &
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
              // Direct simple items first, then locations / item-containers;
              // alphabetical within each group. Presentation only — parent_id unchanged.
              ..orderBy(_byTreeDisplay))
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

  /// Financial totals for each [nodeIds] root: own financial value (items) plus
  /// every active financial descendant. Independent of UI expansion. Sentimental
  /// values are ignored. Overflow is reported per root without wrapping.
  Future<Map<String, SubtreeFinancialTotal>> getSubtreeFinancialTotals(
    Iterable<String> nodeIds,
  ) => _run(() async {
    final ids = [
      ...{...nodeIds},
    ];
    if (ids.isEmpty) return {};

    final inventoryId = await _requireInventoryId();
    final valuesSql = ids.map((_) => '(?)').join(', ');
    final variables = <Variable>[
      for (final id in ids) Variable.withString(id),
      Variable.withString(inventoryId),
      Variable.withString(inventoryId),
    ];

    final rows = await _db
        .customSelect(
          '''
      WITH RECURSIVE
      roots(root_id) AS (VALUES $valuesSql),
      tree(root_id, id, visited) AS (
        SELECT r.root_id, n.id, '|' || hex(CAST(n.id AS BLOB)) || '|'
        FROM roots AS r
        JOIN nodes AS n ON n.id = r.root_id
        WHERE n.inventory_id = ? AND n.status = 'active'
        UNION ALL
        SELECT t.root_id, child.id,
               t.visited || hex(CAST(child.id AS BLOB)) || '|'
        FROM tree AS t
        JOIN nodes AS child ON child.parent_id = t.id
        WHERE child.inventory_id = ?
          AND child.status = 'active'
          AND instr(
            t.visited,
            '|' || hex(CAST(child.id AS BLOB)) || '|'
          ) = 0
      )
      SELECT t.root_id AS root_id,
             n.financial_value_cents AS unit_cents,
             n.quantity AS quantity
      FROM tree AS t
      JOIN nodes AS n ON n.id = t.id
      WHERE n.value_mode = 'financial'
        AND n.financial_value_cents IS NOT NULL
        AND n.quantity IS NOT NULL
        AND n.node_type IN ('item', 'item_container')
      ''',
          variables: variables,
          readsFrom: {_db.nodes},
        )
        .get();

    final contributions = <String, List<({int unit, int quantity})>>{
      for (final id in ids) id: <({int unit, int quantity})>[],
    };
    for (final row in rows) {
      final rootId = row.read<String>('root_id');
      final list = contributions[rootId];
      if (list == null) continue;
      list.add((
        unit: row.read<int>('unit_cents'),
        quantity: row.read<int>('quantity'),
      ));
    }

    final result = <String, SubtreeFinancialTotal>{};
    for (final id in ids) {
      final items = contributions[id] ?? const [];
      if (items.isEmpty) {
        result[id] = const SubtreeFinancialNone();
        continue;
      }
      try {
        var sum = 0;
        for (final item in items) {
          final line = FinancialValuation(
            item.unit,
          ).totalForQuantity(item.quantity);
          sum = _addCents(sum, line);
        }
        result[id] = SubtreeFinancialAmount(sum);
      } on InventoryException catch (error) {
        if (error.code != InventoryErrorCode.financialTotalOverflow) rethrow;
        result[id] = const SubtreeFinancialOverflow();
      }
    }
    return result;
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
      if (InventorySpace.parse(branch.space) != criteria.space) {
        throw const InventoryException(InventoryErrorCode.spaceMismatch);
      }
      branchPath = (await _validatedChain(
        branch,
      )).reversed.map(_toNode).toList();
    }
    final variables = <Variable>[];
    final branchCte = branchId == null
        ? ''
        : '''
          descendants(id) AS (
            SELECT id FROM nodes
            WHERE inventory_id = ? AND parent_id = ? AND status = 'active'
              AND space = ?
            UNION
            SELECT child.id FROM nodes AS child
            JOIN descendants AS d ON child.parent_id = d.id
            WHERE child.inventory_id = ? AND child.status = 'active'
              AND child.space = ?
          ),
        ''';
    if (branchId != null) {
      variables.addAll([
        Variable.withString(inventoryId),
        Variable.withString(branchId),
        Variable.withString(criteria.space.storageValue),
        Variable.withString(inventoryId),
        Variable.withString(criteria.space.storageValue),
      ]);
    }
    final filters = <String>[
      'n.inventory_id = ?',
      "n.status = 'active'",
      'n.space = ?',
    ];
    variables.add(Variable.withString(inventoryId));
    variables.add(Variable.withString(criteria.space.storageValue));
    final name = criteria.name.trim();
    if (name.isNotEmpty) {
      filters.add('moor_contains(n.name, ?, 0) = 1');
      variables.add(Variable.withString(name));
    }
    if (criteria.type case final type?) {
      filters.add('n.node_type = ?');
      variables.add(Variable.withString(type.storageValue));
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
        SELECT n.id, n.name, n.node_type, n.quantity, n.parent_id,
               n.value_mode, n.financial_value_cents, n.sentimental_value
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
          AND parent.node_type IN ('location', 'item_container')
          AND instr(p.visited, '|' || hex(CAST(parent.id AS BLOB)) || '|') = 0
      )
      SELECT m.id, m.name, m.node_type, m.quantity, p.full_path,
             m.value_mode, m.financial_value_cents, m.sentimental_value
      FROM matches AS m
      LEFT JOIN paths AS p ON p.target_id = m.id
        AND p.parent_id IS NULL AND p.node_type = 'location'
      ORDER BY m.name COLLATE NOCASE, m.id
      ''',
          variables: variables,
          readsFrom: {_db.nodes},
        )
        .get();
    final results = <InventorySearchResult>[];
    for (final row in rows) {
      final path = row.readNullable<String>('full_path');
      if (path == null) {
        throw const InventoryException(InventoryErrorCode.invalidHierarchy);
      }
      final type = _parse(
        NodeType.values,
        (value) => value.storageValue,
        row.read<String>('node_type'),
      );
      results.add(
        InventorySearchResult(
          nodeId: row.read<String>('id'),
          name: row.read<String>('name'),
          type: type,
          quantity: row.readNullable<int>('quantity'),
          path: path,
          valuation: type.isItem
              ? _valuationFromColumns(
                  row.readNullable<String>('value_mode'),
                  row.readNullable<int>('financial_value_cents'),
                  row.readNullable<int>('sentimental_value'),
                )
              : null,
        ),
      );
    }
    return InventorySearchResponse(results: results, branchPath: branchPath);
  });

  /// Minimal history of withdrawn items, most recent first.
  Future<List<InventoryNode>> getWithdrawnItems({
    InventorySpace space = InventorySpace.goods,
  }) => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows =
        await (_db.select(_db.nodes)
              ..where(
                (node) =>
                    node.inventoryId.equals(inventoryId) &
                    node.space.equals(space.storageValue) &
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

  /// Creates a node. Item types default to quantity 1 with no price set.
  /// Defaults to [InventorySpace.goods] for V1 callers.
  ///
  /// Stock products always start at [StockLevel.full]. Optional
  /// [stockReference] is a simple total hint (not a unit of measure).
  Future<InventoryNode> createNode({
    required String name,
    required NodeType type,
    InventorySpace space = InventorySpace.goods,
    String? parentId,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    int? stockReference,
  }) => _run(() async {
    final normalizedName = InventoryName.normalizeForStorage(name);
    final isStock = space == InventorySpace.stock;
    final isStockProduct = isStock && type == NodeType.item;
    final isStockContainer = isStock && type == NodeType.itemContainer;

    if (isStock) {
      if (valuation != null) {
        throw const InventoryException(InventoryErrorCode.requiresItem);
      }
      if (!isStockProduct && quantity != null) {
        throw const InventoryException(InventoryErrorCode.requiresItem);
      }
      if (!isStockProduct && stockReference != null) {
        throw const InventoryException(InventoryErrorCode.requiresItem);
      }
    } else if (!type.isItem && (quantity != null || valuation != null)) {
      throw const InventoryException(InventoryErrorCode.requiresItem);
    }
    if (isStockProduct && stockReference != null && stockReference < 1) {
      throw const InventoryException(InventoryErrorCode.invalidQuantity);
    }

    final int? itemQuantity;
    final NodeValuation? itemValuation;
    if (isStockProduct) {
      itemQuantity = StockLevel.full.storageQuarters;
      itemValuation = null;
    } else if (isStockContainer || type == NodeType.location) {
      itemQuantity = null;
      itemValuation = null;
    } else {
      itemQuantity = type.isItem ? (quantity ?? defaultItemQuantity) : null;
      itemValuation = type.isItem ? valuation : null;
      if (itemQuantity != null) _validateQuantity(itemQuantity);
      if (itemValuation != null) _validateValuation(itemValuation);
      if (itemQuantity != null && itemValuation != null) {
        _validateFinancialTotal(itemValuation, itemQuantity);
      }
    }

    final inventoryId = await _requireInventoryId();
    if (parentId == null) {
      if (!type.canBeRoot) {
        throw const InventoryException(InventoryErrorCode.parentRequired);
      }
    } else {
      await _requireValidParent(parentId, inventoryId, childSpace: space);
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
            space: Value(space.storageValue),
            name: normalizedName,
            nodeType: type.storageValue,
            quantity: Value(itemQuantity),
            description: const Value(null),
            condition: Value(_normalizeOptional(condition)),
            valueMode: Value(_valueMode(itemValuation)),
            financialValueCents: Value(_financialCents(itemValuation)),
            sentimentalValue: Value(_sentimentalRating(itemValuation)),
            stockUnit: Value(isStockProduct ? stockUnitSentinel : null),
            unitCostCents: const Value(null),
            stockReference: Value(isStockProduct ? stockReference : null),
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (isStockProduct) {
      await _insertStockMovement(
        inventoryId: inventoryId,
        nodeId: id,
        type: StockMovementType.initial,
        deltaQuarters: StockLevel.full.storageQuarters,
        balanceAfterQuarters: StockLevel.full.storageQuarters,
        unit: stockUnitSentinel,
        createdAt: now,
      );
    }
    return _toNode(await _requireNode(id));
  });

  /// Replaces general properties and an optional item quantity atomically.
  Future<InventoryNode> updateDetails(
    String nodeId, {
    required String name,
    String? condition,
    int? quantity,
  }) => _run(() async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    final normalizedName = InventoryName.normalizeForStorage(
      name,
      existingStored: node.name,
    );
    if (quantity != null) {
      // The outer transaction also rolls back this quantity if the text fails.
      await updateQuantity(nodeId, quantity);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(
        name: Value(normalizedName),
        condition: Value(_normalizeOptional(condition)),
      ),
    );
    return _toNode(await _requireNode(nodeId));
  });

  Future<InventoryNode> updateQuantity(String nodeId, int quantity) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        if (InventorySpace.parse(node.space) == InventorySpace.stock) {
          // Stock balances change only via historized movements.
          throw const InventoryException(InventoryErrorCode.invalidQuantity);
        }
        _validateQuantity(quantity);
        final valuation = _toValuation(node);
        if (valuation != null) {
          _validateFinancialTotal(valuation, quantity);
        }
        await _writeNode(node.id, NodesCompanion(quantity: Value(quantity)));
        return _toNode(await _requireNode(nodeId));
      });

  /// Updates Stock product name, parent, and optional reference quantity.
  Future<InventoryNode> updateStockProduct(
    String nodeId, {
    required String name,
    String? parentId,
    int? stockReference,
  }) => _run(() async {
    final node = await _requireStockProduct(nodeId);
    final normalizedName = InventoryName.normalizeForStorage(
      name,
      existingStored: node.name,
    );
    if (stockReference != null && stockReference < 1) {
      throw const InventoryException(InventoryErrorCode.invalidQuantity);
    }
    if (parentId != node.parentId) {
      await _writeMove(nodeId, parentId);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(
        name: Value(normalizedName),
        stockReference: Value(stockReference),
        stockUnit: const Value(stockUnitSentinel),
        unitCostCents: const Value(null),
      ),
    );
    return _toNode(await _requireNode(nodeId));
  });

  /// Cycles the visual Stock level: 1 → ½ → ¼ → 0 → 1.
  Future<InventoryNode> cycleStockLevel(String nodeId) => _run(() async {
    final node = await _requireStockProduct(nodeId);
    final current = StockLevel.fromStoredQuarters(node.quantity!);
    final next = current.next;
    final oldQ = current.storageQuarters;
    final newQ = next.storageQuarters;
    await _writeNode(nodeId, NodesCompanion(quantity: Value(newQ)));
    await _insertStockMovement(
      inventoryId: node.inventoryId,
      nodeId: nodeId,
      type: StockMovementType.correct,
      deltaQuarters: newQ - oldQ,
      balanceAfterQuarters: newQ,
      unit: stockUnitSentinel,
      createdAt: _timestamp(),
    );
    return _toNode(await _requireNode(nodeId));
  });

  /// Sets an explicit Stock level (used by tests / rare corrections).
  Future<InventoryNode> setStockLevel(String nodeId, StockLevel level) =>
      _run(() async {
        final node = await _requireStockProduct(nodeId);
        final oldQ = StockLevel.fromStoredQuarters(node.quantity!).storageQuarters;
        final newQ = level.storageQuarters;
        if (oldQ == newQ) {
          return _toNode(node);
        }
        await _writeNode(nodeId, NodesCompanion(quantity: Value(newQ)));
        await _insertStockMovement(
          inventoryId: node.inventoryId,
          nodeId: nodeId,
          type: StockMovementType.correct,
          deltaQuarters: newQ - oldQ,
          balanceAfterQuarters: newQ,
          unit: stockUnitSentinel,
          createdAt: _timestamp(),
        );
        return _toNode(await _requireNode(nodeId));
      });

  Future<List<StockLedgerEntry>> getStockMovements(String nodeId) =>
      _run(() async {
        final node = await _requireStockProduct(nodeId);
        final rows =
            await (_db.select(_db.stockMovements)
                  ..where(
                    (row) =>
                        row.inventoryId.equals(node.inventoryId) &
                        row.nodeId.equals(nodeId),
                  )
                  ..orderBy([
                    (row) => OrderingTerm.desc(row.createdAt),
                    (row) => OrderingTerm.desc(row.id),
                  ]))
                .get();
        return rows.map(_toStockLedgerEntry).toList(growable: false);
      });

  /// Recent Stock ledger rows with product names (space-isolated).
  Future<List<StockLedgerEntryNamed>> getRecentStockMovements({
    int limit = 80,
  }) => _run(() async {
    final inventoryId = await _requireInventoryId();
    final rows = await _db
        .customSelect(
          '''
SELECT m.id, m.node_id, m.movement_type, m.delta_quarters,
       m.balance_after_quarters, m.unit, m.created_at, n.name AS product_name
FROM stock_movements m
INNER JOIN nodes n
  ON n.inventory_id = m.inventory_id AND n.id = m.node_id
WHERE m.inventory_id = ?
  AND n.space = 'stock'
ORDER BY m.created_at DESC, m.id DESC
LIMIT ?
''',
          variables: [
            Variable.withString(inventoryId),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.stockMovements, _db.nodes},
        )
        .get();
    return [
      for (final row in rows)
        StockLedgerEntryNamed(
          entry: StockLedgerEntry(
            id: row.read<String>('id'),
            nodeId: row.read<String>('node_id'),
            type: StockMovementType.parse(row.read<String>('movement_type')),
            deltaQuarters: row.read<int>('delta_quarters'),
            balanceAfterQuarters: row.read<int>('balance_after_quarters'),
            unit: row.read<String>('unit'),
            createdAt: _parseDate(row.read<String>('created_at')),
          ),
          productName: row.read<String>('product_name'),
        ),
    ];
  });

  Future<void> _insertStockMovement({
    required String inventoryId,
    required String nodeId,
    required StockMovementType type,
    required int deltaQuarters,
    required int balanceAfterQuarters,
    required String unit,
    required String createdAt,
  }) {
    return _db
        .into(_db.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            id: _generateId(),
            inventoryId: inventoryId,
            nodeId: nodeId,
            movementType: type.storageValue,
            deltaQuarters: deltaQuarters,
            balanceAfterQuarters: balanceAfterQuarters,
            unit: unit,
            createdAt: createdAt,
          ),
        );
  }

  Future<Node> _requireStockProduct(String nodeId) async {
    final node = await _requireActiveItem(nodeId);
    if (InventorySpace.parse(node.space) != InventorySpace.stock ||
        _nodeType(node) != NodeType.item) {
      throw const InventoryException(InventoryErrorCode.requiresItem);
    }
    if (node.stockUnit == null || node.quantity == null) {
      throw const InventoryException(InventoryErrorCode.invalidStoredData);
    }
    return node;
  }

  /// Sets the single active valuation; the other mode is always cleared.
  Future<InventoryNode> setValuation(String nodeId, NodeValuation? valuation) =>
      _run(() async {
        final node = await _requireActiveItem(nodeId);
        if (valuation != null) {
          _validateValuation(valuation);
          _validateFinancialTotal(valuation, node.quantity!);
        }
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

  /// Saves item fields and optional valuation in one transaction.
  Future<InventoryNode> updateItemDetails(
    String nodeId, {
    required String name,
    String? condition,
    required int quantity,
    NodeValuation? valuation,
  }) => _run(() async {
    await _writeItemDetails(
      nodeId,
      name: name,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
    );
    return _toNode(await _requireNode(nodeId));
  });

  /// Moves [nodeId] with all its descendants by changing only its parent.
  /// A null [newParentId] is accepted only for a location becoming a root.
  Future<InventoryNode> moveNode(String nodeId, String? newParentId) =>
      _run(() async {
        await _writeMove(nodeId, newParentId);
        return _toNode(await _requireNode(nodeId));
      });

  /// Updates fields and optionally moves / converts item kind in one
  /// transaction so a failed step never leaves a partial update committed.
  Future<InventoryNode> updateAndOptionallyMove(
    String nodeId, {
    required String name,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    required bool isItem,
    NodeType? itemKind,
    String? newParentId,
    required bool move,
  }) => _run(() async {
    if (itemKind != null) {
      await _writeItemKind(nodeId, itemKind);
    }
    if (isItem) {
      await _writeItemDetails(
        nodeId,
        name: name,
        condition: condition,
        quantity: quantity!,
        valuation: valuation,
      );
    } else {
      final node = await _requireNode(nodeId);
      _requireActive(node);
      final normalizedName = InventoryName.normalizeForStorage(
        name,
        existingStored: node.name,
      );
      await _writeNode(
        nodeId,
        NodesCompanion(
          name: Value(normalizedName),
          condition: Value(_normalizeOptional(condition)),
        ),
      );
    }
    if (move) {
      await _writeMove(nodeId, newParentId);
    }
    return _toNode(await _requireNode(nodeId));
  });

  /// Converts an active item between [NodeType.item] and
  /// [NodeType.itemContainer] without changing id, valuation or children.
  Future<InventoryNode> convertItemKind(String nodeId, NodeType target) =>
      _run(() async {
        await _writeItemKind(nodeId, target);
        return _toNode(await _requireNode(nodeId));
      });

  Future<void> _writeItemKind(String nodeId, NodeType target) async {
    if (target != NodeType.item && target != NodeType.itemContainer) {
      throw const InventoryException(InventoryErrorCode.requiresItem);
    }
    final node = await _requireActiveItem(nodeId);
    final current = _nodeType(node);
    if (current == target) return;
    if (!target.canContain) {
      await _requireNoChildren(node);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(nodeType: Value(target.storageValue)),
    );
  }

  Future<void> _writeItemDetails(
    String nodeId, {
    required String name,
    String? condition,
    required int quantity,
    NodeValuation? valuation,
  }) async {
    final node = await _requireActiveItem(nodeId);
    if (InventorySpace.parse(node.space) == InventorySpace.stock) {
      throw const InventoryException(InventoryErrorCode.invalidQuantity);
    }
    final normalizedName = InventoryName.normalizeForStorage(
      name,
      existingStored: node.name,
    );
    _validateQuantity(quantity);
    if (valuation != null) {
      _validateValuation(valuation);
      _validateFinancialTotal(valuation, quantity);
    }
    await _writeNode(
      nodeId,
      NodesCompanion(
        name: Value(normalizedName),
        condition: Value(_normalizeOptional(condition)),
        quantity: Value(quantity),
        valueMode: Value(_valueMode(valuation)),
        financialValueCents: Value(_financialCents(valuation)),
        sentimentalValue: Value(_sentimentalRating(valuation)),
      ),
    );
  }

  Future<void> _writeMove(String nodeId, String? newParentId) async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    final type = _nodeType(node);
    final space = InventorySpace.parse(node.space);
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
        childSpace: space,
        movingNodeId: nodeId,
      );
    }
    // Ordinary moves never change space; cross-space transfers are later ops.
    await _writeNode(nodeId, NodesCompanion(parentId: Value(newParentId)));
  }

  /// Withdraws an empty item from the active inventory while keeping its
  /// reason and date as minimal history (D07).
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
  Future<void> deleteNodePermanently(String nodeId) => _run(() async {
    final node = await _requireNode(nodeId);
    _requireActive(node);
    await _requireNoChildren(node);
    await (_db.delete(_db.nodes)..where((row) => row.id.equals(nodeId))).go();
  });

  // Transaction and error boundary.

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await _db.transaction(action);
    } on InventoryException {
      rethrow;
    } on DriftRemoteException catch (error) {
      // Production uses a Drift background isolate; SQLite failures arrive wrapped.
      throw _mapStorageFailure(error.remoteCause, fallback: error);
    } on SqliteException catch (error) {
      throw _mapSqliteException(error);
    } on CouldNotRollBackException catch (error) {
      throw InventoryException(InventoryErrorCode.storageFailure, cause: error);
    }
  }

  InventoryException _mapStorageFailure(
    Object cause, {
    required Object fallback,
  }) {
    if (cause is SqliteException) return _mapSqliteException(cause);
    return InventoryException(
      InventoryErrorCode.storageFailure,
      cause: fallback,
    );
  }

  InventoryException _mapSqliteException(SqliteException error) =>
      InventoryException(
        error.resultCode == _sqliteConstraintResultCode
            ? InventoryErrorCode.constraintViolation
            : InventoryErrorCode.storageFailure,
        cause: error,
      );

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
  /// among the parent and its ancestors. [childSpace] must match the parent.
  Future<void> _requireValidParent(
    String parentId,
    String inventoryId, {
    required InventorySpace childSpace,
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
    if (InventorySpace.parse(parent.space) != childSpace) {
      throw const InventoryException(InventoryErrorCode.spaceMismatch);
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

  Future<void> _writeNode(String nodeId, NodesCompanion changes) =>
      (_db.update(_db.nodes)..where((node) => node.id.equals(nodeId))).write(
        changes.copyWith(updatedAt: Value(_timestamp())),
      );

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static void _validateQuantity(int quantity) {
    if (quantity < 1) {
      throw const InventoryException(InventoryErrorCode.invalidQuantity);
    }
  }

  static StockLedgerEntry _toStockLedgerEntry(StockMovement row) =>
      StockLedgerEntry(
        id: row.id,
        nodeId: row.nodeId,
        type: StockMovementType.parse(row.movementType),
        deltaQuarters: row.deltaQuarters,
        balanceAfterQuarters: row.balanceAfterQuarters,
        unit: row.unit,
        createdAt: _parseDate(row.createdAt),
      );

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

  /// Tree siblings: all biens (simple + contenant), then locations, then name.
  /// Keeps item containers with the goods group so a sibling location (e.g.
  /// Garde-robe) cannot intercalate between a parent and its biens.
  static List<OrderClauseGenerator<$NodesTable>> get _byTreeDisplay => [
    (node) => OrderingTerm(
      expression: CustomExpression<int>(
        "CASE WHEN node_type = 'location' THEN 1 ELSE 0 END",
      ),
    ),
    (node) => OrderingTerm.asc(node.name),
    (node) => OrderingTerm.asc(node.id),
  ];

  // Mapping from storage rows; unknown stored values are reported, never
  // silently replaced.

  static NodeType _nodeType(Node node) =>
      _parse(NodeType.values, (type) => type.storageValue, node.nodeType);

  static InventoryNode _toNode(Node node) {
    final type = _nodeType(node);
    final space = InventorySpace.parse(node.space);
    final isStockProduct = space == InventorySpace.stock && type == NodeType.item;
    final carriesQuantity =
        ((space == InventorySpace.goods || space == InventorySpace.toBuy) &&
            type.isItem) ||
        isStockProduct;
    return InventoryNode(
      id: node.id,
      parentId: node.parentId,
      space: space,
      name: node.name,
      type: type,
      condition: node.condition,
      quantity: carriesQuantity ? node.quantity : null,
      valuation: space == InventorySpace.goods && type.isItem
          ? _valuationFromColumns(
              node.valueMode,
              node.financialValueCents,
              node.sentimentalValue,
            )
          : null,
      stockUnit: isStockProduct ? node.stockUnit : null,
      unitCostCents: null,
      stockReference: isStockProduct ? node.stockReference : null,
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

  static NodeValuation? _toValuation(Node node) => _valuationFromColumns(
    node.valueMode,
    node.financialValueCents,
    node.sentimentalValue,
  );

  static NodeValuation? _valuationFromColumns(
    String? valueMode,
    int? financialCents,
    int? sentimentalValue,
  ) {
    switch (valueMode) {
      case 'financial' when financialCents != null:
        return FinancialValuation(financialCents);
      case 'sentimental' when sentimentalValue != null:
        return SentimentalValuation(sentimentalValue);
      case null:
        return null;
      default:
        throw const InventoryException(InventoryErrorCode.invalidStoredData);
    }
  }

  static int _addCents(int left, int right) {
    const maxInt64 = 0x7FFFFFFFFFFFFFFF;
    if (right > 0 && left > maxInt64 - right) {
      throw const InventoryException(InventoryErrorCode.financialTotalOverflow);
    }
    return left + right;
  }

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
