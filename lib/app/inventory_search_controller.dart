import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

class InventorySearchController extends ChangeNotifier {
  InventorySearchController(this._inventory);

  final InventoryTreeController _inventory;
  Timer? _debounce;
  int _readGeneration = 0;
  bool _disposed = false;
  String _name = '';
  NodeType? _type;
  List<InventoryNode>? _branchPath;
  List<InventorySearchResult> _results = const [];
  bool _loading = false;
  String? _readError;

  String get name => _name;
  NodeType? get type => _type;
  List<InventoryNode>? get branchPath => _branchPath;
  List<InventorySearchResult> get results => _results;
  bool get loading => _loading;
  String? get readError => _readError;

  InventorySearchCriteria get criteria => InventorySearchCriteria(
    name: _name,
    type: _type,
    branchId: _branchPath?.last.id,
  );

  void setName(String name) {
    if (_disposed || name == _name) return;
    _name = name;
    _debounce?.cancel();
    final generation = ++_readGeneration;
    final current = criteria;
    _readError = null;
    if (current.isEmpty) {
      _results = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _debounce = null;
      unawaited(_read(current, generation));
    });
  }

  void setType(NodeType? type) {
    if (_disposed || type == _type) return;
    _type = type;
    unawaited(refresh());
  }

  void setBranch(List<InventoryNode> path) {
    if (_disposed) return;
    if (path.isEmpty) throw ArgumentError.value(path, 'path');
    _branchPath = List.unmodifiable(path);
    unawaited(refresh());
  }

  void resetFilters() {
    if (_disposed) return;
    _type = null;
    _branchPath = null;
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = null;
    final generation = ++_readGeneration;
    final current = criteria;
    _readError = null;
    if (current.isEmpty) {
      _results = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    await _read(current, generation);
  }

  Future<void> _read(InventorySearchCriteria current, int generation) async {
    try {
      final response = await _inventory.searchNodes(current);
      if (_disposed || generation != _readGeneration) return;
      _results = response.results;
      if (response.branchPath != null) {
        _branchPath = List.unmodifiable(response.branchPath!);
      }
      _readError = null;
    } on InventoryException catch (error) {
      if (_disposed || generation != _readGeneration) return;
      _results = const [];
      _readError = switch (error.code) {
        InventoryErrorCode.parentNotFound ||
        InventoryErrorCode.parentInactive ||
        InventoryErrorCode.parentCannotContain ||
        InventoryErrorCode.inventoryMismatch => AppStrings.searchBranchUnavailable,
        _ => AppStrings.searchReadError,
      };
    } on Exception {
      if (_disposed || generation != _readGeneration) return;
      _results = const [];
      _readError = AppStrings.searchReadError;
    } finally {
      if (!_disposed && generation == _readGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

class SearchBranchController extends ChangeNotifier {
  SearchBranchController(this._inventory);

  final InventoryTreeController _inventory;
  List<InventoryNode> _path = const [];
  List<InventoryNode> _children = const [];
  bool _loading = false;
  bool _disposed = false;
  int _readGeneration = 0;
  String? _readError;

  List<InventoryNode> get path => _path;
  List<InventoryNode> get children => _children;
  bool get loading => _loading;
  String? get readError => _readError;
  bool get canGoUp => _path.isNotEmpty;
  bool get canChoose => _path.isNotEmpty && !_loading && _readError == null;

  Future<void> load() => _read(_path);

  Future<void> enter(InventoryNode node) {
    if (_disposed || _loading) return Future.value();
    if (!_children.any((child) => child.id == node.id)) {
      throw ArgumentError.value(node.id, 'node');
    }
    return _read([..._path, node]);
  }

  Future<void> goUp() {
    if (_disposed || _loading) return Future.value();
    if (!canGoUp) throw StateError('There is no parent level available.');
    return _read(_path.take(_path.length - 1).toList());
  }

  Future<void> _read(List<InventoryNode> path) async {
    if (_disposed) return;
    final generation = ++_readGeneration;
    _path = List.unmodifiable(path);
    _children = const [];
    _loading = true;
    _readError = null;
    notifyListeners();
    try {
      final children = await _inventory.readDestinationChildren(
        _path.lastOrNull?.id,
      );
      if (!_disposed && generation == _readGeneration) {
        _children = children.where((node) => node.type.canContain).toList();
      }
    } on Exception {
      if (!_disposed && generation == _readGeneration) {
        _readError = AppStrings.searchBranchReadError;
      }
    } finally {
      if (!_disposed && generation == _readGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _readGeneration++;
    super.dispose();
  }
}
