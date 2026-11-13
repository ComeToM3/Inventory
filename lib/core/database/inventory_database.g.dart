// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_database.dart';

// ignore_for_file: type=lint
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
  late final $LocalVerificationEntriesTable localVerificationEntries =
      $LocalVerificationEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localVerificationEntries,
  ];
}

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
  $$LocalVerificationEntriesTableTableManager get localVerificationEntries =>
      $$LocalVerificationEntriesTableTableManager(
        _db,
        _db.localVerificationEntries,
      );
}
