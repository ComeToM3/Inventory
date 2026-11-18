import 'package:flutter/services.dart';

import '../core/backup/backup_contract.dart';

/// Thin SAF bridge: create a document URI, write bytes, optionally re-read.
class AndroidDocumentStore {
  AndroidDocumentStore({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('io.github.cometom3.inventory/documents');

  final MethodChannel _channel;

  Future<String?> createDocument({
    required String suggestedName,
    required String mimeType,
  }) async {
    try {
      final uri = await _channel.invokeMethod<String>('createDocument', {
        'suggestedName': suggestedName,
        'mimeType': mimeType,
      });
      return uri;
    } on PlatformException {
      throw const BackupException(BackupErrorCode.destinationUnavailable);
    }
  }

  /// Opens an existing document; returns null when the user cancels.
  Future<String?> openDocument({required List<String> mimeTypes}) async {
    try {
      final uri = await _channel.invokeMethod<String>('openDocument', {
        'mimeTypes': mimeTypes,
      });
      return uri;
    } on PlatformException {
      throw const BackupException(BackupErrorCode.sourceUnavailable);
    }
  }

  /// Reads a document with a hard size limit matching the backup contract.
  Future<List<int>> readDocumentLimited(
    String uri, {
    int maxBytes = backupMaxFileBytes,
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>('readDocumentLimited', {
        'uri': uri,
        'maxBytes': maxBytes,
      });
      if (result is Uint8List) return result;
      if (result is List) return List<int>.from(result);
      throw const BackupException(BackupErrorCode.sourceUnavailable);
    } on PlatformException catch (error) {
      if (error.code == 'TOO_LARGE') {
        throw const BackupException(BackupErrorCode.limitExceeded);
      }
      if (error.code == 'UNREADABLE') {
        throw const BackupException(BackupErrorCode.sourceUnavailable);
      }
      throw const BackupException(BackupErrorCode.sourceUnavailable);
    }
  }

  Future<void> writeDocument({
    required String uri,
    required List<int> bytes,
  }) async {
    try {
      await _channel.invokeMethod<void>('writeDocument', {
        'uri': uri,
        'bytes': Uint8List.fromList(bytes),
      });
    } on PlatformException {
      throw const BackupException(BackupErrorCode.writeFailed);
    }
  }

  /// Returns null when the provider refuses or cannot reopen the document.
  Future<List<int>?> readDocument(String uri) async {
    try {
      final result = await _channel.invokeMethod<dynamic>('readDocument', {
        'uri': uri,
      });
      if (result == null) return null;
      if (result is Uint8List) return result;
      if (result is List) return List<int>.from(result);
      return null;
    } on PlatformException catch (error) {
      if (error.code == 'UNREADABLE') return null;
      throw const BackupException(BackupErrorCode.verificationFailed);
    }
  }
}
