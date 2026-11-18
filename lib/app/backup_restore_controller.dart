import 'package:flutter/foundation.dart';

import '../core/backup/backup_contract.dart';
import '../core/backup/backup_restorer.dart';
import '../core/database/inventory_database.dart';
import 'android_document_store.dart';
import 'app_strings.dart';

// BackupSnapshot lives in backup_contract.dart.

class BackupRestoreController extends ChangeNotifier {
  BackupRestoreController(
    InventoryDatabase database, {
    BackupRestorer? restorer,
    AndroidDocumentStore? documents,
  }) : _restorer = restorer ?? BackupRestorer(database),
       _documents = documents ?? AndroidDocumentStore();

  final BackupRestorer _restorer;
  final AndroidDocumentStore _documents;
  Future<BackupRestoreResult>? _request;
  BackupRestoreResult? _lastResult;
  BackupRestoreSummary? _pendingSummary;
  BackupSnapshot? _pendingSnapshot;
  bool _disposed = false;

  bool get busy => _request != null;
  BackupRestoreResult? get lastResult => _lastResult;
  BackupRestoreSummary? get pendingSummary => _pendingSummary;

  String? get statusMessage {
    final result = _lastResult;
    if (result == null) return null;
    return switch (result.outcome) {
      BackupRestoreOutcome.success => AppStrings.restoreSuccess,
      BackupRestoreOutcome.cancelled => AppStrings.restoreCancelled,
      BackupRestoreOutcome.rejected => AppStrings.restoreRejected,
      BackupRestoreOutcome.failed => AppStrings.restoreFailed,
    };
  }

  Future<BackupRestoreResult> restore({
    required Future<bool> Function(BackupRestoreSummary summary) confirm,
  }) {
    final pending = _request;
    if (pending != null) return pending;
    _lastResult = null;
    _pendingSummary = null;
    _pendingSnapshot = null;
    _request = _finish(_run(confirm));
    notifyListeners();
    return _request!;
  }

  Future<BackupRestoreResult> _run(
    Future<bool> Function(BackupRestoreSummary summary) confirm,
  ) async {
    try {
      final uri = await _documents.openDocument(
        mimeTypes: const ['application/octet-stream', '*/*'],
      );
      if (uri == null) {
        return const BackupRestoreResult(
          outcome: BackupRestoreOutcome.cancelled,
        );
      }

      final bytes = await _documents.readDocumentLimited(uri);
      final prepared = await _restorer.prepare(bytes);
      if (_disposed) {
        return const BackupRestoreResult(
          outcome: BackupRestoreOutcome.cancelled,
        );
      }
      _pendingSummary = prepared.summary;
      _pendingSnapshot = prepared.snapshot;
      notifyListeners();

      final accepted = await confirm(prepared.summary);
      if (!accepted) {
        _pendingSummary = null;
        _pendingSnapshot = null;
        return const BackupRestoreResult(
          outcome: BackupRestoreOutcome.cancelled,
        );
      }

      final snapshot = _pendingSnapshot;
      if (snapshot == null) {
        return const BackupRestoreResult(
          outcome: BackupRestoreOutcome.failed,
          errorCode: BackupErrorCode.restoreFailed,
        );
      }
      await _restorer.apply(snapshot);
      await _restorer.acknowledgeJournal();
      _pendingSummary = null;
      _pendingSnapshot = null;
      return BackupRestoreResult(
        outcome: BackupRestoreOutcome.success,
        summary: prepared.summary,
      );
    } on BackupException catch (error) {
      _pendingSummary = null;
      _pendingSnapshot = null;
      final outcome = switch (error.code) {
        BackupErrorCode.invalidMagic ||
        BackupErrorCode.invalidHeader ||
        BackupErrorCode.unsupportedVersion ||
        BackupErrorCode.lengthMismatch ||
        BackupErrorCode.checksumMismatch ||
        BackupErrorCode.trailingData ||
        BackupErrorCode.malformedPayload ||
        BackupErrorCode.invalidBusinessData ||
        BackupErrorCode.limitExceeded => BackupRestoreOutcome.rejected,
        _ => BackupRestoreOutcome.failed,
      };
      return BackupRestoreResult(outcome: outcome, errorCode: error.code);
    } on Exception {
      _pendingSummary = null;
      _pendingSnapshot = null;
      return const BackupRestoreResult(
        outcome: BackupRestoreOutcome.failed,
        errorCode: BackupErrorCode.restoreFailed,
      );
    }
  }

  Future<BackupRestoreResult> _finish(
    Future<BackupRestoreResult> request,
  ) async {
    try {
      final result = await request;
      if (!_disposed) _lastResult = result;
      return result;
    } finally {
      _request = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
