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
    List<String> categoryIds = const [],
  }) => engine.createNode(
    name: name,
    type: type,
    parentId: parent?.id,
    quantity: quantity,
    valuation: valuation,
    categoryIds: categoryIds,
  );

  test('crée chaque type et reconstruit une hiérarchie profonde', () async {
    final home = await create('  Appartement  ', NodeType.location);
    final office = await create('Bureau', NodeType.location, parent: home);
    final cabinet = await create('Armoire', NodeType.container, parent: office);
    final toolbox = await create(
      'Boîte à outils',
      NodeType.itemContainer,
      parent: cabinet,
    );
    final box = await create('Boîte', NodeType.container, parent: toolbox);
    final cable = await create('Câble', NodeType.item, parent: box);

    expect(home.name, 'Appartement');
    expect(home.quantity, isNull);
    expect(home.valuation, isNull);
    expect(toolbox.quantity, 1);
    expect(cable.quantity, 1);
    expect(cable.valuation, const FinancialValuation(0));
    expect(cable.financialTotalCents, 0);

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
      create('Boîte racine', NodeType.container),
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
      final shelf = await create('Étagère', NodeType.container, parent: roomA);
      final bag = await create('Sac', NodeType.itemContainer, parent: shelf);
      final pouch = await create('Pochette', NodeType.container, parent: bag);
      final category = await engine.createCategory('Électronique');
      final charger = await create(
        'Chargeur',
        NodeType.item,
        parent: pouch,
        categoryIds: [category.id],
      );
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
      expect(_names(await engine.getNodeCategories(charger.id)), [
        'Électronique',
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
      final category = await engine.createCategory('Voyage');
      await engine.assignCategory(bag.id, category.id);

      final edited = await engine.updateDetails(
        bag.id,
        name: ' Valise bleue ',
        description: ' Cabine ',
        condition: 'Bon',
        quantity: 3,
      );
      expect(edited.name, 'Valise bleue');
      expect(edited.description, 'Cabine');
      expect(edited.condition, 'Bon');
      expect(edited.quantity, 3);
      expect(edited.financialTotalCents, 3750);
      expect(edited.id, bag.id);
      expect(edited.parentId, home.id);
      expect(edited.type, NodeType.itemContainer);
      expect((await engine.getChildren(bag.id)).single.id, child.id);
      expect((await engine.getNodeCategories(bag.id)).single.id, category.id);

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
          description: 'Non enregistré',
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
      expect(reopened.description, 'Cabine');
      expect(reopened.condition, 'Bon');
      expect(reopened.quantity, 3);
      expect(reopened.parentId, home.id);
    },
  );

  test('applique quantités et modes de valorisation exclusifs', () async {
    final home = await create('Appartement', NodeType.location);
    final drawer = await create('Tiroir', NodeType.container, parent: home);
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
      engine.updateQuantity(drawer.id, 2),
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
      engine.setValuation(drawer.id, const FinancialValuation(100)),
      InventoryErrorCode.requiresItem,
    );
    expect(
      (await engine.getNode(cables.id)).valuation,
      const FinancialValuation(0),
    );

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
      description: 'Noirs',
      condition: '   ',
    );
    expect(edited.name, 'Câbles');
    expect(edited.description, 'Noirs');
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
      final first = await engine.createCategory('Première');
      final second = await engine.createCategory('Deuxième');
      final item = await create(
        'Bien',
        NodeType.item,
        parent: home,
        valuation: const FinancialValuation(_maxInt64),
        categoryIds: [first.id],
      );
      final before = await _snapshot(database);
      await database.customStatement('''
      CREATE TEMP TRIGGER reject_grouped_category
      AFTER INSERT ON node_categories
      BEGIN
        SELECT RAISE(ABORT, 'forced category failure');
      END
    ''');
      await _expectCode(
        engine.updateItemDetails(
          item.id,
          name: 'Modifié',
          quantity: 2,
          valuation: const FinancialValuation(0),
          categoryIds: [second.id],
          newCategoryNames: ['Nouvelle'],
        ),
        InventoryErrorCode.constraintViolation,
      );
      expect(await _snapshot(database), before);
      await database.customStatement('DROP TRIGGER reject_grouped_category');

      final saved = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 2,
        valuation: const FinancialValuation(0),
        categoryIds: [second.id],
        newCategoryNames: ['Nouvelle'],
      );
      expect(saved.node.id, item.id);
      expect(saved.node.parentId, home.id);
      expect(saved.node.quantity, 2);
      expect(saved.node.valuation, const FinancialValuation(0));
      expect(
        _names(saved.categories),
        unorderedEquals(['Deuxième', 'Nouvelle']),
      );
      final ids = saved.categories.map((category) => category.id).toList();
      final highUnit = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 1,
        valuation: const FinancialValuation(_maxInt64),
        categoryIds: ids,
      );
      expect(highUnit.node.financialTotalCents, _maxInt64);
      final beforeOverflow = await _snapshot(database);
      await _expectCode(
        engine.updateItemDetails(
          item.id,
          name: 'Invalide',
          quantity: 2,
          valuation: const FinancialValuation(_maxInt64),
          categoryIds: ids,
        ),
        InventoryErrorCode.financialTotalOverflow,
      );
      expect(await _snapshot(database), beforeOverflow);
      final sentimental = await engine.updateItemDetails(
        item.id,
        name: 'Modifié',
        quantity: 2,
        valuation: const SentimentalValuation(4),
        categoryIds: ids,
      );
      expect(sentimental.node.valuation, const SentimentalValuation(4));
      final row = await _row(database, item.id);
      expect(row.financialValueCents, isNull);
      expect(row.sentimentalValue, 4);
    },
  );

  test('gère les catégories indépendamment de la hiérarchie', () async {
    final home = await create('Appartement', NodeType.location);
    final box = await create('Boîte', NodeType.container, parent: home);
    final electronics = await engine.createCategory('Électronique');
    final tools = await engine.createCategory('Outillage');
    final kit = await create(
      'Trousse',
      NodeType.itemContainer,
      parent: box,
      categoryIds: [electronics.id],
    );

    await engine.assignCategory(kit.id, tools.id);
    expect(
      _names(await engine.getNodeCategories(kit.id)),
      unorderedEquals(['Électronique', 'Outillage']),
    );
    await _expectCode(
      engine.assignCategory(kit.id, tools.id),
      InventoryErrorCode.categoryAlreadyAssigned,
    );
    await _expectCode(
      engine.assignCategory(box.id, tools.id),
      InventoryErrorCode.requiresItem,
    );
    await _expectCode(
      engine.createNode(
        name: 'Pièce',
        type: NodeType.location,
        parentId: home.id,
        categoryIds: [tools.id],
      ),
      InventoryErrorCode.requiresItem,
    );
    await _expectCode(
      engine.assignCategory(kit.id, 'absente'),
      InventoryErrorCode.categoryNotFound,
    );

    await engine.renameCategory(electronics.id, 'Informatique');
    expect((await engine.getNode(kit.id)).parentId, box.id);
    expect(
      _names(await engine.getNodeCategories(kit.id)),
      unorderedEquals(['Informatique', 'Outillage']),
    );

    await engine.unassignCategory(kit.id, tools.id);
    await _expectCode(
      engine.unassignCategory(kit.id, tools.id),
      InventoryErrorCode.categoryNotAssigned,
    );

    await engine.deleteCategory(electronics.id);
    expect(await engine.getNodeCategories(kit.id), isEmpty);
    expect((await engine.getNode(kit.id)).parentId, box.id);
    expect(_names(await engine.getCategories()), ['Outillage']);
  });

  test('recherche les nœuds actifs avec des filtres combinés', () async {
    final home = await create('Maison', NodeType.location);
    final workshop = await create('Atelier', NodeType.location);
    final office = await create('Bureau', NodeType.location, parent: home);
    final cabinet = await create('Armoire', NodeType.container, parent: office);
    final lighting = await engine.createCategory('Éclairage');
    final decoration = await engine.createCategory('Décoration');
    final homeLamp = await create(
      'Lampe',
      NodeType.item,
      parent: cabinet,
      quantity: 3,
      categoryIds: [lighting.id, decoration.id],
    );
    final workshopLamp = await create(
      'Lampe',
      NodeType.item,
      parent: workshop,
      categoryIds: [lighting.id],
    );
    final withdrawn = await create(
      'Lampe retirée',
      NodeType.item,
      parent: cabinet,
      categoryIds: [lighting.id],
    );
    await engine.withdrawItem(withdrawn.id, WithdrawalReason.loss);
    final accented = await create(
      'Étagère 100%_neuve',
      NodeType.container,
      parent: home,
    );
    await create('Étagère 100Xneuve', NodeType.container, parent: home);

    final lamps = await engine.searchNodes(
      InventorySearchCriteria(name: 'lAM', categoryId: lighting.id),
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
        categoryId: lighting.id,
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
        InventorySearchCriteria(name: 'lam', type: NodeType.container),
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
    await _expectCode(
      engine.searchNodes(
        const InventorySearchCriteria(categoryId: 'catégorie absente'),
      ),
      InventoryErrorCode.categoryNotFound,
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
      InventorySearchCriteria(name: 'lam', categoryId: lighting.id),
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
    final cabinet = await create('Armoire', NodeType.container, parent: home);
    final box = await create('Boîte', NodeType.container, parent: cabinet);
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
    final cabinet = await create('Armoire', NodeType.container, parent: home);
    final bag = await create('Sac', NodeType.itemContainer, parent: cabinet);
    final category = await engine.createCategory('Vêtements');
    final scarf = await create(
      'Foulard',
      NodeType.item,
      parent: bag,
      valuation: const SentimentalValuation(5),
      categoryIds: [category.id],
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
      engine.withdrawItem(cabinet.id, WithdrawalReason.loss),
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
    expect(_names(await engine.getNodeCategories(scarf.id)), ['Vêtements']);
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
      categoryIds: [category.id],
    );
    await engine.deleteNodePermanently(mistake.id);
    await _expectCode(
      engine.getNode(mistake.id),
      InventoryErrorCode.nodeNotFound,
    );
    final associations = await database.select(database.nodeCategories).get();
    expect(associations.map((row) => row.nodeId), [scarf.id]);
    expect(_names(await engine.getCategories()), ['Vêtements']);
    expect(
      _names(await engine.getWithdrawnItems()),
      unorderedEquals(['Foulard', 'Sac']),
    );
  });

  test('annule entièrement une opération composée en échec', () async {
    final home = await create('Appartement', NodeType.location);
    final category = await engine.createCategory('Outillage');
    final before = await _snapshot(database);

    await _expectCode(
      create(
        'Perceuse',
        NodeType.item,
        parent: home,
        categoryIds: [category.id, 'absente'],
      ),
      InventoryErrorCode.categoryNotFound,
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
        categoryIds: [category.id],
      ),
      InventoryErrorCode.constraintViolation,
    );
    expect(await _snapshot(database), afterFirst);
  });

  test('conserve l’état métier après fermeture et réouverture', () async {
    final home = await create('Appartement', NodeType.location);
    final box = await create('Boîte', NodeType.container, parent: home);
    final category = await engine.createCategory('Électronique');
    final lot = await create(
      'Piles',
      NodeType.item,
      parent: box,
      quantity: 8,
      valuation: const FinancialValuation(125),
      categoryIds: [category.id],
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
    expect(_names(await engine.getNodeCategories(lot.id)), ['Électronique']);
    expect(_names(await engine.getChildren(box.id)), ['Piles']);
    final history = await engine.getWithdrawnItems();
    expect(_names(history), ['Montre']);
    expect(history.single.withdrawalReason, WithdrawalReason.loss);
    expect(history.single.withdrawnAt, _now);
  });
}

List<String> _names(Iterable<Object> values) => values
    .map(
      (value) => switch (value) {
        InventoryNode(:final name) => name,
        InventoryCategory(:final name) => name,
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
