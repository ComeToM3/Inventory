import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/domain/inventory_engine.dart';
import '../core/domain/inventory_models.dart';

class InventoryTreeEntry {
  const InventoryTreeEntry({required this.node, required this.depth});

  final InventoryNode node;
  final int depth;
}

class InventoryTreeController extends ChangeNotifier {
  InventoryTreeController(this._engine);

  final InventoryEngine _engine;
  final _children = <String, List<InventoryNode>>{};
  final _childRequests = <String, Future<void>>{};
  final _readVersions = <String?, int>{};
  final _pendingOperations = <Future<void>>{};
  final _expanded = <String>{};
  final _childErrors = <String>{};
  List<InventoryNode>? _roots;
  Future<void>? _rootRequest;
  bool _rootError = false;
  bool _disposed = false;

  List<InventoryNode>? get roots => _roots;
  bool get loadingRoots => _rootRequest != null;
  bool get rootError => _rootError;

  bool isExpanded(String nodeId) => _expanded.contains(nodeId);
  bool isLoadingChildren(String nodeId) => _childRequests.containsKey(nodeId);
  bool hasChildError(String nodeId) => _childErrors.contains(nodeId);

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
      final roots = await _engine.getRootLocations();
      if (_isCurrentRead(null, version)) _roots = roots;
    } on Exception {
      if (_isCurrentRead(null, version)) _rootError = true;
    }
  }

  Future<void> _finishRoots(Future<void> request) async {
    try {
      await request;
    } finally {
      _rootRequest = null;
      if (!_disposed) notifyListeners();
    }
  }

  void toggle(InventoryNode node) {
    if (_disposed || !node.type.canContain) return;
    if (_expanded.remove(node.id)) {
      notifyListeners();
      return;
    }
    _expanded.add(node.id);
    if (!_children.containsKey(node.id) &&
        !_childRequests.containsKey(node.id)) {
      _startChildren(node.id);
    }
    notifyListeners();
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
    } on Exception {
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
    await _engine.createNode(name: name, type: type, parentId: parentId);
    await _refreshParent(parentId, expandParent: true);
  }

  Future<InventoryNodeDetails> readNodeDetails(String nodeId) =>
      _trackOperation(() async {
        final path = await _engine.getPath(nodeId);
        final node = path.last;
        final categories = node.type.isItem
            ? await _engine.getNodeCategories(nodeId)
            : <InventoryCategory>[];
        return InventoryNodeDetails(
          node: node,
          path: path,
          categories: categories,
        );
      });

  Future<List<InventoryNode>> readDestinationChildren(String? parentId) =>
      _trackOperation(
        () => parentId == null
            ? _engine.getRootLocations()
            : _engine.getChildren(parentId),
      );

  Future<List<InventoryCategory>> readCategories() =>
      _trackOperation(_engine.getCategories);

  Future<InventorySearchResponse> searchNodes(
    InventorySearchCriteria criteria,
  ) => _trackOperation(() => _engine.searchNodes(criteria));

  Future<({InventoryNode node, List<InventoryCategory> categories})>
  updateItemDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    required int quantity,
    required NodeValuation valuation,
    required Iterable<String> categoryIds,
    required Iterable<String> newCategoryNames,
  }) => _trackOperation(() async {
    final result = await _engine.updateItemDetails(
      nodeId,
      name: name,
      description: description,
      condition: condition,
      quantity: quantity,
      valuation: valuation,
      categoryIds: categoryIds,
      newCategoryNames: newCategoryNames,
    );
    _applyConfirmedNode(result.node);
    await _refreshParent(result.node.parentId);
    return result;
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

    final parents = {previous.parentId, moved.parentId};
    // Pre-move snapshots must not restore the old edge, even on read failure.
    for (final parentId in parents) {
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

  Future<InventoryNode> updateNodeDetails(
    String nodeId, {
    required String name,
    String? description,
    String? condition,
    int? quantity,
  }) => _trackOperation(() async {
    final node = await _engine.updateDetails(
      nodeId,
      name: name,
      description: description,
      condition: condition,
      quantity: quantity,
    );
    _applyConfirmedNode(node);
    await _refreshParent(node.parentId);
    return node;
  });

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
      ..._childRequests.values,
      ..._pendingOperations,
    ]);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
