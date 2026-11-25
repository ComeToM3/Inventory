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

typedef DocumentFileWriter =
    Future<void> Function({required String uri, required String path});

typedef DocumentBytesReader = Future<List<int>?> Function(String uri);

typedef DocumentFileReader = Future<String?> Function(String uri);

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
    DocumentBytesWriter? writeDestination,
    DocumentFileWriter? writeDestinationFile,
    DocumentBytesReader? readDestination,
    DocumentFileReader? readDestinationFile,
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

      tempFile = await buildTempFile();
      BackupCodec.decodeAndVerify(await tempFile.readAsBytes());

      try {
        if (writeDestinationFile != null) {
          await writeDestinationFile(uri: uri, path: tempFile.path);
        } else if (writeDestination != null) {
          await writeDestination(
            uri: uri,
            bytes: await tempFile.readAsBytes(),
          );
        } else {
          return const BackupExportResult(
            outcome: BackupExportOutcome.failed,
            errorCode: BackupErrorCode.writeFailed,
          );
        }
      } catch (_) {
        return const BackupExportResult(
          outcome: BackupExportOutcome.failed,
          errorCode: BackupErrorCode.writeFailed,
        );
      }

      if (readDestinationFile == null && readDestination == null) {
        return BackupExportResult(
          outcome: BackupExportOutcome.writtenUnverified,
          displayName: suggestedName,
        );
      }

      try {
        if (readDestinationFile != null) {
          final remotePath = await readDestinationFile(uri);
          if (remotePath == null) {
            return BackupExportResult(
              outcome: BackupExportOutcome.writtenUnverified,
              displayName: suggestedName,
            );
          }
          final remoteFile = File(remotePath);
          final localBytes = await tempFile.readAsBytes();
          final remoteBytes = await remoteFile.readAsBytes();
          await _deleteQuietly(remoteFile);
          if (!_sameBytes(remoteBytes, localBytes)) {
            return const BackupExportResult(
              outcome: BackupExportOutcome.failed,
              errorCode: BackupErrorCode.verificationFailed,
            );
          }
          BackupCodec.decodeAndVerify(remoteBytes);
        } else {
          final remote = await readDestination!(uri);
          if (remote == null) {
            return BackupExportResult(
              outcome: BackupExportOutcome.writtenUnverified,
              displayName: suggestedName,
            );
          }
          final localBytes = await tempFile.readAsBytes();
          if (!_sameBytes(remote, localBytes)) {
            return const BackupExportResult(
              outcome: BackupExportOutcome.failed,
              errorCode: BackupErrorCode.verificationFailed,
            );
          }
          BackupCodec.decodeAndVerify(remote);
        }
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
    final packed = await _reader.readWithMediaFiles();
    if (packed.media.isEmpty) {
      final bytes = BackupCodec.encodeFile(
        packed.snapshot,
        createdAtUtc: _clock().toUtc(),
        media: const [],
      );
      BackupCodec.decodeAndVerify(bytes);
      return bytes;
    }
    final temp = await buildTempFileFrom(packed.snapshot, packed.media);
    try {
      final bytes = await temp.readAsBytes();
      BackupCodec.decodeAndVerify(bytes);
      return bytes;
    } finally {
      await _deleteQuietly(temp);
    }
  }

  Future<File> buildTempFile() async {
    final packed = await _reader.readWithMediaFiles();
    return buildTempFileFrom(packed.snapshot, packed.media);
  }

  Future<File> buildTempFileFrom(
    BackupSnapshot snapshot,
    List<({BackupMediaManifestEntry entry, File file})> media,
  ) async {
    final directory = await _temporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'inventory_export_${_clock().microsecondsSinceEpoch}.$backupFileExtension',
    );
    if (media.isEmpty) {
      final bytes = BackupCodec.encodeFile(
        snapshot,
        createdAtUtc: _clock().toUtc(),
        media: const [],
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    await BackupCodec.encodeToFile(
      file,
      snapshot,
      createdAtUtc: _clock().toUtc(),
      media: media,
    );
    return file;
  }

  static Future<void> cleanupOrphanTemps({
    Future<Directory> Function()? temporaryDirectory,
  }) async {
    try {
      final directory = await (temporaryDirectory ?? getTemporaryDirectory)();
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if ((name.startsWith('inventory_export_') ||
                name.startsWith('inventory_import_')) &&
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
