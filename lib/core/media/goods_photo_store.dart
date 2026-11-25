import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/uuid_generator.dart';

/// Private WebP storage for the optional goods main photo (M4.2-A).
///
/// Keeps one optimized file per active photo. SQLite stores only [relPath].
class GoodsPhotoStore {
  GoodsPhotoStore();

  static const maxLongSide = 1280;
  static const webpQuality = 80;
  static const _photosDirName = 'photos';
  static const _tempDirName = 'tmp';

  Future<Directory> _supportDir() => getApplicationSupportDirectory();

  Future<Directory> photosDirectory() async {
    final dir = Directory(
      p.join((await _supportDir()).path, _photosDirName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _tempDirectory() async {
    final dir = Directory(
      p.join((await photosDirectory()).path, _tempDirName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Absolute file for a relative path stored in SQLite (`photos/….webp`).
  Future<File?> resolve(String? relPath) async {
    if (relPath == null || relPath.isEmpty) return null;
    if (p.isAbsolute(relPath) ||
        relPath.contains('..') ||
        !relPath.startsWith('$_photosDirName/')) {
      return null;
    }
    final file = File(p.join((await _supportDir()).path, relPath));
    if (!await file.exists()) return null;
    return file;
  }

  /// Optimizes [sourcePath] into a temporary WebP under `photos/tmp/`.
  /// Does not modify the user's original gallery/camera file beyond reading.
  Future<File> optimizeToTemp(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Source image missing');
    }
    final tmp = await _tempDirectory();
    final target = File(p.join(tmp.path, '${generateUuidV4()}.webp'));
    final result = await FlutterImageCompress.compressAndGetFile(
      source.path,
      target.path,
      format: CompressFormat.webp,
      quality: webpQuality,
      minWidth: maxLongSide,
      minHeight: maxLongSide,
      keepExif: false,
    );
    if (result == null) {
      throw StateError('WebP compression failed');
    }
    final out = File(result.path);
    if (!await out.exists() || await out.length() == 0) {
      throw StateError('WebP output empty');
    }
    return out;
  }

  /// Moves a temp WebP into the permanent photos directory.
  /// Returns the relative path to store in SQLite.
  Future<String> promoteTemp(File tempWebp) async {
    final photos = await photosDirectory();
    final name = '${generateUuidV4()}.webp';
    final dest = File(p.join(photos.path, name));
    if (await dest.exists()) {
      await dest.delete();
    }
    await tempWebp.rename(dest.path);
    return '$_photosDirName/$name';
  }

  Future<void> deleteRel(String? relPath) async {
    final file = await resolve(relPath);
    if (file == null) return;
    try {
      await file.delete();
    } on FileSystemException {
      // Best-effort cleanup; DB remains source of truth for the path.
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
