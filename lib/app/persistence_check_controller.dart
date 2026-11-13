import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/database/inventory_database.dart';
import 'app_strings.dart';

class PersistenceCheckController extends ChangeNotifier {
  PersistenceCheckController(this._database);

  final InventoryDatabase _database;
  Future<void>? _pendingOperation;
  bool _disposed = false;
  bool _loading = true;
  bool _ready = false;
  bool _saving = false;
  String? _savedValue;
  String? _message;

  bool get loading => _loading;
  bool get ready => _ready;
  bool get saving => _saving;
  String? get savedValue => _savedValue;
  String? get message => _message;

  Future<void> initialize() {
    final operation = _load();
    _pendingOperation = operation;
    return operation;
  }

  Future<void> _load() async {
    try {
      final value = await _database.readVerificationValue();
      if (_disposed) return;
      _savedValue = value;
      _ready = true;
    } catch (_) {
      if (_disposed) return;
      _message = AppStrings.databaseOpenError;
    } finally {
      _loading = false;
      _notifyIfActive();
    }
  }

  Future<void> save(String value) {
    if (_disposed || !_ready || _saving) return Future.value();
    _saving = true;
    _message = null;
    final operation = _save(value);
    _pendingOperation = operation;
    notifyListeners();
    return operation;
  }

  Future<void> _save(String value) async {
    try {
      await _database.saveVerificationValue(value);
      if (_disposed) return;
      _savedValue = value;
      _message = AppStrings.saveSuccess;
    } catch (_) {
      if (_disposed) return;
      _message = AppStrings.saveError;
    } finally {
      _saving = false;
      _notifyIfActive();
    }
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_closeAfterPendingOperation());
    super.dispose();
  }

  Future<void> _closeAfterPendingOperation() async {
    try {
      await _pendingOperation;
      await _database.close();
    } catch (_) {
      debugPrint('Impossible de fermer la base locale.');
    }
  }
}
