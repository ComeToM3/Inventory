import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/backup/backup_codec.dart';
import 'package:inventory/core/backup/backup_contract.dart';
import 'package:inventory/core/backup/backup_payload.dart';
import 'package:inventory/core/backup/backup_restorer.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePaths extends PathProviderPlatform {
  _FakePaths(this.root);
  final Directory root;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;

  @override
  Future<String?> getTemporaryPath() async =>
      Directory(p.join(root.path, 'tmp')).path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trip médias + restauration isolée', () async {
    final root = Directory.systemTemp.createTempSync('inv_m52_media_');
    PathProviderPlatform.instance = _FakePaths(root);
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    final photos = Directory(p.join(root.path, 'photos'))..createSync();
    final docs = Directory(p.join(root.path, 'documents'))..createSync();
    final photoFile = File(p.join(photos.path, 'shot.webp'))
      ..writeAsBytesSync(utf8Or('WEBPDATA'));
    final docFile = File(p.join(docs.path, 'bill.pdf'))
      ..writeAsBytesSync(utf8Or('%PDF-demo'));

    final sourceDb = InventoryDatabase(
      NativeDatabase(File(p.join(root.path, 'source.sqlite'))),
    );
    final targetDb = InventoryDatabase(
      NativeDatabase(File(p.join(root.path, 'target.sqlite'))),
    );
    addTearDown(() async {
      await sourceDb.close();
      await targetDb.close();
    });

    var seq = 1;
    final liveEngine = InventoryEngine(
      sourceDb,
      clock: () => DateTime.utc(2026, 11, 21, 12),
      generateId: () =>
          '00000000-0000-4000-8000-${(seq++).toString().padLeft(12, '0')}',
    );

    final rootLoc = await liveEngine.createNode(
      name: 'Maison',
      type: NodeType.location,
    );
    final item = await liveEngine.createNode(
      name: 'Lampe',
      type: NodeType.item,
      parentId: rootLoc.id,
      quantity: 1,
      valuation: const FinancialValuation(1000),
    );
    await sourceDb.customStatement(
      'UPDATE nodes SET photo_rel_path = ?, icon_key = ? WHERE id = ?',
      ['photos/shot.webp', 'lightbulb', item.id],
    );
    await sourceDb.customStatement(
      '''
      INSERT INTO node_documents
      (id, inventory_id, node_id, display_name, rel_path, mime_type, byte_size, sort_index, created_at)
      VALUES (?, (SELECT id FROM inventories LIMIT 1), ?, ?, ?, ?, ?, 0, ?)
      ''',
      [
        '00000000-0000-4000-8000-000000000090',
        item.id,
        'bill.pdf',
        'documents/bill.pdf',
        'application/pdf',
        docFile.lengthSync(),
        DateTime.utc(2026, 11, 21, 12).toIso8601String(),
      ],
    );
    await sourceDb.customStatement(
      "INSERT OR REPLACE INTO app_preferences (key, value) VALUES ('show_advanced_by_default', 'true')",
    );

    // Export via codec with collected files.
    final photoBytes = photoFile.readAsBytesSync();
    final docBytes = docFile.readAsBytesSync();
    final photoEntry = BackupMediaManifestEntry(
      relPath: 'photos/shot.webp',
      byteSize: photoBytes.length,
      sha256: sha256.convert(photoBytes).toString(),
    );
    final docEntry = BackupMediaManifestEntry(
      relPath: 'documents/bill.pdf',
      byteSize: docBytes.length,
      sha256: sha256.convert(docBytes).toString(),
    );

    final nodes = await sourceDb.select(sourceDb.nodes).get();
    final inv = await sourceDb.select(sourceDb.inventories).getSingle();
    final prefs = await sourceDb.select(sourceDb.appPreferences).get();
    final documents = await sourceDb.select(sourceDb.nodeDocuments).get();
    final snapshot = BackupSnapshot(
      inventory: {
        'id': inv.id,
        'singleton_key': inv.singletonKey,
        'created_at': inv.createdAt,
        'updated_at': inv.updatedAt,
      },
      nodes: [
        for (final n in nodes)
          {
            'id': n.id,
            'inventory_id': n.inventoryId,
            'parent_id': n.parentId,
            'space': n.space,
            'name': n.name,
            'node_type': n.nodeType,
            'quantity': n.quantity,
            'description': n.description,
            'condition': n.condition,
            'value_mode': n.valueMode,
            'financial_value_cents': n.financialValueCents,
            'sentimental_value': n.sentimentalValue,
            'stock_unit': n.stockUnit,
            'unit_cost_cents': n.unitCostCents,
            'stock_reference': n.stockReference,
            'desired_quantity': n.desiredQuantity,
            'target_price_cents': n.targetPriceCents,
            'sibling_order': n.siblingOrder,
            'show_advanced': n.showAdvanced,
            'barcode_ref': n.barcodeRef,
            'purchase_date': n.purchaseDate,
            'purchase_price_cents': n.purchasePriceCents,
            'purchase_place': n.purchasePlace,
            'objective': n.objective,
            'photo_rel_path': n.photoRelPath,
            'icon_key': n.iconKey,
            'status': n.status,
            'withdrawal_reason': n.withdrawalReason,
            'withdrawn_at': n.withdrawnAt,
            'created_at': n.createdAt,
            'updated_at': n.updatedAt,
          },
      ],
      categories: const [],
      nodeCategories: const [],
      appPreferences: [
        for (final r in prefs) {'key': r.key, 'value': r.value},
      ],
      nodeDocuments: [
        for (final r in documents)
          {
            'id': r.id,
            'inventory_id': r.inventoryId,
            'node_id': r.nodeId,
            'display_name': r.displayName,
            'rel_path': r.relPath,
            'mime_type': r.mimeType,
            'byte_size': r.byteSize,
            'sort_index': r.sortIndex,
            'created_at': r.createdAt,
          },
      ],
      mediaFiles: [photoEntry, docEntry],
    );

    final bytes = BackupCodec.encodeFile(
      snapshot,
      createdAtUtc: DateTime.utc(2026, 11, 21, 12),
      media: [
        (entry: photoEntry, bytes: photoBytes),
        (entry: docEntry, bytes: docBytes),
      ],
    );
    BackupCodec.decodeAndVerify(bytes);
    BackupPayload.decodeBytes(bytes);

    // Target starts with a different inventory.
    final targetEngine = InventoryEngine(
      targetDb,
      clock: () => DateTime.utc(2026, 11, 21, 12),
      generateId: () =>
          '00000000-0000-4000-8000-${(seq++).toString().padLeft(12, '0')}',
    );
    await targetEngine.createNode(name: 'Ancien', type: NodeType.location);

    final restorer = BackupRestorer(
      targetDb,
      temporaryDirectory: () async => Directory(p.join(root.path, 'tmp'))
        ..createSync(recursive: true),
    );
    final prepared = await restorer.prepare(bytes);
    expect(prepared.summary.nodeCount, 2);
    await restorer.apply(prepared.snapshot);
    await restorer.acknowledgeJournal();

    final restoredPhoto = File(p.join(root.path, 'photos', 'shot.webp'));
    final restoredDoc = File(p.join(root.path, 'documents', 'bill.pdf'));
    expect(await restoredPhoto.exists(), isTrue);
    expect(await restoredDoc.exists(), isTrue);
    expect(await restoredPhoto.readAsBytes(), photoBytes);
    expect(await restoredDoc.readAsBytes(), docBytes);

    final restoredNodes = await targetDb.select(targetDb.nodes).get();
    expect(restoredNodes.map((n) => n.name).toSet(), {'Maison', 'Lampe'});
    final lamp = restoredNodes.singleWhere((n) => n.name == 'Lampe');
    expect(lamp.photoRelPath, 'photos/shot.webp');
    expect(lamp.iconKey, 'lightbulb');
    expect(lamp.financialValueCents, 1000);

    final restoredPrefs = await targetDb.select(targetDb.appPreferences).get();
    expect(
      restoredPrefs.any(
        (p) => p.key == 'show_advanced_by_default' && p.value == 'true',
      ),
      isTrue,
    );
  });
}

List<int> utf8Or(String value) => value.codeUnits;
