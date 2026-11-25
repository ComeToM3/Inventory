import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/domain/inventory_engine.dart';
import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/purchase_models.dart';
import '../core/domain/stock_quantity.dart';
import '../core/media/goods_document_store.dart';
import '../core/media/goods_photo_store.dart';

/// Result of resolving a long-press drop on the tree.
enum OrganizeDropKind { none, reorderBefore, reorderAfter, nest }

class InventoryTreeEntry {
  const InventoryTreeEntry({required this.node, required this.depth});

  final InventoryNode node;
  final int depth;
}

class InventoryTreeController extends ChangeNotifier {
  InventoryTreeController(
    this._engine, {
    this.space = InventorySpace.goods,
  });

  final InventoryEngine _engine;

  InventoryEngine get engine => _engine;

  /// Space this tree belongs to (Biens / Stock / À acheter).
  final InventorySpace space;

  final _children = <String, List<InventoryNode>>{};
  final _childRequests = <String, Future<void>>{};
  final _readVersions = <String?, int>{};
  final _pendingOperations = <Future<void>>{};
  final _expanded = <String>{};
  final _childErrors = <String>{};
  final _subtreeTotals = <String, SubtreeFinancialTotal>{};
  final _pendingTotals = <String>{};
  Future<void>? _totalsRequest;
  List<InventoryNode>? _roots;
  Future<void>? _rootRequest;
  bool _rootError = false;
  bool _disposed = false;
  /// One-shot: expand locations only (not item-containers) after first load.
  var _initialLocationsExpandDone = false;
  Future<void>? _initialLocationsExpandRequest;

  /// True after the initial locations-only expand has finished (or been skipped).
  bool get isInitialLocationsExpandDone => _initialLocationsExpandDone;

  List<InventoryNode>? get roots => _roots;
  bool get loadingRoots => _rootRequest != null;
  bool get rootError => _rootError;

  bool isExpanded(String nodeId) => _expanded.contains(nodeId);
  bool isLoadingChildren(String nodeId) => _childRequests.containsKey(nodeId);
  bool hasChildError(String nodeId) => _childErrors.contains(nodeId);

  /// Direct children already loaded for [nodeId], if any.
  int? loadedChildCount(String nodeId) => _children[nodeId]?.length;

  /// Cached subtree financial total, if already loaded.
  SubtreeFinancialTotal? subtreeFinancialTotal(String nodeId) =>
      _subtreeTotals[nodeId];

  /// Ensures financial totals for containing nodes (independent of expansion).
  void ensureSubtreeTotals(Iterable<String> nodeIds) {
    if (_disposed) return;
    final missing = [
      for (final id in nodeIds)
        if (!_subtreeTotals.containsKey(id) && !_pendingTotals.contains(id)) id,
    ];
    if (missing.isEmpty) return;
    _pendingTotals.addAll(missing);
    _totalsRequest ??= _finishTotals(_loadPendingTotals());
  }

  List<InventoryTreeEntry> get visibleEntries {
    final roots = _roots;
    if (roots == null) return [];

    final visible = <InventoryTreeEntry>[];
    final pending = [
      for (final node in roots.reversed)
        InventoryTreeEntry(node: node, depth: 0),
    ];
    while (pending.isNotEmpty) {
      final entry = pending.removeLast();
      visible.add(entry);
      if (_expanded.contains(entry.node.id)) {
        final children = _children[entry.node.id];
        if (children != null) {
          for (final child in children.reversed) {
            pending.add(
              InventoryTreeEntry(node: child, depth: entry.depth + 1),
            );
          }
        }
      }
    }
    return visible;
  }

  void loadRoots() {
    if (_disposed || _rootRequest != null) return;
    _rootError = false;
    _rootRequest = _finishRoots(_loadRoots());
    notifyListeners();
  }

  Future<void> _loadRoots() async {
    final version = _readVersions[null];
    try {
      await _engine.ensurePermanentRoot(space: space);
      final roots = await _engine.getRootLocations(space: space);
      if (_isCurrentRead(null, version)) _roots = roots;
    } catch (_) {
      if (_isCurrentRead(null, version)) _rootError = true;
    }
  }

  /// Permanent root for this space (ensured). Used as default creation parent.
  Future<InventoryNode> ensurePermanentRootNode() => _trackOperation(
    () => _engine.ensurePermanentRoot(space: space),
  );

  Future<void> _finishRoots(Future<void> request) async {
    try {
      await request;
    } finally {
      _rootRequest = null;
      if (!_disposed) {
        notifyListeners();
        if (!_initialLocationsExpandDone &&
            _roots != null &&
            !_rootError &&
            _initialLocationsExpandRequest == null) {
          _initialLocationsExpandRequest = _expandLocationsInitial();
        }
      }
    }
  }

  /// Opens all [NodeType.location] branches; leaves biens-contenants collapsed.
  Future<void> _expandLocationsInitial() async {
    if (_disposed || _initialLocationsExpandDone) return;
    try {
      final pending = <InventoryNode>[
        for (final root in _roots ?? const <InventoryNode>[])
          if (root.type == NodeType.location) root,
      ];
      while (pending.isNotEmpty && !_disposed) {
        final node = pending.removeAt(0);
        if (!_expanded.contains(node.id)) {
          _expanded.add(node.id);
          if (!_children.containsKey(node.id) &&
              !_childRequests.containsKey(node.id)) {
            _startChildren(node.id);
          }
        }
        final request = _childRequests[node.id];
        if (request != null) await request;
        if (_disposed) return;
        final children = _children[node.id];
        if (children != null) {
          for (final child in children) {
            if (child.type == NodeType.location) pending.add(child);
          }
        }
        notifyListeners();
      }
    } finally {
      _initialLocationsExpandDone = true;
      _initialLocationsExpandRequest = null;
      if (!_disposed) notifyListeners();
    }
  }

  void toggle(InventoryNode node) {
    if (_disposed || !node.type.canContain) return;
    if (_expanded.remove(node.id)) {
      notifyListeners();
      return;
    }
    expand(node);
  }

  /// Expands [node] if collapsed; no-op when already open.
  void expand(InventoryNode node) {
    if (_disposed || !node.type.canContain) return;
    if (_expanded.contains(node.id)) return;
    _expanded.add(node.id);
    if (!_children.containsKey(node.id) &&
        !_childRequests.containsKey(node.id)) {
      _startChildren(node.id);
    }
    notifyListeners();
  }

  /// Collapses [node] if expanded; no-op otherwise.
  void collapse(InventoryNode node) {
    if (_disposed) return;
    if (_expanded.remove(node.id)) notifyListeners();
  }

  /// Expands and waits until children are loaded (or failed).
  Future<void> expandAndLoadChildren(InventoryNode node) async {
    if (_disposed || !node.type.canContain) return;
    expand(node);
    await _childRequests[node.id];
  }

  /// Expands ancestors so [nodeId] becomes reachable in [visibleEntries].
  Future<void> revealNode(String nodeId) => _trackOperation(() async {
    final path = await _engine.getPath(nodeId);
    for (final ancestor in path.take(path.length - 1)) {
      if (!ancestor.type.canContain) continue;
      _expanded.add(ancestor.id);
      if (!_children.containsKey(ancestor.id) &&
          !_childRequests.containsKey(ancestor.id)) {
        _startChildren(ancestor.id);
      }
      await _childRequests[ancestor.id];
    }
    if (!_disposed) notifyListeners();
  });

  InventoryNode? findCachedNode(String nodeId) {
    final roots = _roots;
    if (roots != null) {
      for (final root in roots) {
        if (root.id == nodeId) return root;
      }
    }
    for (final children in _children.values) {
      for (final child in children) {
        if (child.id == nodeId) return child;
      }
    }
    return null;
  }

  /// UI-side drop check; engine remains the authority on commit.
  bool canAcceptDrop({
    required InventoryNode dragged,
    required InventoryNode target,
  }) {
    if (!target.type.canContain) return false;
    if (target.id == dragged.id) return false;
    return !_isCachedAncestor(ancestorId: dragged.id, nodeId: target.id);
  }

  /// True when [dragged] and [target] share the same parent (peers).
  bool canAcceptReorder({
    required InventoryNode dragged,
    required InventoryNode target,
  }) {
    if (dragged.id == target.id) return false;
    return dragged.parentId == target.parentId;
  }

  /// Single gesture: nest into a container/location, or reorder peers.
  ///
  /// [verticalRatio] is 0 at the top of the target row and 1 at the bottom.
  /// Peer rows use the upper/lower half (or edge strips when the target can
  /// also nest) so changing parent is not required to change order.
  OrganizeDropKind resolveOrganizeDrop({
    required InventoryNode dragged,
    required InventoryNode target,
    double verticalRatio = 0.5,
  }) {
    if (dragged.id == target.id) return OrganizeDropKind.none;
    final ratio = verticalRatio.clamp(0.0, 1.0);
    // Already inside this parent: nest would be a no-op — reject center drops.
    final nest = canAcceptDrop(dragged: dragged, target: target) &&
        dragged.parentId != target.id;
    final reorder = canAcceptReorder(dragged: dragged, target: target);

    if (reorder) {
      if (nest) {
        // Edge strips = reorder; center = change parent into the target.
        if (ratio < 0.28) return OrganizeDropKind.reorderBefore;
        if (ratio > 0.72) return OrganizeDropKind.reorderAfter;
        return OrganizeDropKind.nest;
      }
      return ratio < 0.5
          ? OrganizeDropKind.reorderBefore
          : OrganizeDropKind.reorderAfter;
    }
    if (nest) return OrganizeDropKind.nest;
    return OrganizeDropKind.none;
  }

  bool isSameParentDrop({
    required InventoryNode dragged,
    required InventoryNode target,
  }) =>
      dragged.parentId == target.id;

  Future<void> reorderSiblings({
    String? parentId,
    required List<String> orderedIds,
  }) => _trackOperation(() async {
    await _engine.reorderSiblings(
      space: space,
      parentId: parentId,
      orderedIds: orderedIds,
    );
    if (_disposed) return;
    await _refreshParent(parentId);
  });

  /// Places [nodeId] immediately before [beforeId] among siblings.
  Future<void> placeSiblingBefore({
    required String nodeId,
    required String beforeId,
  }) => _placeSiblingRelative(
        nodeId: nodeId,
        anchorId: beforeId,
        after: false,
      );

  /// Places [nodeId] immediately after [afterId] among siblings.
  Future<void> placeSiblingAfter({
    required String nodeId,
    required String afterId,
  }) => _placeSiblingRelative(
        nodeId: nodeId,
        anchorId: afterId,
        after: true,
      );

  Future<void> _placeSiblingRelative({
    required String nodeId,
    required String anchorId,
    required bool after,
  }) => _trackOperation(() async {
    final node = await _engine.getNode(nodeId);
    final anchor = await _engine.getNode(anchorId);
    if (node.parentId != anchor.parentId) {
      throw const InventoryException(InventoryErrorCode.invalidHierarchy);
    }
    final siblings = node.parentId == null
        ? await _engine.getRootLocations(space: space)
        : await _engine.getChildren(node.parentId!);
    final ids = [for (final s in siblings) s.id];
    ids.remove(nodeId);
    final index = ids.indexOf(anchorId);
    if (index < 0) {
      throw const InventoryException(InventoryErrorCode.nodeNotFound);
    }
    ids.insert(after ? index + 1 : index, nodeId);
    await _engine.reorderSiblings(
      space: space,
      parentId: node.parentId,
      orderedIds: ids,
    );
    if (_disposed) return;
    await _refreshParent(node.parentId);
  });

  Future<void> moveSibling({
    required String nodeId,
    required int delta,
  }) => _trackOperation(() async {
    final node = await _engine.getNode(nodeId);
    final siblings = node.parentId == null
        ? await _engine.getRootLocations(space: space)
        : await _engine.getChildren(node.parentId!);
    final ids = [for (final s in siblings) s.id];
    final index = ids.indexOf(nodeId);
    if (index < 0) {
      throw const InventoryException(InventoryErrorCode.nodeNotFound);
    }
    final next = index + delta;
    if (next < 0 || next >= ids.length) return;
    ids.removeAt(index);
    ids.insert(next, nodeId);
    await _engine.reorderSiblings(
      space: space,
      parentId: node.parentId,
      orderedIds: ids,
    );
    if (_disposed) return;
    await _refreshParent(node.parentId);
  });

  bool _isCachedAncestor({
    required String ancestorId,
    required String nodeId,
  }) {
    var currentId = nodeId;
    final seen = <String>{};
    while (true) {
      if (currentId == ancestorId) return true;
      if (!seen.add(currentId)) return true;
      final node = findCachedNode(currentId);
      final parentId = node?.parentId;
      if (parentId == null) return false;
      currentId = parentId;
    }
  }

  void retryChildren(String nodeId) {
    if (_disposed ||
        !_expanded.contains(nodeId) ||
        _childRequests.containsKey(nodeId)) {
      return;
    }
    _startChildren(nodeId);
    notifyListeners();
  }

  void _startChildren(String nodeId) {
    _childErrors.remove(nodeId);
    _childRequests[nodeId] = _finishChildren(nodeId, _loadChildren(nodeId));
  }

  Future<void> _loadChildren(String nodeId) async {
    final version = _readVersions[nodeId];
    try {
      final children = await _engine.getChildren(nodeId);
      if (_isCurrentRead(nodeId, version)) _children[nodeId] = children;
    } catch (_) {
      if (_isCurrentRead(nodeId, version)) _childErrors.add(nodeId);
    }
  }

  bool _isCurrentRead(String? parentId, int? version) =>
      !_disposed && _readVersions[parentId] == version;

  Future<void> _finishChildren(String nodeId, Future<void> request) async {
    try {
      await request;
    } finally {
      _childRequests.remove(nodeId);
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> createNode({
    required String name,
    required NodeType type,
    String? parentId,
  }) => _trackOperation(
    () => _createNode(name: name, type: type, parentId: parentId),
  );

  Future<void> _createNode({
    required String name,
    required NodeType type,
    String? parentId,
  }) async {
    await _engine.createNode(
      name: name,
      type: type,
      space: space,
      parentId: parentId,
    );
    _invalidateSubtreeTotals();
    await _refreshParent(parentId, expandParent: true);
  }

  Future<void> _loadPendingTotals() async {
    while (_pendingTotals.isNotEmpty && !_disposed) {
      final batch = _pendingTotals.toList();
      _pendingTotals.clear();
      try {
        final totals = await _engine.getSubtreeFinancialTotals(batch);
        if (_disposed) return;
        for (final id in batch) {
          _subtreeTotals[id] = totals[id] ?? const SubtreeFinancialNone();
        }
      } on Exception {
        if (_disposed) return;
        for (final id in batch) {
          _subtreeTotals.putIfAbsent(id, () => const SubtreeFinancialNone());
        }
      }
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _finishTotals(Future<void> request) async {
    try {
      await request;
    } finally {
      _totalsRequest = null;
      if (!_disposed && _pendingTotals.isNotEmpty) {
        _totalsRequest = _finishTotals(_loadPendingTotals());
      }
    }
  }

  void _invalidateSubtreeTotals() {
    _subtreeTotals.clear();
    _pendingTotals.clear();
  }

  Future<InventoryNodeDetails> readNodeDetails(String nodeId) =>
      _trackOperation(() async {
        final path = await _engine.getPath(nodeId);
        return InventoryNodeDetails(node: path.last, path: path);
      });

  Future<List<InventoryNode>> readDestinationChildren(String? parentId) =>
      _trackOperation(
        () => parentId == null
            ? _engine.getRootLocations(space: space)
            : _engine.getChildren(parentId),
      );

  /// Flat list of containment candidates with path labels for in-form selectors.
  Future<List<({InventoryNode node, String pathLabel, int depth})>>
  listContainmentCandidates({String? excludingSubtreeRootId}) =>
      _trackOperation(() async {
        final excluded = <String>{};
        if (excludingSubtreeRootId != null) {
          excluded.add(excludingSubtreeRootId);
          Future<void> collectDescendants(String id) async {
            final children = await _engine.getChildren(id);
            for (final child in children) {
              excluded.add(child.id);
              if (child.type.canContain) await collectDescendants(child.id);
            }
          }

          final root = await _engine.getNode(excludingSubtreeRootId);
          if (root.type.canContain) {
            await collectDescendants(excludingSubtreeRootId);
          }
        }

        final results = <({InventoryNode node, String pathLabel, int depth})>[];
        Future<void> walk(InventoryNode node, List<String> pathNames) async {
          if (excluded.contains(node.id)) return;
          if (node.type.canContain) {
            results.add((
              node: node,
              pathLabel: [...pathNames, node.name].join(' → '),
              depth: pathNames.length,
            ));
            final children = await _engine.getChildren(node.id);
            for (final child in children) {
              await walk(child, [...pathNames, node.name]);
            }
          }
        }

        final roots = await _engine.getRootLocations(space: space);
        for (final root in roots) {
          await walk(root, const []);
        }
        return results;
      });

  Future<InventorySearchResponse> searchNodes(
    InventorySearchCriteria criteria,
  ) => _trackOperation(
    () => _engine.searchNodes(
      InventorySearchCriteria(
        name: criteria.name,
        type: criteria.type,
        branchId: criteria.branchId,
        space: space,
      ),
    ),
  );

  Future<InventoryNode> updateItemDetails(
    String nodeId, {
    required String name,
    String? condition,
    required int quantity,
    NodeValuation? valuation,
  }) => _trackOperation(() async {
    final node = await _engine.updateItemDetails(
      nodeId,
      name: name,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
    );
    _invalidateSubtreeTotals();
    _applyConfirmedNode(node);
    await _refreshParent(node.parentId);
    return node;
  });

  /// Saves field edits and an optional parent change in one engine transaction.
  Future<InventoryNode> saveEditedNode({
    required String nodeId,
    required String name,
    String? condition,
    int? quantity,
    NodeValuation? valuation,
    required bool isItem,
    NodeType? itemKind,
    String? newParentId,
    required bool move,
    String? barcodeRef,
    String? purchaseDate,
    int? purchasePriceCents,
    String? purchasePlace,
    ItemObjective objective = ItemObjective.none,
    String? photoRelPath,
    String? iconKey,
  }) => _trackOperation(() async {
    final previous = await _engine.getNode(nodeId);
    final destinationPath = !move || newParentId == null
        ? <InventoryNode>[]
        : await _engine.getPath(newParentId);
    final saved = await _engine.updateAndOptionallyMove(
      nodeId,
      name: name,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
      isItem: isItem,
      itemKind: itemKind,
      newParentId: newParentId,
      move: move,
      barcodeRef: barcodeRef,
      purchaseDate: purchaseDate,
      purchasePriceCents: purchasePriceCents,
      purchasePlace: purchasePlace,
      objective: objective,
      photoRelPath: photoRelPath,
      iconKey: iconKey,
    );
    if (_disposed) return saved;
    _invalidateSubtreeTotals();
    if (!saved.type.canContain) {
      _expanded.remove(saved.id);
      _children.remove(saved.id);
    }
    if (!move) {
      _applyConfirmedNode(saved);
      await _refreshParent(saved.parentId);
      return saved;
    }
    final parents = {previous.parentId, saved.parentId};
    for (final parentId in parents) {
      _detachFromParentCache(parentId, nodeId);
    }
    for (final ancestor in destinationPath) {
      _expanded.add(ancestor.id);
      if (!parents.contains(ancestor.id) &&
          !_children.containsKey(ancestor.id) &&
          !_childRequests.containsKey(ancestor.id)) {
        _startChildren(ancestor.id);
      }
    }
    if (_roots == null && _rootRequest == null) loadRoots();
    notifyListeners();
    await Future.wait([
      for (final parentId in parents) _refreshParent(parentId),
      for (final ancestor in destinationPath) ?_childRequests[ancestor.id],
      ?_rootRequest,
    ]);
    return saved;
  });

  Future<InventoryNode> moveNode(
    String nodeId,
    String? newParentId, {
    bool revealDestination = true,
  }) => _trackOperation(() async {
    final previous = await _engine.getNode(nodeId);
    final destinationPath = newParentId == null || !revealDestination
        ? <InventoryNode>[]
        : await _engine.getPath(newParentId);
    final moved = await _engine.moveNode(nodeId, newParentId);
    if (_disposed) return moved;
    _invalidateSubtreeTotals();

    final parents = {previous.parentId, moved.parentId};
    // Pre-move snapshots must not restore the old edge, even on read failure.
    for (final parentId in parents) {
      _detachFromParentCache(parentId, nodeId);
    }
    for (final ancestor in destinationPath) {
      _expanded.add(ancestor.id);
      if (!parents.contains(ancestor.id) &&
          !_children.containsKey(ancestor.id) &&
          !_childRequests.containsKey(ancestor.id)) {
        _startChildren(ancestor.id);
      }
    }
    if (_roots == null && _rootRequest == null) loadRoots();
    notifyListeners();
    await Future.wait([
      for (final parentId in parents) _refreshParent(parentId),
      for (final ancestor in destinationPath) ?_childRequests[ancestor.id],
      ?_rootRequest,
    ]);
    return moved;
  });

  /// Moves [nodeId] under [newParentId] (nullable = root) then places it at
  /// [index] among the destination siblings. Same parent is allowed (reorder).
  Future<InventoryNode> relocateNode({
    required String nodeId,
    required String? newParentId,
    required int index,
  }) => _trackOperation(() async {
    final previous = await _engine.getNode(nodeId);
    final parentChanged = previous.parentId != newParentId;
    if (parentChanged) {
      await _engine.moveNode(nodeId, newParentId);
    }
    final siblings = newParentId == null
        ? await _engine.getRootLocations(space: space)
        : await _engine.getChildren(newParentId);
    final ids = [for (final s in siblings) s.id];
    ids.remove(nodeId);
    final clamped = index.clamp(0, ids.length);
    ids.insert(clamped, nodeId);
    await _engine.reorderSiblings(
      space: space,
      parentId: newParentId,
      orderedIds: ids,
    );
    final moved = await _engine.getNode(nodeId);
    if (_disposed) return moved;
    _invalidateSubtreeTotals();
    final parents = {previous.parentId, moved.parentId};
    for (final parentId in parents) {
      _detachFromParentCache(parentId, nodeId);
    }
    if (newParentId != null) {
      final destinationPath = await _engine.getPath(newParentId);
      for (final ancestor in destinationPath) {
        _expanded.add(ancestor.id);
        if (!parents.contains(ancestor.id) &&
            !_children.containsKey(ancestor.id) &&
            !_childRequests.containsKey(ancestor.id)) {
          _startChildren(ancestor.id);
        }
      }
      await Future.wait([
        for (final parentId in parents) _refreshParent(parentId),
        for (final ancestor in destinationPath) ?_childRequests[ancestor.id],
        ?_rootRequest,
      ]);
    } else {
      if (_roots == null && _rootRequest == null) loadRoots();
      await Future.wait([
        for (final parentId in parents) _refreshParent(parentId),
        ?_rootRequest,
      ]);
    }
    if (!_disposed) notifyListeners();
    return moved;
  });

  /// Active siblings under [parentId] (null = roots), excluding [excludingId].
  Future<List<InventoryNode>> listSiblings({
    String? parentId,
    String? excludingId,
  }) => _trackOperation(() async {
    final siblings = parentId == null
        ? await _engine.getRootLocations(space: space)
        : await _engine.getChildren(parentId);
    if (excludingId == null) return siblings;
    return [for (final s in siblings) if (s.id != excludingId) s];
  });

  /// Withdraws an active item and removes it from the active tree cache.
  Future<InventoryNode> withdrawItem(String nodeId, WithdrawalReason reason) =>
      _trackOperation(() async {
        final previous = await _engine.getNode(nodeId);
        final withdrawn = await _engine.withdrawItem(nodeId, reason);
        if (_disposed) return withdrawn;
        _invalidateSubtreeTotals();
        _detachFromParentCache(previous.parentId, nodeId);
        _forgetSubtree(nodeId);
        notifyListeners();
        await _refreshParent(previous.parentId);
        return withdrawn;
      });

  /// Permanently deletes an active node and removes it from the tree cache.
  Future<void> deleteNodePermanently(String nodeId) =>
      _trackOperation(() async {
        final previous = await _engine.getNode(nodeId);
        final docPaths = await _engine.deleteNodePermanently(nodeId);
        await GoodsPhotoStore().deleteRel(previous.photoRelPath);
        final docs = GoodsDocumentStore();
        for (final path in docPaths) {
          await docs.deleteRel(path);
        }
        if (_disposed) return;
        _invalidateSubtreeTotals();
        _detachFromParentCache(previous.parentId, nodeId);
        _forgetSubtree(nodeId);
        notifyListeners();
        await _refreshParent(previous.parentId);
      });

  Future<List<NodeDocument>> listNodeDocuments(String nodeId) =>
      _trackOperation(() => _engine.listNodeDocuments(nodeId));

  Future<bool> nodeHasDocuments(String nodeId) =>
      _trackOperation(() => _engine.nodeHasDocuments(nodeId));

  Future<List<String>> syncNodeDocuments(
    String nodeId, {
    required List<NodeDocumentWrite> documents,
  }) => _trackOperation(
    () => _engine.syncNodeDocuments(nodeId, documents: documents),
  );

  Future<List<InventoryNode>> readWithdrawnItems() =>
      _trackOperation(() => _engine.getWithdrawnItems(space: space));

  /// Historical details without reconstructing a physical path.
  Future<InventoryNode> readWithdrawnNodeDetails(String nodeId) =>
      _trackOperation(() async {
        final node = await _engine.getNode(nodeId);
        if (node.status != NodeStatus.withdrawn) {
          throw const InventoryException(InventoryErrorCode.nodeNotFound);
        }
        return node;
      });

  void _detachFromParentCache(String? parentId, String nodeId) {
    _readVersions[parentId] = (_readVersions[parentId] ?? 0) + 1;
    if (parentId == null) {
      _roots = _roots?.where((node) => node.id != nodeId).toList();
    } else {
      final children = _children[parentId];
      if (children != null) {
        _children[parentId] = children
            .where((node) => node.id != nodeId)
            .toList();
      }
    }
  }

  void _forgetSubtree(String nodeId) {
    _readVersions[nodeId] = (_readVersions[nodeId] ?? 0) + 1;
    _expanded.remove(nodeId);
    _children.remove(nodeId);
    _childErrors.remove(nodeId);
  }

  Future<InventoryNode> updateNodeDetails(
    String nodeId, {
    required String name,
    String? condition,
    int? quantity,
  }) => _trackOperation(() async {
    final node = await _engine.updateDetails(
      nodeId,
      name: name,
      condition: condition,
      quantity: quantity,
    );
    _invalidateSubtreeTotals();
    _applyConfirmedNode(node);
    await _refreshParent(node.parentId);
    return node;
  });

  Future<InventoryNode> createNodeAt({
    required String name,
    required NodeType type,
    String? parentId,
    int? quantity,
    NodeValuation? valuation,
    String? condition,
    int? stockReference,
    int? targetPriceCents,
    bool? showAdvanced,
    String? barcodeRef,
    String? purchaseDate,
    int? purchasePriceCents,
    String? purchasePlace,
    ItemObjective objective = ItemObjective.none,
    String? photoRelPath,
    String? iconKey,
  }) => _trackOperation(() async {
    final node = await _engine.createNode(
      name: name,
      type: type,
      space: space,
      parentId: parentId,
      quantity: quantity,
      valuation: valuation,
      condition: condition,
      stockReference: stockReference,
      targetPriceCents: targetPriceCents,
      showAdvanced: showAdvanced,
      barcodeRef: barcodeRef,
      purchaseDate: purchaseDate,
      purchasePriceCents: purchasePriceCents,
      purchasePlace: purchasePlace,
      objective: objective,
      photoRelPath: photoRelPath,
      iconKey: iconKey,
    );
    _invalidateSubtreeTotals();
    await _refreshParent(parentId, expandParent: true);
    return node;
  });

  Future<InventoryNode> updateShowAdvanced(
    String nodeId, {
    required bool showAdvanced,
  }) => _trackOperation(() async {
    final node = await _engine.updateShowAdvanced(
      nodeId,
      showAdvanced: showAdvanced,
    );
    _applyConfirmedNode(node);
    return node;
  });

  Future<InventoryNode> updateToBuyNeed(
    String nodeId, {
    required String name,
    String? parentId,
    required int remainingQuantity,
    int? targetPriceCents,
    String? iconKey,
  }) => _trackOperation(() async {
    final before = await _engine.getNode(nodeId);
    final previousParent = before.parentId;
    final node = await _engine.updateToBuyNeed(
      nodeId,
      name: name,
      parentId: parentId,
      remainingQuantity: remainingQuantity,
      targetPriceCents: targetPriceCents,
      iconKey: iconKey,
    );
    if (_disposed) return node;
    _invalidateSubtreeTotals();
    _applyConfirmedNode(node);
    if (previousParent != node.parentId) {
      await _refreshParent(previousParent);
    }
    await _refreshParent(node.parentId, expandParent: true);
    return node;
  });

  Future<InventoryNode> acquireNeed(
    String needId, {
    required int quantity,
    required InventorySpace destinationSpace,
    String? destinationParentId,
    String? existingStockProductId,
    StockAcquireMode stockMode = StockAcquireMode.createNew,
    int? paidPriceCents,
    NodeValuation? goodsValuation,
  }) => _trackOperation(() async {
    final before = await _engine.getNode(needId);
    final previousParent = before.parentId;
    final node = await _engine.acquireNeed(
      needId,
      quantity: quantity,
      destinationSpace: destinationSpace,
      destinationParentId: destinationParentId,
      existingStockProductId: existingStockProductId,
      stockMode: stockMode,
      paidPriceCents: paidPriceCents,
      goodsValuation: goodsValuation,
    );
    if (_disposed) return node;
    _invalidateSubtreeTotals();
    await _refreshParent(previousParent);
    if (node.parentId != null && node.parentId != previousParent) {
      await _refreshParent(node.parentId);
    }
    if (node.status != NodeStatus.active) {
      // Fully acquired: drop stale cache entry under the old parent.
      notifyListeners();
    } else {
      _applyConfirmedNode(node);
    }
    return node;
  });

  Future<InventoryNode> abandonNeed(String needId) => _trackOperation(() async {
    final before = await _engine.getNode(needId);
    final previousParent = before.parentId;
    final node = await _engine.abandonNeed(needId);
    if (_disposed) return node;
    _invalidateSubtreeTotals();
    await _refreshParent(previousParent);
    notifyListeners();
    return node;
  });

  Future<List<PurchaseLedgerEntryNamed>> readRecentPurchaseEvents() =>
      _trackOperation(() => _engine.getRecentPurchaseEvents());

  Future<InventoryNode> cycleStockLevel(String nodeId) =>
      _trackOperation(() async {
        final node = await _engine.cycleStockLevel(nodeId);
        if (_disposed) return node;
        _applyConfirmedNode(node);
        return node;
      });

  Future<InventoryNode> setStockLevel(String nodeId, StockLevel level) =>
      _trackOperation(() async {
        final node = await _engine.setStockLevel(nodeId, level);
        if (_disposed) return node;
        _applyConfirmedNode(node);
        return node;
      });

  Future<InventoryNode> updateStockProduct(
    String nodeId, {
    required String name,
    String? parentId,
    int? stockReference,
    String? iconKey,
  }) => _trackOperation(() async {
    final before = await _engine.getNode(nodeId);
    final previousParent = before.parentId;
    final node = await _engine.updateStockProduct(
      nodeId,
      name: name,
      parentId: parentId,
      stockReference: stockReference,
      iconKey: iconKey,
    );
    if (_disposed) return node;
    _invalidateSubtreeTotals();
    _applyConfirmedNode(node);
    if (previousParent != node.parentId) {
      await _refreshParent(previousParent);
    }
    await _refreshParent(node.parentId, expandParent: true);
    return node;
  });

  Future<List<StockLedgerEntry>> readStockMovements(String nodeId) =>
      _trackOperation(() => _engine.getStockMovements(nodeId));

  Future<List<StockLedgerEntryNamed>> readRecentStockMovements() =>
      _trackOperation(() => _engine.getRecentStockMovements());

  void _applyConfirmedNode(InventoryNode node) {
    if (_disposed) return;
    final parentId = node.parentId;
    _readVersions[parentId] = (_readVersions[parentId] ?? 0) + 1;
    final cached = parentId == null ? _roots : _children[parentId];
    if (cached == null) return;
    final updated = [
      for (final entry in cached) entry.id == node.id ? node : entry,
    ];
    if (parentId == null) {
      _roots = updated;
    } else {
      _children[parentId] = updated;
    }
    notifyListeners();
  }

  Future<void> _refreshParent(
    String? parentId, {
    bool expandParent = false,
  }) async {
    if (_disposed) return;
    if (parentId == null) {
      while (true) {
        final pending = _rootRequest;
        if (pending == null) break;
        await pending;
        if (_disposed) return;
      }
      if (_disposed) return;
      loadRoots();
      final refresh = _rootRequest;
      if (refresh != null) await refresh;
    } else {
      while (true) {
        final pending = _childRequests[parentId];
        if (pending == null) break;
        await pending;
        if (_disposed) return;
      }
      if (_disposed) return;
      if (expandParent) _expanded.add(parentId);
      _startChildren(parentId);
      notifyListeners();
      final refresh = _childRequests[parentId];
      if (refresh != null) await refresh;
    }
  }

  Future<T> _trackOperation<T>(Future<T> Function() action) async {
    if (_disposed) throw StateError('The inventory controller is disposed.');
    final completion = Completer<void>();
    _pendingOperations.add(completion.future);
    try {
      return await action();
    } finally {
      _pendingOperations.remove(completion.future);
      completion.complete();
    }
  }

  Future<void> waitForPendingOperations() async {
    await Future.wait([
      ?_rootRequest,
      ?_totalsRequest,
      ..._childRequests.values,
      ..._pendingOperations,
    ]);
  }

  /// Drops all presentation caches after an inventory replacement.
  void resetAfterRestore() {
    if (_disposed) return;
    for (final key in _readVersions.keys.toList()) {
      _readVersions[key] = (_readVersions[key] ?? 0) + 1;
    }
    _readVersions[null] = (_readVersions[null] ?? 0) + 1;
    _children.clear();
    _childRequests.clear();
    _childErrors.clear();
    _expanded.clear();
    _initialLocationsExpandDone = false;
    _initialLocationsExpandRequest = null;
    _invalidateSubtreeTotals();
    _roots = null;
    _rootError = false;
    _rootRequest = null;
    notifyListeners();
    loadRoots();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
