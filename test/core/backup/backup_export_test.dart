import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/backup/backup_codec.dart';
import 'package:inventory/core/backup/backup_contract.dart';
import 'package:inventory/core/backup/backup_exporter.dart';
import 'package:inventory/core/backup/backup_payload.dart';
import 'package:inventory/core/backup/backup_snapshot_reader.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 11, 14, 15, 30, 0);
  final tempRoot = Directory.systemTemp.createTempSync(
    'inventory_backup_test_',
  );
  tearDownAll(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  Future<
    ({
      InventoryDatabase database,
      InventoryEngine engine,
      BackupExporter exporter,
    })
  >
  openFixture() async {
    final database = InventoryDatabase(NativeDatabase.memory());
    final engine = InventoryEngine(
      database,
      clock: () => fixedNow,
      generateId: () =>
          '00000000-0000-4000-8000-${(_nextId++).toString().padLeft(12, '0')}',
    );
    final exporter = BackupExporter(
      database,
      clock: () => fixedNow,
      temporaryDirectory: () async => tempRoot,
    );
    return (database: database, engine: engine, exporter: exporter);
  }

  test('exporte un inventaire représentatif vérifiable', () async {
    final fixture = await openFixture();
    final engine = fixture.engine;
    final exporter = fixture.exporter;

    try {
      final maison = await engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final bureau = await engine.createNode(
        name: 'Bureau',
        type: NodeType.location,
        parentId: maison.id,
      );
      await engine.createNode(
        name: 'Lampe',
        type: NodeType.item,
        parentId: bureau.id,
        quantity: 2,
        valuation: const FinancialValuation(1250),
      );
      final souvenir = await engine.createNode(
        name: 'Photo',
        type: NodeType.item,
        parentId: bureau.id,
        valuation: const SentimentalValuation(5),
      );
      await engine.withdrawItem(souvenir.id, WithdrawalReason.donation);

      final before = await _tableFingerprint(fixture.database);
      final bytes = await exporter.buildFileBytes();
      final decoded = BackupCodec.decodeAndVerify(bytes);
      final after = await _tableFingerprint(fixture.database);
      expect(after, before);

      final text = utf8.decode(bytes);
      expect(text.startsWith('INVENTORY-BACKUP\n'), isTrue);
      expect(decoded.header.formatId, backupFormatId);
      expect(decoded.header.formatVersion, backupFormatVersion);
      expect(decoded.header.dataSchemaVersion, backupDataSchemaVersion);
      expect(decoded.header.payloadLength, decoded.payloadBytes.length);
      expect(
        decoded.header.payloadSha256,
        sha256.convert(decoded.payloadBytes).toString(),
      );

      final payload =
          jsonDecode(utf8.decode(decoded.jsonUtf8)) as Map<String, dynamic>;
      expect(payload.keys.toSet(), {
        'inventory',
        'nodes',
        'categories',
        'node_categories',
        'stock_movements',
        'purchase_events',
        'app_preferences',
        'node_documents',
        'media_files',
      });
      final nodes = (payload['nodes'] as List).cast<Map<String, dynamic>>();
      // Ordered by primary key id (creation sequence with sequential test ids).
      expect(nodes.map((node) => node['name']), [
        'Maison',
        'Bureau',
        'Lampe',
        'Photo',
      ]);
      final lamp = nodes.singleWhere((node) => node['name'] == 'Lampe');
      expect(lamp['quantity'], 2);
      expect(lamp['financial_value_cents'], 1250);
      expect(lamp['sentimental_value'], isNull);
      expect(lamp['value_mode'], 'financial');
      final photo = nodes.singleWhere((node) => node['name'] == 'Photo');
      expect(photo['status'], 'withdrawn');
      expect(photo['withdrawal_reason'], 'donation');
      expect(photo['parent_id'], isNull);
      expect(photo['sentimental_value'], 5);
      expect(photo['financial_value_cents'], isNull);
      expect(payload['categories'], isEmpty);
      expect(payload['node_categories'], isEmpty);
      expect(lamp['description'], isNull);
    } finally {
      await fixture.database.close();
    }
  });

  test('détecte troncature et altération du payload', () async {
    final fixture = await openFixture();
    try {
      await fixture.engine.createNode(name: 'Seul', type: NodeType.location);
      final bytes = await fixture.exporter.buildFileBytes();

      expect(
        () => BackupCodec.decodeAndVerify(bytes.sublist(0, bytes.length - 4)),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            BackupErrorCode.lengthMismatch,
          ),
        ),
      );

      final altered = Uint8List.fromList(bytes);
      altered[altered.length - 1] ^= 0x01;
      expect(
        () => BackupCodec.decodeAndVerify(altered),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            BackupErrorCode.checksumMismatch,
          ),
        ),
      );
    } finally {
      await fixture.database.close();
    }
  });

  test('exporte un inventaire vide et refuse une version inconnue', () async {
    final fixture = await openFixture();
    try {
      final bytes = await fixture.exporter.buildFileBytes();
      final file = BackupCodec.decodeAndVerify(bytes);
      final payload =
          jsonDecode(utf8.decode(file.jsonUtf8)) as Map<String, dynamic>;
      expect(payload['nodes'], isEmpty);
      expect(payload['categories'], isEmpty);
      expect(payload['node_categories'], isEmpty);
      expect(payload['media_files'], isEmpty);
      expect((payload['inventory'] as Map)['singleton_key'], 1);

      final headerEnd = bytes.indexOf(0x0A, utf8.encode('INVENTORY-BACKUP\n').length);
      final header = jsonDecode(
        utf8.decode(bytes.sublist(utf8.encode('INVENTORY-BACKUP\n').length, headerEnd)),
      ) as Map<String, dynamic>;
      header['format_version'] = 99;
      final broken = [
        ...utf8.encode('INVENTORY-BACKUP\n'),
        ...utf8.encode('${jsonEncode(header)}\n'),
        ...bytes.sublist(headerEnd + 1),
      ];
      expect(
        () => BackupCodec.decodeAndVerify(broken),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            BackupErrorCode.unsupportedVersion,
          ),
        ),
      );
    } finally {
      await fixture.database.close();
    }
  });

  test('annulation, écriture vérifiée et destination non relisible', () async {
    final fixture = await openFixture();
    try {
      await fixture.engine.createNode(name: 'Maison', type: NodeType.location);
      final before = await _tableFingerprint(fixture.database);

      final cancelled = await fixture.exporter.export(
        pickDestination: ({required suggestedName, required mimeType}) async =>
            null,
        writeDestination: ({required uri, required bytes}) async {},
      );
      expect(cancelled.outcome, BackupExportOutcome.cancelled);
      expect(await _tableFingerprint(fixture.database), before);

      List<int>? written;
      final verified = await fixture.exporter.export(
        pickDestination: ({required suggestedName, required mimeType}) async =>
            'memory://backup.invbackup',
        writeDestination: ({required uri, required bytes}) async {
          written = List<int>.from(bytes);
        },
        readDestination: (uri) async => written,
      );
      expect(verified.outcome, BackupExportOutcome.verified);
      expect(written, isNotNull);
      BackupCodec.decodeAndVerify(written!);

      final unverifiable = await fixture.exporter.export(
        pickDestination: ({required suggestedName, required mimeType}) async =>
            'memory://opaque.invbackup',
        writeDestination: ({required uri, required bytes}) async {},
        readDestination: (uri) async => null,
      );
      expect(unverifiable.outcome, BackupExportOutcome.writtenUnverified);

      final failedWrite = await fixture.exporter.export(
        pickDestination: ({required suggestedName, required mimeType}) async =>
            'memory://fail.invbackup',
        writeDestination: ({required uri, required bytes}) async {
          throw StateError('disk full');
        },
      );
      expect(failedWrite.outcome, BackupExportOutcome.failed);
      expect(failedWrite.errorCode, BackupErrorCode.writeFailed);
      expect(await _tableFingerprint(fixture.database), before);
    } finally {
      await fixture.database.close();
    }
  });

  test('inclut et vérifie les médias ; refuse manifeste incohérent', () async {
    final photoBytes = utf8.encode('fake-webp-bytes');
    final docBytes = utf8.encode('%PDF-1.4 fake');
    final photoEntry = BackupMediaManifestEntry(
      relPath: 'photos/demo.webp',
      byteSize: photoBytes.length,
      sha256: sha256.convert(photoBytes).toString(),
    );
    final docEntry = BackupMediaManifestEntry(
      relPath: 'documents/demo.pdf',
      byteSize: docBytes.length,
      sha256: sha256.convert(docBytes).toString(),
    );
    final fixture = await openFixture();
    try {
      final root = await fixture.engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final item = await fixture.engine.createNode(
        name: 'Bien photo',
        type: NodeType.item,
        parentId: root.id,
      );
      final base = await BackupSnapshotReader(fixture.database).read();
      final nodes = [
        for (final node in base.nodes)
          if (node['id'] == item.id)
            {...node, 'photo_rel_path': photoEntry.relPath}
          else
            node,
      ];
      final snapshot = BackupSnapshot(
        inventory: base.inventory,
        nodes: nodes,
        categories: const [],
        nodeCategories: const [],
        nodeDocuments: [
          {
            'id': '00000000-0000-4000-8000-000000000099',
            'inventory_id': base.inventory['id'],
            'node_id': item.id,
            'display_name': 'facture.pdf',
            'rel_path': docEntry.relPath,
            'mime_type': 'application/pdf',
            'byte_size': docBytes.length,
            'sort_index': 0,
            'created_at': fixedNow.toIso8601String(),
          },
        ],
        mediaFiles: [photoEntry, docEntry],
      );
      final bytes = BackupCodec.encodeFile(
        snapshot,
        createdAtUtc: fixedNow,
        media: [
          (entry: photoEntry, bytes: photoBytes),
          (entry: docEntry, bytes: docBytes),
        ],
      );
      final decoded = BackupCodec.decodeAndVerify(bytes);
      expect(decoded.mediaBlobs.length, 2);
      expect(decoded.mediaBlobs[0], photoBytes);
      final parsed = BackupPayload.decodeBytes(bytes);
      expect(parsed.mediaFiles.length, 2);
      expect(parsed.nodes.singleWhere((n) => n['id'] == item.id)['photo_rel_path'],
          photoEntry.relPath);

      final truncated = bytes.sublist(0, bytes.length - 3);
      expect(
        () => BackupCodec.decodeAndVerify(truncated),
        throwsA(
          isA<BackupException>().having(
            (e) => e.code,
            'code',
            BackupErrorCode.lengthMismatch,
          ),
        ),
      );

      final missingMedia = BackupSnapshot(
        inventory: snapshot.inventory,
        nodes: snapshot.nodes,
        categories: const [],
        nodeCategories: const [],
        nodeDocuments: snapshot.nodeDocuments,
        mediaFiles: [photoEntry],
      );
      expect(
        () => BackupPayload.validateBusinessRules(
          missingMedia,
          requireMedia: true,
        ),
        throwsA(
          isA<BackupException>().having(
            (e) => e.code,
            'code',
            BackupErrorCode.mediaMissing,
          ),
        ),
      );
    } finally {
      await fixture.database.close();
    }
  });

  test('la lecture d’instantané préserve les relations et l’ordre par identifiant', () async {
    final fixture = await openFixture();
    try {
      final root = await fixture.engine.createNode(
        name: 'Zed',
        type: NodeType.location,
      );
      await fixture.engine.createNode(name: 'Alpha', type: NodeType.location);
      final item = await fixture.engine.createNode(
        name: 'Bien',
        type: NodeType.item,
        parentId: root.id,
      );

      final snapshot = await BackupSnapshotReader(fixture.database).read();
      expect(snapshot.nodes.map((node) => node['name']), [
        'Zed',
        'Alpha',
        'Bien',
      ]);
      expect(snapshot.categories, isEmpty);
      expect(snapshot.nodeCategories, isEmpty);
      final bien = snapshot.nodes.singleWhere((node) => node['id'] == item.id);
      expect(bien['parent_id'], root.id);
    } finally {
      await fixture.database.close();
    }
  });
}

var _nextId = 1;

Future<String> _tableFingerprint(InventoryDatabase database) async {
  final inventories = await database.select(database.inventories).get();
  final nodes = await database.select(database.nodes).get();
  final categories = await database.select(database.categories).get();
  final associations = await database.select(database.nodeCategories).get();
  return jsonEncode({
    'inventories': [
      for (final row in inventories)
        [row.id, row.singletonKey, row.createdAt, row.updatedAt],
    ],
    'nodes': [
      for (final row in nodes)
        [
          row.id,
          row.parentId,
          row.name,
          row.nodeType,
          row.quantity,
          row.financialValueCents,
          row.sentimentalValue,
          row.status,
          row.withdrawalReason,
          row.withdrawnAt,
          row.updatedAt,
        ],
    ],
    'categories': [
      for (final row in categories) [row.id, row.name, row.updatedAt],
    ],
    'associations': [
      for (final row in associations)
        [row.inventoryId, row.nodeId, row.categoryId],
    ],
  });
}
