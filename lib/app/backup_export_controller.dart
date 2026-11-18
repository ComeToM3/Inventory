import 'package:flutter/foundation.dart';

import '../core/backup/backup_contract.dart';
import '../core/backup/backup_exporter.dart';
import '../core/database/inventory_database.dart';
import 'android_document_store.dart';
import 'app_strings.dart';

class BackupExportController extends ChangeNotifier {
  BackupExportController(
    InventoryDatabase database, {
    BackupExporter? exporter,
    AndroidDocumentStore? documents,
  }) : _exporter = exporter ?? BackupExporter(database),
       _documents = documents ?? AndroidDocumentStore();

  final BackupExporter _exporter;
  final AndroidDocumentStore _documents;
  Future<BackupExportResult>? _request;
  BackupExportResult? _lastResult;
  bool _disposed = false;

  bool get exporting => _request != null;
  BackupExportResult? get lastResult => _lastResult;

  String? get statusMessage {
    final result = _lastResult;
    if (result == null) return null;
    return switch (result.outcome) {
      BackupExportOutcome.verified => AppStrings.backupVerified,
      BackupExportOutcome.writtenUnverified =>
        AppStrings.backupWrittenUnverified,
      BackupExportOutcome.failed => AppStrings.backupFailed,
      BackupExportOutcome.cancelled => AppStrings.backupCancelled,
    };
  }

  Future<BackupExportResult> export() {
    final pending = _request;
    if (pending != null) return pending;
    _lastResult = null;
    _request = _finish(_run());
    notifyListeners();
    return _request!;
  }

  Future<BackupExportResult> _run() async {
    try {
      return await _exporter.export(
        pickDestination:
            ({required String suggestedName, required String mimeType}) =>
                _documents.createDocument(
                  suggestedName: suggestedName,
                  mimeType: mimeType,
                ),
        writeDestination: ({required String uri, required List<int> bytes}) =>
            _documents.writeDocument(uri: uri, bytes: bytes),
        readDestination: _documents.readDocument,
      );
    } on BackupException catch (error) {
      return BackupExportResult(
        outcome: BackupExportOutcome.failed,
        errorCode: error.code,
      );
    } on Exception {
      return const BackupExportResult(
        outcome: BackupExportOutcome.failed,
        errorCode: BackupErrorCode.writeFailed,
      );
    }
  }

  Future<BackupExportResult> _finish(Future<BackupExportResult> request) async {
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
