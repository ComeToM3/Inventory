import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/inventory_database.dart';
import 'backup_codec.dart';
import 'backup_contract.dart';
import 'backup_snapshot_reader.dart';

typedef DocumentDestinationPicker =
    Future<String?> Function({
      required String suggestedName,
      required String mimeType,
    });

typedef DocumentBytesWriter =
    Future<void> Function({required String uri, required List<int> bytes});

typedef DocumentBytesReader = Future<List<int>?> Function(String uri);

/// Prepares a verified temporary backup, then copies it to a user destination.
class BackupExporter {
  BackupExporter(
    InventoryDatabase database, {
    BackupSnapshotReader? reader,
    DateTime Function()? clock,
    Future<Directory> Function()? temporaryDirectory,
  }) : _reader = reader ?? BackupSnapshotReader(database),
       _clock = clock ?? DateTime.now,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final BackupSnapshotReader _reader;
  final DateTime Function() _clock;
  final Future<Directory> Function() _temporaryDirectory;

  Future<BackupExportResult> export({
    required DocumentDestinationPicker pickDestination,
    required DocumentBytesWriter writeDestination,
    DocumentBytesReader? readDestination,
  }) async {
    File? tempFile;
    try {
      final suggestedName = _suggestedFileName(_clock().toUtc());
      final uri = await pickDestination(
        suggestedName: suggestedName,
        mimeType: backupMimeType,
      );
      if (uri == null) {
        return const BackupExportResult(outcome: BackupExportOutcome.cancelled);
      }

      final snapshot = await _reader.read();
      final bytes = BackupCodec.encodeFile(
        snapshot,
        createdAtUtc: _clock().toUtc(),
      );
      BackupCodec.decodeAndVerify(bytes);

      tempFile = await _writeTemp(bytes);
      BackupCodec.decodeAndVerify(await tempFile.readAsBytes());

      try {
        await writeDestination(uri: uri, bytes: bytes);
      } catch (_) {
        return const BackupExportResult(
          outcome: BackupExportOutcome.failed,
          errorCode: BackupErrorCode.writeFailed,
        );
      }

      if (readDestination == null) {
        return BackupExportResult(
          outcome: BackupExportOutcome.writtenUnverified,
          displayName: suggestedName,
        );
      }

      try {
        final remote = await readDestination(uri);
        if (remote == null) {
          return BackupExportResult(
            outcome: BackupExportOutcome.writtenUnverified,
            displayName: suggestedName,
          );
        }
        if (!_sameBytes(remote, bytes)) {
          return const BackupExportResult(
            outcome: BackupExportOutcome.failed,
            errorCode: BackupErrorCode.verificationFailed,
          );
        }
        BackupCodec.decodeAndVerify(remote);
        return BackupExportResult(
          outcome: BackupExportOutcome.verified,
          displayName: suggestedName,
        );
      } on BackupException catch (error) {
        return BackupExportResult(
          outcome: BackupExportOutcome.failed,
          errorCode: error.code,
        );
      } on Exception {
        return BackupExportResult(
          outcome: BackupExportOutcome.writtenUnverified,
          displayName: suggestedName,
        );
      }
    } on BackupException catch (error) {
      return BackupExportResult(
        outcome: BackupExportOutcome.failed,
        errorCode: error.code,
      );
    } on Exception {
      return const BackupExportResult(
        outcome: BackupExportOutcome.failed,
        errorCode: BackupErrorCode.serializationFailed,
      );
    } finally {
      await _deleteQuietly(tempFile);
    }
  }

  /// Builds framed bytes without touching a destination (tests / prep).
  Future<List<int>> buildFileBytes() async {
    final snapshot = await _reader.read();
    final bytes = BackupCodec.encodeFile(
      snapshot,
      createdAtUtc: _clock().toUtc(),
    );
    BackupCodec.decodeAndVerify(bytes);
    return bytes;
  }

  static Future<void> cleanupOrphanTemps({
    Future<Directory> Function()? temporaryDirectory,
  }) async {
    try {
      final directory = await (temporaryDirectory ?? getTemporaryDirectory)();
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('inventory_export_') &&
            name.endsWith('.$backupFileExtension')) {
          await _deleteQuietly(entity);
        }
      }
    } on Exception {
      // Private cleanup must never block startup.
    }
  }

  static String _suggestedFileName(DateTime utc) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${utc.year}${two(utc.month)}${two(utc.day)}-'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
    return 'inventory-$stamp.$backupFileExtension';
  }

  Future<File> _writeTemp(List<int> bytes) async {
    final directory = await _temporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'inventory_export_${_clock().microsecondsSinceEpoch}.$backupFileExtension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } on Exception {
      // Ignore cleanup failures.
    }
  }
}
