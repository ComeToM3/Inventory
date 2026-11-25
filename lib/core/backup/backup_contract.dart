/// Shared Inventory backup contract.
///
/// [backupFormatVersion] is the `.invbackup` framing version (independent of
/// the SQLite Drift schemaVersion). [backupDataSchemaVersion] describes the
/// JSON business payload shape.
library;

const backupMagic = 'INVENTORY-BACKUP';
const backupFormatId = 'inventory-backup';

/// Current export framing. Imports accept [backupMinFormatVersion] through this.
const backupFormatVersion = 2;
const backupMinFormatVersion = 1;

/// Current export schema.
/// Schema 1 = V1 (no `space`); schema 2 = nodes include `space`;
/// schema 3 = V2 fields + stock/purchase/prefs/documents + media manifest.
const backupDataSchemaVersion = 3;
const backupMinDataSchemaVersion = 1;
const backupFileExtension = 'invbackup';
const backupMimeType = 'application/octet-stream';

/// Soft safety ceiling (not the former hard 32 MiB product limit).
const backupMaxFileBytes = 512 * 1024 * 1024;
const backupMaxHeaderBytes = 4 * 1024;
const backupMaxNodes = 100000;
const backupMaxJsonDepth = 8;
const backupMaxMediaFiles = 50000;

enum BackupExportOutcome { verified, writtenUnverified, failed, cancelled }

class BackupException implements Exception {
  const BackupException(this.code, [this.message]);

  final BackupErrorCode code;
  final String? message;

  @override
  String toString() => 'BackupException(${code.name})';
}

enum BackupErrorCode {
  invalidMagic,
  invalidHeader,
  unsupportedVersion,
  lengthMismatch,
  checksumMismatch,
  trailingData,
  malformedPayload,
  limitExceeded,
  snapshotFailed,
  serializationFailed,
  destinationUnavailable,
  writeFailed,
  verificationFailed,
  invalidBusinessData,
  mediaMissing,
  restoreFailed,
  restoreBlocked,
  databaseUnreliable,
  sourceUnavailable,
}

enum BackupRestoreOutcome {
  success,
  cancelled,
  rejected,
  failed,
}

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.createdAtUtc,
    required this.nodeCount,
    required this.withdrawnCount,
  });

  final String createdAtUtc;
  final int nodeCount;
  final int withdrawnCount;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.outcome,
    this.summary,
    this.errorCode,
  });

  final BackupRestoreOutcome outcome;
  final BackupRestoreSummary? summary;
  final BackupErrorCode? errorCode;
}

enum RestorationJournalStatus {
  /// Durable intent recorded; active inventory not replaced yet.
  pending('pending'),

  /// SQLite business data replaced; media activation not confirmed.
  dbReady('db_ready'),

  /// SQLite and media (when any) verified together.
  committed('committed');

  const RestorationJournalStatus(this.storageValue);
  final String storageValue;
}

class RestorationRecoveryState {
  const RestorationRecoveryState({
    required this.status,
    required this.operationId,
    required this.messageKind,
  });

  final RestorationJournalStatus status;
  final String operationId;
  final RestorationRecoveryMessage messageKind;
}

enum RestorationRecoveryMessage {
  /// pending: previous inventory kept, restore not applied.
  notApplied,

  /// committed: restore finished before UI confirmation.
  completed,

  /// inventory cannot be verified; block normal use.
  unreliable,
}

class BackupHeader {
  const BackupHeader({
    required this.formatId,
    required this.formatVersion,
    required this.dataSchemaVersion,
    required this.createdAtUtc,
    required this.payloadLength,
    required this.payloadSha256,
  });

  final String formatId;
  final int formatVersion;
  final int dataSchemaVersion;
  final String createdAtUtc;
  final int payloadLength;
  final String payloadSha256;
}

/// Manifest entry for a media file embedded after the JSON payload (format 2).
class BackupMediaManifestEntry {
  const BackupMediaManifestEntry({
    required this.relPath,
    required this.byteSize,
    required this.sha256,
  });

  final String relPath;
  final int byteSize;
  final String sha256;

  Map<String, Object?> toJson() => {
        'rel_path': relPath,
        'byte_size': byteSize,
        'sha256': sha256,
      };

  static BackupMediaManifestEntry fromJson(Map<String, Object?> raw) {
    final relPath = raw['rel_path'];
    final byteSize = raw['byte_size'];
    final digest = raw['sha256'];
    if (relPath is! String ||
        byteSize is! int ||
        digest is! String ||
        byteSize < 0) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    return BackupMediaManifestEntry(
      relPath: relPath,
      byteSize: byteSize,
      sha256: digest,
    );
  }
}

class BackupSnapshot {
  const BackupSnapshot({
    required this.inventory,
    required this.nodes,
    required this.categories,
    required this.nodeCategories,
    this.stockMovements = const [],
    this.purchaseEvents = const [],
    this.appPreferences = const [],
    this.nodeDocuments = const [],
    this.mediaFiles = const [],
  });

  final Map<String, Object?> inventory;
  final List<Map<String, Object?>> nodes;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> nodeCategories;
  final List<Map<String, Object?>> stockMovements;
  final List<Map<String, Object?>> purchaseEvents;
  final List<Map<String, Object?>> appPreferences;
  final List<Map<String, Object?>> nodeDocuments;
  final List<BackupMediaManifestEntry> mediaFiles;
}

class BackupFile {
  const BackupFile({
    required this.header,
    required this.payloadBytes,
    required this.jsonUtf8,
    required this.bytes,
    this.mediaBlobs = const [],
  });

  final BackupHeader header;

  /// Entire framed payload (hashed by [BackupHeader.payloadSha256]).
  final List<int> payloadBytes;

  /// JSON portion of the payload (format 1: equals [payloadBytes]).
  final List<int> jsonUtf8;

  final List<int> bytes;

  /// In-memory media blobs for format 2 (empty when staged on disk).
  final List<List<int>> mediaBlobs;
}

class BackupExportResult {
  const BackupExportResult({
    required this.outcome,
    this.displayName,
    this.errorCode,
  });

  final BackupExportOutcome outcome;
  final String? displayName;
  final BackupErrorCode? errorCode;

  bool get isSuccess =>
      outcome == BackupExportOutcome.verified ||
      outcome == BackupExportOutcome.writtenUnverified;
}
