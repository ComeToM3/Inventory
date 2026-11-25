import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/database/inventory_database.dart';
import 'package:inventory/core/domain/inventory_engine.dart';
import 'package:inventory/core/domain/inventory_exception.dart';
import 'package:inventory/core/domain/inventory_models.dart';

final _now = DateTime.utc(2026, 11, 13, 12);
const _maxInt64 = 0x7FFFFFFFFFFFFFFF;

void main() {
  late Directory directory;
  late String path;
  late InventoryDatabase database;
  late InventoryEngine engine;

  InventoryDatabase openDatabase() =>
      InventoryDatabase(NativeDatabase(File(path)));

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_engine_');
    path = '${directory.path}${Platform.pathSeparator}inventory.sqlite';
    database = openDatabase();
    engine = InventoryEngine(database, clock: () => _now);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<InventoryNode> create(
    String name,
    NodeType type, {
    InventoryNode? parent,
    int? quantity,
    NodeValuation? valuation,
  }) => engine.createNode(
    name: name,
    type: type,
    parentId: parent?.id,
    quantity: quantity,
    valuation: valuation,
  );

  test('crée chaque type et reconstruit une hiérarchie profonde', () async {
    final home = await create('  Appartement  ', NodeType.location);
    final office = await create('Bureau', NodeType.location, parent: home);
    final cabinet = await create('Armoire', NodeType.itemContainer, parent: office);
    final toolbox = await create(
      'Boîte à outils',
      NodeType.itemContainer,
      parent: cabinet,
    );
    final box = await create('Boîte', NodeType.itemContainer, parent: toolbox);
    final cable = await create('Câble', NodeType.item, parent: box);

    expect(home.name, 'Appartement');
    expect(home.quantity, isNull);
    expect(home.valuation, isNull);
    expect(toolbox.quantity, 1);
    expect(cable.quantity, 1);
    expect(cable.valuation, isNull);
    expect(cable.financialTotalCents, isNull);

    expect(_names(await engine.getPath(cable.id)), [
      'Appartement',
      'Bureau',
      'Armoire',
      'Boîte à outils',
      'Boîte',
      'Câble',
    ]);
    expect(_names(await engine.getAncestors(cable.id)), [
      'Appartement',
      'Bureau',
      'Armoire',
      'Boîte à outils',
      'Boîte',
    ]);
    expect(_names(await engine.getRootLocations()), ['Appartement']);
    expect(_names(await engine.getChildren(cabinet.id)), ['Boîte à outils']);

    await _expectCode(
      create('Boîte racine', NodeType.itemContainer),
      InventoryErrorCode.parentRequired,
    );
    await _expectCode(
      create('Bien racine', NodeType.item),
      InventoryErrorCode.parentRequired,
    );
    await _expectCode(
      create('Sous-câble', NodeType.item, parent: cable),
      InventoryErrorCode.parentCannotContain,
    );
    await _expectCode(
      engine.createNode(
        name: 'Orphelin',
        type: NodeType.item,
        parentId: 'absent',
      ),
      InventoryErrorCode.parentNotFound,
    );
    await _expectCode(
      create(' \u00a0 ', NodeType.item, parent: box),
      InventoryErrorCode.emptyName,
    );
    await _expectCode(
      create('Pièce', NodeType.location, parent: home, quantity: 2),
      InventoryErrorCode.requiresItem,
    );
  });

  test(
    'déplace un contenant avec ses descendants et refuse les cycles',
    () async {
      final home = await create('Appartement', NodeType.location);
      final roomA = await create('Chambre', NodeType.location, parent: home);
      final roomB = await create('Garage', NodeType.location, parent: home);
      final shelf = await create('Étagère', NodeType.itemContainer, parent: roomA);
      final bag = await create('Sac', NodeType.itemContainer, parent: shelf);
      final pouch = await create('Pochette', NodeType.itemContainer, parent: bag);
      final charger = await create('Chargeur', NodeType.item, parent: pouch);
      final emptyCase = await create(
        'Valise vide',
        NodeType.itemContainer,
        parent: roomA,
      );
      await engine.withdrawItem(emptyCase.id, WithdrawalReason.donation);

      final moved = await engine.moveNode(shelf.id, roomB.id);
      expect(moved.parentId, roomB.id);
      expect((await engine.getNode(bag.id)).parentId, shelf.id);
      expect((await engine.getNode(pouch.id)).parentId, bag.id);
      expect((await engine.getNode(charger.id)).parentId, pouch.id);
      expect(_names(await engine.getPath(charger.id)), [
        'Appartement',
        'Garage',
        'Étagère',
        'Sac',
        'Pochette',
        'Chargeur',
      ]);
      expect(await engine.getChildren(roomA.id), isEmpty);

      final before = await _snapshot(database);
      await database.customStatement('''
        CREATE TEMP TRIGGER reject_move
        AFTER UPDATE OF parent_id ON nodes
        BEGIN
          SELECT RAISE(ABORT, 'forced move failure');
        END
      ''');
      await _expectCode(
        engine.moveNode(shelf.id, roomA.id),
        InventoryErrorCode.constraintViolation,
      );
      expect(await _snapshot(database), before);
      await database.customStatement('DROP TRIGGER reject_move');

      await _expectCode(
        engine.moveNode(shelf.id, shelf.id),
        InventoryErrorCode.cycleDetected,
      );
      await _expectCode(
        engine.moveNode(shelf.id, pouch.id),
        InventoryErrorCode.cycleDetected,
      );
      await _expectCode(
        engine.moveNode(home.id, bag.id),
        InventoryErrorCode.cycleDetected,
      );
      await _expectCode(
        engine.moveNode(shelf.id, charger.id),
        InventoryErrorCode.parentCannotContain,
      );
      await _expectCode(
        engine.moveNode(shelf.id, emptyCase.id),
        InventoryErrorCode.parentInactive,
      );
      await _expectCode(
        create('Câble', NodeType.item, parent: emptyCase),
        InventoryErrorCode.parentInactive,
      );
      await _expectCode(
        engine.moveNode(shelf.id, null),
        InventoryErrorCode.parentRequired,
      );
      await _expectCode(
        engine.moveNode(emptyCase.id, roomB.id),
        InventoryErrorCode.nodeInactive,
      );
      expect(await _snapshot(database), before);

      await engine.moveNode(roomB.id, null);
      expect(_names(await engine.getRootLocations()), [
        'Appartement',
        'Garage',
      ]);
      expect(_names(await engine.getPath(charger.id)), [
        'Garage',
        'Étagère',
        'Sac',
        'Pochette',
        'Chargeur',
      ]);
    },
  );

  test(
    'modifie atomiquement les propriétés générales sans déplacer les nœuds',
    () async {
      final home = await create('Appartement', NodeType.location);
      final bag = await create(
        'Valise',
        NodeType.itemContainer,
        parent: home,
        quantity: 2,
        valuation: const FinancialValuation(1250),
      );
      final child = await create('Livre', NodeType.item, parent: bag);

      final edited = await engine.updateDetails(
        bag.id,
        name: ' Valise bleue ',
        condition: 'Bon',
        quantity: 3,
      );
      expect(edited.name, 'Valise bleue');
      expect(edited.condition, 'Bon');
      expect(edited.quantity, 3);
      expect(edited.financialTotalCents, 3750);
      expect(edited.id, bag.id);
      expect(edited.parentId, home.id);
      expect(edited.type, NodeType.itemContainer);
      expect((await engine.getChildren(bag.id)).single.id, child.id);

      final before = await _snapshot(database);
      await database.customStatement('''
      CREATE TEMP TRIGGER reject_general_text
      BEFORE UPDATE OF name ON nodes
      WHEN NEW.name = 'Refus technique'
      BEGIN
        SELECT RAISE(ABORT, 'forced write failure');
      END
    ''');
      await _expectCode(
        engine.updateDetails(
          bag.id,
          name: 'Refus technique',
          quantity: 7,
        ),
        InventoryErrorCode.constraintViolation,
      );
      expect(await _snapshot(database), before);
      await database.customStatement('DROP TRIGGER reject_general_text');

      await _expectCode(
        engine.updateDetails(bag.id, name: 'Invalide', quantity: 0),
        InventoryErrorCode.invalidQuantity,
      );
      await _expectCode(
        engine.updateDetails(bag.id, name: 'Trop grand', quantity: _maxInt64),
        InventoryErrorCode.financialTotalOverflow,
      );
      await _expectCode(
        engine.updateDetails(home.id, name: 'Maison', quantity: 2),
        InventoryErrorCode.requiresItem,
      );
      expect(await _snapshot(database), before);

      await database.close();
      database = openDatabase();
      engine = InventoryEngine(database);
      final reopened = await engine.getNode(bag.id);
      expect(reopened.name, 'Valise bleue');
      expect(reopened.condition, 'Bon');
      expect(reopened.quantity, 3);
      expect(reopened.parentId, home.id);
    },
  );

  test('applique quantités et modes de valorisation exclusifs', () async {
    final home = await create('Appartement', NodeType.location);
    final drawer = await create('Tiroir', NodeType.itemContainer, parent: home);
    final cables = await create(
      'Câbles USB-C',
      NodeType.item,
      parent: drawer,
      quantity: 4,
      valuation: const FinancialValuation(1250),
    );
    expect(cables.financialTotalCents, 5000);

    final reduced = await engine.updateQuantity(cables.id, 3);
    expect(reduced.financialTotalCents, 3750);
    await _expectCode(
      engine.updateQuantity(cables.id, 0),
      InventoryErrorCode.invalidQuantity,
    );
    await _expectCode(
      create('Lot vide', NodeType.item, parent: drawer, quantity: -1),
      InventoryErrorCode.invalidQuantity,
    );
    await _expectCode(
      engine.updateQuantity(home.id, 2),
      InventoryErrorCode.requiresItem,
    );

    final sentimental = await engine.setValuation(
      cables.id,
      const SentimentalValuation(4),
    );
    expect(sentimental.valuation, const SentimentalValuation(4));
    expect(sentimental.financialTotalCents, isNull);
    var row = await _row(database, cables.id);
    expect(row.valueMode, 'sentimental');
    expect(row.financialValueCents, isNull);
    expect(row.sentimentalValue, 4);

    final financial = await engine.setValuation(
      cables.id,
      const FinancialValuation(0),
    );
    expect(financial.financialTotalCents, 0);
    row = await _row(database, cables.id);
    expect(row.valueMode, 'financial');
    expect(row.financialValueCents, 0);
    expect(row.sentimentalValue, isNull);

    for (final invalid in [
      (
        const SentimentalValuation(0),
        InventoryErrorCode.invalidSentimentalValue,
      ),
      (
        const SentimentalValuation(6),
        InventoryErrorCode.invalidSentimentalValue,
      ),
      (const FinancialValuation(-1), InventoryErrorCode.invalidFinancialValue),
    ]) {
      await _expectCode(engine.setValuation(cables.id, invalid.$1), invalid.$2);
    }
    await _expectCode(
      engine.setValuation(home.id, const FinancialValuation(100)),
      InventoryErrorCode.requiresItem,
    );
    expect(
      (await engine.getNode(cables.id)).valuation,
      const FinancialValuation(0),
    );

    final cleared = await engine.setValuation(cables.id, null);
    expect(cleared.valuation, isNull);
    expect(cleared.financialTotalCents, isNull);
    row = await _row(database, cables.id);
    expect(row.valueMode, isNull);
    await engine.setValuation(cables.id, const FinancialValuation(0));

    await _expectCode(
      engine.setValuation(cables.id, const FinancialValuation(_maxInt64 ~/ 2)),
      InventoryErrorCode.financialTotalOverflow,
    );
    expect(
      (await engine.getNode(cables.id)).valuation,
      const FinancialValuation(0),
    );

    final edited = await engine.updateDetails(
      cables.id,
      name: ' Câbles ',
      condition: '   ',
    );
    expect(edited.name, 'Câbles');
    expect(edited.condition, isNull);
    expect(edited.parentId, drawer.id);
  });

  test('refuse les dépassements dans chaque chemin financier', () async {
    final home = await create('Maison', NodeType.location);
    await _expectCode(
      create(
        'Invalide',
        NodeType.item,
        parent: home,
        quantity: 2,
        valuation: const FinancialValuation(_maxInt64),
      ),
      InventoryErrorCode.financialTotalOverflow,
    );
    final item = await create(
      'Bien',
      NodeType.item,
      parent: home,
      valuation: const FinancialValuation(_maxInt64),
    );
    await _expectCode(
      engine.updateQuantity(item.id, 2),
      InventoryErrorCode.financialTotalOverflow,
    );
    expect((await engine.getNode(item.id)).quantity, 1);
    await engine.setValuation(
      item.id,
      const FinancialValuation(_maxInt64 ~/ 2),
    );
    final boundary = await engine.updateQuantity(item.id, 2);
    expect(boundary.financialTotalCents, _maxInt64 - 1);
    await _expectCode(
      engine.setValuation(item.id, const FinancialValuation(_maxInt64)),
      InventoryErrorCode.financialTotalOverflow,
    );
    expect(
      (await engine.getNode(item.id)).valuation,
      const FinancialValuation(_maxInt64 ~/ 2),
    );
  });

  test(
    'enregistre les modifications groupées ou annule chaque écriture',
    () async {
      final home = await create('Maison', NodeType.location);
      final item = await create(
        'Bien',
        NodeType.item,
        parent: home,
        valuation: const FinancialValuation(_maxInt64),
      );
      final before = await _snapshot(database);
      await database.customStatement('''
      CREATE TEMP TRIGGER reject_grouped_update
      BEFORE UPDATE OF name ON nodes
      WHEN NEW.name = 'Refus technique'
      BEGIN
        SELECT RAISE(ABORT, 'forced write failure');
      END
    ''');
      await _expectCode(
        engine.updateItemDetails(
          item.id,
          name: 'Refus technique',
          quantity: 2,
          valuation: const FinancialValuation(0),
        ),
        InventoryErrorCode.constraintViolation,
      );
      expect(await _snapshot(database), before);
      await database.customStatement('DROP TRIGGER reject_grouped_update');

      final saved = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 2,
        valuation: const FinancialValuation(0),
      );
      expect(saved.id, item.id);
      expect(saved.parentId, home.id);
      expect(saved.quantity, 2);
      expect(saved.valuation, const FinancialValuation(0));
      final highUnit = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 1,
        valuation: const FinancialValuation(_maxInt64),
      );
      expect(highUnit.financialTotalCents, _maxInt64);
      final beforeOverflow = await _snapshot(database);
      await _expectCode(
        engine.updateItemDetails(
          item.id,
          name: 'Invalide',
          quantity: 2,
          valuation: const FinancialValuation(_maxInt64),
        ),
        InventoryErrorCode.financialTotalOverflow,
      );
      expect(await _snapshot(database), beforeOverflow);
      final sentimental = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 2,
        valuation: const SentimentalValuation(4),
      );
      expect(sentimental.valuation, const SentimentalValuation(4));
      final row = await _row(database, item.id);
      expect(row.financialValueCents, isNull);
      expect(row.sentimentalValue, 4);
      final unset = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 2,
      );
      expect(unset.valuation, isNull);
      expect(unset.financialTotalCents, isNull);
    },
  );

  test('recherche les nœuds actifs avec des filtres combinés', () async {
    final home = await create('Maison', NodeType.location);
    final workshop = await create('Atelier', NodeType.location);
    final office = await create('Bureau', NodeType.location, parent: home);
    final cabinet = await create('Armoire', NodeType.itemContainer, parent: office);
    final homeLamp = await create(
      'Lampe',
      NodeType.item,
      parent: cabinet,
      quantity: 3,
    );
    final workshopLamp = await create(
      'Lampe',
      NodeType.item,
      parent: workshop,
    );
    final withdrawn = await create(
      'Lampe retirée',
      NodeType.item,
      parent: cabinet,
    );
    await engine.withdrawItem(withdrawn.id, WithdrawalReason.loss);
    final accented = await create(
      'Étagère 100%_neuve',
      NodeType.itemContainer,
      parent: home,
    );
    await create('Étagère 100Xneuve', NodeType.itemContainer, parent: home);

    final lamps = await engine.searchNodes(
      InventorySearchCriteria(name: 'lAM'),
    );
    expect(
      lamps.results.map((result) => result.nodeId),
      unorderedEquals([homeLamp.id, workshopLamp.id]),
    );
    expect(lamps.results, hasLength(2));
    final first = lamps.results.singleWhere(
      (result) => result.nodeId == homeLamp.id,
    );
    expect(first.type, NodeType.item);
    expect(first.quantity, 3);
    expect(first.path, 'Maison → Bureau → Armoire → Lampe');
    expect(
      lamps.results
          .singleWhere((result) => result.nodeId == workshopLamp.id)
          .path,
      'Atelier → Lampe',
    );

    final filtered = await engine.searchNodes(
      InventorySearchCriteria(
        name: 'LAM',
        type: NodeType.item,
        branchId: office.id,
      ),
    );
    expect(filtered.results.map((result) => result.nodeId), [homeLamp.id]);
    expect(_names(filtered.branchPath!), ['Maison', 'Bureau']);
    expect(
      (await engine.searchNodes(
        InventorySearchCriteria(name: 'Maison', branchId: home.id),
      )).results,
      isEmpty,
    );
    expect(
      (await engine.searchNodes(
        InventorySearchCriteria(name: 'lam', type: NodeType.itemContainer),
      )).results,
      isEmpty,
    );
    expect(
      (await engine.searchNodes(
        const InventorySearchCriteria(name: 'ÉTAGÈRE 100%_'),
      )).results.map((result) => result.nodeId),
      [accented.id],
    );
    await _expectCode(
      engine.searchNodes(InventorySearchCriteria(branchId: homeLamp.id)),
      InventoryErrorCode.parentCannotContain,
    );

    await engine.moveNode(homeLamp.id, workshop.id);
    expect(
      (await engine.searchNodes(
        InventorySearchCriteria(name: 'lam', branchId: office.id),
      )).results,
      isEmpty,
    );
    await database.close();
    database = openDatabase();
    engine = InventoryEngine(database);
    final reopened = await engine.searchNodes(
      InventorySearchCriteria(name: 'lam'),
    );
    expect(
      reopened.results.map((result) => result.nodeId),
      unorderedEquals([homeLamp.id, workshopLamp.id]),
    );
    expect(
      reopened.results
          .singleWhere((result) => result.nodeId == homeLamp.id)
          .path,
      'Atelier → Lampe',
    );
  });

  test('signale une hiérarchie cyclique pendant la recherche', () async {
    final home = await create('Maison', NodeType.location);
    final cabinet = await create('Armoire', NodeType.itemContainer, parent: home);
    final box = await create('Boîte', NodeType.itemContainer, parent: cabinet);
    await database.customStatement(
      'UPDATE nodes SET parent_id = ? WHERE id = ?',
      [box.id, cabinet.id],
    );

    await _expectCode(
      engine.searchNodes(const InventorySearchCriteria(name: 'Boîte')),
      InventoryErrorCode.invalidHierarchy,
    );
    await _expectCode(
      engine.searchNodes(InventorySearchCriteria(branchId: box.id)),
      InventoryErrorCode.invalidHierarchy,
    );
  });

  test('distingue retrait historique et suppression définitive', () async {
    final home = await create('Appartement', NodeType.location);
    final cabinet = await create('Armoire', NodeType.itemContainer, parent: home);
    final bag = await create('Sac', NodeType.itemContainer, parent: cabinet);
    final scarf = await create(
      'Foulard',
      NodeType.item,
      parent: bag,
      valuation: const SentimentalValuation(5),
    );

    final before = await _snapshot(database);
    await _expectCode(
      engine.deleteNodePermanently(cabinet.id),
      InventoryErrorCode.nodeHasChildren,
    );
    await _expectCode(
      engine.withdrawItem(bag.id, WithdrawalReason.loss),
      InventoryErrorCode.nodeHasChildren,
    );
    await _expectCode(
      engine.withdrawItem(home.id, WithdrawalReason.loss),
      InventoryErrorCode.requiresItem,
    );
    expect(await _snapshot(database), before);

    final withdrawn = await engine.withdrawItem(
      scarf.id,
      WithdrawalReason.donation,
    );
    expect(withdrawn.status, NodeStatus.withdrawn);
    expect(withdrawn.withdrawalReason, WithdrawalReason.donation);
    expect(withdrawn.withdrawnAt, _now);
    expect(withdrawn.parentId, isNull);
    expect(withdrawn.name, 'Foulard');
    expect(withdrawn.valuation, const SentimentalValuation(5));
    expect(await engine.getChildren(bag.id), isEmpty);
    expect(_names(await engine.getWithdrawnItems()), ['Foulard']);

    for (final operation in <Future<Object?> Function()>[
      () => engine.getPath(scarf.id),
      () => engine.updateQuantity(scarf.id, 2),
      () => engine.moveNode(scarf.id, bag.id),
      () => engine.withdrawItem(scarf.id, WithdrawalReason.sale),
      () => engine.deleteNodePermanently(scarf.id),
    ]) {
      await _expectCode(operation(), InventoryErrorCode.nodeInactive);
    }

    await engine.withdrawItem(bag.id, WithdrawalReason.sale);
    await engine.deleteNodePermanently(cabinet.id);
    expect(await engine.getChildren(home.id), isEmpty);
    expect(
      _names(await engine.getWithdrawnItems()),
      unorderedEquals(['Foulard', 'Sac']),
    );

    final mistake = await create(
      'Erreur',
      NodeType.item,
      parent: home,
    );
    await engine.deleteNodePermanently(mistake.id);
    await _expectCode(
      engine.getNode(mistake.id),
      InventoryErrorCode.nodeNotFound,
    );
    expect(
      _names(await engine.getWithdrawnItems()),
      unorderedEquals(['Foulard', 'Sac']),
    );
  });

  test('annule entièrement une opération composée en échec', () async {
    final home = await create('Appartement', NodeType.location);
    final before = await _snapshot(database);

    await _expectCode(
      create('Perceuse', NodeType.item, parent: home, quantity: 0),
      InventoryErrorCode.invalidQuantity,
    );
    expect(await _snapshot(database), before);

    final fixedIdEngine = InventoryEngine(
      database,
      clock: () => _now,
      generateId: () => 'identifiant-fixe',
    );
    await fixedIdEngine.createNode(
      name: 'Premier',
      type: NodeType.item,
      parentId: home.id,
    );
    final afterFirst = await _snapshot(database);
    await _expectCode(
      fixedIdEngine.createNode(
        name: 'Doublon',
        type: NodeType.item,
        parentId: home.id,
      ),
      InventoryErrorCode.constraintViolation,
    );
    expect(await _snapshot(database), afterFirst);
  });

  test('conserve l’état métier après fermeture et réouverture', () async {
    final home = await create('Appartement', NodeType.location);
    final box = await create('Boîte', NodeType.itemContainer, parent: home);
    final lot = await create(
      'Piles',
      NodeType.item,
      parent: box,
      quantity: 8,
      valuation: const FinancialValuation(125),
    );
    final lost = await create('Montre', NodeType.item, parent: box);
    await engine.withdrawItem(lost.id, WithdrawalReason.loss);

    await database.close();
    database = openDatabase();
    engine = InventoryEngine(database, clock: () => _now);

    final reloaded = await engine.getNode(lot.id);
    expect(reloaded.quantity, 8);
    expect(reloaded.financialTotalCents, 1000);
    expect(_names(await engine.getPath(lot.id)), [
      'Appartement',
      'Boîte',
      'Piles',
    ]);
    expect(_names(await engine.getChildren(box.id)), ['Piles']);
    final history = await engine.getWithdrawnItems();
    expect(_names(history), ['Montre']);
    expect(history.single.withdrawalReason, WithdrawalReason.loss);
    expect(history.single.withdrawnAt, _now);
  });

  test('agrège les totaux financiers de sous-arbre sans double comptage', () async {
    final home = await create('Maison', NodeType.location);
    final office = await create('Bureau', NodeType.location, parent: home);
    final cabinet = await create('Armoire', NodeType.itemContainer, parent: office);
    final lamp = await create(
      'Lampe',
      NodeType.item,
      parent: cabinet,
      quantity: 2,
      valuation: const FinancialValuation(1500),
    );
    final toolkit = await create(
      'Boîte à outils',
      NodeType.itemContainer,
      parent: cabinet,
      quantity: 1,
      valuation: const FinancialValuation(4000),
    );
    await create(
      'Tournevis',
      NodeType.item,
      parent: toolkit,
      valuation: const FinancialValuation(500),
    );
    await create(
      'Photo',
      NodeType.item,
      parent: office,
      valuation: const SentimentalValuation(5),
    );
    final sold = await create(
      'Vieux câble',
      NodeType.item,
      parent: office,
      valuation: const FinancialValuation(9999),
    );
    await engine.withdrawItem(sold.id, WithdrawalReason.sale);

    final closed = await engine.getSubtreeFinancialTotals([home.id]);
    expect(closed[home.id], isA<SubtreeFinancialAmount>());
    expect((closed[home.id]! as SubtreeFinancialAmount).cents, 2 * 1500 + 4000 + 500);

    final levels = await engine.getSubtreeFinancialTotals([
      home.id,
      office.id,
      cabinet.id,
      toolkit.id,
    ]);
    expect((levels[office.id]! as SubtreeFinancialAmount).cents, 7500);
    expect((levels[cabinet.id]! as SubtreeFinancialAmount).cents, 7500);
    expect((levels[toolkit.id]! as SubtreeFinancialAmount).cents, 4500);

    await engine.updateItemDetails(
      lamp.id,
      name: lamp.name,
      quantity: 3,
      valuation: const FinancialValuation(1500),
    );
    final afterQty = await engine.getSubtreeFinancialTotals([home.id, cabinet.id]);
    expect((afterQty[home.id]! as SubtreeFinancialAmount).cents, 3 * 1500 + 4500);
    expect((afterQty[cabinet.id]! as SubtreeFinancialAmount).cents, 9000);

    final salon = await create('Salon', NodeType.location, parent: home);
    await engine.moveNode(lamp.id, salon.id);
    final afterMove = await engine.getSubtreeFinancialTotals([
      home.id,
      cabinet.id,
      salon.id,
    ]);
    expect((afterMove[cabinet.id]! as SubtreeFinancialAmount).cents, 4500);
    expect((afterMove[salon.id]! as SubtreeFinancialAmount).cents, 4500);
    expect((afterMove[home.id]! as SubtreeFinancialAmount).cents, 9000);

    final empty = await create('Cave', NodeType.location, parent: home);
    final none = await engine.getSubtreeFinancialTotals([empty.id]);
    expect(none[empty.id], isA<SubtreeFinancialNone>());
  });

  test('signale un débordement de total de sous-arbre contrôlé', () async {
    final home = await create('Maison', NodeType.location);
    final a = await create(
      'A',
      NodeType.item,
      parent: home,
      valuation: const FinancialValuation(_maxInt64 - 10),
    );
    final b = await create(
      'B',
      NodeType.item,
      parent: home,
      valuation: const FinancialValuation(20),
    );
    expect(a.financialTotalCents, _maxInt64 - 10);
    expect(b.financialTotalCents, 20);
    final totals = await engine.getSubtreeFinancialTotals([home.id]);
    expect(totals[home.id], isA<SubtreeFinancialOverflow>());
  });

  test('expose la valorisation dans les résultats de recherche', () async {
    final home = await create('Maison', NodeType.location);
    await create(
      'Lampe EVGA',
      NodeType.item,
      parent: home,
      quantity: 2,
      valuation: const FinancialValuation(12000),
    );
    final found = await engine.searchNodes(
      const InventorySearchCriteria(name: 'EVGA'),
    );
    expect(found.results, hasLength(1));
    expect(found.results.single.quantity, 2);
    expect(found.results.single.valuation, const FinancialValuation(12000));
  });

  test(
    'M3.1 conserve l’ordre manuel des frères (création puis réordonnancement)',
    () async {
      final home = await create('Maison', NodeType.location);
      final room = await create('Chambre', NodeType.location, parent: home);
      final wardrobe =
          await create('Garde-robe', NodeType.location, parent: room);
      final desk = await create(
        'Bureau',
        NodeType.itemContainer,
        parent: room,
        valuation: const FinancialValuation(12000),
      );
      final computer = await create(
        'Ordinateur principal',
        NodeType.item,
        parent: room,
        valuation: const FinancialValuation(100000),
      );
      final keyboard = await create(
        'Clavier',
        NodeType.item,
        parent: room,
        valuation: const FinancialValuation(500),
      );

      // New siblings append in creation order.
      expect(_names(await engine.getChildren(room.id)), [
        'Garde-robe',
        'Bureau',
        'Ordinateur principal',
        'Clavier',
      ]);

      await engine.reorderSiblings(
        space: InventorySpace.goods,
        parentId: room.id,
        orderedIds: [desk.id, keyboard.id, computer.id, wardrobe.id],
      );
      expect(_names(await engine.getChildren(room.id)), [
        'Bureau',
        'Clavier',
        'Ordinateur principal',
        'Garde-robe',
      ]);
    },
  );

  test(
    'DEV-32 convertit un bien simple valorisé en contenant sans perdre id/valeur',
    () async {
      final home = await create('Maison', NodeType.location);
      final desk = await create(
        'bureau assis debout',
        NodeType.item,
        parent: home,
        quantity: 1,
        valuation: const FinancialValuation(12000),
      );
      expect(desk.name, 'Bureau assis debout');
      expect(desk.type, NodeType.item);

      final converted = await engine.convertItemKind(
        desk.id,
        NodeType.itemContainer,
      );
      expect(converted.id, desk.id);
      expect(converted.type, NodeType.itemContainer);
      expect(converted.name, 'Bureau assis debout');
      expect(converted.quantity, 1);
      expect(converted.financialTotalCents, 12000);
      expect(converted.parentId, home.id);

      final monitor = await create(
        'Moniteur',
        NodeType.item,
        parent: converted,
        valuation: const FinancialValuation(25000),
      );
      await create(
        'Clavier',
        NodeType.item,
        parent: converted,
        valuation: const FinancialValuation(500),
      );
      await create(
        'Souris',
        NodeType.item,
        parent: converted,
        valuation: const FinancialValuation(1000),
      );

      final totals = await engine.getSubtreeFinancialTotals([converted.id]);
      expect(
        (totals[converted.id]! as SubtreeFinancialAmount).cents,
        12000 + 25000 + 500 + 1000,
      );
      expect(monitor.parentId, converted.id);

      await _expectCode(
        engine.convertItemKind(converted.id, NodeType.item),
        InventoryErrorCode.nodeHasChildren,
      );
      expect((await engine.getNode(converted.id)).type, NodeType.itemContainer);
      expect((await engine.getChildren(converted.id)), hasLength(3));
    },
  );

  test(
    'DEV-32 reconvertit un contenant vide et refuse les noms trop longs',
    () async {
      final home = await create('Maison', NodeType.location);
      final box = await create(
        'Boîte',
        NodeType.itemContainer,
        parent: home,
        valuation: const FinancialValuation(800),
      );
      final simple = await engine.convertItemKind(box.id, NodeType.item);
      expect(simple.type, NodeType.item);
      expect(simple.financialTotalCents, 800);

      final longOk = 'a' * InventoryEngine.maxNameLength;
      final created = await create(longOk, NodeType.item, parent: home);
      expect(created.name.length, InventoryEngine.maxNameLength);

      await _expectCode(
        create('${longOk}x', NodeType.item, parent: home),
        InventoryErrorCode.nameTooLong,
      );

      // Historical longer name may be re-saved unchanged.
      await database.customStatement(
        "UPDATE nodes SET name = ? WHERE id = ?",
        ['${'b' * 90}', created.id],
      );
      final kept = await engine.updateItemDetails(
        created.id,
        name: 'b' * 90,
        quantity: 1,
      );
      expect(kept.name.length, 90);
      await _expectCode(
        engine.updateItemDetails(
          created.id,
          name: 'c' * 81,
          quantity: 1,
        ),
        InventoryErrorCode.nameTooLong,
      );
    },
  );
}

List<String> _names(Iterable<Object> values) => values
    .map(
      (value) => switch (value) {
        InventoryNode(:final name) => name,
        _ => throw ArgumentError.value(value),
      },
    )
    .toList();

Future<void> _expectCode(Future<Object?> operation, InventoryErrorCode code) =>
    expectLater(
      operation,
      throwsA(
        isA<InventoryException>().having((error) => error.code, 'code', code),
      ),
    );

Future<Node> _row(InventoryDatabase database, String id) => (database.select(
  database.nodes,
)..where((node) => node.id.equals(id))).getSingle();

Future<List<String>> _snapshot(InventoryDatabase database) async => [
  ...(await database.select(database.nodes).get()).map((row) => '$row'),
  ...(await database.select(database.categories).get()).map((row) => '$row'),
  ...(await database.select(database.nodeCategories).get()).map(
    (row) => '$row',
  ),
]..sort();
