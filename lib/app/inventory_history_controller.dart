import 'package:flutter/foundation.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

class InventoryHistoryController extends ChangeNotifier {
  InventoryHistoryController(this._inventory);

  final InventoryTreeController _inventory;
  int _readGeneration = 0;
  bool _disposed = false;
  List<InventoryNode> _items = const [];
  bool _loading = false;
  String? _readError;

  List<InventoryNode> get items => _items;
  bool get loading => _loading;
  String? get readError => _readError;

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_readGeneration;
    _loading = true;
    _readError = null;
    notifyListeners();
    try {
      final items = await _inventory.readWithdrawnItems();
      if (!_disposed && generation == _readGeneration) {
        _items = items;
      }
    } on Exception {
      if (!_disposed && generation == _readGeneration) {
        _readError = AppStrings.historyReadError;
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
