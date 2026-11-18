import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/backup/backup_codec.dart';
import 'package:inventory/core/backup/backup_contract.dart';
import 'package:inventory/core/backup/backup_exporter.dart';
import 'package:inventory/core/backup/backup_payload.dart';
import 'package:inventory/core/backup/backup_restorer.dart';
import 'package:inventory/core/backup/restoration_recovery.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_models.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 11, 14, 16, 0, 0);
  var idSeq = 1;

  Future<
    ({
      InventoryDatabase database,
      InventoryEngine engine,
      BackupExporter exporter,
    })
  >
  open() async {
    final database = InventoryDatabase(NativeDatabase.memory());
    final engine = InventoryEngine(
      database,
      clock: () => fixedNow,
      generateId: () =>
          '00000000-0000-4000-8000-${(100000000000 + idSeq++).toString()}',
    );
    final exporter = BackupExporter(database, clock: () => fixedNow);
    return (database: database, engine: engine, exporter: exporter);
  }

  Future<String> fingerprint(InventoryDatabase database) async {
    final inventories = await database.select(database.inventories).get();
    final nodes = await database.select(database.nodes).get();
    final categories = await database.select(database.categories).get();
    final associations = await database.select(database.nodeCategories).get();
    return jsonEncode({
      'inventories': [
        for (final row in inventories) [row.id, row.updatedAt],
      ],
      'nodes': [
        for (final row in nodes)
          [row.id, row.name, row.parentId, row.status, row.updatedAt],
      ],
      'categories': [
        for (final row in categories) [row.id, row.name],
      ],
      'associations': [
        for (final row in associations) [row.nodeId, row.categoryId],
      ],
    });
  }

  test('restaure un inventaire validé et conserve les relations', () async {
    final source = await open();
    final target = await open();
    try {
      final maison = await source.engine.createNode(
        name: 'Maison',
        type: NodeType.location,
      );
      final bureau = await source.engine.createNode(
        name: 'Bureau',
        type: NodeType.location,
        parentId: maison.id,
      );
      await source.engine.createNode(
        name: 'Lampe',
        type: NodeType.item,
        parentId: bureau.id,
        quantity: 2,
        valuation: const FinancialValuation(1250),
      );
      final photo = await source.engine.createNode(
        name: 'Photo',
        type: NodeType.item,
        parentId: bureau.id,
        valuation: const SentimentalValuation(5),
      );
      await source.engine.withdrawItem(photo.id, WithdrawalReason.donation);
      final bytes = await source.exporter.buildFileBytes();

      await target.engine.createNode(
        name: 'Temporaire',
        type: NodeType.location,
      );

      final restorer = BackupRestorer(target.database, clock: () => fixedNow);
      final prepared = await restorer.prepare(bytes);
      expect(prepared.summary.nodeCount, 4);
      expect(prepared.summary.withdrawnCount, 1);
      await restorer.apply(prepared.snapshot);
      await restorer.acknowledgeJournal();

      final nodes = await target.engine.getRootLocations();
      expect(nodes.map((node) => node.name), ['Maison']);
      final children = await target.engine.getChildren(nodes.single.id);
      expect(children.map((node) => node.name), ['Bureau']);
      final items = await target.engine.getChildren(children.single.id);
      expect(items.map((node) => node.name), ['Lampe']);
      expect(items.single.quantity, 2);
      expect(items.single.financialTotalCents, 2500);
      final history = await target.engine.getWithdrawnItems();
      expect(history.single.name, 'Photo');
      expect(history.single.withdrawalReason, WithdrawalReason.donation);
      expect(await BackupRestorer.currentJournal(target.database), isNull);
    } finally {
      await source.database.close();
      await target.database.close();
    }
  });

  test('rejette un fichier altéré sans modifier la base active', () async {
    final fixture = await open();
    try {
      await fixture.engine.createNode(name: 'Actuel', type: NodeType.location);
      final before = await fingerprint(fixture.database);
      final bytes = Uint8List.fromList(
        utf8.encode('INVENTORY-BACKUP\n{"format_id":"inventory-backup"}\n{}'),
      );
      final restorer = BackupRestorer(fixture.database);
      expect(
        () => restorer.prepare(bytes),
        throwsA(isA<BackupException>()),
      );
      expect(await fingerprint(fixture.database), before);
      expect(await BackupRestorer.currentJournal(fixture.database), isNull);
    } finally {
      await fixture.database.close();
    }
  });

  test('une interruption après pending conserve l’ancien inventaire', () async {
    final source = await open();
    final target = await open();
    try {
      await source.engine.createNode(name: 'Archive', type: NodeType.location);
      final bytes = await source.exporter.buildFileBytes();
      await target.engine.createNode(name: 'Courant', type: NodeType.location);
      final before = await fingerprint(target.database);

      final restorer = BackupRestorer(
        target.database,
        clock: () => fixedNow,
        debugAfterPending: () async {
          throw Exception('interrupted after pending');
        },
      );
      final prepared = await restorer.prepare(bytes);
      await expectLater(
        () => restorer.apply(prepared.snapshot),
        throwsA(isA<BackupException>()),
      );
      expect(await fingerprint(target.database), before);
      final journal = await BackupRestorer.currentJournal(target.database);
      expect(journal?.status, RestorationJournalStatus.pending.name);

      final recovery = await RestorationRecovery(target.database).inspect();
      expect(recovery?.messageKind, RestorationRecoveryMessage.notApplied);
      await RestorationRecovery(target.database).acknowledge(recovery!);
      expect(await BackupRestorer.currentJournal(target.database), isNull);
      expect(await fingerprint(target.database), before);
    } finally {
      await source.database.close();
      await target.database.close();
    }
  });

  test('un échec avant committed annule le remplacement', () async {
    final source = await open();
    final target = await open();
    try {
      await source.engine.createNode(name: 'Archive', type: NodeType.location);
      final bytes = await source.exporter.buildFileBytes();
      await target.engine.createNode(name: 'Courant', type: NodeType.location);
      final before = await fingerprint(target.database);

      final restorer = BackupRestorer(
        target.database,
        clock: () => fixedNow,
        debugBeforeCommit: () async {
          throw Exception('interrupted before committed');
        },
      );
      final prepared = await restorer.prepare(bytes);
      await expectLater(
        () => restorer.apply(prepared.snapshot),
        throwsA(isA<BackupException>()),
      );
      expect(await fingerprint(target.database), before);
      expect(
        (await BackupRestorer.currentJournal(target.database))?.status,
        RestorationJournalStatus.pending.name,
      );
    } finally {
      await source.database.close();
      await target.database.close();
    }
  });

  test('refuse une sauvegarde avec cycle hiérarchique', () async {
    final fixture = await open();
    try {
      final root = await fixture.engine.createNode(
        name: 'A',
        type: NodeType.location,
      );
      final child = await fixture.engine.createNode(
        name: 'B',
        type: NodeType.location,
        parentId: root.id,
      );
      final bytes = await fixture.exporter.buildFileBytes();
      final file = BackupCodec.decodeAndVerify(bytes);
      final snapshot = BackupPayload.parseVerifiedFile(file);
      final mutated = BackupSnapshot(
        inventory: snapshot.inventory,
        nodes: [
          for (final node in snapshot.nodes)
            if (node['id'] == root.id)
              {...node, 'parent_id': child.id}
            else
              node,
        ],
        categories: snapshot.categories,
        nodeCategories: snapshot.nodeCategories,
      );
      final corrupt = BackupCodec.encodeFile(
        mutated,
        createdAtUtc: fixedNow,
      );
      expect(
        () => BackupPayload.decodeBytes(corrupt),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            BackupErrorCode.invalidBusinessData,
          ),
        ),
      );
    } finally {
      await fixture.database.close();
    }
  });

  test('normalise un ancien nœud container en item_container', () {
    final legacy = BackupPayload.normalizeLegacyNode({
      'id': 'x',
      'node_type': 'container',
      'description': 'ancien',
      'quantity': null,
      'value_mode': 'financial',
      'financial_value_cents': 500,
      'sentimental_value': null,
    });
    expect(legacy['node_type'], 'item_container');
    expect(legacy['quantity'], 1);
    expect(legacy['description'], isNull);
    expect(legacy['value_mode'], isNull);
    expect(legacy['financial_value_cents'], isNull);

    final zeroPrice = BackupPayload.normalizeLegacyNode({
      'node_type': 'item',
      'description': 'ancien',
      'quantity': 2,
      'value_mode': 'financial',
      'financial_value_cents': 0,
      'sentimental_value': null,
    });
    expect(zeroPrice['node_type'], 'item');
    expect(zeroPrice['quantity'], 2);
    expect(zeroPrice['value_mode'], isNull);
    expect(zeroPrice['financial_value_cents'], isNull);

    final priced = BackupPayload.normalizeLegacyNode({
      'node_type': 'item',
      'value_mode': 'financial',
      'financial_value_cents': 100,
    });
    expect(priced['value_mode'], 'financial');
    expect(priced['financial_value_cents'], 100);
  });

  test('restaure un inventaire vide valide', () async {
    final source = await open();
    final target = await open();
    try {
      final bytes = await source.exporter.buildFileBytes();
      await target.engine.createNode(
        name: 'À remplacer',
        type: NodeType.location,
      );
      final restorer = BackupRestorer(target.database, clock: () => fixedNow);
      final prepared = await restorer.prepare(bytes);
      expect(prepared.summary.nodeCount, 0);
      await restorer.apply(prepared.snapshot);
      await restorer.acknowledgeJournal();
      expect(await target.engine.getRootLocations(), isEmpty);
    } finally {
      await source.database.close();
      await target.database.close();
    }
  });
}
