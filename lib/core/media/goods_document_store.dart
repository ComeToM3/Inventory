import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/uuid_generator.dart';

/// Private byte-faithful storage for goods supporting documents (M4.2-B).
///
/// Separate from [GoodsPhotoStore]: no recompression, one private copy per doc.
class GoodsDocumentStore {
  GoodsDocumentStore();

  static const maxBytes = 15 * 1024 * 1024;
  static const allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png', 'webp'};
  static const _dirName = 'documents';
  static const _tempDirName = 'tmp';

  Future<Directory> _supportDir() => getApplicationSupportDirectory();

  Future<Directory> documentsDirectory() async {
    final dir = Directory(p.join((await _supportDir()).path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _tempDirectory() async {
    final dir = Directory(
      p.join((await documentsDirectory()).path, _tempDirName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String? normalizeExtension(String? nameOrExt) {
    if (nameOrExt == null || nameOrExt.isEmpty) return null;
    var ext = nameOrExt.trim().toLowerCase();
    if (ext.contains('.')) {
      ext = p.extension(ext).replaceFirst('.', '');
    }
    if (ext.isEmpty) return null;
    return allowedExtensions.contains(ext) ? ext : null;
  }

  static String mimeForExtension(String ext) => switch (ext) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };

  Future<File?> resolve(String? relPath) async {
    if (relPath == null || relPath.isEmpty) return null;
    if (p.isAbsolute(relPath) ||
        relPath.contains('..') ||
        !relPath.startsWith('$_dirName/')) {
      return null;
    }
    final file = File(p.join((await _supportDir()).path, relPath));
    if (!await file.exists()) return null;
    return file;
  }

  /// Copies [sourcePath] into `documents/tmp/` without altering bytes.
  Future<PendingDocumentCopy> copyToTemp({
    required String sourcePath,
    required String displayName,
    required String extension,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const GoodsDocumentException.missingSource();
    }
    return _writeTempCopy(
      displayName: displayName,
      extension: extension,
      knownSize: await source.length(),
      write: (dest) => source.copy(dest.path),
    );
  }

  /// Copies a byte stream into `documents/tmp/` without altering content.
  ///
  /// Used when the system picker returns a content URI without a local path.
  Future<PendingDocumentCopy> copyStreamToTemp({
    required Stream<List<int>> bytes,
    required String displayName,
    required String extension,
    int? knownSize,
  }) {
    return _writeTempCopy(
      displayName: displayName,
      extension: extension,
      knownSize: knownSize,
      write: (dest) async {
        final sink = dest.openWrite();
        try {
          await for (final chunk in bytes) {
            sink.add(chunk);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
      },
    );
  }

  Future<PendingDocumentCopy> _writeTempCopy({
    required String displayName,
    required String extension,
    required Future<void> Function(File dest) write,
    int? knownSize,
  }) async {
    if (knownSize != null) {
      if (knownSize <= 0) {
        throw const GoodsDocumentException.emptyFile();
      }
      if (knownSize > maxBytes) {
        throw const GoodsDocumentException.tooLarge();
      }
    }
    final ext = normalizeExtension(extension);
    if (ext == null) {
      throw const GoodsDocumentException.unsupportedType();
    }
    final tmp = await _tempDirectory();
    final dest = File(p.join(tmp.path, '${generateUuidV4()}.$ext'));
    try {
      await write(dest);
      final size = await dest.length();
      if (size <= 0) {
        throw const GoodsDocumentException.emptyFile();
      }
      if (size > maxBytes) {
        throw const GoodsDocumentException.tooLarge();
      }
      return PendingDocumentCopy(
        tempFile: dest,
        displayName: displayName.trim().isEmpty
            ? 'document.$ext'
            : displayName.trim(),
        extension: ext,
        mimeType: mimeForExtension(ext),
        byteSize: size,
      );
    } on GoodsDocumentException {
      await deleteTemp(dest);
      rethrow;
    } catch (_) {
      await deleteTemp(dest);
      rethrow;
    }
  }

  /// Moves a temp copy into the permanent documents directory.
  Future<String> promoteTemp(PendingDocumentCopy pending) async {
    final docs = await documentsDirectory();
    final name = '${generateUuidV4()}.${pending.extension}';
    final dest = File(p.join(docs.path, name));
    if (await dest.exists()) {
      await dest.delete();
    }
    await pending.tempFile.rename(dest.path);
    return '$_dirName/$name';
  }

  Future<void> deleteRel(String? relPath) async {
    final file = await resolve(relPath);
    if (file == null) return;
    try {
      await file.delete();
    } on FileSystemException {
      // Best-effort.
    }
  }

  Future<void> deleteTemp(File? temp) async {
    if (temp == null) return;
    try {
      if (await temp.exists()) await temp.delete();
    } on FileSystemException {
      // Ignore.
    }
  }
}

class PendingDocumentCopy {
  const PendingDocumentCopy({
    required this.tempFile,
    required this.displayName,
    required this.extension,
    required this.mimeType,
    required this.byteSize,
  });

  final File tempFile;
  final String displayName;
  final String extension;
  final String mimeType;
  final int byteSize;
}

enum GoodsDocumentError {
  missingSource,
  emptyFile,
  tooLarge,
  unsupportedType,
}

class GoodsDocumentException implements Exception {
  const GoodsDocumentException(this.code);

  const GoodsDocumentException.missingSource()
    : code = GoodsDocumentError.missingSource;

  const GoodsDocumentException.emptyFile() : code = GoodsDocumentError.emptyFile;

  const GoodsDocumentException.tooLarge() : code = GoodsDocumentError.tooLarge;

  const GoodsDocumentException.unsupportedType()
    : code = GoodsDocumentError.unsupportedType;

  final GoodsDocumentError code;
}
