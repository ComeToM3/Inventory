import 'package:flutter/foundation.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

class NodeMoveController extends ChangeNotifier {
  NodeMoveController(
    this._inventory,
    this.node, {
    this.revealDestination = true,
  });

  final InventoryTreeController _inventory;
  final InventoryNode node;
  final bool revealDestination;
  List<InventoryNode> _path = [];
  List<InventoryNode> _children = [];
  bool _loading = false;
  bool _disposed = false;
  int _readGeneration = 0;
  String? _readError;
  String? _moveError;
  Future<bool>? _moveRequest;

  List<InventoryNode> get children => _children;
  bool get loading => _loading;
  bool get moving => _moveRequest != null;
  bool get canGoUp => _path.isNotEmpty && !moving;
  String? get readError => _readError;
  String? get moveError => _moveError;
  String? get parentId => _path.lastOrNull?.id;
  String get destinationPath => _path.isEmpty
      ? AppStrings.inventoryRoot
      : _path.map((part) => part.name).join(' → ');
  bool get isCurrentParent => parentId == node.parentId;
  bool get canChoose =>
      !_loading &&
      !moving &&
      _readError == null &&
      !isCurrentParent &&
      (_path.isNotEmpty || node.type.canBeRoot);

  Future<void> load() => _read(_path);

  Future<void> enter(InventoryNode destination) {
    if (!children.any((child) => child.id == destination.id)) {
      throw ArgumentError.value(destination.id, 'destination');
    }
    return _read([..._path, destination]);
  }

  Future<void> goUp() {
    if (!canGoUp) throw StateError('There is no parent level available.');
    return _read(_path.take(_path.length - 1).toList());
  }

  Future<void> _read(List<InventoryNode> path) async {
    if (_disposed || moving) return;
    final generation = ++_readGeneration;
    _path = path;
    _children = [];
    _loading = true;
    _readError = null;
    _moveError = null;
    notifyListeners();
    try {
      final children = await _inventory.readDestinationChildren(parentId);
      if (!_disposed && generation == _readGeneration) {
        // Pruning the moving node also makes its entire subtree unreachable.
        _children = children
            .where((child) => child.type.canContain && child.id != node.id)
            .toList();
      }
    } on Exception {
      if (!_disposed && generation == _readGeneration) {
        _readError = AppStrings.destinationReadError;
      }
    } finally {
      if (!_disposed && generation == _readGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> move() {
    final pending = _moveRequest;
    if (pending != null) return pending;
    if (_disposed || !canChoose) {
      throw StateError('No new destination has been selected.');
    }
    _moveError = null;
    _moveRequest = _finishMove(_move());
    notifyListeners();
    return _moveRequest!;
  }

  Future<bool> _move() async {
    try {
      await _inventory.moveNode(
        node.id,
        parentId,
        revealDestination: revealDestination,
      );
      return true;
    } on InventoryException catch (error) {
      if (!_disposed) {
        _moveError = switch (error.code) {
          InventoryErrorCode.cycleDetected => AppStrings.cyclicDestination,
          InventoryErrorCode.parentNotFound ||
          InventoryErrorCode.parentInactive ||
          InventoryErrorCode.parentCannotContain ||
          InventoryErrorCode.parentRequired ||
          InventoryErrorCode.invalidHierarchy => AppStrings.invalidDestination,
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
          _ => AppStrings.moveError,
        };
      }
      return false;
    } on Exception {
      if (!_disposed) _moveError = AppStrings.moveError;
      return false;
    }
  }

  Future<bool> _finishMove(Future<bool> request) async {
    try {
      return await request;
    } finally {
      _moveRequest = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _readGeneration++;
    super.dispose();
  }
}
