import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'backup_contract.dart';
import 'backup_media.dart';

final _utf8 = utf8;
final _magicLine = _utf8.encode('$backupMagic\n');

/// Builds and verifies `.invbackup` bytes according to the versioned contract.
abstract final class BackupCodec {
  /// In-memory encode (tests / small snapshots). Prefer [encodeToFile] for media.
  static List<int> encodeFile(
    BackupSnapshot snapshot, {
    required DateTime createdAtUtc,
    List<({BackupMediaManifestEntry entry, List<int> bytes})>? media,
  }) {
    final mediaEntries = media ??
        [
          for (final entry in snapshot.mediaFiles)
            (
              entry: entry,
              bytes: const <int>[],
            ),
        ];
    if (media != null) {
      for (final item in media) {
        if (item.bytes.length != item.entry.byteSize) {
          throw const BackupException(BackupErrorCode.mediaMissing);
        }
        final digest = sha256.convert(item.bytes).toString();
        if (digest != item.entry.sha256) {
          throw const BackupException(BackupErrorCode.checksumMismatch);
        }
      }
    } else if (snapshot.mediaFiles.isNotEmpty) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }

    final effective = BackupSnapshot(
      inventory: snapshot.inventory,
      nodes: snapshot.nodes,
      categories: snapshot.categories,
      nodeCategories: snapshot.nodeCategories,
      stockMovements: snapshot.stockMovements,
      purchaseEvents: snapshot.purchaseEvents,
      appPreferences: snapshot.appPreferences,
      nodeDocuments: snapshot.nodeDocuments,
      mediaFiles: [for (final item in mediaEntries) item.entry],
    );
    final jsonUtf8 = _utf8.encode(jsonEncode(_payloadObject(effective)));
    if (effective.nodes.length > backupMaxNodes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    if (effective.mediaFiles.length > backupMaxMediaFiles) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    final payload = BytesBuilder(copy: false);
    _writeUint32BE(payload, jsonUtf8.length);
    payload.add(jsonUtf8);
    for (final item in mediaEntries) {
      _writeUint32BE(payload, item.bytes.length);
      payload.add(item.bytes);
    }
    final payloadBytes = payload.takeBytes();
    return _frame(payloadBytes, createdAtUtc: createdAtUtc);
  }

  /// Streams media from disk into [outFile] without loading every blob in RAM.
  static Future<void> encodeToFile(
    File outFile,
    BackupSnapshot snapshot, {
    required DateTime createdAtUtc,
    required List<({BackupMediaManifestEntry entry, File file})> media,
  }) async {
    if (snapshot.nodes.length > backupMaxNodes ||
        media.length > backupMaxMediaFiles) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    for (final item in media) {
      BackupMedia.assertSafeRelPath(item.entry.relPath);
      if (!await item.file.exists()) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      final length = await item.file.length();
      if (length != item.entry.byteSize) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      final digest = await BackupMedia.sha256File(item.file);
      if (digest != item.entry.sha256) {
        throw const BackupException(BackupErrorCode.checksumMismatch);
      }
    }

    final effective = BackupSnapshot(
      inventory: snapshot.inventory,
      nodes: snapshot.nodes,
      categories: snapshot.categories,
      nodeCategories: snapshot.nodeCategories,
      stockMovements: snapshot.stockMovements,
      purchaseEvents: snapshot.purchaseEvents,
      appPreferences: snapshot.appPreferences,
      nodeDocuments: snapshot.nodeDocuments,
      mediaFiles: [for (final item in media) item.entry],
    );
    final jsonUtf8 = _utf8.encode(jsonEncode(_payloadObject(effective)));

    final payloadFile = File('${outFile.path}.payload');
    final payloadSink = payloadFile.openWrite();
    try {
      payloadSink.add(_uint32BE(jsonUtf8.length));
      payloadSink.add(jsonUtf8);
      for (final item in media) {
        payloadSink.add(_uint32BE(item.entry.byteSize));
        await for (final chunk in item.file.openRead()) {
          payloadSink.add(chunk);
        }
      }
      await payloadSink.flush();
    } finally {
      await payloadSink.close();
    }

    final payloadLength = await payloadFile.length();
    if (payloadLength > backupMaxFileBytes) {
      await _deleteQuietly(payloadFile);
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    final digest = await BackupMedia.sha256File(payloadFile);
    final headerObject = <String, Object?>{
      'format_id': backupFormatId,
      'format_version': backupFormatVersion,
      'data_schema_version': backupDataSchemaVersion,
      'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
      'payload_length': payloadLength,
      'payload_sha256': digest,
    };
    final headerLine = _utf8.encode('${jsonEncode(headerObject)}\n');
    if (headerLine.length > backupMaxHeaderBytes) {
      await _deleteQuietly(payloadFile);
      throw const BackupException(BackupErrorCode.limitExceeded);
    }

    final outSink = outFile.openWrite();
    try {
      outSink.add(_magicLine);
      outSink.add(headerLine);
      await for (final chunk in payloadFile.openRead()) {
        outSink.add(chunk);
      }
      await outSink.flush();
    } finally {
      await outSink.close();
      await _deleteQuietly(payloadFile);
    }

    final total = await outFile.length();
    if (total > backupMaxFileBytes) {
      await _deleteQuietly(outFile);
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
  }

  /// Parses and verifies framing, length and SHA-256.
  static BackupFile decodeAndVerify(List<int> bytes) {
    if (bytes.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    final framed = _parseFrame(bytes);
    final split = _splitPayload(
      framed.payloadBytes,
      formatVersion: framed.header.formatVersion,
    );
    _validateJsonShape(
      split.jsonUtf8,
      dataSchemaVersion: framed.header.dataSchemaVersion,
    );
    return BackupFile(
      header: framed.header,
      payloadBytes: framed.payloadBytes,
      jsonUtf8: split.jsonUtf8,
      bytes: List<int>.from(bytes),
      mediaBlobs: split.mediaBlobs,
    );
  }

  /// Verifies a file on disk and extracts media into [stagingDir].
  static Future<BackupFile> decodeFileToStaging(
    File file, {
    required Directory stagingDir,
  }) async {
    final length = await file.length();
    if (length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    final bytes = await file.readAsBytes();
    final decoded = decodeAndVerify(bytes);
    final payload = jsonDecode(utf8.decode(decoded.jsonUtf8));
    if (payload is! Map) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    final mediaRaw = payload['media_files'];
    final manifest = <BackupMediaManifestEntry>[];
    if (mediaRaw is List) {
      for (final row in mediaRaw) {
        if (row is! Map) {
          throw const BackupException(BackupErrorCode.malformedPayload);
        }
        manifest.add(
          BackupMediaManifestEntry.fromJson(row.cast<String, Object?>()),
        );
      }
    } else if (decoded.header.formatVersion >= 2) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    if (manifest.length != decoded.mediaBlobs.length) {
      throw const BackupException(BackupErrorCode.mediaMissing);
    }
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create(recursive: true);
    for (var i = 0; i < manifest.length; i++) {
      final entry = manifest[i];
      BackupMedia.assertSafeRelPath(entry.relPath);
      final blob = decoded.mediaBlobs[i];
      if (blob.length != entry.byteSize) {
        throw const BackupException(BackupErrorCode.mediaMissing);
      }
      if (sha256.convert(blob).toString() != entry.sha256) {
        throw const BackupException(BackupErrorCode.checksumMismatch);
      }
      final out = File(p.join(stagingDir.path, entry.relPath));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(blob, flush: true);
    }
    return decoded;
  }

  static Map<String, Object?> _payloadObject(BackupSnapshot snapshot) {
    return {
      'inventory': snapshot.inventory,
      'nodes': snapshot.nodes,
      'categories': snapshot.categories,
      'node_categories': snapshot.nodeCategories,
      'stock_movements': snapshot.stockMovements,
      'purchase_events': snapshot.purchaseEvents,
      'app_preferences': snapshot.appPreferences,
      'node_documents': snapshot.nodeDocuments,
      'media_files': [
        for (final entry in snapshot.mediaFiles) entry.toJson(),
      ],
    };
  }

  static List<int> _frame(
    List<int> payloadBytes, {
    required DateTime createdAtUtc,
  }) {
    if (payloadBytes.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    final digest = sha256.convert(payloadBytes).toString();
    final headerObject = <String, Object?>{
      'format_id': backupFormatId,
      'format_version': backupFormatVersion,
      'data_schema_version': backupDataSchemaVersion,
      'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
      'payload_length': payloadBytes.length,
      'payload_sha256': digest,
    };
    final headerLine = _utf8.encode('${jsonEncode(headerObject)}\n');
    if (headerLine.length > backupMaxHeaderBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    final bytes = BytesBuilder(copy: false)
      ..add(_magicLine)
      ..add(headerLine)
      ..add(payloadBytes);
    final file = bytes.takeBytes();
    if (file.length > backupMaxFileBytes) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    return file;
  }

  static ({BackupHeader header, List<int> payloadBytes}) _parseFrame(
    List<int> bytes,
  ) {
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
        header.formatVersion < backupMinFormatVersion ||
        header.formatVersion > backupFormatVersion ||
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
    final payloadBytes = bytes.sublist(payloadStart);
    final digest = sha256.convert(payloadBytes).toString();
    if (digest != header.payloadSha256) {
      throw const BackupException(BackupErrorCode.checksumMismatch);
    }
    return (header: header, payloadBytes: payloadBytes);
  }

  static ({List<int> jsonUtf8, List<List<int>> mediaBlobs}) _splitPayload(
    List<int> payloadBytes, {
    required int formatVersion,
  }) {
    if (formatVersion == 1) {
      return (jsonUtf8: payloadBytes, mediaBlobs: const []);
    }
    if (payloadBytes.length < 4) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    final jsonLen = _readUint32BE(payloadBytes, 0);
    final jsonStart = 4;
    final jsonEnd = jsonStart + jsonLen;
    if (jsonLen < 0 || jsonEnd > payloadBytes.length) {
      throw const BackupException(BackupErrorCode.lengthMismatch);
    }
    final jsonUtf8 = payloadBytes.sublist(jsonStart, jsonEnd);
    final mediaBlobs = <List<int>>[];
    var offset = jsonEnd;
    while (offset < payloadBytes.length) {
      if (offset + 4 > payloadBytes.length) {
        throw const BackupException(BackupErrorCode.lengthMismatch);
      }
      final mediaLen = _readUint32BE(payloadBytes, offset);
      offset += 4;
      final mediaEnd = offset + mediaLen;
      if (mediaLen < 0 || mediaEnd > payloadBytes.length) {
        throw const BackupException(BackupErrorCode.lengthMismatch);
      }
      mediaBlobs.add(payloadBytes.sublist(offset, mediaEnd));
      offset = mediaEnd;
    }
    if (mediaBlobs.length > backupMaxMediaFiles) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    return (jsonUtf8: jsonUtf8, mediaBlobs: mediaBlobs);
  }

  static void _validateJsonShape(
    List<int> jsonUtf8, {
    required int dataSchemaVersion,
  }) {
    try {
      final decoded = jsonDecode(_utf8.decode(jsonUtf8, allowMalformed: false));
      if (decoded is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requirePayloadShape(
        decoded.cast<String, Object?>(),
        dataSchemaVersion: dataSchemaVersion,
      );
    } on BackupException {
      rethrow;
    } on FormatException {
      throw const BackupException(BackupErrorCode.malformedPayload);
    } on Exception {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
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

  static void _requirePayloadShape(
    Map<String, Object?> payload, {
    required int dataSchemaVersion,
  }) {
    final expectedCore = {
      'inventory',
      'nodes',
      'categories',
      'node_categories',
    };
    final expectedV2 = {
      ...expectedCore,
      'stock_movements',
      'purchase_events',
      'app_preferences',
      'node_documents',
      'media_files',
    };
    final expected = dataSchemaVersion >= 3 ? expectedV2 : expectedCore;
    if (dataSchemaVersion >= 3) {
      if (!expected.every(payload.containsKey)) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
    } else if (payload.length != expected.length ||
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

    final nodeRequired = <String>{
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
    };
    final nodeOptional = <String>{'space'};
    if (dataSchemaVersion >= 3) {
      nodeRequired.addAll(const {
        'space',
        'stock_unit',
        'unit_cost_cents',
        'stock_reference',
        'desired_quantity',
        'target_price_cents',
        'sibling_order',
        'show_advanced',
        'barcode_ref',
        'purchase_date',
        'purchase_price_cents',
        'purchase_place',
        'objective',
        'photo_rel_path',
        'icon_key',
      });
      nodeOptional.clear();
    }

    for (final row in nodes) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requireKeys(
        row.cast<String, Object?>(),
        nodeRequired,
        optional: nodeOptional,
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

    if (dataSchemaVersion >= 3) {
      _requireListOfMaps(payload['stock_movements'], const {
        'id',
        'inventory_id',
        'node_id',
        'movement_type',
        'delta_quarters',
        'balance_after_quarters',
        'unit',
        'created_at',
      });
      _requireListOfMaps(payload['purchase_events'], const {
        'id',
        'inventory_id',
        'need_node_id',
        'event_type',
        'quantity',
        'target_price_cents',
        'paid_price_cents',
        'destination_space',
        'destination_node_id',
        'destination_parent_id',
        'created_at',
      });
      _requireListOfMaps(payload['app_preferences'], const {
        'key',
        'value',
      });
      _requireListOfMaps(payload['node_documents'], const {
        'id',
        'inventory_id',
        'node_id',
        'display_name',
        'rel_path',
        'mime_type',
        'byte_size',
        'sort_index',
        'created_at',
      });
      final media = payload['media_files'];
      if (media is! List) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      if (media.length > backupMaxMediaFiles) {
        throw const BackupException(BackupErrorCode.limitExceeded);
      }
      for (final row in media) {
        if (row is! Map) {
          throw const BackupException(BackupErrorCode.malformedPayload);
        }
        _requireKeys(row.cast<String, Object?>(), const {
          'rel_path',
          'byte_size',
          'sha256',
        });
      }
    }
  }

  static void _requireListOfMaps(Object? raw, Set<String> keys) {
    if (raw is! List) {
      throw const BackupException(BackupErrorCode.malformedPayload);
    }
    for (final row in raw) {
      if (row is! Map) {
        throw const BackupException(BackupErrorCode.malformedPayload);
      }
      _requireKeys(row.cast<String, Object?>(), keys);
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

  static void _writeUint32BE(BytesBuilder builder, int value) {
    builder.add(_uint32BE(value));
  }

  static List<int> _uint32BE(int value) {
    if (value < 0 || value > 0xffffffff) {
      throw const BackupException(BackupErrorCode.limitExceeded);
    }
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  static int _readUint32BE(List<int> bytes, int offset) =>
      ((bytes[offset] & 0xff) << 24) |
      ((bytes[offset + 1] & 0xff) << 16) |
      ((bytes[offset + 2] & 0xff) << 8) |
      (bytes[offset + 3] & 0xff);

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on Exception {
      // Ignore.
    }
  }
}
