/// Shared Inventory backup contract (format_version / data_schema_version = 1).
/// Produced by DEV-12 and consumed by DEV-13 without redefining the frame.
library;

const backupMagic = 'INVENTORY-BACKUP';
const backupFormatId = 'inventory-backup';
const backupFormatVersion = 1;

/// Current export schema. Imports accept [backupMinDataSchemaVersion] through
/// this value. Schema 1 = V1 (no `space`); schema 2 = nodes include `space`.
const backupDataSchemaVersion = 2;
const backupMinDataSchemaVersion = 1;
const backupFileExtension = 'invbackup';
const backupMimeType = 'application/octet-stream';

/// Recommended hard limits from docs/09-backup-recovery.md §4.2.
const backupMaxFileBytes = 32 * 1024 * 1024;
const backupMaxHeaderBytes = 4 * 1024;
const backupMaxNodes = 100000;
const backupMaxJsonDepth = 8;

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

enum RestorationJournalStatus { pending, committed }

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

class BackupSnapshot {
  const BackupSnapshot({
    required this.inventory,
    required this.nodes,
    required this.categories,
    required this.nodeCategories,
  });

  final Map<String, Object?> inventory;
  final List<Map<String, Object?>> nodes;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> nodeCategories;
}

class BackupFile {
  const BackupFile({
    required this.header,
    required this.payloadUtf8,
    required this.bytes,
  });

  final BackupHeader header;
  final List<int> payloadUtf8;
  final List<int> bytes;
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
