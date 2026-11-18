import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'backup_contract.dart';

final _utf8 = utf8;
final _magicLine = _utf8.encode('$backupMagic\n');

/// Builds and verifies `.invbackup` bytes according to docs/09-backup-recovery.md.
abstract final class BackupCodec {
  static List<int> encodeFile(
    BackupSnapshot snapshot, {
    required DateTime createdAtUtc,
  }) {
    final payloadObject = <String, Object?>{
      'inventory': snapshot.inventory,
      'nodes': snapshot.nodes,
      'categories': snapshot.categories,
      'node_categories': snapshot.nodeCategories,
    };
    final payloadUtf8 = _utf8.encode(jsonEncode(payloadObject));
    if (payloadUtf8.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    if (snapshot.nodes.length > backupMaxNodes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    final digest = sha256.convert(payloadUtf8).toString();
    final headerObject = <String, Object?>{
      'format_id': backupFormatId,
      'format_version': backupFormatVersion,
      'data_schema_version': backupDataSchemaVersion,
      'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
      'payload_length': payloadUtf8.length,
      'payload_sha256': digest,
    };
    final headerLine = _utf8.encode('${jsonEncode(headerObject)}\n');
    if (headerLine.length > backupMaxHeaderBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    final bytes = BytesBuilder(copy: false)
      ..add(_magicLine)
      ..add(headerLine)
      ..add(payloadUtf8);
    final file = bytes.takeBytes();
    if (file.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    return file;
  }

  /// Parses and verifies framing, length and SHA-256. Structural payload checks
  /// are intentionally minimal so DEV-13 can deepen business validation.
  static BackupFile decodeAndVerify(List<int> bytes) {
    if (bytes.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    if (!_startsWith(bytes, _magicLine)) {
      throw const BackupException(BackupErrorCode.invalidMagic);
    }

    final headerStart = _magicLine.length;
    final headerEnd = _indexOfByte(bytes, 0x0A, headerStart);
    if (headerEnd < 0) {
      throw const BackupException(BackupErrorCode.invalidHeader);
    }
    final headerLength = headerEnd - headerStart + 1;
    if (headerLength > backupMaxHeaderBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    late final Map<String, Object?> headerMap;
    try {
      final headerJson = _utf8.decode(
        bytes.sublist(headerStart, headerEnd),
        allowMalformed: false,
      );
      final decoded = jsonDecode(headerJson);
      if (decoded is! Map) {
        throw const BackupException(BackupErrorCode.invalidHeader);
      }
      headerMap = decoded.cast<String, Object?>();
    } on BackupException {
      rethrow;
    } on FormatException {
      throw const BackupException(BackupErrorCode.invalidHeader);
    } on Exception {
      throw const BackupException(BackupErrorCode.invalidHeader);
    }

    final header = _parseHeader(headerMap);
    if (header.formatId != backupFormatId ||
        header.formatVersion != backupFormatVersion ||
        header.dataSchemaVersion < backupMinDataSchemaVersion ||
        header.dataSchemaVersion > backupDataSchemaVersion) {
      throw const BackupException(BackupErrorCode.unsupportedVersion);
    }

    final payloadStart = headerEnd + 1;
    final remaining = bytes.length - payloadStart;
    if (remaining != header.payloadLength) {
      throw BackupException(
        remaining < header.payloadLength
            ? BackupErrorCode.lengthMismatch
            : BackupErrorCode.trailingData,
      );
    }
    final payloadUtf8 = bytes.sublist(payloadStart);
    final digest = sha256.convert(payloadUtf8).toString();
    if (digest != header.payloadSha256) {
      throw const BackupException(BackupErrorCode.checksumMismatch);
    }

    try {
      final decoded = jsonDecode(
        _utf8.decode(payloadUtf8, allowMalformed: false),
      );
      if (decoded is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requirePayloadShape(decoded.cast<String, Object?>());
    } on BackupException {
      rethrow;
    } on FormatException {
      throw const BackupException(BackupErrorCode.malformedPayload);
    } on Exception {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }

    return BackupFile(
      header: header,
      payloadUtf8: payloadUtf8,
      bytes: List<int>.from(bytes),
    );
  }

  static BackupHeader _parseHeader(Map<String, Object?> map) {
    final required = {
      'format_id',
      'format_version',
      'data_schema_version',
      'created_at_utc',
      'payload_length',
      'payload_sha256',
    };
    if (map.length != required.length ||
        required.any((key) => !map.containsKey(key))) {
      throw const BackupException(BackupErrorCode.invalidHeader);
    }
    final formatId = map['format_id'];
    final formatVersion = map['format_version'];
    final dataSchemaVersion = map['data_schema_version'];
    final createdAtUtc = map['created_at_utc'];
    final payloadLength = map['payload_length'];
    final payloadSha256 = map['payload_sha256'];
    if (formatId is! String ||
        formatVersion is! int ||
        dataSchemaVersion is! int ||
        createdAtUtc is! String ||
        payloadLength is! int ||
        payloadSha256 is! String ||
        payloadLength < 0 ||
        !_isHexSha256(payloadSha256)) {
      throw const BackupException(BackupErrorCode.invalidHeader);
    }
    return BackupHeader(
      formatId: formatId,
      formatVersion: formatVersion,
      dataSchemaVersion: dataSchemaVersion,
      createdAtUtc: createdAtUtc,
      payloadLength: payloadLength,
      payloadSha256: payloadSha256,
    );
  }

  static void _requirePayloadShape(Map<String, Object?> payload) {
    const expected = {'inventory', 'nodes', 'categories', 'node_categories'};
    if (payload.length != expected.length ||
        expected.any((key) => !payload.containsKey(key))) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    final inventory = payload['inventory'];
    final nodes = payload['nodes'];
    final categories = payload['categories'];
    final associations = payload['node_categories'];
    if (inventory is! Map ||
        nodes is! List ||
        categories is! List ||
        associations is! List) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    if (nodes.length > backupMaxNodes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    _requireKeys(inventory.cast<String, Object?>(), const {
      'id',
      'singleton_key',
      'created_at',
      'updated_at',
    });
    for (final row in nodes) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      // `space` optional for schema 1 (V1); present for schema 2+.
      _requireKeys(
        row.cast<String, Object?>(),
        const {
          'id',
          'inventory_id',
          'parent_id',
          'name',
          'node_type',
          'quantity',
          'description',
          'condition',
          'value_mode',
          'financial_value_cents',
          'sentimental_value',
          'status',
          'withdrawal_reason',
          'withdrawn_at',
          'created_at',
          'updated_at',
        },
        optional: const {'space'},
      );
    }
    for (final row in categories) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requireKeys(row.cast<String, Object?>(), const {
        'id',
        'inventory_id',
        'name',
        'created_at',
        'updated_at',
      });
    }
    for (final row in associations) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requireKeys(row.cast<String, Object?>(), const {
        'inventory_id',
        'node_id',
        'category_id',
      });
    }
  }

  static void _requireKeys(
    Map<String, Object?> row,
    Set<String> expected, {
    Set<String> optional = const {},
  }) {
    if (expected.any((key) => !row.containsKey(key))) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    final allowed = expected.union(optional);
    if (row.keys.any((key) => !allowed.contains(key))) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
  }

  static bool _isHexSha256(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  static int _indexOfByte(List<int> bytes, int value, int start) {
    for (var i = start; i < bytes.length; i++) {
      if (bytes[i] == value) return i;
    }
    return -1;
  }
}
