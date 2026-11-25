// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_database.dart';

// ignore_for_file: type=lint
class $InventoriesTable extends Inventories
    with TableInfo<$InventoriesTable, Inventory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _singletonKeyMeta = const VerificationMeta(
    'singletonKey',
  );
  @override
  late final GeneratedColumn<int> singletonKey = GeneratedColumn<int>(
    'singleton_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    singletonKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Inventory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('singleton_key')) {
      context.handle(
        _singletonKeyMeta,
        singletonKey.isAcceptableOrUnknown(
          data['singleton_key']!,
          _singletonKeyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Inventory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Inventory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      singletonKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoriesTable createAlias(String alias) {
    return $InventoriesTable(attachedDatabase, alias);
  }
}

class Inventory extends DataClass implements Insertable<Inventory> {
  final String id;
  final int singletonKey;
  final String createdAt;
  final String updatedAt;
  const Inventory({
    required this.id,
    required this.singletonKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['singleton_key'] = Variable<int>(singletonKey);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  InventoriesCompanion toCompanion(bool nullToAbsent) {
    return InventoriesCompanion(
      id: Value(id),
      singletonKey: Value(singletonKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Inventory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Inventory(
      id: serializer.fromJson<String>(json['id']),
      singletonKey: serializer.fromJson<int>(json['singletonKey']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'singletonKey': serializer.toJson<int>(singletonKey),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Inventory copyWith({
    String? id,
    int? singletonKey,
    String? createdAt,
    String? updatedAt,
  }) => Inventory(
    id: id ?? this.id,
    singletonKey: singletonKey ?? this.singletonKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Inventory copyWithCompanion(InventoriesCompanion data) {
    return Inventory(
      id: data.id.present ? data.id.value : this.id,
      singletonKey: data.singletonKey.present
          ? data.singletonKey.value
          : this.singletonKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Inventory(')
          ..write('id: $id, ')
          ..write('singletonKey: $singletonKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, singletonKey, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Inventory &&
          other.id == this.id &&
          other.singletonKey == this.singletonKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InventoriesCompanion extends UpdateCompanion<Inventory> {
  final Value<String> id;
  final Value<int> singletonKey;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const InventoriesCompanion({
    this.id = const Value.absent(),
    this.singletonKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoriesCompanion.insert({
    required String id,
    this.singletonKey = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Inventory> custom({
    Expression<String>? id,
    Expression<int>? singletonKey,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (singletonKey != null) 'singleton_key': singletonKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoriesCompanion copyWith({
    Value<String>? id,
    Value<int>? singletonKey,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return InventoriesCompanion(
      id: id ?? this.id,
      singletonKey: singletonKey ?? this.singletonKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (singletonKey.present) {
      map['singleton_key'] = Variable<int>(singletonKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoriesCompanion(')
          ..write('id: $id, ')
          ..write('singletonKey: $singletonKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spaceMeta = const VerificationMeta('space');
  @override
  late final GeneratedColumn<String> space = GeneratedColumn<String>(
    'space',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('goods'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeTypeMeta = const VerificationMeta(
    'nodeType',
  );
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
    'node_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueModeMeta = const VerificationMeta(
    'valueMode',
  );
  @override
  late final GeneratedColumn<String> valueMode = GeneratedColumn<String>(
    'value_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('financial'),
  );
  static const VerificationMeta _financialValueCentsMeta =
      const VerificationMeta('financialValueCents');
  @override
  late final GeneratedColumn<int> financialValueCents = GeneratedColumn<int>(
    'financial_value_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sentimentalValueMeta = const VerificationMeta(
    'sentimentalValue',
  );
  @override
  late final GeneratedColumn<int> sentimentalValue = GeneratedColumn<int>(
    'sentimental_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockUnitMeta = const VerificationMeta(
    'stockUnit',
  );
  @override
  late final GeneratedColumn<String> stockUnit = GeneratedColumn<String>(
    'stock_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitCostCentsMeta = const VerificationMeta(
    'unitCostCents',
  );
  @override
  late final GeneratedColumn<int> unitCostCents = GeneratedColumn<int>(
    'unit_cost_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockReferenceMeta = const VerificationMeta(
    'stockReference',
  );
  @override
  late final GeneratedColumn<int> stockReference = GeneratedColumn<int>(
    'stock_reference',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _desiredQuantityMeta = const VerificationMeta(
    'desiredQuantity',
  );
  @override
  late final GeneratedColumn<int> desiredQuantity = GeneratedColumn<int>(
    'desired_quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPriceCentsMeta = const VerificationMeta(
    'targetPriceCents',
  );
  @override
  late final GeneratedColumn<int> targetPriceCents = GeneratedColumn<int>(
    'target_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siblingOrderMeta = const VerificationMeta(
    'siblingOrder',
  );
  @override
  late final GeneratedColumn<int> siblingOrder = GeneratedColumn<int>(
    'sibling_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _showAdvancedMeta = const VerificationMeta(
    'showAdvanced',
  );
  @override
  late final GeneratedColumn<bool> showAdvanced = GeneratedColumn<bool>(
    'show_advanced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_advanced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _barcodeRefMeta = const VerificationMeta(
    'barcodeRef',
  );
  @override
  late final GeneratedColumn<String> barcodeRef = GeneratedColumn<String>(
    'barcode_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceCentsMeta =
      const VerificationMeta('purchasePriceCents');
  @override
  late final GeneratedColumn<int> purchasePriceCents = GeneratedColumn<int>(
    'purchase_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePlaceMeta = const VerificationMeta(
    'purchasePlace',
  );
  @override
  late final GeneratedColumn<String> purchasePlace = GeneratedColumn<String>(
    'purchase_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _photoRelPathMeta = const VerificationMeta(
    'photoRelPath',
  );
  @override
  late final GeneratedColumn<String> photoRelPath = GeneratedColumn<String>(
    'photo_rel_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _withdrawalReasonMeta = const VerificationMeta(
    'withdrawalReason',
  );
  @override
  late final GeneratedColumn<String> withdrawalReason = GeneratedColumn<String>(
    'withdrawal_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _withdrawnAtMeta = const VerificationMeta(
    'withdrawnAt',
  );
  @override
  late final GeneratedColumn<String> withdrawnAt = GeneratedColumn<String>(
    'withdrawn_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryId,
    parentId,
    space,
    name,
    nodeType,
    quantity,
    description,
    condition,
    valueMode,
    financialValueCents,
    sentimentalValue,
    stockUnit,
    unitCostCents,
    stockReference,
    desiredQuantity,
    targetPriceCents,
    siblingOrder,
    showAdvanced,
    barcodeRef,
    purchaseDate,
    purchasePriceCents,
    purchasePlace,
    objective,
    photoRelPath,
    iconKey,
    status,
    withdrawalReason,
    withdrawnAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('space')) {
      context.handle(
        _spaceMeta,
        space.isAcceptableOrUnknown(data['space']!, _spaceMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('node_type')) {
      context.handle(
        _nodeTypeMeta,
        nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('value_mode')) {
      context.handle(
        _valueModeMeta,
        valueMode.isAcceptableOrUnknown(data['value_mode']!, _valueModeMeta),
      );
    }
    if (data.containsKey('financial_value_cents')) {
      context.handle(
        _financialValueCentsMeta,
        financialValueCents.isAcceptableOrUnknown(
          data['financial_value_cents']!,
          _financialValueCentsMeta,
        ),
      );
    }
    if (data.containsKey('sentimental_value')) {
      context.handle(
        _sentimentalValueMeta,
        sentimentalValue.isAcceptableOrUnknown(
          data['sentimental_value']!,
          _sentimentalValueMeta,
        ),
      );
    }
    if (data.containsKey('stock_unit')) {
      context.handle(
        _stockUnitMeta,
        stockUnit.isAcceptableOrUnknown(data['stock_unit']!, _stockUnitMeta),
      );
    }
    if (data.containsKey('unit_cost_cents')) {
      context.handle(
        _unitCostCentsMeta,
        unitCostCents.isAcceptableOrUnknown(
          data['unit_cost_cents']!,
          _unitCostCentsMeta,
        ),
      );
    }
    if (data.containsKey('stock_reference')) {
      context.handle(
        _stockReferenceMeta,
        stockReference.isAcceptableOrUnknown(
          data['stock_reference']!,
          _stockReferenceMeta,
        ),
      );
    }
    if (data.containsKey('desired_quantity')) {
      context.handle(
        _desiredQuantityMeta,
        desiredQuantity.isAcceptableOrUnknown(
          data['desired_quantity']!,
          _desiredQuantityMeta,
        ),
      );
    }
    if (data.containsKey('target_price_cents')) {
      context.handle(
        _targetPriceCentsMeta,
        targetPriceCents.isAcceptableOrUnknown(
          data['target_price_cents']!,
          _targetPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('sibling_order')) {
      context.handle(
        _siblingOrderMeta,
        siblingOrder.isAcceptableOrUnknown(
          data['sibling_order']!,
          _siblingOrderMeta,
        ),
      );
    }
    if (data.containsKey('show_advanced')) {
      context.handle(
        _showAdvancedMeta,
        showAdvanced.isAcceptableOrUnknown(
          data['show_advanced']!,
          _showAdvancedMeta,
        ),
      );
    }
    if (data.containsKey('barcode_ref')) {
      context.handle(
        _barcodeRefMeta,
        barcodeRef.isAcceptableOrUnknown(data['barcode_ref']!, _barcodeRefMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price_cents')) {
      context.handle(
        _purchasePriceCentsMeta,
        purchasePriceCents.isAcceptableOrUnknown(
          data['purchase_price_cents']!,
          _purchasePriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('purchase_place')) {
      context.handle(
        _purchasePlaceMeta,
        purchasePlace.isAcceptableOrUnknown(
          data['purchase_place']!,
          _purchasePlaceMeta,
        ),
      );
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    }
    if (data.containsKey('photo_rel_path')) {
      context.handle(
        _photoRelPathMeta,
        photoRelPath.isAcceptableOrUnknown(
          data['photo_rel_path']!,
          _photoRelPathMeta,
        ),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('withdrawal_reason')) {
      context.handle(
        _withdrawalReasonMeta,
        withdrawalReason.isAcceptableOrUnknown(
          data['withdrawal_reason']!,
          _withdrawalReasonMeta,
        ),
      );
    }
    if (data.containsKey('withdrawn_at')) {
      context.handle(
        _withdrawnAtMeta,
        withdrawnAt.isAcceptableOrUnknown(
          data['withdrawn_at']!,
          _withdrawnAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {inventoryId, id},
  ];
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      space: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      valueMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_mode'],
      ),
      financialValueCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}financial_value_cents'],
      ),
      sentimentalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentimental_value'],
      ),
      stockUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_unit'],
      ),
      unitCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cost_cents'],
      ),
      stockReference: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_reference'],
      ),
      desiredQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}desired_quantity'],
      ),
      targetPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_price_cents'],
      ),
      siblingOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sibling_order'],
      )!,
      showAdvanced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_advanced'],
      )!,
      barcodeRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_ref'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      ),
      purchasePriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_cents'],
      ),
      purchasePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_place'],
      ),
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      )!,
      photoRelPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_rel_path'],
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      withdrawalReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}withdrawal_reason'],
      ),
      withdrawnAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}withdrawn_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  final String id;
  final String inventoryId;
  final String? parentId;

  /// Inventory space: goods (Biens), stock, or to_buy (À acheter).
  final String space;
  final String name;
  final String nodeType;

  /// Goods: piece count. Stock products: level storage 0/1/2/4 (M2.1-C).
  final int? quantity;
  final String? description;
  final String? condition;
  final String? valueMode;
  final int? financialValueCents;
  final int? sentimentalValue;

  /// Internal Stock sentinel / legacy unit label; null outside stock products.
  final String? stockUnit;

  /// Legacy optional unit cost; unused by M2.1-C UI.
  final int? unitCostCents;

  /// Optional conceptual total for a Stock product (e.g. 10).
  final int? stockReference;

  /// To-buy: wished quantity; null outside to-buy needs.
  final int? desiredQuantity;

  /// To-buy: optional target unit price in CAD cents.
  final int? targetPriceCents;

  /// Manual display order among active siblings (same parent + space).
  final int siblingOrder;

  /// Snapshot of advanced-section expansion at creation (or later toggles).
  /// Independent of the global default preference after the node exists.
  final bool showAdvanced;

  /// Optional barcode / reference (goods advanced fields, M4.1-B).
  final String? barcodeRef;

  /// Optional purchase date as `yyyy-MM-dd` (goods only).
  final String? purchaseDate;

  /// Optional amount paid in CAD cents (independent of valuation).
  final int? purchasePriceCents;

  /// Optional seller / place of purchase.
  final String? purchasePlace;

  /// Goods objective: none | sell | repair.
  final String objective;

  /// Relative path to the optional main photo WebP (`photos/….webp`).
  final String? photoRelPath;

  /// Manual icon catalog key; null = resolve automatically from the name.
  final String? iconKey;
  final String status;
  final String? withdrawalReason;
  final String? withdrawnAt;
  final String createdAt;
  final String updatedAt;
  const Node({
    required this.id,
    required this.inventoryId,
    this.parentId,
    required this.space,
    required this.name,
    required this.nodeType,
    this.quantity,
    this.description,
    this.condition,
    this.valueMode,
    this.financialValueCents,
    this.sentimentalValue,
    this.stockUnit,
    this.unitCostCents,
    this.stockReference,
    this.desiredQuantity,
    this.targetPriceCents,
    required this.siblingOrder,
    required this.showAdvanced,
    this.barcodeRef,
    this.purchaseDate,
    this.purchasePriceCents,
    this.purchasePlace,
    required this.objective,
    this.photoRelPath,
    this.iconKey,
    required this.status,
    this.withdrawalReason,
    this.withdrawnAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_id'] = Variable<String>(inventoryId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['space'] = Variable<String>(space);
    map['name'] = Variable<String>(name);
    map['node_type'] = Variable<String>(nodeType);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<int>(quantity);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || valueMode != null) {
      map['value_mode'] = Variable<String>(valueMode);
    }
    if (!nullToAbsent || financialValueCents != null) {
      map['financial_value_cents'] = Variable<int>(financialValueCents);
    }
    if (!nullToAbsent || sentimentalValue != null) {
      map['sentimental_value'] = Variable<int>(sentimentalValue);
    }
    if (!nullToAbsent || stockUnit != null) {
      map['stock_unit'] = Variable<String>(stockUnit);
    }
    if (!nullToAbsent || unitCostCents != null) {
      map['unit_cost_cents'] = Variable<int>(unitCostCents);
    }
    if (!nullToAbsent || stockReference != null) {
      map['stock_reference'] = Variable<int>(stockReference);
    }
    if (!nullToAbsent || desiredQuantity != null) {
      map['desired_quantity'] = Variable<int>(desiredQuantity);
    }
    if (!nullToAbsent || targetPriceCents != null) {
      map['target_price_cents'] = Variable<int>(targetPriceCents);
    }
    map['sibling_order'] = Variable<int>(siblingOrder);
    map['show_advanced'] = Variable<bool>(showAdvanced);
    if (!nullToAbsent || barcodeRef != null) {
      map['barcode_ref'] = Variable<String>(barcodeRef);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<String>(purchaseDate);
    }
    if (!nullToAbsent || purchasePriceCents != null) {
      map['purchase_price_cents'] = Variable<int>(purchasePriceCents);
    }
    if (!nullToAbsent || purchasePlace != null) {
      map['purchase_place'] = Variable<String>(purchasePlace);
    }
    map['objective'] = Variable<String>(objective);
    if (!nullToAbsent || photoRelPath != null) {
      map['photo_rel_path'] = Variable<String>(photoRelPath);
    }
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || withdrawalReason != null) {
      map['withdrawal_reason'] = Variable<String>(withdrawalReason);
    }
    if (!nullToAbsent || withdrawnAt != null) {
      map['withdrawn_at'] = Variable<String>(withdrawnAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      inventoryId: Value(inventoryId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      space: Value(space),
      name: Value(name),
      nodeType: Value(nodeType),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      valueMode: valueMode == null && nullToAbsent
          ? const Value.absent()
          : Value(valueMode),
      financialValueCents: financialValueCents == null && nullToAbsent
          ? const Value.absent()
          : Value(financialValueCents),
      sentimentalValue: sentimentalValue == null && nullToAbsent
          ? const Value.absent()
          : Value(sentimentalValue),
      stockUnit: stockUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(stockUnit),
      unitCostCents: unitCostCents == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCostCents),
      stockReference: stockReference == null && nullToAbsent
          ? const Value.absent()
          : Value(stockReference),
      desiredQuantity: desiredQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(desiredQuantity),
      targetPriceCents: targetPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPriceCents),
      siblingOrder: Value(siblingOrder),
      showAdvanced: Value(showAdvanced),
      barcodeRef: barcodeRef == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodeRef),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      purchasePriceCents: purchasePriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePriceCents),
      purchasePlace: purchasePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePlace),
      objective: Value(objective),
      photoRelPath: photoRelPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoRelPath),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      status: Value(status),
      withdrawalReason: withdrawalReason == null && nullToAbsent
          ? const Value.absent()
          : Value(withdrawalReason),
      withdrawnAt: withdrawnAt == null && nullToAbsent
          ? const Value.absent()
          : Value(withdrawnAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      id: serializer.fromJson<String>(json['id']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      space: serializer.fromJson<String>(json['space']),
      name: serializer.fromJson<String>(json['name']),
      nodeType: serializer.fromJson<String>(json['nodeType']),
      quantity: serializer.fromJson<int?>(json['quantity']),
      description: serializer.fromJson<String?>(json['description']),
      condition: serializer.fromJson<String?>(json['condition']),
      valueMode: serializer.fromJson<String?>(json['valueMode']),
      financialValueCents: serializer.fromJson<int?>(
        json['financialValueCents'],
      ),
      sentimentalValue: serializer.fromJson<int?>(json['sentimentalValue']),
      stockUnit: serializer.fromJson<String?>(json['stockUnit']),
      unitCostCents: serializer.fromJson<int?>(json['unitCostCents']),
      stockReference: serializer.fromJson<int?>(json['stockReference']),
      desiredQuantity: serializer.fromJson<int?>(json['desiredQuantity']),
      targetPriceCents: serializer.fromJson<int?>(json['targetPriceCents']),
      siblingOrder: serializer.fromJson<int>(json['siblingOrder']),
      showAdvanced: serializer.fromJson<bool>(json['showAdvanced']),
      barcodeRef: serializer.fromJson<String?>(json['barcodeRef']),
      purchaseDate: serializer.fromJson<String?>(json['purchaseDate']),
      purchasePriceCents: serializer.fromJson<int?>(json['purchasePriceCents']),
      purchasePlace: serializer.fromJson<String?>(json['purchasePlace']),
      objective: serializer.fromJson<String>(json['objective']),
      photoRelPath: serializer.fromJson<String?>(json['photoRelPath']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      status: serializer.fromJson<String>(json['status']),
      withdrawalReason: serializer.fromJson<String?>(json['withdrawalReason']),
      withdrawnAt: serializer.fromJson<String?>(json['withdrawnAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'parentId': serializer.toJson<String?>(parentId),
      'space': serializer.toJson<String>(space),
      'name': serializer.toJson<String>(name),
      'nodeType': serializer.toJson<String>(nodeType),
      'quantity': serializer.toJson<int?>(quantity),
      'description': serializer.toJson<String?>(description),
      'condition': serializer.toJson<String?>(condition),
      'valueMode': serializer.toJson<String?>(valueMode),
      'financialValueCents': serializer.toJson<int?>(financialValueCents),
      'sentimentalValue': serializer.toJson<int?>(sentimentalValue),
      'stockUnit': serializer.toJson<String?>(stockUnit),
      'unitCostCents': serializer.toJson<int?>(unitCostCents),
      'stockReference': serializer.toJson<int?>(stockReference),
      'desiredQuantity': serializer.toJson<int?>(desiredQuantity),
      'targetPriceCents': serializer.toJson<int?>(targetPriceCents),
      'siblingOrder': serializer.toJson<int>(siblingOrder),
      'showAdvanced': serializer.toJson<bool>(showAdvanced),
      'barcodeRef': serializer.toJson<String?>(barcodeRef),
      'purchaseDate': serializer.toJson<String?>(purchaseDate),
      'purchasePriceCents': serializer.toJson<int?>(purchasePriceCents),
      'purchasePlace': serializer.toJson<String?>(purchasePlace),
      'objective': serializer.toJson<String>(objective),
      'photoRelPath': serializer.toJson<String?>(photoRelPath),
      'iconKey': serializer.toJson<String?>(iconKey),
      'status': serializer.toJson<String>(status),
      'withdrawalReason': serializer.toJson<String?>(withdrawalReason),
      'withdrawnAt': serializer.toJson<String?>(withdrawnAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Node copyWith({
    String? id,
    String? inventoryId,
    Value<String?> parentId = const Value.absent(),
    String? space,
    String? name,
    String? nodeType,
    Value<int?> quantity = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> valueMode = const Value.absent(),
    Value<int?> financialValueCents = const Value.absent(),
    Value<int?> sentimentalValue = const Value.absent(),
    Value<String?> stockUnit = const Value.absent(),
    Value<int?> unitCostCents = const Value.absent(),
    Value<int?> stockReference = const Value.absent(),
    Value<int?> desiredQuantity = const Value.absent(),
    Value<int?> targetPriceCents = const Value.absent(),
    int? siblingOrder,
    bool? showAdvanced,
    Value<String?> barcodeRef = const Value.absent(),
    Value<String?> purchaseDate = const Value.absent(),
    Value<int?> purchasePriceCents = const Value.absent(),
    Value<String?> purchasePlace = const Value.absent(),
    String? objective,
    Value<String?> photoRelPath = const Value.absent(),
    Value<String?> iconKey = const Value.absent(),
    String? status,
    Value<String?> withdrawalReason = const Value.absent(),
    Value<String?> withdrawnAt = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => Node(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    parentId: parentId.present ? parentId.value : this.parentId,
    space: space ?? this.space,
    name: name ?? this.name,
    nodeType: nodeType ?? this.nodeType,
    quantity: quantity.present ? quantity.value : this.quantity,
    description: description.present ? description.value : this.description,
    condition: condition.present ? condition.value : this.condition,
    valueMode: valueMode.present ? valueMode.value : this.valueMode,
    financialValueCents: financialValueCents.present
        ? financialValueCents.value
        : this.financialValueCents,
    sentimentalValue: sentimentalValue.present
        ? sentimentalValue.value
        : this.sentimentalValue,
    stockUnit: stockUnit.present ? stockUnit.value : this.stockUnit,
    unitCostCents: unitCostCents.present
        ? unitCostCents.value
        : this.unitCostCents,
    stockReference: stockReference.present
        ? stockReference.value
        : this.stockReference,
    desiredQuantity: desiredQuantity.present
        ? desiredQuantity.value
        : this.desiredQuantity,
    targetPriceCents: targetPriceCents.present
        ? targetPriceCents.value
        : this.targetPriceCents,
    siblingOrder: siblingOrder ?? this.siblingOrder,
    showAdvanced: showAdvanced ?? this.showAdvanced,
    barcodeRef: barcodeRef.present ? barcodeRef.value : this.barcodeRef,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    purchasePriceCents: purchasePriceCents.present
        ? purchasePriceCents.value
        : this.purchasePriceCents,
    purchasePlace: purchasePlace.present
        ? purchasePlace.value
        : this.purchasePlace,
    objective: objective ?? this.objective,
    photoRelPath: photoRelPath.present ? photoRelPath.value : this.photoRelPath,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    status: status ?? this.status,
    withdrawalReason: withdrawalReason.present
        ? withdrawalReason.value
        : this.withdrawalReason,
    withdrawnAt: withdrawnAt.present ? withdrawnAt.value : this.withdrawnAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      id: data.id.present ? data.id.value : this.id,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      space: data.space.present ? data.space.value : this.space,
      name: data.name.present ? data.name.value : this.name,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      description: data.description.present
          ? data.description.value
          : this.description,
      condition: data.condition.present ? data.condition.value : this.condition,
      valueMode: data.valueMode.present ? data.valueMode.value : this.valueMode,
      financialValueCents: data.financialValueCents.present
          ? data.financialValueCents.value
          : this.financialValueCents,
      sentimentalValue: data.sentimentalValue.present
          ? data.sentimentalValue.value
          : this.sentimentalValue,
      stockUnit: data.stockUnit.present ? data.stockUnit.value : this.stockUnit,
      unitCostCents: data.unitCostCents.present
          ? data.unitCostCents.value
          : this.unitCostCents,
      stockReference: data.stockReference.present
          ? data.stockReference.value
          : this.stockReference,
      desiredQuantity: data.desiredQuantity.present
          ? data.desiredQuantity.value
          : this.desiredQuantity,
      targetPriceCents: data.targetPriceCents.present
          ? data.targetPriceCents.value
          : this.targetPriceCents,
      siblingOrder: data.siblingOrder.present
          ? data.siblingOrder.value
          : this.siblingOrder,
      showAdvanced: data.showAdvanced.present
          ? data.showAdvanced.value
          : this.showAdvanced,
      barcodeRef: data.barcodeRef.present
          ? data.barcodeRef.value
          : this.barcodeRef,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      purchasePriceCents: data.purchasePriceCents.present
          ? data.purchasePriceCents.value
          : this.purchasePriceCents,
      purchasePlace: data.purchasePlace.present
          ? data.purchasePlace.value
          : this.purchasePlace,
      objective: data.objective.present ? data.objective.value : this.objective,
      photoRelPath: data.photoRelPath.present
          ? data.photoRelPath.value
          : this.photoRelPath,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      status: data.status.present ? data.status.value : this.status,
      withdrawalReason: data.withdrawalReason.present
          ? data.withdrawalReason.value
          : this.withdrawalReason,
      withdrawnAt: data.withdrawnAt.present
          ? data.withdrawnAt.value
          : this.withdrawnAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('parentId: $parentId, ')
          ..write('space: $space, ')
          ..write('name: $name, ')
          ..write('nodeType: $nodeType, ')
          ..write('quantity: $quantity, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('valueMode: $valueMode, ')
          ..write('financialValueCents: $financialValueCents, ')
          ..write('sentimentalValue: $sentimentalValue, ')
          ..write('stockUnit: $stockUnit, ')
          ..write('unitCostCents: $unitCostCents, ')
          ..write('stockReference: $stockReference, ')
          ..write('desiredQuantity: $desiredQuantity, ')
          ..write('targetPriceCents: $targetPriceCents, ')
          ..write('siblingOrder: $siblingOrder, ')
          ..write('showAdvanced: $showAdvanced, ')
          ..write('barcodeRef: $barcodeRef, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('purchasePlace: $purchasePlace, ')
          ..write('objective: $objective, ')
          ..write('photoRelPath: $photoRelPath, ')
          ..write('iconKey: $iconKey, ')
          ..write('status: $status, ')
          ..write('withdrawalReason: $withdrawalReason, ')
          ..write('withdrawnAt: $withdrawnAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    inventoryId,
    parentId,
    space,
    name,
    nodeType,
    quantity,
    description,
    condition,
    valueMode,
    financialValueCents,
    sentimentalValue,
    stockUnit,
    unitCostCents,
    stockReference,
    desiredQuantity,
    targetPriceCents,
    siblingOrder,
    showAdvanced,
    barcodeRef,
    purchaseDate,
    purchasePriceCents,
    purchasePlace,
    objective,
    photoRelPath,
    iconKey,
    status,
    withdrawalReason,
    withdrawnAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.parentId == this.parentId &&
          other.space == this.space &&
          other.name == this.name &&
          other.nodeType == this.nodeType &&
          other.quantity == this.quantity &&
          other.description == this.description &&
          other.condition == this.condition &&
          other.valueMode == this.valueMode &&
          other.financialValueCents == this.financialValueCents &&
          other.sentimentalValue == this.sentimentalValue &&
          other.stockUnit == this.stockUnit &&
          other.unitCostCents == this.unitCostCents &&
          other.stockReference == this.stockReference &&
          other.desiredQuantity == this.desiredQuantity &&
          other.targetPriceCents == this.targetPriceCents &&
          other.siblingOrder == this.siblingOrder &&
          other.showAdvanced == this.showAdvanced &&
          other.barcodeRef == this.barcodeRef &&
          other.purchaseDate == this.purchaseDate &&
          other.purchasePriceCents == this.purchasePriceCents &&
          other.purchasePlace == this.purchasePlace &&
          other.objective == this.objective &&
          other.photoRelPath == this.photoRelPath &&
          other.iconKey == this.iconKey &&
          other.status == this.status &&
          other.withdrawalReason == this.withdrawalReason &&
          other.withdrawnAt == this.withdrawnAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<String> id;
  final Value<String> inventoryId;
  final Value<String?> parentId;
  final Value<String> space;
  final Value<String> name;
  final Value<String> nodeType;
  final Value<int?> quantity;
  final Value<String?> description;
  final Value<String?> condition;
  final Value<String?> valueMode;
  final Value<int?> financialValueCents;
  final Value<int?> sentimentalValue;
  final Value<String?> stockUnit;
  final Value<int?> unitCostCents;
  final Value<int?> stockReference;
  final Value<int?> desiredQuantity;
  final Value<int?> targetPriceCents;
  final Value<int> siblingOrder;
  final Value<bool> showAdvanced;
  final Value<String?> barcodeRef;
  final Value<String?> purchaseDate;
  final Value<int?> purchasePriceCents;
  final Value<String?> purchasePlace;
  final Value<String> objective;
  final Value<String?> photoRelPath;
  final Value<String?> iconKey;
  final Value<String> status;
  final Value<String?> withdrawalReason;
  final Value<String?> withdrawnAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.space = const Value.absent(),
    this.name = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.valueMode = const Value.absent(),
    this.financialValueCents = const Value.absent(),
    this.sentimentalValue = const Value.absent(),
    this.stockUnit = const Value.absent(),
    this.unitCostCents = const Value.absent(),
    this.stockReference = const Value.absent(),
    this.desiredQuantity = const Value.absent(),
    this.targetPriceCents = const Value.absent(),
    this.siblingOrder = const Value.absent(),
    this.showAdvanced = const Value.absent(),
    this.barcodeRef = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchasePriceCents = const Value.absent(),
    this.purchasePlace = const Value.absent(),
    this.objective = const Value.absent(),
    this.photoRelPath = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.status = const Value.absent(),
    this.withdrawalReason = const Value.absent(),
    this.withdrawnAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    required String inventoryId,
    this.parentId = const Value.absent(),
    this.space = const Value.absent(),
    required String name,
    required String nodeType,
    this.quantity = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.valueMode = const Value.absent(),
    this.financialValueCents = const Value.absent(),
    this.sentimentalValue = const Value.absent(),
    this.stockUnit = const Value.absent(),
    this.unitCostCents = const Value.absent(),
    this.stockReference = const Value.absent(),
    this.desiredQuantity = const Value.absent(),
    this.targetPriceCents = const Value.absent(),
    this.siblingOrder = const Value.absent(),
    this.showAdvanced = const Value.absent(),
    this.barcodeRef = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchasePriceCents = const Value.absent(),
    this.purchasePlace = const Value.absent(),
    this.objective = const Value.absent(),
    this.photoRelPath = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.status = const Value.absent(),
    this.withdrawalReason = const Value.absent(),
    this.withdrawnAt = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryId = Value(inventoryId),
       name = Value(name),
       nodeType = Value(nodeType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Node> custom({
    Expression<String>? id,
    Expression<String>? inventoryId,
    Expression<String>? parentId,
    Expression<String>? space,
    Expression<String>? name,
    Expression<String>? nodeType,
    Expression<int>? quantity,
    Expression<String>? description,
    Expression<String>? condition,
    Expression<String>? valueMode,
    Expression<int>? financialValueCents,
    Expression<int>? sentimentalValue,
    Expression<String>? stockUnit,
    Expression<int>? unitCostCents,
    Expression<int>? stockReference,
    Expression<int>? desiredQuantity,
    Expression<int>? targetPriceCents,
    Expression<int>? siblingOrder,
    Expression<bool>? showAdvanced,
    Expression<String>? barcodeRef,
    Expression<String>? purchaseDate,
    Expression<int>? purchasePriceCents,
    Expression<String>? purchasePlace,
    Expression<String>? objective,
    Expression<String>? photoRelPath,
    Expression<String>? iconKey,
    Expression<String>? status,
    Expression<String>? withdrawalReason,
    Expression<String>? withdrawnAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (parentId != null) 'parent_id': parentId,
      if (space != null) 'space': space,
      if (name != null) 'name': name,
      if (nodeType != null) 'node_type': nodeType,
      if (quantity != null) 'quantity': quantity,
      if (description != null) 'description': description,
      if (condition != null) 'condition': condition,
      if (valueMode != null) 'value_mode': valueMode,
      if (financialValueCents != null)
        'financial_value_cents': financialValueCents,
      if (sentimentalValue != null) 'sentimental_value': sentimentalValue,
      if (stockUnit != null) 'stock_unit': stockUnit,
      if (unitCostCents != null) 'unit_cost_cents': unitCostCents,
      if (stockReference != null) 'stock_reference': stockReference,
      if (desiredQuantity != null) 'desired_quantity': desiredQuantity,
      if (targetPriceCents != null) 'target_price_cents': targetPriceCents,
      if (siblingOrder != null) 'sibling_order': siblingOrder,
      if (showAdvanced != null) 'show_advanced': showAdvanced,
      if (barcodeRef != null) 'barcode_ref': barcodeRef,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchasePriceCents != null)
        'purchase_price_cents': purchasePriceCents,
      if (purchasePlace != null) 'purchase_place': purchasePlace,
      if (objective != null) 'objective': objective,
      if (photoRelPath != null) 'photo_rel_path': photoRelPath,
      if (iconKey != null) 'icon_key': iconKey,
      if (status != null) 'status': status,
      if (withdrawalReason != null) 'withdrawal_reason': withdrawalReason,
      if (withdrawnAt != null) 'withdrawn_at': withdrawnAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryId,
    Value<String?>? parentId,
    Value<String>? space,
    Value<String>? name,
    Value<String>? nodeType,
    Value<int?>? quantity,
    Value<String?>? description,
    Value<String?>? condition,
    Value<String?>? valueMode,
    Value<int?>? financialValueCents,
    Value<int?>? sentimentalValue,
    Value<String?>? stockUnit,
    Value<int?>? unitCostCents,
    Value<int?>? stockReference,
    Value<int?>? desiredQuantity,
    Value<int?>? targetPriceCents,
    Value<int>? siblingOrder,
    Value<bool>? showAdvanced,
    Value<String?>? barcodeRef,
    Value<String?>? purchaseDate,
    Value<int?>? purchasePriceCents,
    Value<String?>? purchasePlace,
    Value<String>? objective,
    Value<String?>? photoRelPath,
    Value<String?>? iconKey,
    Value<String>? status,
    Value<String?>? withdrawalReason,
    Value<String?>? withdrawnAt,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      parentId: parentId ?? this.parentId,
      space: space ?? this.space,
      name: name ?? this.name,
      nodeType: nodeType ?? this.nodeType,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      valueMode: valueMode ?? this.valueMode,
      financialValueCents: financialValueCents ?? this.financialValueCents,
      sentimentalValue: sentimentalValue ?? this.sentimentalValue,
      stockUnit: stockUnit ?? this.stockUnit,
      unitCostCents: unitCostCents ?? this.unitCostCents,
      stockReference: stockReference ?? this.stockReference,
      desiredQuantity: desiredQuantity ?? this.desiredQuantity,
      targetPriceCents: targetPriceCents ?? this.targetPriceCents,
      siblingOrder: siblingOrder ?? this.siblingOrder,
      showAdvanced: showAdvanced ?? this.showAdvanced,
      barcodeRef: barcodeRef ?? this.barcodeRef,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePriceCents: purchasePriceCents ?? this.purchasePriceCents,
      purchasePlace: purchasePlace ?? this.purchasePlace,
      objective: objective ?? this.objective,
      photoRelPath: photoRelPath ?? this.photoRelPath,
      iconKey: iconKey ?? this.iconKey,
      status: status ?? this.status,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (space.present) {
      map['space'] = Variable<String>(space.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (valueMode.present) {
      map['value_mode'] = Variable<String>(valueMode.value);
    }
    if (financialValueCents.present) {
      map['financial_value_cents'] = Variable<int>(financialValueCents.value);
    }
    if (sentimentalValue.present) {
      map['sentimental_value'] = Variable<int>(sentimentalValue.value);
    }
    if (stockUnit.present) {
      map['stock_unit'] = Variable<String>(stockUnit.value);
    }
    if (unitCostCents.present) {
      map['unit_cost_cents'] = Variable<int>(unitCostCents.value);
    }
    if (stockReference.present) {
      map['stock_reference'] = Variable<int>(stockReference.value);
    }
    if (desiredQuantity.present) {
      map['desired_quantity'] = Variable<int>(desiredQuantity.value);
    }
    if (targetPriceCents.present) {
      map['target_price_cents'] = Variable<int>(targetPriceCents.value);
    }
    if (siblingOrder.present) {
      map['sibling_order'] = Variable<int>(siblingOrder.value);
    }
    if (showAdvanced.present) {
      map['show_advanced'] = Variable<bool>(showAdvanced.value);
    }
    if (barcodeRef.present) {
      map['barcode_ref'] = Variable<String>(barcodeRef.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (purchasePriceCents.present) {
      map['purchase_price_cents'] = Variable<int>(purchasePriceCents.value);
    }
    if (purchasePlace.present) {
      map['purchase_place'] = Variable<String>(purchasePlace.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (photoRelPath.present) {
      map['photo_rel_path'] = Variable<String>(photoRelPath.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (withdrawalReason.present) {
      map['withdrawal_reason'] = Variable<String>(withdrawalReason.value);
    }
    if (withdrawnAt.present) {
      map['withdrawn_at'] = Variable<String>(withdrawnAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('parentId: $parentId, ')
          ..write('space: $space, ')
          ..write('name: $name, ')
          ..write('nodeType: $nodeType, ')
          ..write('quantity: $quantity, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('valueMode: $valueMode, ')
          ..write('financialValueCents: $financialValueCents, ')
          ..write('sentimentalValue: $sentimentalValue, ')
          ..write('stockUnit: $stockUnit, ')
          ..write('unitCostCents: $unitCostCents, ')
          ..write('stockReference: $stockReference, ')
          ..write('desiredQuantity: $desiredQuantity, ')
          ..write('targetPriceCents: $targetPriceCents, ')
          ..write('siblingOrder: $siblingOrder, ')
          ..write('showAdvanced: $showAdvanced, ')
          ..write('barcodeRef: $barcodeRef, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('purchasePlace: $purchasePlace, ')
          ..write('objective: $objective, ')
          ..write('photoRelPath: $photoRelPath, ')
          ..write('iconKey: $iconKey, ')
          ..write('status: $status, ')
          ..write('withdrawalReason: $withdrawalReason, ')
          ..write('withdrawnAt: $withdrawnAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryId,
    name,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {inventoryId, id},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String inventoryId;
  final String name;
  final String createdAt;
  final String updatedAt;
  const Category({
    required this.id,
    required this.inventoryId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_id'] = Variable<String>(inventoryId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      inventoryId: Value(inventoryId),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Category copyWith({
    String? id,
    String? inventoryId,
    String? name,
    String? createdAt,
    String? updatedAt,
  }) => Category(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, inventoryId, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> inventoryId;
  final Value<String> name;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String inventoryId,
    required String name,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryId = Value(inventoryId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? inventoryId,
    Expression<String>? name,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryId,
    Value<String>? name,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeCategoriesTable extends NodeCategories
    with TableInfo<$NodeCategoriesTable, NodeCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [inventoryId, nodeId, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId, categoryId};
  @override
  NodeCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeCategory(
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $NodeCategoriesTable createAlias(String alias) {
    return $NodeCategoriesTable(attachedDatabase, alias);
  }
}

class NodeCategory extends DataClass implements Insertable<NodeCategory> {
  final String inventoryId;
  final String nodeId;
  final String categoryId;
  const NodeCategory({
    required this.inventoryId,
    required this.nodeId,
    required this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['inventory_id'] = Variable<String>(inventoryId);
    map['node_id'] = Variable<String>(nodeId);
    map['category_id'] = Variable<String>(categoryId);
    return map;
  }

  NodeCategoriesCompanion toCompanion(bool nullToAbsent) {
    return NodeCategoriesCompanion(
      inventoryId: Value(inventoryId),
      nodeId: Value(nodeId),
      categoryId: Value(categoryId),
    );
  }

  factory NodeCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeCategory(
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'inventoryId': serializer.toJson<String>(inventoryId),
      'nodeId': serializer.toJson<String>(nodeId),
      'categoryId': serializer.toJson<String>(categoryId),
    };
  }

  NodeCategory copyWith({
    String? inventoryId,
    String? nodeId,
    String? categoryId,
  }) => NodeCategory(
    inventoryId: inventoryId ?? this.inventoryId,
    nodeId: nodeId ?? this.nodeId,
    categoryId: categoryId ?? this.categoryId,
  );
  NodeCategory copyWithCompanion(NodeCategoriesCompanion data) {
    return NodeCategory(
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeCategory(')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(inventoryId, nodeId, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeCategory &&
          other.inventoryId == this.inventoryId &&
          other.nodeId == this.nodeId &&
          other.categoryId == this.categoryId);
}

class NodeCategoriesCompanion extends UpdateCompanion<NodeCategory> {
  final Value<String> inventoryId;
  final Value<String> nodeId;
  final Value<String> categoryId;
  final Value<int> rowid;
  const NodeCategoriesCompanion({
    this.inventoryId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeCategoriesCompanion.insert({
    required String inventoryId,
    required String nodeId,
    required String categoryId,
    this.rowid = const Value.absent(),
  }) : inventoryId = Value(inventoryId),
       nodeId = Value(nodeId),
       categoryId = Value(categoryId);
  static Insertable<NodeCategory> custom({
    Expression<String>? inventoryId,
    Expression<String>? nodeId,
    Expression<String>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (nodeId != null) 'node_id': nodeId,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeCategoriesCompanion copyWith({
    Value<String>? inventoryId,
    Value<String>? nodeId,
    Value<String>? categoryId,
    Value<int>? rowid,
  }) {
    return NodeCategoriesCompanion(
      inventoryId: inventoryId ?? this.inventoryId,
      nodeId: nodeId ?? this.nodeId,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeCategoriesCompanion(')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalVerificationEntriesTable extends LocalVerificationEntries
    with TableInfo<$LocalVerificationEntriesTable, LocalVerificationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVerificationEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_verification_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVerificationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalVerificationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVerificationEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalVerificationEntriesTable createAlias(String alias) {
    return $LocalVerificationEntriesTable(attachedDatabase, alias);
  }
}

class LocalVerificationEntry extends DataClass
    implements Insertable<LocalVerificationEntry> {
  final int id;
  final String value;
  const LocalVerificationEntry({required this.id, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalVerificationEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalVerificationEntriesCompanion(
      id: Value(id),
      value: Value(value),
    );
  }

  factory LocalVerificationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVerificationEntry(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalVerificationEntry copyWith({int? id, String? value}) =>
      LocalVerificationEntry(id: id ?? this.id, value: value ?? this.value);
  LocalVerificationEntry copyWithCompanion(
    LocalVerificationEntriesCompanion data,
  ) {
    return LocalVerificationEntry(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVerificationEntry(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVerificationEntry &&
          other.id == this.id &&
          other.value == this.value);
}

class LocalVerificationEntriesCompanion
    extends UpdateCompanion<LocalVerificationEntry> {
  final Value<int> id;
  final Value<String> value;
  const LocalVerificationEntriesCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  LocalVerificationEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String value,
  }) : value = Value(value);
  static Insertable<LocalVerificationEntry> custom({
    Expression<int>? id,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
    });
  }

  LocalVerificationEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? value,
  }) {
    return LocalVerificationEntriesCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalVerificationEntriesCompanion(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $RestorationJournalEntriesTable extends RestorationJournalEntries
    with TableInfo<$RestorationJournalEntriesTable, RestorationJournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestorationJournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [operationId, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restoration_journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestorationJournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  RestorationJournalEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestorationJournalEntry(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RestorationJournalEntriesTable createAlias(String alias) {
    return $RestorationJournalEntriesTable(attachedDatabase, alias);
  }
}

class RestorationJournalEntry extends DataClass
    implements Insertable<RestorationJournalEntry> {
  final String operationId;
  final String status;
  final String createdAt;
  const RestorationJournalEntry({
    required this.operationId,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  RestorationJournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return RestorationJournalEntriesCompanion(
      operationId: Value(operationId),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory RestorationJournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestorationJournalEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  RestorationJournalEntry copyWith({
    String? operationId,
    String? status,
    String? createdAt,
  }) => RestorationJournalEntry(
    operationId: operationId ?? this.operationId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  RestorationJournalEntry copyWithCompanion(
    RestorationJournalEntriesCompanion data,
  ) {
    return RestorationJournalEntry(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestorationJournalEntry(')
          ..write('operationId: $operationId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(operationId, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestorationJournalEntry &&
          other.operationId == this.operationId &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class RestorationJournalEntriesCompanion
    extends UpdateCompanion<RestorationJournalEntry> {
  final Value<String> operationId;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<int> rowid;
  const RestorationJournalEntriesCompanion({
    this.operationId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestorationJournalEntriesCompanion.insert({
    required String operationId,
    required String status,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<RestorationJournalEntry> custom({
    Expression<String>? operationId,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestorationJournalEntriesCompanion copyWith({
    Value<String>? operationId,
    Value<String>? status,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return RestorationJournalEntriesCompanion(
      operationId: operationId ?? this.operationId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestorationJournalEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaQuartersMeta = const VerificationMeta(
    'deltaQuarters',
  );
  @override
  late final GeneratedColumn<int> deltaQuarters = GeneratedColumn<int>(
    'delta_quarters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterQuartersMeta =
      const VerificationMeta('balanceAfterQuarters');
  @override
  late final GeneratedColumn<int> balanceAfterQuarters = GeneratedColumn<int>(
    'balance_after_quarters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryId,
    nodeId,
    movementType,
    deltaQuarters,
    balanceAfterQuarters,
    unit,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('delta_quarters')) {
      context.handle(
        _deltaQuartersMeta,
        deltaQuarters.isAcceptableOrUnknown(
          data['delta_quarters']!,
          _deltaQuartersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deltaQuartersMeta);
    }
    if (data.containsKey('balance_after_quarters')) {
      context.handle(
        _balanceAfterQuartersMeta,
        balanceAfterQuarters.isAcceptableOrUnknown(
          data['balance_after_quarters']!,
          _balanceAfterQuartersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterQuartersMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      deltaQuarters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta_quarters'],
      )!,
      balanceAfterQuarters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_after_quarters'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String inventoryId;
  final String nodeId;
  final String movementType;
  final int deltaQuarters;
  final int balanceAfterQuarters;
  final String unit;
  final String createdAt;
  const StockMovement({
    required this.id,
    required this.inventoryId,
    required this.nodeId,
    required this.movementType,
    required this.deltaQuarters,
    required this.balanceAfterQuarters,
    required this.unit,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_id'] = Variable<String>(inventoryId);
    map['node_id'] = Variable<String>(nodeId);
    map['movement_type'] = Variable<String>(movementType);
    map['delta_quarters'] = Variable<int>(deltaQuarters);
    map['balance_after_quarters'] = Variable<int>(balanceAfterQuarters);
    map['unit'] = Variable<String>(unit);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      inventoryId: Value(inventoryId),
      nodeId: Value(nodeId),
      movementType: Value(movementType),
      deltaQuarters: Value(deltaQuarters),
      balanceAfterQuarters: Value(balanceAfterQuarters),
      unit: Value(unit),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      deltaQuarters: serializer.fromJson<int>(json['deltaQuarters']),
      balanceAfterQuarters: serializer.fromJson<int>(
        json['balanceAfterQuarters'],
      ),
      unit: serializer.fromJson<String>(json['unit']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'nodeId': serializer.toJson<String>(nodeId),
      'movementType': serializer.toJson<String>(movementType),
      'deltaQuarters': serializer.toJson<int>(deltaQuarters),
      'balanceAfterQuarters': serializer.toJson<int>(balanceAfterQuarters),
      'unit': serializer.toJson<String>(unit),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  StockMovement copyWith({
    String? id,
    String? inventoryId,
    String? nodeId,
    String? movementType,
    int? deltaQuarters,
    int? balanceAfterQuarters,
    String? unit,
    String? createdAt,
  }) => StockMovement(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    nodeId: nodeId ?? this.nodeId,
    movementType: movementType ?? this.movementType,
    deltaQuarters: deltaQuarters ?? this.deltaQuarters,
    balanceAfterQuarters: balanceAfterQuarters ?? this.balanceAfterQuarters,
    unit: unit ?? this.unit,
    createdAt: createdAt ?? this.createdAt,
  );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      deltaQuarters: data.deltaQuarters.present
          ? data.deltaQuarters.value
          : this.deltaQuarters,
      balanceAfterQuarters: data.balanceAfterQuarters.present
          ? data.balanceAfterQuarters.value
          : this.balanceAfterQuarters,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('movementType: $movementType, ')
          ..write('deltaQuarters: $deltaQuarters, ')
          ..write('balanceAfterQuarters: $balanceAfterQuarters, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryId,
    nodeId,
    movementType,
    deltaQuarters,
    balanceAfterQuarters,
    unit,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.nodeId == this.nodeId &&
          other.movementType == this.movementType &&
          other.deltaQuarters == this.deltaQuarters &&
          other.balanceAfterQuarters == this.balanceAfterQuarters &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> inventoryId;
  final Value<String> nodeId;
  final Value<String> movementType;
  final Value<int> deltaQuarters;
  final Value<int> balanceAfterQuarters;
  final Value<String> unit;
  final Value<String> createdAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.deltaQuarters = const Value.absent(),
    this.balanceAfterQuarters = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String inventoryId,
    required String nodeId,
    required String movementType,
    required int deltaQuarters,
    required int balanceAfterQuarters,
    required String unit,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryId = Value(inventoryId),
       nodeId = Value(nodeId),
       movementType = Value(movementType),
       deltaQuarters = Value(deltaQuarters),
       balanceAfterQuarters = Value(balanceAfterQuarters),
       unit = Value(unit),
       createdAt = Value(createdAt);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? inventoryId,
    Expression<String>? nodeId,
    Expression<String>? movementType,
    Expression<int>? deltaQuarters,
    Expression<int>? balanceAfterQuarters,
    Expression<String>? unit,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (nodeId != null) 'node_id': nodeId,
      if (movementType != null) 'movement_type': movementType,
      if (deltaQuarters != null) 'delta_quarters': deltaQuarters,
      if (balanceAfterQuarters != null)
        'balance_after_quarters': balanceAfterQuarters,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryId,
    Value<String>? nodeId,
    Value<String>? movementType,
    Value<int>? deltaQuarters,
    Value<int>? balanceAfterQuarters,
    Value<String>? unit,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      nodeId: nodeId ?? this.nodeId,
      movementType: movementType ?? this.movementType,
      deltaQuarters: deltaQuarters ?? this.deltaQuarters,
      balanceAfterQuarters: balanceAfterQuarters ?? this.balanceAfterQuarters,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (deltaQuarters.present) {
      map['delta_quarters'] = Variable<int>(deltaQuarters.value);
    }
    if (balanceAfterQuarters.present) {
      map['balance_after_quarters'] = Variable<int>(balanceAfterQuarters.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('movementType: $movementType, ')
          ..write('deltaQuarters: $deltaQuarters, ')
          ..write('balanceAfterQuarters: $balanceAfterQuarters, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseEventsTable extends PurchaseEvents
    with TableInfo<$PurchaseEventsTable, PurchaseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _needNodeIdMeta = const VerificationMeta(
    'needNodeId',
  );
  @override
  late final GeneratedColumn<String> needNodeId = GeneratedColumn<String>(
    'need_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPriceCentsMeta = const VerificationMeta(
    'targetPriceCents',
  );
  @override
  late final GeneratedColumn<int> targetPriceCents = GeneratedColumn<int>(
    'target_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidPriceCentsMeta = const VerificationMeta(
    'paidPriceCents',
  );
  @override
  late final GeneratedColumn<int> paidPriceCents = GeneratedColumn<int>(
    'paid_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationSpaceMeta = const VerificationMeta(
    'destinationSpace',
  );
  @override
  late final GeneratedColumn<String> destinationSpace = GeneratedColumn<String>(
    'destination_space',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationNodeIdMeta = const VerificationMeta(
    'destinationNodeId',
  );
  @override
  late final GeneratedColumn<String> destinationNodeId =
      GeneratedColumn<String>(
        'destination_node_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationParentIdMeta =
      const VerificationMeta('destinationParentId');
  @override
  late final GeneratedColumn<String> destinationParentId =
      GeneratedColumn<String>(
        'destination_parent_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryId,
    needNodeId,
    eventType,
    quantity,
    targetPriceCents,
    paidPriceCents,
    destinationSpace,
    destinationNodeId,
    destinationParentId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('need_node_id')) {
      context.handle(
        _needNodeIdMeta,
        needNodeId.isAcceptableOrUnknown(
          data['need_node_id']!,
          _needNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needNodeIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('target_price_cents')) {
      context.handle(
        _targetPriceCentsMeta,
        targetPriceCents.isAcceptableOrUnknown(
          data['target_price_cents']!,
          _targetPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('paid_price_cents')) {
      context.handle(
        _paidPriceCentsMeta,
        paidPriceCents.isAcceptableOrUnknown(
          data['paid_price_cents']!,
          _paidPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('destination_space')) {
      context.handle(
        _destinationSpaceMeta,
        destinationSpace.isAcceptableOrUnknown(
          data['destination_space']!,
          _destinationSpaceMeta,
        ),
      );
    }
    if (data.containsKey('destination_node_id')) {
      context.handle(
        _destinationNodeIdMeta,
        destinationNodeId.isAcceptableOrUnknown(
          data['destination_node_id']!,
          _destinationNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_parent_id')) {
      context.handle(
        _destinationParentIdMeta,
        destinationParentId.isAcceptableOrUnknown(
          data['destination_parent_id']!,
          _destinationParentIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      needNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}need_node_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      targetPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_price_cents'],
      ),
      paidPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_price_cents'],
      ),
      destinationSpace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_space'],
      ),
      destinationNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_node_id'],
      ),
      destinationParentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_parent_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PurchaseEventsTable createAlias(String alias) {
    return $PurchaseEventsTable(attachedDatabase, alias);
  }
}

class PurchaseEvent extends DataClass implements Insertable<PurchaseEvent> {
  final String id;
  final String inventoryId;
  final String needNodeId;
  final String eventType;
  final int quantity;
  final int? targetPriceCents;
  final int? paidPriceCents;
  final String? destinationSpace;
  final String? destinationNodeId;
  final String? destinationParentId;
  final String createdAt;
  const PurchaseEvent({
    required this.id,
    required this.inventoryId,
    required this.needNodeId,
    required this.eventType,
    required this.quantity,
    this.targetPriceCents,
    this.paidPriceCents,
    this.destinationSpace,
    this.destinationNodeId,
    this.destinationParentId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_id'] = Variable<String>(inventoryId);
    map['need_node_id'] = Variable<String>(needNodeId);
    map['event_type'] = Variable<String>(eventType);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || targetPriceCents != null) {
      map['target_price_cents'] = Variable<int>(targetPriceCents);
    }
    if (!nullToAbsent || paidPriceCents != null) {
      map['paid_price_cents'] = Variable<int>(paidPriceCents);
    }
    if (!nullToAbsent || destinationSpace != null) {
      map['destination_space'] = Variable<String>(destinationSpace);
    }
    if (!nullToAbsent || destinationNodeId != null) {
      map['destination_node_id'] = Variable<String>(destinationNodeId);
    }
    if (!nullToAbsent || destinationParentId != null) {
      map['destination_parent_id'] = Variable<String>(destinationParentId);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PurchaseEventsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseEventsCompanion(
      id: Value(id),
      inventoryId: Value(inventoryId),
      needNodeId: Value(needNodeId),
      eventType: Value(eventType),
      quantity: Value(quantity),
      targetPriceCents: targetPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPriceCents),
      paidPriceCents: paidPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(paidPriceCents),
      destinationSpace: destinationSpace == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationSpace),
      destinationNodeId: destinationNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationNodeId),
      destinationParentId: destinationParentId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationParentId),
      createdAt: Value(createdAt),
    );
  }

  factory PurchaseEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseEvent(
      id: serializer.fromJson<String>(json['id']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      needNodeId: serializer.fromJson<String>(json['needNodeId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      quantity: serializer.fromJson<int>(json['quantity']),
      targetPriceCents: serializer.fromJson<int?>(json['targetPriceCents']),
      paidPriceCents: serializer.fromJson<int?>(json['paidPriceCents']),
      destinationSpace: serializer.fromJson<String?>(json['destinationSpace']),
      destinationNodeId: serializer.fromJson<String?>(
        json['destinationNodeId'],
      ),
      destinationParentId: serializer.fromJson<String?>(
        json['destinationParentId'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'needNodeId': serializer.toJson<String>(needNodeId),
      'eventType': serializer.toJson<String>(eventType),
      'quantity': serializer.toJson<int>(quantity),
      'targetPriceCents': serializer.toJson<int?>(targetPriceCents),
      'paidPriceCents': serializer.toJson<int?>(paidPriceCents),
      'destinationSpace': serializer.toJson<String?>(destinationSpace),
      'destinationNodeId': serializer.toJson<String?>(destinationNodeId),
      'destinationParentId': serializer.toJson<String?>(destinationParentId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PurchaseEvent copyWith({
    String? id,
    String? inventoryId,
    String? needNodeId,
    String? eventType,
    int? quantity,
    Value<int?> targetPriceCents = const Value.absent(),
    Value<int?> paidPriceCents = const Value.absent(),
    Value<String?> destinationSpace = const Value.absent(),
    Value<String?> destinationNodeId = const Value.absent(),
    Value<String?> destinationParentId = const Value.absent(),
    String? createdAt,
  }) => PurchaseEvent(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    needNodeId: needNodeId ?? this.needNodeId,
    eventType: eventType ?? this.eventType,
    quantity: quantity ?? this.quantity,
    targetPriceCents: targetPriceCents.present
        ? targetPriceCents.value
        : this.targetPriceCents,
    paidPriceCents: paidPriceCents.present
        ? paidPriceCents.value
        : this.paidPriceCents,
    destinationSpace: destinationSpace.present
        ? destinationSpace.value
        : this.destinationSpace,
    destinationNodeId: destinationNodeId.present
        ? destinationNodeId.value
        : this.destinationNodeId,
    destinationParentId: destinationParentId.present
        ? destinationParentId.value
        : this.destinationParentId,
    createdAt: createdAt ?? this.createdAt,
  );
  PurchaseEvent copyWithCompanion(PurchaseEventsCompanion data) {
    return PurchaseEvent(
      id: data.id.present ? data.id.value : this.id,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      needNodeId: data.needNodeId.present
          ? data.needNodeId.value
          : this.needNodeId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      targetPriceCents: data.targetPriceCents.present
          ? data.targetPriceCents.value
          : this.targetPriceCents,
      paidPriceCents: data.paidPriceCents.present
          ? data.paidPriceCents.value
          : this.paidPriceCents,
      destinationSpace: data.destinationSpace.present
          ? data.destinationSpace.value
          : this.destinationSpace,
      destinationNodeId: data.destinationNodeId.present
          ? data.destinationNodeId.value
          : this.destinationNodeId,
      destinationParentId: data.destinationParentId.present
          ? data.destinationParentId.value
          : this.destinationParentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseEvent(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('needNodeId: $needNodeId, ')
          ..write('eventType: $eventType, ')
          ..write('quantity: $quantity, ')
          ..write('targetPriceCents: $targetPriceCents, ')
          ..write('paidPriceCents: $paidPriceCents, ')
          ..write('destinationSpace: $destinationSpace, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('destinationParentId: $destinationParentId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryId,
    needNodeId,
    eventType,
    quantity,
    targetPriceCents,
    paidPriceCents,
    destinationSpace,
    destinationNodeId,
    destinationParentId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseEvent &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.needNodeId == this.needNodeId &&
          other.eventType == this.eventType &&
          other.quantity == this.quantity &&
          other.targetPriceCents == this.targetPriceCents &&
          other.paidPriceCents == this.paidPriceCents &&
          other.destinationSpace == this.destinationSpace &&
          other.destinationNodeId == this.destinationNodeId &&
          other.destinationParentId == this.destinationParentId &&
          other.createdAt == this.createdAt);
}

class PurchaseEventsCompanion extends UpdateCompanion<PurchaseEvent> {
  final Value<String> id;
  final Value<String> inventoryId;
  final Value<String> needNodeId;
  final Value<String> eventType;
  final Value<int> quantity;
  final Value<int?> targetPriceCents;
  final Value<int?> paidPriceCents;
  final Value<String?> destinationSpace;
  final Value<String?> destinationNodeId;
  final Value<String?> destinationParentId;
  final Value<String> createdAt;
  final Value<int> rowid;
  const PurchaseEventsCompanion({
    this.id = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.needNodeId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.targetPriceCents = const Value.absent(),
    this.paidPriceCents = const Value.absent(),
    this.destinationSpace = const Value.absent(),
    this.destinationNodeId = const Value.absent(),
    this.destinationParentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseEventsCompanion.insert({
    required String id,
    required String inventoryId,
    required String needNodeId,
    required String eventType,
    required int quantity,
    this.targetPriceCents = const Value.absent(),
    this.paidPriceCents = const Value.absent(),
    this.destinationSpace = const Value.absent(),
    this.destinationNodeId = const Value.absent(),
    this.destinationParentId = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryId = Value(inventoryId),
       needNodeId = Value(needNodeId),
       eventType = Value(eventType),
       quantity = Value(quantity),
       createdAt = Value(createdAt);
  static Insertable<PurchaseEvent> custom({
    Expression<String>? id,
    Expression<String>? inventoryId,
    Expression<String>? needNodeId,
    Expression<String>? eventType,
    Expression<int>? quantity,
    Expression<int>? targetPriceCents,
    Expression<int>? paidPriceCents,
    Expression<String>? destinationSpace,
    Expression<String>? destinationNodeId,
    Expression<String>? destinationParentId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (needNodeId != null) 'need_node_id': needNodeId,
      if (eventType != null) 'event_type': eventType,
      if (quantity != null) 'quantity': quantity,
      if (targetPriceCents != null) 'target_price_cents': targetPriceCents,
      if (paidPriceCents != null) 'paid_price_cents': paidPriceCents,
      if (destinationSpace != null) 'destination_space': destinationSpace,
      if (destinationNodeId != null) 'destination_node_id': destinationNodeId,
      if (destinationParentId != null)
        'destination_parent_id': destinationParentId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryId,
    Value<String>? needNodeId,
    Value<String>? eventType,
    Value<int>? quantity,
    Value<int?>? targetPriceCents,
    Value<int?>? paidPriceCents,
    Value<String?>? destinationSpace,
    Value<String?>? destinationNodeId,
    Value<String?>? destinationParentId,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return PurchaseEventsCompanion(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      needNodeId: needNodeId ?? this.needNodeId,
      eventType: eventType ?? this.eventType,
      quantity: quantity ?? this.quantity,
      targetPriceCents: targetPriceCents ?? this.targetPriceCents,
      paidPriceCents: paidPriceCents ?? this.paidPriceCents,
      destinationSpace: destinationSpace ?? this.destinationSpace,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      destinationParentId: destinationParentId ?? this.destinationParentId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (needNodeId.present) {
      map['need_node_id'] = Variable<String>(needNodeId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (targetPriceCents.present) {
      map['target_price_cents'] = Variable<int>(targetPriceCents.value);
    }
    if (paidPriceCents.present) {
      map['paid_price_cents'] = Variable<int>(paidPriceCents.value);
    }
    if (destinationSpace.present) {
      map['destination_space'] = Variable<String>(destinationSpace.value);
    }
    if (destinationNodeId.present) {
      map['destination_node_id'] = Variable<String>(destinationNodeId.value);
    }
    if (destinationParentId.present) {
      map['destination_parent_id'] = Variable<String>(
        destinationParentId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseEventsCompanion(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('needNodeId: $needNodeId, ')
          ..write('eventType: $eventType, ')
          ..write('quantity: $quantity, ')
          ..write('targetPriceCents: $targetPriceCents, ')
          ..write('paidPriceCents: $paidPriceCents, ')
          ..write('destinationSpace: $destinationSpace, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('destinationParentId: $destinationParentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final String key;
  final String value;
  const AppPreference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppPreference copyWith({String? key, String? value}) =>
      AppPreference(key: key ?? this.key, value: value ?? this.value);
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.key == this.key &&
          other.value == this.value);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeDocumentsTable extends NodeDocuments
    with TableInfo<$NodeDocumentsTable, NodeDocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryIdMeta = const VerificationMeta(
    'inventoryId',
  );
  @override
  late final GeneratedColumn<String> inventoryId = GeneratedColumn<String>(
    'inventory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relPathMeta = const VerificationMeta(
    'relPath',
  );
  @override
  late final GeneratedColumn<String> relPath = GeneratedColumn<String>(
    'rel_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryId,
    nodeId,
    displayName,
    relPath,
    mimeType,
    byteSize,
    sortIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeDocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
        _inventoryIdMeta,
        inventoryId.isAcceptableOrUnknown(
          data['inventory_id']!,
          _inventoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('rel_path')) {
      context.handle(
        _relPathMeta,
        relPath.isAcceptableOrUnknown(data['rel_path']!, _relPathMeta),
      );
    } else if (isInserting) {
      context.missing(_relPathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeDocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeDocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      relPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rel_path'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NodeDocumentsTable createAlias(String alias) {
    return $NodeDocumentsTable(attachedDatabase, alias);
  }
}

class NodeDocumentRow extends DataClass implements Insertable<NodeDocumentRow> {
  final String id;
  final String inventoryId;
  final String nodeId;

  /// Original display name when available.
  final String displayName;

  /// Relative path under app support (`documents/….ext`).
  final String relPath;
  final String mimeType;
  final int byteSize;
  final int sortIndex;
  final String createdAt;
  const NodeDocumentRow({
    required this.id,
    required this.inventoryId,
    required this.nodeId,
    required this.displayName,
    required this.relPath,
    required this.mimeType,
    required this.byteSize,
    required this.sortIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_id'] = Variable<String>(inventoryId);
    map['node_id'] = Variable<String>(nodeId);
    map['display_name'] = Variable<String>(displayName);
    map['rel_path'] = Variable<String>(relPath);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    map['sort_index'] = Variable<int>(sortIndex);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  NodeDocumentsCompanion toCompanion(bool nullToAbsent) {
    return NodeDocumentsCompanion(
      id: Value(id),
      inventoryId: Value(inventoryId),
      nodeId: Value(nodeId),
      displayName: Value(displayName),
      relPath: Value(relPath),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      sortIndex: Value(sortIndex),
      createdAt: Value(createdAt),
    );
  }

  factory NodeDocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeDocumentRow(
      id: serializer.fromJson<String>(json['id']),
      inventoryId: serializer.fromJson<String>(json['inventoryId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      relPath: serializer.fromJson<String>(json['relPath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryId': serializer.toJson<String>(inventoryId),
      'nodeId': serializer.toJson<String>(nodeId),
      'displayName': serializer.toJson<String>(displayName),
      'relPath': serializer.toJson<String>(relPath),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  NodeDocumentRow copyWith({
    String? id,
    String? inventoryId,
    String? nodeId,
    String? displayName,
    String? relPath,
    String? mimeType,
    int? byteSize,
    int? sortIndex,
    String? createdAt,
  }) => NodeDocumentRow(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    nodeId: nodeId ?? this.nodeId,
    displayName: displayName ?? this.displayName,
    relPath: relPath ?? this.relPath,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    sortIndex: sortIndex ?? this.sortIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  NodeDocumentRow copyWithCompanion(NodeDocumentsCompanion data) {
    return NodeDocumentRow(
      id: data.id.present ? data.id.value : this.id,
      inventoryId: data.inventoryId.present
          ? data.inventoryId.value
          : this.inventoryId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      relPath: data.relPath.present ? data.relPath.value : this.relPath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeDocumentRow(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('displayName: $displayName, ')
          ..write('relPath: $relPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryId,
    nodeId,
    displayName,
    relPath,
    mimeType,
    byteSize,
    sortIndex,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeDocumentRow &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.nodeId == this.nodeId &&
          other.displayName == this.displayName &&
          other.relPath == this.relPath &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.sortIndex == this.sortIndex &&
          other.createdAt == this.createdAt);
}

class NodeDocumentsCompanion extends UpdateCompanion<NodeDocumentRow> {
  final Value<String> id;
  final Value<String> inventoryId;
  final Value<String> nodeId;
  final Value<String> displayName;
  final Value<String> relPath;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<int> sortIndex;
  final Value<String> createdAt;
  final Value<int> rowid;
  const NodeDocumentsCompanion({
    this.id = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.relPath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeDocumentsCompanion.insert({
    required String id,
    required String inventoryId,
    required String nodeId,
    required String displayName,
    required String relPath,
    required String mimeType,
    required int byteSize,
    this.sortIndex = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryId = Value(inventoryId),
       nodeId = Value(nodeId),
       displayName = Value(displayName),
       relPath = Value(relPath),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize),
       createdAt = Value(createdAt);
  static Insertable<NodeDocumentRow> custom({
    Expression<String>? id,
    Expression<String>? inventoryId,
    Expression<String>? nodeId,
    Expression<String>? displayName,
    Expression<String>? relPath,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<int>? sortIndex,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (nodeId != null) 'node_id': nodeId,
      if (displayName != null) 'display_name': displayName,
      if (relPath != null) 'rel_path': relPath,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryId,
    Value<String>? nodeId,
    Value<String>? displayName,
    Value<String>? relPath,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<int>? sortIndex,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return NodeDocumentsCompanion(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      nodeId: nodeId ?? this.nodeId,
      displayName: displayName ?? this.displayName,
      relPath: relPath ?? this.relPath,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<String>(inventoryId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (relPath.present) {
      map['rel_path'] = Variable<String>(relPath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('nodeId: $nodeId, ')
          ..write('displayName: $displayName, ')
          ..write('relPath: $relPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$InventoryDatabase extends GeneratedDatabase {
  _$InventoryDatabase(QueryExecutor e) : super(e);
  $InventoryDatabaseManager get managers => $InventoryDatabaseManager(this);
  late final $InventoriesTable inventories = $InventoriesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $NodeCategoriesTable nodeCategories = $NodeCategoriesTable(this);
  late final $LocalVerificationEntriesTable localVerificationEntries =
      $LocalVerificationEntriesTable(this);
  late final $RestorationJournalEntriesTable restorationJournalEntries =
      $RestorationJournalEntriesTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $PurchaseEventsTable purchaseEvents = $PurchaseEventsTable(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  late final $NodeDocumentsTable nodeDocuments = $NodeDocumentsTable(this);
  late final Index nodesParentIdx = Index(
    'nodes_parent_idx',
    'CREATE INDEX nodes_parent_idx ON nodes (inventory_id, parent_id)',
  );
  late final Index nodesActiveNameIdx = Index(
    'nodes_active_name_idx',
    'CREATE INDEX nodes_active_name_idx ON nodes (inventory_id, status, name)',
  );
  late final Index nodeCategoriesCategoryIdx = Index(
    'node_categories_category_idx',
    'CREATE INDEX node_categories_category_idx ON node_categories (inventory_id, category_id)',
  );
  late final Index stockMovementsNodeIdx = Index(
    'stock_movements_node_idx',
    'CREATE INDEX stock_movements_node_idx ON stock_movements (inventory_id, node_id, created_at)',
  );
  late final Index purchaseEventsNeedIdx = Index(
    'purchase_events_need_idx',
    'CREATE INDEX purchase_events_need_idx ON purchase_events (inventory_id, need_node_id, created_at)',
  );
  late final Index nodeDocumentsNodeIdx = Index(
    'node_documents_node_idx',
    'CREATE INDEX node_documents_node_idx ON node_documents (inventory_id, node_id, sort_index)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inventories,
    nodes,
    categories,
    nodeCategories,
    localVerificationEntries,
    restorationJournalEntries,
    stockMovements,
    purchaseEvents,
    appPreferences,
    nodeDocuments,
    nodesParentIdx,
    nodesActiveNameIdx,
    nodeCategoriesCategoryIdx,
    stockMovementsNodeIdx,
    purchaseEventsNeedIdx,
    nodeDocumentsNodeIdx,
  ];
}

typedef $$InventoriesTableCreateCompanionBuilder =
    InventoriesCompanion Function({
      required String id,
      Value<int> singletonKey,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$InventoriesTableUpdateCompanionBuilder =
    InventoriesCompanion Function({
      Value<String> id,
      Value<int> singletonKey,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$InventoriesTableReferences
    extends BaseReferences<_$InventoryDatabase, $InventoriesTable, Inventory> {
  $$InventoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NodesTable, List<Node>> _nodesRefsTable(
    _$InventoryDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nodes,
    aliasName: 'inventories__id__nodes__inventory_id',
  );

  $$NodesTableProcessedTableManager get nodesRefs {
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.inventoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
  _categoriesRefsTable(_$InventoryDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'inventories__id__categories__inventory_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.inventoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
  _stockMovementsRefsTable(_$InventoryDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockMovements,
        aliasName: 'inventories__id__stock_movements__inventory_id',
      );

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager(
      $_db,
      $_db.stockMovements,
    ).filter((f) => f.inventoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PurchaseEventsTable, List<PurchaseEvent>>
  _purchaseEventsRefsTable(_$InventoryDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.purchaseEvents,
        aliasName: 'inventories__id__purchase_events__inventory_id',
      );

  $$PurchaseEventsTableProcessedTableManager get purchaseEventsRefs {
    final manager = $$PurchaseEventsTableTableManager(
      $_db,
      $_db.purchaseEvents,
    ).filter((f) => f.inventoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchaseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodeDocumentsTable, List<NodeDocumentRow>>
  _nodeDocumentsRefsTable(_$InventoryDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.nodeDocuments,
        aliasName: 'inventories__id__node_documents__inventory_id',
      );

  $$NodeDocumentsTableProcessedTableManager get nodeDocumentsRefs {
    final manager = $$NodeDocumentsTableTableManager(
      $_db,
      $_db.nodeDocuments,
    ).filter((f) => f.inventoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeDocumentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoriesTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoriesTable> {
  $$InventoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> nodesRefs(
    Expression<bool> Function($$NodesTableFilterComposer f) f,
  ) {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
    Expression<bool> Function($$StockMovementsTableFilterComposer f) f,
  ) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableFilterComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchaseEventsRefs(
    Expression<bool> Function($$PurchaseEventsTableFilterComposer f) f,
  ) {
    final $$PurchaseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseEvents,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseEventsTableFilterComposer(
            $db: $db,
            $table: $db.purchaseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nodeDocumentsRefs(
    Expression<bool> Function($$NodeDocumentsTableFilterComposer f) f,
  ) {
    final $$NodeDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeDocuments,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.nodeDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoriesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoriesTable> {
  $$InventoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoriesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoriesTable> {
  $$InventoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> nodesRefs<T extends Object>(
    Expression<T> Function($$NodesTableAnnotationComposer a) f,
  ) {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
    Expression<T> Function($$StockMovementsTableAnnotationComposer a) f,
  ) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMovements,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchaseEventsRefs<T extends Object>(
    Expression<T> Function($$PurchaseEventsTableAnnotationComposer a) f,
  ) {
    final $$PurchaseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseEvents,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nodeDocumentsRefs<T extends Object>(
    Expression<T> Function($$NodeDocumentsTableAnnotationComposer a) f,
  ) {
    final $$NodeDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeDocuments,
      getReferencedColumn: (t) => t.inventoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoriesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoriesTable,
          Inventory,
          $$InventoriesTableFilterComposer,
          $$InventoriesTableOrderingComposer,
          $$InventoriesTableAnnotationComposer,
          $$InventoriesTableCreateCompanionBuilder,
          $$InventoriesTableUpdateCompanionBuilder,
          (Inventory, $$InventoriesTableReferences),
          Inventory,
          PrefetchHooks Function({
            bool nodesRefs,
            bool categoriesRefs,
            bool stockMovementsRefs,
            bool purchaseEventsRefs,
            bool nodeDocumentsRefs,
          })
        > {
  $$InventoriesTableTableManager(
    _$InventoryDatabase db,
    $InventoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> singletonKey = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoriesCompanion(
                id: id,
                singletonKey: singletonKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> singletonKey = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InventoriesCompanion.insert(
                id: id,
                singletonKey: singletonKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InventoriesTable, Inventory>(table),
                  $$InventoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                nodesRefs = false,
                categoriesRefs = false,
                stockMovementsRefs = false,
                purchaseEventsRefs = false,
                nodeDocumentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nodesRefs) db.nodes,
                    if (categoriesRefs) db.categories,
                    if (stockMovementsRefs) db.stockMovements,
                    if (purchaseEventsRefs) db.purchaseEvents,
                    if (nodeDocumentsRefs) db.nodeDocuments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nodesRefs)
                        await $_getPrefetchedDataByColumns<
                          Inventory,
                          $InventoriesTable,
                          Node,
                          $NodesTable
                        >(
                          currentTable: table,
                          referencedTable: $$InventoriesTableReferences
                              ._nodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'inventory_id',
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Inventory,
                          $InventoriesTable,
                          Category,
                          $CategoriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$InventoriesTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'inventory_id',
                          typedResults: items,
                        ),
                      if (stockMovementsRefs)
                        await $_getPrefetchedDataByColumns<
                          Inventory,
                          $InventoriesTable,
                          StockMovement,
                          $StockMovementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$InventoriesTableReferences
                              ._stockMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).stockMovementsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'inventory_id',
                          typedResults: items,
                        ),
                      if (purchaseEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          Inventory,
                          $InventoriesTable,
                          PurchaseEvent,
                          $PurchaseEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$InventoriesTableReferences
                              ._purchaseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).purchaseEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'inventory_id',
                          typedResults: items,
                        ),
                      if (nodeDocumentsRefs)
                        await $_getPrefetchedDataByColumns<
                          Inventory,
                          $InventoriesTable,
                          NodeDocumentRow,
                          $NodeDocumentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$InventoriesTableReferences
                              ._nodeDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodeDocumentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'inventory_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InventoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoriesTable,
      Inventory,
      $$InventoriesTableFilterComposer,
      $$InventoriesTableOrderingComposer,
      $$InventoriesTableAnnotationComposer,
      $$InventoriesTableCreateCompanionBuilder,
      $$InventoriesTableUpdateCompanionBuilder,
      (Inventory, $$InventoriesTableReferences),
      Inventory,
      PrefetchHooks Function({
        bool nodesRefs,
        bool categoriesRefs,
        bool stockMovementsRefs,
        bool purchaseEventsRefs,
        bool nodeDocumentsRefs,
      })
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      required String id,
      required String inventoryId,
      Value<String?> parentId,
      Value<String> space,
      required String name,
      required String nodeType,
      Value<int?> quantity,
      Value<String?> description,
      Value<String?> condition,
      Value<String?> valueMode,
      Value<int?> financialValueCents,
      Value<int?> sentimentalValue,
      Value<String?> stockUnit,
      Value<int?> unitCostCents,
      Value<int?> stockReference,
      Value<int?> desiredQuantity,
      Value<int?> targetPriceCents,
      Value<int> siblingOrder,
      Value<bool> showAdvanced,
      Value<String?> barcodeRef,
      Value<String?> purchaseDate,
      Value<int?> purchasePriceCents,
      Value<String?> purchasePlace,
      Value<String> objective,
      Value<String?> photoRelPath,
      Value<String?> iconKey,
      Value<String> status,
      Value<String?> withdrawalReason,
      Value<String?> withdrawnAt,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<String> id,
      Value<String> inventoryId,
      Value<String?> parentId,
      Value<String> space,
      Value<String> name,
      Value<String> nodeType,
      Value<int?> quantity,
      Value<String?> description,
      Value<String?> condition,
      Value<String?> valueMode,
      Value<int?> financialValueCents,
      Value<int?> sentimentalValue,
      Value<String?> stockUnit,
      Value<int?> unitCostCents,
      Value<int?> stockReference,
      Value<int?> desiredQuantity,
      Value<int?> targetPriceCents,
      Value<int> siblingOrder,
      Value<bool> showAdvanced,
      Value<String?> barcodeRef,
      Value<String?> purchaseDate,
      Value<int?> purchasePriceCents,
      Value<String?> purchasePlace,
      Value<String> objective,
      Value<String?> photoRelPath,
      Value<String?> iconKey,
      Value<String> status,
      Value<String?> withdrawalReason,
      Value<String?> withdrawnAt,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$NodesTableReferences
    extends BaseReferences<_$InventoryDatabase, $NodesTable, Node> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InventoriesTable _inventoryIdTable(_$InventoryDatabase db) =>
      db.inventories.createAlias('nodes__inventory_id__inventories__id');

  $$InventoriesTableProcessedTableManager get inventoryId {
    final $_column = $_itemColumn<String>('inventory_id')!;

    final manager = $$InventoriesTableTableManager(
      $_db,
      $_db.inventories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodesTableFilterComposer
    extends Composer<_$InventoryDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get space => $composableBuilder(
    column: $table.space,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueMode => $composableBuilder(
    column: $table.valueMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get financialValueCents => $composableBuilder(
    column: $table.financialValueCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentimentalValue => $composableBuilder(
    column: $table.sentimentalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockUnit => $composableBuilder(
    column: $table.stockUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitCostCents => $composableBuilder(
    column: $table.unitCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockReference => $composableBuilder(
    column: $table.stockReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get desiredQuantity => $composableBuilder(
    column: $table.desiredQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get siblingOrder => $composableBuilder(
    column: $table.siblingOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showAdvanced => $composableBuilder(
    column: $table.showAdvanced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeRef => $composableBuilder(
    column: $table.barcodeRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchasePlace => $composableBuilder(
    column: $table.purchasePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoRelPath => $composableBuilder(
    column: $table.photoRelPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoriesTableFilterComposer get inventoryId {
    final $$InventoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableFilterComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get space => $composableBuilder(
    column: $table.space,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueMode => $composableBuilder(
    column: $table.valueMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get financialValueCents => $composableBuilder(
    column: $table.financialValueCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentimentalValue => $composableBuilder(
    column: $table.sentimentalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockUnit => $composableBuilder(
    column: $table.stockUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitCostCents => $composableBuilder(
    column: $table.unitCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockReference => $composableBuilder(
    column: $table.stockReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get desiredQuantity => $composableBuilder(
    column: $table.desiredQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get siblingOrder => $composableBuilder(
    column: $table.siblingOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showAdvanced => $composableBuilder(
    column: $table.showAdvanced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeRef => $composableBuilder(
    column: $table.barcodeRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchasePlace => $composableBuilder(
    column: $table.purchasePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoRelPath => $composableBuilder(
    column: $table.photoRelPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoriesTableOrderingComposer get inventoryId {
    final $$InventoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableOrderingComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get space =>
      $composableBuilder(column: $table.space, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get valueMode =>
      $composableBuilder(column: $table.valueMode, builder: (column) => column);

  GeneratedColumn<int> get financialValueCents => $composableBuilder(
    column: $table.financialValueCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentimentalValue => $composableBuilder(
    column: $table.sentimentalValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stockUnit =>
      $composableBuilder(column: $table.stockUnit, builder: (column) => column);

  GeneratedColumn<int> get unitCostCents => $composableBuilder(
    column: $table.unitCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockReference => $composableBuilder(
    column: $table.stockReference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get desiredQuantity => $composableBuilder(
    column: $table.desiredQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get siblingOrder => $composableBuilder(
    column: $table.siblingOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showAdvanced => $composableBuilder(
    column: $table.showAdvanced,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeRef => $composableBuilder(
    column: $table.barcodeRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchasePlace => $composableBuilder(
    column: $table.purchasePlace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<String> get photoRelPath => $composableBuilder(
    column: $table.photoRelPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InventoriesTableAnnotationComposer get inventoryId {
    final $$InventoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, $$NodesTableReferences),
          Node,
          PrefetchHooks Function({bool inventoryId})
        > {
  $$NodesTableTableManager(_$InventoryDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> space = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> valueMode = const Value.absent(),
                Value<int?> financialValueCents = const Value.absent(),
                Value<int?> sentimentalValue = const Value.absent(),
                Value<String?> stockUnit = const Value.absent(),
                Value<int?> unitCostCents = const Value.absent(),
                Value<int?> stockReference = const Value.absent(),
                Value<int?> desiredQuantity = const Value.absent(),
                Value<int?> targetPriceCents = const Value.absent(),
                Value<int> siblingOrder = const Value.absent(),
                Value<bool> showAdvanced = const Value.absent(),
                Value<String?> barcodeRef = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchasePriceCents = const Value.absent(),
                Value<String?> purchasePlace = const Value.absent(),
                Value<String> objective = const Value.absent(),
                Value<String?> photoRelPath = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> withdrawalReason = const Value.absent(),
                Value<String?> withdrawnAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                inventoryId: inventoryId,
                parentId: parentId,
                space: space,
                name: name,
                nodeType: nodeType,
                quantity: quantity,
                description: description,
                condition: condition,
                valueMode: valueMode,
                financialValueCents: financialValueCents,
                sentimentalValue: sentimentalValue,
                stockUnit: stockUnit,
                unitCostCents: unitCostCents,
                stockReference: stockReference,
                desiredQuantity: desiredQuantity,
                targetPriceCents: targetPriceCents,
                siblingOrder: siblingOrder,
                showAdvanced: showAdvanced,
                barcodeRef: barcodeRef,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                purchasePlace: purchasePlace,
                objective: objective,
                photoRelPath: photoRelPath,
                iconKey: iconKey,
                status: status,
                withdrawalReason: withdrawalReason,
                withdrawnAt: withdrawnAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryId,
                Value<String?> parentId = const Value.absent(),
                Value<String> space = const Value.absent(),
                required String name,
                required String nodeType,
                Value<int?> quantity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> valueMode = const Value.absent(),
                Value<int?> financialValueCents = const Value.absent(),
                Value<int?> sentimentalValue = const Value.absent(),
                Value<String?> stockUnit = const Value.absent(),
                Value<int?> unitCostCents = const Value.absent(),
                Value<int?> stockReference = const Value.absent(),
                Value<int?> desiredQuantity = const Value.absent(),
                Value<int?> targetPriceCents = const Value.absent(),
                Value<int> siblingOrder = const Value.absent(),
                Value<bool> showAdvanced = const Value.absent(),
                Value<String?> barcodeRef = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchasePriceCents = const Value.absent(),
                Value<String?> purchasePlace = const Value.absent(),
                Value<String> objective = const Value.absent(),
                Value<String?> photoRelPath = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> withdrawalReason = const Value.absent(),
                Value<String?> withdrawnAt = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                inventoryId: inventoryId,
                parentId: parentId,
                space: space,
                name: name,
                nodeType: nodeType,
                quantity: quantity,
                description: description,
                condition: condition,
                valueMode: valueMode,
                financialValueCents: financialValueCents,
                sentimentalValue: sentimentalValue,
                stockUnit: stockUnit,
                unitCostCents: unitCostCents,
                stockReference: stockReference,
                desiredQuantity: desiredQuantity,
                targetPriceCents: targetPriceCents,
                siblingOrder: siblingOrder,
                showAdvanced: showAdvanced,
                barcodeRef: barcodeRef,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                purchasePlace: purchasePlace,
                objective: objective,
                photoRelPath: photoRelPath,
                iconKey: iconKey,
                status: status,
                withdrawalReason: withdrawalReason,
                withdrawnAt: withdrawnAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, Node>(table),
                  $$NodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryId,
                                referencedTable: $$NodesTableReferences
                                    ._inventoryIdTable(db),
                                referencedColumn: $$NodesTableReferences
                                    ._inventoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, $$NodesTableReferences),
      Node,
      PrefetchHooks Function({bool inventoryId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String inventoryId,
      required String name,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> inventoryId,
      Value<String> name,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$InventoryDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InventoriesTable _inventoryIdTable(_$InventoryDatabase db) =>
      db.inventories.createAlias('categories__inventory_id__inventories__id');

  $$InventoriesTableProcessedTableManager get inventoryId {
    final $_column = $_itemColumn<String>('inventory_id')!;

    final manager = $$InventoriesTableTableManager(
      $_db,
      $_db.inventories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$InventoryDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoriesTableFilterComposer get inventoryId {
    final $$InventoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableFilterComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoriesTableOrderingComposer get inventoryId {
    final $$InventoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableOrderingComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InventoriesTableAnnotationComposer get inventoryId {
    final $$InventoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool inventoryId})
        > {
  $$CategoriesTableTableManager(_$InventoryDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                inventoryId: inventoryId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryId,
                required String name,
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                inventoryId: inventoryId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryId,
                                referencedTable: $$CategoriesTableReferences
                                    ._inventoryIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._inventoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool inventoryId})
    >;
typedef $$NodeCategoriesTableCreateCompanionBuilder =
    NodeCategoriesCompanion Function({
      required String inventoryId,
      required String nodeId,
      required String categoryId,
      Value<int> rowid,
    });
typedef $$NodeCategoriesTableUpdateCompanionBuilder =
    NodeCategoriesCompanion Function({
      Value<String> inventoryId,
      Value<String> nodeId,
      Value<String> categoryId,
      Value<int> rowid,
    });

class $$NodeCategoriesTableFilterComposer
    extends Composer<_$InventoryDatabase, $NodeCategoriesTable> {
  $$NodeCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodeCategoriesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $NodeCategoriesTable> {
  $$NodeCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodeCategoriesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $NodeCategoriesTable> {
  $$NodeCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get inventoryId => $composableBuilder(
    column: $table.inventoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );
}

class $$NodeCategoriesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $NodeCategoriesTable,
          NodeCategory,
          $$NodeCategoriesTableFilterComposer,
          $$NodeCategoriesTableOrderingComposer,
          $$NodeCategoriesTableAnnotationComposer,
          $$NodeCategoriesTableCreateCompanionBuilder,
          $$NodeCategoriesTableUpdateCompanionBuilder,
          (
            NodeCategory,
            BaseReferences<
              _$InventoryDatabase,
              $NodeCategoriesTable,
              NodeCategory
            >,
          ),
          NodeCategory,
          PrefetchHooks Function()
        > {
  $$NodeCategoriesTableTableManager(
    _$InventoryDatabase db,
    $NodeCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> inventoryId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeCategoriesCompanion(
                inventoryId: inventoryId,
                nodeId: nodeId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String inventoryId,
                required String nodeId,
                required String categoryId,
                Value<int> rowid = const Value.absent(),
              }) => NodeCategoriesCompanion.insert(
                inventoryId: inventoryId,
                nodeId: nodeId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeCategoriesTable, NodeCategory>(table),
                  BaseReferences<
                    _$InventoryDatabase,
                    $NodeCategoriesTable,
                    NodeCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodeCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $NodeCategoriesTable,
      NodeCategory,
      $$NodeCategoriesTableFilterComposer,
      $$NodeCategoriesTableOrderingComposer,
      $$NodeCategoriesTableAnnotationComposer,
      $$NodeCategoriesTableCreateCompanionBuilder,
      $$NodeCategoriesTableUpdateCompanionBuilder,
      (
        NodeCategory,
        BaseReferences<_$InventoryDatabase, $NodeCategoriesTable, NodeCategory>,
      ),
      NodeCategory,
      PrefetchHooks Function()
    >;
typedef $$LocalVerificationEntriesTableCreateCompanionBuilder =
    LocalVerificationEntriesCompanion Function({
      Value<int> id,
      required String value,
    });
typedef $$LocalVerificationEntriesTableUpdateCompanionBuilder =
    LocalVerificationEntriesCompanion Function({
      Value<int> id,
      Value<String> value,
    });

class $$LocalVerificationEntriesTableFilterComposer
    extends Composer<_$InventoryDatabase, $LocalVerificationEntriesTable> {
  $$LocalVerificationEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalVerificationEntriesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $LocalVerificationEntriesTable> {
  $$LocalVerificationEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalVerificationEntriesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $LocalVerificationEntriesTable> {
  $$LocalVerificationEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalVerificationEntriesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $LocalVerificationEntriesTable,
          LocalVerificationEntry,
          $$LocalVerificationEntriesTableFilterComposer,
          $$LocalVerificationEntriesTableOrderingComposer,
          $$LocalVerificationEntriesTableAnnotationComposer,
          $$LocalVerificationEntriesTableCreateCompanionBuilder,
          $$LocalVerificationEntriesTableUpdateCompanionBuilder,
          (
            LocalVerificationEntry,
            BaseReferences<
              _$InventoryDatabase,
              $LocalVerificationEntriesTable,
              LocalVerificationEntry
            >,
          ),
          LocalVerificationEntry,
          PrefetchHooks Function()
        > {
  $$LocalVerificationEntriesTableTableManager(
    _$InventoryDatabase db,
    $LocalVerificationEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVerificationEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalVerificationEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalVerificationEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => LocalVerificationEntriesCompanion(id: id, value: value),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String value}) =>
                  LocalVerificationEntriesCompanion.insert(
                    id: id,
                    value: value,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalVerificationEntriesTable,
                    LocalVerificationEntry
                  >(table),
                  BaseReferences<
                    _$InventoryDatabase,
                    $LocalVerificationEntriesTable,
                    LocalVerificationEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalVerificationEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $LocalVerificationEntriesTable,
      LocalVerificationEntry,
      $$LocalVerificationEntriesTableFilterComposer,
      $$LocalVerificationEntriesTableOrderingComposer,
      $$LocalVerificationEntriesTableAnnotationComposer,
      $$LocalVerificationEntriesTableCreateCompanionBuilder,
      $$LocalVerificationEntriesTableUpdateCompanionBuilder,
      (
        LocalVerificationEntry,
        BaseReferences<
          _$InventoryDatabase,
          $LocalVerificationEntriesTable,
          LocalVerificationEntry
        >,
      ),
      LocalVerificationEntry,
      PrefetchHooks Function()
    >;
typedef $$RestorationJournalEntriesTableCreateCompanionBuilder =
    RestorationJournalEntriesCompanion Function({
      required String operationId,
      required String status,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$RestorationJournalEntriesTableUpdateCompanionBuilder =
    RestorationJournalEntriesCompanion Function({
      Value<String> operationId,
      Value<String> status,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$RestorationJournalEntriesTableFilterComposer
    extends Composer<_$InventoryDatabase, $RestorationJournalEntriesTable> {
  $$RestorationJournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RestorationJournalEntriesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $RestorationJournalEntriesTable> {
  $$RestorationJournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RestorationJournalEntriesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $RestorationJournalEntriesTable> {
  $$RestorationJournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RestorationJournalEntriesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $RestorationJournalEntriesTable,
          RestorationJournalEntry,
          $$RestorationJournalEntriesTableFilterComposer,
          $$RestorationJournalEntriesTableOrderingComposer,
          $$RestorationJournalEntriesTableAnnotationComposer,
          $$RestorationJournalEntriesTableCreateCompanionBuilder,
          $$RestorationJournalEntriesTableUpdateCompanionBuilder,
          (
            RestorationJournalEntry,
            BaseReferences<
              _$InventoryDatabase,
              $RestorationJournalEntriesTable,
              RestorationJournalEntry
            >,
          ),
          RestorationJournalEntry,
          PrefetchHooks Function()
        > {
  $$RestorationJournalEntriesTableTableManager(
    _$InventoryDatabase db,
    $RestorationJournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestorationJournalEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RestorationJournalEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RestorationJournalEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestorationJournalEntriesCompanion(
                operationId: operationId,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String status,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RestorationJournalEntriesCompanion.insert(
                operationId: operationId,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RestorationJournalEntriesTable,
                    RestorationJournalEntry
                  >(table),
                  BaseReferences<
                    _$InventoryDatabase,
                    $RestorationJournalEntriesTable,
                    RestorationJournalEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RestorationJournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $RestorationJournalEntriesTable,
      RestorationJournalEntry,
      $$RestorationJournalEntriesTableFilterComposer,
      $$RestorationJournalEntriesTableOrderingComposer,
      $$RestorationJournalEntriesTableAnnotationComposer,
      $$RestorationJournalEntriesTableCreateCompanionBuilder,
      $$RestorationJournalEntriesTableUpdateCompanionBuilder,
      (
        RestorationJournalEntry,
        BaseReferences<
          _$InventoryDatabase,
          $RestorationJournalEntriesTable,
          RestorationJournalEntry
        >,
      ),
      RestorationJournalEntry,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      required String id,
      required String inventoryId,
      required String nodeId,
      required String movementType,
      required int deltaQuarters,
      required int balanceAfterQuarters,
      required String unit,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<String> id,
      Value<String> inventoryId,
      Value<String> nodeId,
      Value<String> movementType,
      Value<int> deltaQuarters,
      Value<int> balanceAfterQuarters,
      Value<String> unit,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$StockMovementsTableReferences
    extends
        BaseReferences<
          _$InventoryDatabase,
          $StockMovementsTable,
          StockMovement
        > {
  $$StockMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoriesTable _inventoryIdTable(_$InventoryDatabase db) => db
      .inventories
      .createAlias('stock_movements__inventory_id__inventories__id');

  $$InventoriesTableProcessedTableManager get inventoryId {
    final $_column = $_itemColumn<String>('inventory_id')!;

    final manager = $$InventoriesTableTableManager(
      $_db,
      $_db.inventories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$InventoryDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deltaQuarters => $composableBuilder(
    column: $table.deltaQuarters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceAfterQuarters => $composableBuilder(
    column: $table.balanceAfterQuarters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoriesTableFilterComposer get inventoryId {
    final $$InventoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableFilterComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deltaQuarters => $composableBuilder(
    column: $table.deltaQuarters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceAfterQuarters => $composableBuilder(
    column: $table.balanceAfterQuarters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoriesTableOrderingComposer get inventoryId {
    final $$InventoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableOrderingComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deltaQuarters => $composableBuilder(
    column: $table.deltaQuarters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balanceAfterQuarters => $composableBuilder(
    column: $table.balanceAfterQuarters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InventoriesTableAnnotationComposer get inventoryId {
    final $$InventoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $StockMovementsTable,
          StockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (StockMovement, $$StockMovementsTableReferences),
          StockMovement,
          PrefetchHooks Function({bool inventoryId})
        > {
  $$StockMovementsTableTableManager(
    _$InventoryDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> deltaQuarters = const Value.absent(),
                Value<int> balanceAfterQuarters = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                inventoryId: inventoryId,
                nodeId: nodeId,
                movementType: movementType,
                deltaQuarters: deltaQuarters,
                balanceAfterQuarters: balanceAfterQuarters,
                unit: unit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryId,
                required String nodeId,
                required String movementType,
                required int deltaQuarters,
                required int balanceAfterQuarters,
                required String unit,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion.insert(
                id: id,
                inventoryId: inventoryId,
                nodeId: nodeId,
                movementType: movementType,
                deltaQuarters: deltaQuarters,
                balanceAfterQuarters: balanceAfterQuarters,
                unit: unit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockMovementsTable, StockMovement>(table),
                  $$StockMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryId,
                                referencedTable: $$StockMovementsTableReferences
                                    ._inventoryIdTable(db),
                                referencedColumn:
                                    $$StockMovementsTableReferences
                                        ._inventoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $StockMovementsTable,
      StockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (StockMovement, $$StockMovementsTableReferences),
      StockMovement,
      PrefetchHooks Function({bool inventoryId})
    >;
typedef $$PurchaseEventsTableCreateCompanionBuilder =
    PurchaseEventsCompanion Function({
      required String id,
      required String inventoryId,
      required String needNodeId,
      required String eventType,
      required int quantity,
      Value<int?> targetPriceCents,
      Value<int?> paidPriceCents,
      Value<String?> destinationSpace,
      Value<String?> destinationNodeId,
      Value<String?> destinationParentId,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$PurchaseEventsTableUpdateCompanionBuilder =
    PurchaseEventsCompanion Function({
      Value<String> id,
      Value<String> inventoryId,
      Value<String> needNodeId,
      Value<String> eventType,
      Value<int> quantity,
      Value<int?> targetPriceCents,
      Value<int?> paidPriceCents,
      Value<String?> destinationSpace,
      Value<String?> destinationNodeId,
      Value<String?> destinationParentId,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$PurchaseEventsTableReferences
    extends
        BaseReferences<
          _$InventoryDatabase,
          $PurchaseEventsTable,
          PurchaseEvent
        > {
  $$PurchaseEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoriesTable _inventoryIdTable(_$InventoryDatabase db) => db
      .inventories
      .createAlias('purchase_events__inventory_id__inventories__id');

  $$InventoriesTableProcessedTableManager get inventoryId {
    final $_column = $_itemColumn<String>('inventory_id')!;

    final manager = $$InventoriesTableTableManager(
      $_db,
      $_db.inventories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PurchaseEventsTableFilterComposer
    extends Composer<_$InventoryDatabase, $PurchaseEventsTable> {
  $$PurchaseEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get needNodeId => $composableBuilder(
    column: $table.needNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidPriceCents => $composableBuilder(
    column: $table.paidPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationSpace => $composableBuilder(
    column: $table.destinationSpace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationParentId => $composableBuilder(
    column: $table.destinationParentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoriesTableFilterComposer get inventoryId {
    final $$InventoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableFilterComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseEventsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $PurchaseEventsTable> {
  $$PurchaseEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get needNodeId => $composableBuilder(
    column: $table.needNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidPriceCents => $composableBuilder(
    column: $table.paidPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationSpace => $composableBuilder(
    column: $table.destinationSpace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationParentId => $composableBuilder(
    column: $table.destinationParentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoriesTableOrderingComposer get inventoryId {
    final $$InventoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableOrderingComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseEventsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $PurchaseEventsTable> {
  $$PurchaseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get needNodeId => $composableBuilder(
    column: $table.needNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get targetPriceCents => $composableBuilder(
    column: $table.targetPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidPriceCents => $composableBuilder(
    column: $table.paidPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationSpace => $composableBuilder(
    column: $table.destinationSpace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationParentId => $composableBuilder(
    column: $table.destinationParentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InventoriesTableAnnotationComposer get inventoryId {
    final $$InventoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseEventsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $PurchaseEventsTable,
          PurchaseEvent,
          $$PurchaseEventsTableFilterComposer,
          $$PurchaseEventsTableOrderingComposer,
          $$PurchaseEventsTableAnnotationComposer,
          $$PurchaseEventsTableCreateCompanionBuilder,
          $$PurchaseEventsTableUpdateCompanionBuilder,
          (PurchaseEvent, $$PurchaseEventsTableReferences),
          PurchaseEvent,
          PrefetchHooks Function({bool inventoryId})
        > {
  $$PurchaseEventsTableTableManager(
    _$InventoryDatabase db,
    $PurchaseEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<String> needNodeId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int?> targetPriceCents = const Value.absent(),
                Value<int?> paidPriceCents = const Value.absent(),
                Value<String?> destinationSpace = const Value.absent(),
                Value<String?> destinationNodeId = const Value.absent(),
                Value<String?> destinationParentId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseEventsCompanion(
                id: id,
                inventoryId: inventoryId,
                needNodeId: needNodeId,
                eventType: eventType,
                quantity: quantity,
                targetPriceCents: targetPriceCents,
                paidPriceCents: paidPriceCents,
                destinationSpace: destinationSpace,
                destinationNodeId: destinationNodeId,
                destinationParentId: destinationParentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryId,
                required String needNodeId,
                required String eventType,
                required int quantity,
                Value<int?> targetPriceCents = const Value.absent(),
                Value<int?> paidPriceCents = const Value.absent(),
                Value<String?> destinationSpace = const Value.absent(),
                Value<String?> destinationNodeId = const Value.absent(),
                Value<String?> destinationParentId = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseEventsCompanion.insert(
                id: id,
                inventoryId: inventoryId,
                needNodeId: needNodeId,
                eventType: eventType,
                quantity: quantity,
                targetPriceCents: targetPriceCents,
                paidPriceCents: paidPriceCents,
                destinationSpace: destinationSpace,
                destinationNodeId: destinationNodeId,
                destinationParentId: destinationParentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchaseEventsTable, PurchaseEvent>(table),
                  $$PurchaseEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryId,
                                referencedTable: $$PurchaseEventsTableReferences
                                    ._inventoryIdTable(db),
                                referencedColumn:
                                    $$PurchaseEventsTableReferences
                                        ._inventoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PurchaseEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $PurchaseEventsTable,
      PurchaseEvent,
      $$PurchaseEventsTableFilterComposer,
      $$PurchaseEventsTableOrderingComposer,
      $$PurchaseEventsTableAnnotationComposer,
      $$PurchaseEventsTableCreateCompanionBuilder,
      $$PurchaseEventsTableUpdateCompanionBuilder,
      (PurchaseEvent, $$PurchaseEventsTableReferences),
      PurchaseEvent,
      PrefetchHooks Function({bool inventoryId})
    >;
typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$InventoryDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<
              _$InventoryDatabase,
              $AppPreferencesTable,
              AppPreference
            >,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$InventoryDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppPreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppPreferencesTable, AppPreference>(table),
                  BaseReferences<
                    _$InventoryDatabase,
                    $AppPreferencesTable,
                    AppPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<
          _$InventoryDatabase,
          $AppPreferencesTable,
          AppPreference
        >,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;
typedef $$NodeDocumentsTableCreateCompanionBuilder =
    NodeDocumentsCompanion Function({
      required String id,
      required String inventoryId,
      required String nodeId,
      required String displayName,
      required String relPath,
      required String mimeType,
      required int byteSize,
      Value<int> sortIndex,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$NodeDocumentsTableUpdateCompanionBuilder =
    NodeDocumentsCompanion Function({
      Value<String> id,
      Value<String> inventoryId,
      Value<String> nodeId,
      Value<String> displayName,
      Value<String> relPath,
      Value<String> mimeType,
      Value<int> byteSize,
      Value<int> sortIndex,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$NodeDocumentsTableReferences
    extends
        BaseReferences<
          _$InventoryDatabase,
          $NodeDocumentsTable,
          NodeDocumentRow
        > {
  $$NodeDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoriesTable _inventoryIdTable(_$InventoryDatabase db) => db
      .inventories
      .createAlias('node_documents__inventory_id__inventories__id');

  $$InventoriesTableProcessedTableManager get inventoryId {
    final $_column = $_itemColumn<String>('inventory_id')!;

    final manager = $$InventoriesTableTableManager(
      $_db,
      $_db.inventories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeDocumentsTableFilterComposer
    extends Composer<_$InventoryDatabase, $NodeDocumentsTable> {
  $$NodeDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoriesTableFilterComposer get inventoryId {
    final $$InventoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableFilterComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeDocumentsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $NodeDocumentsTable> {
  $$NodeDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoriesTableOrderingComposer get inventoryId {
    final $$InventoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableOrderingComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeDocumentsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $NodeDocumentsTable> {
  $$NodeDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relPath =>
      $composableBuilder(column: $table.relPath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InventoriesTableAnnotationComposer get inventoryId {
    final $$InventoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryId,
      referencedTable: $db.inventories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.inventories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeDocumentsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $NodeDocumentsTable,
          NodeDocumentRow,
          $$NodeDocumentsTableFilterComposer,
          $$NodeDocumentsTableOrderingComposer,
          $$NodeDocumentsTableAnnotationComposer,
          $$NodeDocumentsTableCreateCompanionBuilder,
          $$NodeDocumentsTableUpdateCompanionBuilder,
          (NodeDocumentRow, $$NodeDocumentsTableReferences),
          NodeDocumentRow,
          PrefetchHooks Function({bool inventoryId})
        > {
  $$NodeDocumentsTableTableManager(
    _$InventoryDatabase db,
    $NodeDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> relPath = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeDocumentsCompanion(
                id: id,
                inventoryId: inventoryId,
                nodeId: nodeId,
                displayName: displayName,
                relPath: relPath,
                mimeType: mimeType,
                byteSize: byteSize,
                sortIndex: sortIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryId,
                required String nodeId,
                required String displayName,
                required String relPath,
                required String mimeType,
                required int byteSize,
                Value<int> sortIndex = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NodeDocumentsCompanion.insert(
                id: id,
                inventoryId: inventoryId,
                nodeId: nodeId,
                displayName: displayName,
                relPath: relPath,
                mimeType: mimeType,
                byteSize: byteSize,
                sortIndex: sortIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeDocumentsTable, NodeDocumentRow>(table),
                  $$NodeDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryId,
                                referencedTable: $$NodeDocumentsTableReferences
                                    ._inventoryIdTable(db),
                                referencedColumn: $$NodeDocumentsTableReferences
                                    ._inventoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodeDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $NodeDocumentsTable,
      NodeDocumentRow,
      $$NodeDocumentsTableFilterComposer,
      $$NodeDocumentsTableOrderingComposer,
      $$NodeDocumentsTableAnnotationComposer,
      $$NodeDocumentsTableCreateCompanionBuilder,
      $$NodeDocumentsTableUpdateCompanionBuilder,
      (NodeDocumentRow, $$NodeDocumentsTableReferences),
      NodeDocumentRow,
      PrefetchHooks Function({bool inventoryId})
    >;

class $InventoryDatabaseManager {
  final _$InventoryDatabase _db;
  $InventoryDatabaseManager(this._db);
  $$InventoriesTableTableManager get inventories =>
      $$InventoriesTableTableManager(_db, _db.inventories);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$NodeCategoriesTableTableManager get nodeCategories =>
      $$NodeCategoriesTableTableManager(_db, _db.nodeCategories);
  $$LocalVerificationEntriesTableTableManager get localVerificationEntries =>
      $$LocalVerificationEntriesTableTableManager(
        _db,
        _db.localVerificationEntries,
      );
  $$RestorationJournalEntriesTableTableManager get restorationJournalEntries =>
      $$RestorationJournalEntriesTableTableManager(
        _db,
        _db.restorationJournalEntries,
      );
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$PurchaseEventsTableTableManager get purchaseEvents =>
      $$PurchaseEventsTableTableManager(_db, _db.purchaseEvents);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
  $$NodeDocumentsTableTableManager get nodeDocuments =>
      $$NodeDocumentsTableTableManager(_db, _db.nodeDocuments);
}
