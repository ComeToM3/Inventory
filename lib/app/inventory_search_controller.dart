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
  int _categoriesGeneration = 0;
  bool _disposed = false;
  String _name = '';
  NodeType? _type;
  String? _categoryId;
  List<InventoryNode>? _branchPath;
  List<InventorySearchResult> _results = const [];
  List<InventoryCategory> _categories = const [];
  bool _loading = false;
  bool _loadingCategories = false;
  String? _readError;
  String? _categoriesError;

  String get name => _name;
  NodeType? get type => _type;
  String? get categoryId => _categoryId;
  List<InventoryNode>? get branchPath => _branchPath;
  List<InventorySearchResult> get results => _results;
  List<InventoryCategory> get categories => _categories;
  bool get loading => _loading;
  bool get loadingCategories => _loadingCategories;
  String? get readError => _readError;
  String? get categoriesError => _categoriesError;

  InventorySearchCriteria get criteria => InventorySearchCriteria(
    name: _name,
    type: _type,
    categoryId: _categoryId,
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

  void setCategory(String? categoryId) {
    if (_disposed || categoryId == _categoryId) return;
    _categoryId = categoryId;
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
    _categoryId = null;
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
      if (_isCurrent(generation)) {
        final path = response.branchPath;
        if (current.branchId != null &&
            (path == null ||
                path.isEmpty ||
                path.last.id != current.branchId)) {
          throw const InventoryException(InventoryErrorCode.invalidStoredData);
        }
        _results = response.results;
        if (current.branchId != null) {
          _branchPath = path;
        }
      }
    } on InventoryException catch (error) {
      if (_isCurrent(generation)) {
        _readError = switch (error.code) {
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive ||
          InventoryErrorCode.parentCannotContain
              when current.branchId != null =>
            AppStrings.searchBranchUnavailable,
          InventoryErrorCode.categoryNotFound =>
            AppStrings.searchCategoryUnavailable,
          _ => AppStrings.searchReadError,
        };
      }
    } on Exception {
      if (_isCurrent(generation)) _readError = AppStrings.searchReadError;
    } finally {
      if (_isCurrent(generation)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadCategories() async {
    if (_disposed) return;
    final generation = ++_categoriesGeneration;
    _loadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      final categories = await _inventory.readCategories();
      if (!_disposed && generation == _categoriesGeneration) {
        _categories = categories;
      }
    } on Exception {
      if (!_disposed && generation == _categoriesGeneration) {
        _categoriesError = AppStrings.categoriesReadError;
      }
    } finally {
      if (!_disposed && generation == _categoriesGeneration) {
        _loadingCategories = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _readGeneration;

  @override
  void dispose() {
    _disposed = true;
    _readGeneration++;
    _categoriesGeneration++;
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
