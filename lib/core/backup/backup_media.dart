import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup_contract.dart';

/// Relative media path safety and on-disk staging/activation for restores.
abstract final class BackupMedia {
  static const photosPrefix = 'photos/';
  static const documentsPrefix = 'documents/';
  static const stagingDirName = 'restore_media_staging';
  static const previousDirName = 'restore_media_previous';

  static bool isSafeRelPath(String relPath) {
    if (relPath.isEmpty ||
        relPath.contains('\\') ||
        relPath.contains('\x00') ||
        relPath.contains('..') ||
        p.isAbsolute(relPath) ||
        relPath.startsWith('/')) {
      return false;
    }
    final normalized = p.posix.normalize(relPath);
    if (normalized != relPath || normalized.startsWith('..')) {
      return false;
    }
    return normalized.startsWith(photosPrefix) ||
        normalized.startsWith(documentsPrefix);
  }

  static void assertSafeRelPath(String relPath) {
    if (!isSafeRelPath(relPath)) {
      throw const BackupException(BackupErrorCode.invalidBusinessData);
    }
  }

  static Future<Directory> supportDirectory() =>
      getApplicationSupportDirectory();

  static Future<File> resolveInSupport(String relPath) async {
    assertSafeRelPath(relPath);
    return File(p.join((await supportDirectory()).path, relPath));
  }

  static Future<Directory> stagingRoot() async {
    final dir = Directory(
      p.join((await supportDirectory()).path, stagingDirName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> clearStaging() async {
    final dir = Directory(
      p.join((await supportDirectory()).path, stagingDirName),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<File> stagingFileFor(String relPath) async {
    assertSafeRelPath(relPath);
    final file = File(p.join((await stagingRoot()).path, relPath));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<String> sha256File(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static Future<BackupMediaManifestEntry> manifestForFile({
    required String relPath,
    required File file,
  }) async {
    assertSafeRelPath(relPath);
    if (!await file.exists()) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }
    final length = await file.length();
    if (length <= 0) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }
    return BackupMediaManifestEntry(
      relPath: relPath,
      byteSize: length,
      sha256: await sha256File(file),
    );
  }

  /// Collects referenced media from the live support directory.
  static Future<List<({BackupMediaManifestEntry entry, File file})>>
      collectReferenced({
    required Iterable<String?> photoRelPaths,
    required Iterable<String> documentRelPaths,
  }) async {
    final ordered = <String>[];
    final seen = <String>{};
    void add(String? path) {
      if (path == null || path.isEmpty) return;
      assertSafeRelPath(path);
      if (seen.add(path)) ordered.add(path);
    }

    for (final path in photoRelPaths) {
      add(path);
    }
    for (final path in documentRelPaths) {
      add(path);
    }
    if (ordered.length > backupMaxMediaFiles) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    final out = <({BackupMediaManifestEntry entry, File file})>[];
    for (final relPath in ordered) {
      final file = await resolveInSupport(relPath);
      if (!await file.exists()) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      final entry = await manifestForFile(relPath: relPath, file: file);
      out.add((entry: entry, file: file));
    }
    return out;
  }

  static Future<void> verifyStagingMatches(
    List<BackupMediaManifestEntry> manifest,
  ) async {
    final seen = <String>{};
    for (final entry in manifest) {
      assertSafeRelPath(entry.relPath);
      if (!seen.add(entry.relPath)) {
        throw const BackupException(BackupErrorCode.invalidBusinessData);
      }
      final file = await stagingFileFor(entry.relPath);
      if (!await file.exists()) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      final length = await file.length();
      if (length != entry.byteSize) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      final digest = await sha256File(file);
      if (digest != entry.sha256) {
        throw const BackupException(BackupErrorCode.checksumMismatch);
      }
    }
  }

  /// Swaps staged photos/documents into the live support tree.
  /// Previous trees are kept under [previousDirName] until [discardPrevious].
  static Future<void> activateStaging() async {
    final support = await supportDirectory();
    final staging = Directory(p.join(support.path, stagingDirName));
    if (!await staging.exists()) return;

    final previous = Directory(p.join(support.path, previousDirName));
    if (await previous.exists()) {
      await previous.delete(recursive: true);
    }
    await previous.create(recursive: true);

    for (final name in const ['photos', 'documents']) {
      final live = Directory(p.join(support.path, name));
      final staged = Directory(p.join(staging.path, name));
      final bak = Directory(p.join(previous.path, name));
      if (await live.exists()) {
        await live.rename(bak.path);
      }
      if (await staged.exists()) {
        await staged.rename(live.path);
      } else if (await bak.exists()) {
        // No staged tree: keep previous empty for this channel.
        await Directory(live.path).create(recursive: true);
      }
    }
  }

  static Future<void> discardPrevious() async {
    final previous = Directory(
      p.join((await supportDirectory()).path, previousDirName),
    );
    if (await previous.exists()) {
      await previous.delete(recursive: true);
    }
    await clearStaging();
  }

  /// Best-effort rollback of media trees after a failed activation.
  static Future<void> restorePrevious() async {
    final support = await supportDirectory();
    final previous = Directory(p.join(support.path, previousDirName));
    if (!await previous.exists()) return;
    for (final name in const ['photos', 'documents']) {
      final live = Directory(p.join(support.path, name));
      final bak = Directory(p.join(previous.path, name));
      if (await live.exists()) {
        await live.delete(recursive: true);
      }
      if (await bak.exists()) {
        await bak.rename(live.path);
      }
    }
    await previous.delete(recursive: true);
  }

  static Future<void> verifyLiveMatches(
    List<BackupMediaManifestEntry> manifest,
  ) async {
    for (final entry in manifest) {
      final file = await resolveInSupport(entry.relPath);
      if (!await file.exists()) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      if (await file.length() != entry.byteSize) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      if (await sha256File(file) != entry.sha256) {
        throw const BackupException(BackupErrorCode.checksumMismatch);
      }
    }
  }

  static Future<bool> liveFilesExist(Iterable<String> relPaths) async {
    for (final relPath in relPaths) {
      assertSafeRelPath(relPath);
      final file = await resolveInSupport(relPath);
      if (!await file.exists() || await file.length() <= 0) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> stagingContainsAll(Iterable<String> relPaths) async {
    final root = Directory(
      p.join((await supportDirectory()).path, stagingDirName),
    );
    if (!await root.exists()) return false;
    for (final relPath in relPaths) {
      assertSafeRelPath(relPath);
      final file = File(p.join(root.path, relPath));
      if (!await file.exists() || await file.length() <= 0) {
        return false;
      }
    }
    return true;
  }
}
