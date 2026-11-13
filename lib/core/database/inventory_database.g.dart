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
    name,
    nodeType,
    quantity,
    description,
    condition,
    valueMode,
    financialValueCents,
    sentimentalValue,
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
  final String name;
  final String nodeType;
  final int? quantity;
  final String? description;
  final String? condition;
  final String? valueMode;
  final int? financialValueCents;
  final int? sentimentalValue;
  final String status;
  final String? withdrawalReason;
  final String? withdrawnAt;
  final String createdAt;
  final String updatedAt;
  const Node({
    required this.id,
    required this.inventoryId,
    this.parentId,
    required this.name,
    required this.nodeType,
    this.quantity,
    this.description,
    this.condition,
    this.valueMode,
    this.financialValueCents,
    this.sentimentalValue,
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
      'name': serializer.toJson<String>(name),
      'nodeType': serializer.toJson<String>(nodeType),
      'quantity': serializer.toJson<int?>(quantity),
      'description': serializer.toJson<String?>(description),
      'condition': serializer.toJson<String?>(condition),
      'valueMode': serializer.toJson<String?>(valueMode),
      'financialValueCents': serializer.toJson<int?>(financialValueCents),
      'sentimentalValue': serializer.toJson<int?>(sentimentalValue),
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
    String? name,
    String? nodeType,
    Value<int?> quantity = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> valueMode = const Value.absent(),
    Value<int?> financialValueCents = const Value.absent(),
    Value<int?> sentimentalValue = const Value.absent(),
    String? status,
    Value<String?> withdrawalReason = const Value.absent(),
    Value<String?> withdrawnAt = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => Node(
    id: id ?? this.id,
    inventoryId: inventoryId ?? this.inventoryId,
    parentId: parentId.present ? parentId.value : this.parentId,
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
          ..write('name: $name, ')
          ..write('nodeType: $nodeType, ')
          ..write('quantity: $quantity, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('valueMode: $valueMode, ')
          ..write('financialValueCents: $financialValueCents, ')
          ..write('sentimentalValue: $sentimentalValue, ')
          ..write('status: $status, ')
          ..write('withdrawalReason: $withdrawalReason, ')
          ..write('withdrawnAt: $withdrawnAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryId,
    parentId,
    name,
    nodeType,
    quantity,
    description,
    condition,
    valueMode,
    financialValueCents,
    sentimentalValue,
    status,
    withdrawalReason,
    withdrawnAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.inventoryId == this.inventoryId &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.nodeType == this.nodeType &&
          other.quantity == this.quantity &&
          other.description == this.description &&
          other.condition == this.condition &&
          other.valueMode == this.valueMode &&
          other.financialValueCents == this.financialValueCents &&
          other.sentimentalValue == this.sentimentalValue &&
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
  final Value<String> name;
  final Value<String> nodeType;
  final Value<int?> quantity;
  final Value<String?> description;
  final Value<String?> condition;
  final Value<String?> valueMode;
  final Value<int?> financialValueCents;
  final Value<int?> sentimentalValue;
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
    this.name = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.valueMode = const Value.absent(),
    this.financialValueCents = const Value.absent(),
    this.sentimentalValue = const Value.absent(),
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
    required String name,
    required String nodeType,
    this.quantity = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.valueMode = const Value.absent(),
    this.financialValueCents = const Value.absent(),
    this.sentimentalValue = const Value.absent(),
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
    Expression<String>? name,
    Expression<String>? nodeType,
    Expression<int>? quantity,
    Expression<String>? description,
    Expression<String>? condition,
    Expression<String>? valueMode,
    Expression<int>? financialValueCents,
    Expression<int>? sentimentalValue,
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
      if (name != null) 'name': name,
      if (nodeType != null) 'node_type': nodeType,
      if (quantity != null) 'quantity': quantity,
      if (description != null) 'description': description,
      if (condition != null) 'condition': condition,
      if (valueMode != null) 'value_mode': valueMode,
      if (financialValueCents != null)
        'financial_value_cents': financialValueCents,
      if (sentimentalValue != null) 'sentimental_value': sentimentalValue,
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
    Value<String>? name,
    Value<String>? nodeType,
    Value<int?>? quantity,
    Value<String?>? description,
    Value<String?>? condition,
    Value<String?>? valueMode,
    Value<int?>? financialValueCents,
    Value<int?>? sentimentalValue,
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
      name: name ?? this.name,
      nodeType: nodeType ?? this.nodeType,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      valueMode: valueMode ?? this.valueMode,
      financialValueCents: financialValueCents ?? this.financialValueCents,
      sentimentalValue: sentimentalValue ?? this.sentimentalValue,
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
          ..write('name: $name, ')
          ..write('nodeType: $nodeType, ')
          ..write('quantity: $quantity, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('valueMode: $valueMode, ')
          ..write('financialValueCents: $financialValueCents, ')
          ..write('sentimentalValue: $sentimentalValue, ')
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

abstract class _$InventoryDatabase extends GeneratedDatabase {
  _$InventoryDatabase(QueryExecutor e) : super(e);
  $InventoryDatabaseManager get managers => $InventoryDatabaseManager(this);
  late final $InventoriesTable inventories = $InventoriesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $NodeCategoriesTable nodeCategories = $NodeCategoriesTable(this);
  late final $LocalVerificationEntriesTable localVerificationEntries =
      $LocalVerificationEntriesTable(this);
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
    nodesParentIdx,
    nodesActiveNameIdx,
    nodeCategoriesCategoryIdx,
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
          PrefetchHooks Function({bool nodesRefs, bool categoriesRefs})
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
          prefetchHooksCallback: ({nodesRefs = false, categoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (nodesRefs) db.nodes,
                if (categoriesRefs) db.categories,
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
                          $$InventoriesTableReferences(db, table, p0).nodesRefs,
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
      PrefetchHooks Function({bool nodesRefs, bool categoriesRefs})
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      required String id,
      required String inventoryId,
      Value<String?> parentId,
      required String name,
      required String nodeType,
      Value<int?> quantity,
      Value<String?> description,
      Value<String?> condition,
      Value<String?> valueMode,
      Value<int?> financialValueCents,
      Value<int?> sentimentalValue,
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
      Value<String> name,
      Value<String> nodeType,
      Value<int?> quantity,
      Value<String?> description,
      Value<String?> condition,
      Value<String?> valueMode,
      Value<int?> financialValueCents,
      Value<int?> sentimentalValue,
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
                Value<String> name = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> valueMode = const Value.absent(),
                Value<int?> financialValueCents = const Value.absent(),
                Value<int?> sentimentalValue = const Value.absent(),
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
                name: name,
                nodeType: nodeType,
                quantity: quantity,
                description: description,
                condition: condition,
                valueMode: valueMode,
                financialValueCents: financialValueCents,
                sentimentalValue: sentimentalValue,
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
                required String name,
                required String nodeType,
                Value<int?> quantity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> valueMode = const Value.absent(),
                Value<int?> financialValueCents = const Value.absent(),
                Value<int?> sentimentalValue = const Value.absent(),
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
                name: name,
                nodeType: nodeType,
                quantity: quantity,
                description: description,
                condition: condition,
                valueMode: valueMode,
                financialValueCents: financialValueCents,
                sentimentalValue: sentimentalValue,
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
}
