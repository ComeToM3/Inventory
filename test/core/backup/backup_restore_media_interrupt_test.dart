import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/backup/backup_codec.dart';
import 'package:inventory/core/backup/backup_contract.dart';
import 'package:inventory/core/backup/backup_restorer.dart';
import 'package:inventory/core/backup/restoration_recovery.dart';
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
  final fixedNow = DateTime.utc(2026, 11, 21, 18);

  Future<
    ({
      Directory root,
      InventoryDatabase source,
      InventoryDatabase target,
      List<int> bytes,
      List<int> photoBytes,
    })
  >
  fixtureWithMedia() async {
    final root = Directory.systemTemp.createTempSync('inv_m53a_');
    PathProviderPlatform.instance = _FakePaths(root);
    Directory(p.join(root.path, 'photos')).createSync(recursive: true);
    Directory(p.join(root.path, 'documents')).createSync(recursive: true);
    final photoBytes = 'WEBP-REAL'.codeUnits;
    final docBytes = '%PDF-1.4 real'.codeUnits;
    File(p.join(root.path, 'photos', 'shot.webp')).writeAsBytesSync(photoBytes);
    File(p.join(root.path, 'documents', 'a.pdf')).writeAsBytesSync(docBytes);
    File(p.join(root.path, 'documents', 'b.png')).writeAsBytesSync([1, 2, 3, 4]);

    var seq = 1;
    String nextId() =>
        '00000000-0000-4000-8000-${(seq++).toString().padLeft(12, '0')}';

    final source = InventoryDatabase(
      NativeDatabase(File(p.join(root.path, 'source.sqlite'))),
    );
    final target = InventoryDatabase(
      NativeDatabase(File(p.join(root.path, 'target.sqlite'))),
    );
    final engine = InventoryEngine(
      source,
      clock: () => fixedNow,
      generateId: nextId,
    );
    final loc = await engine.createNode(name: 'Maison', type: NodeType.location);
    final item = await engine.createNode(
      name: 'Lampe',
      type: NodeType.item,
      parentId: loc.id,
      valuation: const FinancialValuation(2500),
    );
    await source.customStatement(
      'UPDATE nodes SET photo_rel_path = ?, icon_key = ? WHERE id = ?',
      ['photos/shot.webp', 'lightbulb', item.id],
    );
    final invId =
        (await source.select(source.inventories).getSingle()).id;
    await source.customStatement(
      '''
INSERT INTO node_documents
(id, inventory_id, node_id, display_name, rel_path, mime_type, byte_size, sort_index, created_at)
VALUES (?, ?, ?, 'a.pdf', 'documents/a.pdf', 'application/pdf', ?, 0, ?),
       (?, ?, ?, 'b.png', 'documents/b.png', 'image/png', 4, 1, ?)
''',
      [
        nextId(),
        invId,
        item.id,
        docBytes.length,
        fixedNow.toIso8601String(),
        nextId(),
        invId,
        item.id,
        fixedNow.toIso8601String(),
      ],
    );

    final photoEntry = BackupMediaManifestEntry(
      relPath: 'photos/shot.webp',
      byteSize: photoBytes.length,
      sha256: sha256.convert(photoBytes).toString(),
    );
    final docA = BackupMediaManifestEntry(
      relPath: 'documents/a.pdf',
      byteSize: docBytes.length,
      sha256: sha256.convert(docBytes).toString(),
    );
    final docBBytes = [1, 2, 3, 4];
    final docB = BackupMediaManifestEntry(
      relPath: 'documents/b.png',
      byteSize: 4,
      sha256: sha256.convert(docBBytes).toString(),
    );

    final nodes = await source.select(source.nodes).get();
    final inv = await source.select(source.inventories).getSingle();
    final docs = await source.select(source.nodeDocuments).get();
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
      nodeDocuments: [
        for (final r in docs)
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
      mediaFiles: [photoEntry, docA, docB],
    );
    final bytes = BackupCodec.encodeFile(
      snapshot,
      createdAtUtc: fixedNow,
      media: [
        (entry: photoEntry, bytes: photoBytes),
        (entry: docA, bytes: docBytes),
        (entry: docB, bytes: docBBytes),
      ],
    );
    return (
      root: root,
      source: source,
      target: target,
      bytes: bytes,
      photoBytes: photoBytes,
    );
  }

  test('restauration médias normale → committed + fichiers live', () async {
    final f = await fixtureWithMedia();
    addTearDown(() async {
      await f.source.close();
      await f.target.close();
      if (f.root.existsSync()) f.root.deleteSync(recursive: true);
    });
    final targetEngine = InventoryEngine(
      f.target,
      clock: () => fixedNow,
      generateId: () => '00000000-0000-4000-8000-000000009999',
    );
    await targetEngine.createNode(name: 'Ancien', type: NodeType.location);

    final restorer = BackupRestorer(f.target);
    final prepared = await restorer.prepare(f.bytes);
    await restorer.apply(prepared.snapshot);
    await restorer.acknowledgeJournal();

    expect(await File(p.join(f.root.path, 'photos', 'shot.webp')).exists(), isTrue);
    expect(await File(p.join(f.root.path, 'documents', 'a.pdf')).exists(), isTrue);
    expect(await BackupRestorer.currentJournal(f.target), isNull);
    final recovery = await RestorationRecovery(f.target).inspect();
    expect(recovery, isNull);
  });

  test('échec avant remplacement SQLite conserve l’ancien inventaire', () async {
    final f = await fixtureWithMedia();
    addTearDown(() async {
      await f.source.close();
      await f.target.close();
      if (f.root.existsSync()) f.root.deleteSync(recursive: true);
    });
    final targetEngine = InventoryEngine(
      f.target,
      clock: () => fixedNow,
      generateId: () => '00000000-0000-4000-8000-000000009998',
    );
    await targetEngine.createNode(name: 'Courant', type: NodeType.location);
    final before = await f.target.select(f.target.nodes).get();

    final restorer = BackupRestorer(
      f.target,
      debugAfterPending: () async => throw Exception('stop'),
    );
    final prepared = await restorer.prepare(f.bytes);
    await expectLater(
      () => restorer.apply(prepared.snapshot),
      throwsA(isA<BackupException>()),
    );
    final after = await f.target.select(f.target.nodes).get();
    expect(after.single.name, 'Courant');
    expect(before.length, after.length);
    expect(
      (await BackupRestorer.currentJournal(f.target))?.status,
      RestorationJournalStatus.pending.storageValue,
    );
    final recovery = await RestorationRecovery(f.target).inspect();
    expect(recovery?.messageKind, RestorationRecoveryMessage.notApplied);
  });

  test('échec après db_ready : recovery finalise les médias depuis staging', () async {
    final f = await fixtureWithMedia();
    addTearDown(() async {
      await f.source.close();
      await f.target.close();
      if (f.root.existsSync()) f.root.deleteSync(recursive: true);
    });
    final targetEngine = InventoryEngine(
      f.target,
      clock: () => fixedNow,
      generateId: () => '00000000-0000-4000-8000-000000009997',
    );
    await targetEngine.createNode(name: 'Courant', type: NodeType.location);

    final restorer = BackupRestorer(
      f.target,
      debugAfterDbReady: () async => throw Exception('crash after db_ready'),
    );
    final prepared = await restorer.prepare(f.bytes);
    await expectLater(
      () => restorer.apply(prepared.snapshot),
      throwsA(isA<BackupException>()),
    );
    expect(
      (await BackupRestorer.currentJournal(f.target))?.status,
      RestorationJournalStatus.dbReady.storageValue,
    );
    // New SQLite already applied.
    final names = (await f.target.select(f.target.nodes).get())
        .map((n) => n.name)
        .toSet();
    expect(names.contains('Maison'), isTrue);
    expect(names.contains('Courant'), isFalse);

    final recovery = await RestorationRecovery(f.target).inspect();
    expect(recovery?.messageKind, RestorationRecoveryMessage.completed);
    expect(await File(p.join(f.root.path, 'photos', 'shot.webp')).readAsBytes(),
        f.photoBytes);
    expect(
      (await BackupRestorer.currentJournal(f.target))?.status,
      RestorationJournalStatus.committed.storageValue,
    );
  });

  test('committed sans médias référencés → unreliable', () async {
    final f = await fixtureWithMedia();
    addTearDown(() async {
      await f.source.close();
      await f.target.close();
      if (f.root.existsSync()) f.root.deleteSync(recursive: true);
    });
    final restorer = BackupRestorer(f.target);
    final prepared = await restorer.prepare(f.bytes);
    await restorer.apply(prepared.snapshot);
    // Corrupt live media after successful commit.
    File(p.join(f.root.path, 'photos', 'shot.webp')).deleteSync();
    final recovery = await RestorationRecovery(f.target).inspect();
    expect(recovery?.messageKind, RestorationRecoveryMessage.unreliable);
  });
}
