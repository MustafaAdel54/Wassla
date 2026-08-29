// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_database.dart';

// ignore_for_file: type=lint
class $LocalManifestTable extends LocalManifest
    with TableInfo<$LocalManifestTable, LocalManifestData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalManifestTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _datasetVersionMeta = const VerificationMeta(
    'datasetVersion',
  );
  @override
  late final GeneratedColumn<int> datasetVersion = GeneratedColumn<int>(
    'dataset_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _graphBuiltForVersionMeta =
      const VerificationMeta('graphBuiltForVersion');
  @override
  late final GeneratedColumn<int> graphBuiltForVersion = GeneratedColumn<int>(
    'graph_built_for_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    datasetVersion,
    schemaVersion,
    updatedAt,
    graphBuiltForVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_manifest';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalManifestData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_version')) {
      context.handle(
        _datasetVersionMeta,
        datasetVersion.isAcceptableOrUnknown(
          data['dataset_version']!,
          _datasetVersionMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('graph_built_for_version')) {
      context.handle(
        _graphBuiltForVersionMeta,
        graphBuiltForVersion.isAcceptableOrUnknown(
          data['graph_built_for_version']!,
          _graphBuiltForVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalManifestData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalManifestData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      datasetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dataset_version'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      graphBuiltForVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}graph_built_for_version'],
      )!,
    );
  }

  @override
  $LocalManifestTable createAlias(String alias) {
    return $LocalManifestTable(attachedDatabase, alias);
  }
}

class LocalManifestData extends DataClass
    implements Insertable<LocalManifestData> {
  final int id;
  final int datasetVersion;
  final int schemaVersion;
  final String updatedAt;
  final int graphBuiltForVersion;
  const LocalManifestData({
    required this.id,
    required this.datasetVersion,
    required this.schemaVersion,
    required this.updatedAt,
    required this.graphBuiltForVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_version'] = Variable<int>(datasetVersion);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['updated_at'] = Variable<String>(updatedAt);
    map['graph_built_for_version'] = Variable<int>(graphBuiltForVersion);
    return map;
  }

  LocalManifestCompanion toCompanion(bool nullToAbsent) {
    return LocalManifestCompanion(
      id: Value(id),
      datasetVersion: Value(datasetVersion),
      schemaVersion: Value(schemaVersion),
      updatedAt: Value(updatedAt),
      graphBuiltForVersion: Value(graphBuiltForVersion),
    );
  }

  factory LocalManifestData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalManifestData(
      id: serializer.fromJson<int>(json['id']),
      datasetVersion: serializer.fromJson<int>(json['datasetVersion']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      graphBuiltForVersion: serializer.fromJson<int>(
        json['graphBuiltForVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetVersion': serializer.toJson<int>(datasetVersion),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'graphBuiltForVersion': serializer.toJson<int>(graphBuiltForVersion),
    };
  }

  LocalManifestData copyWith({
    int? id,
    int? datasetVersion,
    int? schemaVersion,
    String? updatedAt,
    int? graphBuiltForVersion,
  }) => LocalManifestData(
    id: id ?? this.id,
    datasetVersion: datasetVersion ?? this.datasetVersion,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    graphBuiltForVersion: graphBuiltForVersion ?? this.graphBuiltForVersion,
  );
  LocalManifestData copyWithCompanion(LocalManifestCompanion data) {
    return LocalManifestData(
      id: data.id.present ? data.id.value : this.id,
      datasetVersion: data.datasetVersion.present
          ? data.datasetVersion.value
          : this.datasetVersion,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      graphBuiltForVersion: data.graphBuiltForVersion.present
          ? data.graphBuiltForVersion.value
          : this.graphBuiltForVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalManifestData(')
          ..write('id: $id, ')
          ..write('datasetVersion: $datasetVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('graphBuiltForVersion: $graphBuiltForVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    datasetVersion,
    schemaVersion,
    updatedAt,
    graphBuiltForVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalManifestData &&
          other.id == this.id &&
          other.datasetVersion == this.datasetVersion &&
          other.schemaVersion == this.schemaVersion &&
          other.updatedAt == this.updatedAt &&
          other.graphBuiltForVersion == this.graphBuiltForVersion);
}

class LocalManifestCompanion extends UpdateCompanion<LocalManifestData> {
  final Value<int> id;
  final Value<int> datasetVersion;
  final Value<int> schemaVersion;
  final Value<String> updatedAt;
  final Value<int> graphBuiltForVersion;
  const LocalManifestCompanion({
    this.id = const Value.absent(),
    this.datasetVersion = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.graphBuiltForVersion = const Value.absent(),
  });
  LocalManifestCompanion.insert({
    this.id = const Value.absent(),
    this.datasetVersion = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.graphBuiltForVersion = const Value.absent(),
  });
  static Insertable<LocalManifestData> custom({
    Expression<int>? id,
    Expression<int>? datasetVersion,
    Expression<int>? schemaVersion,
    Expression<String>? updatedAt,
    Expression<int>? graphBuiltForVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetVersion != null) 'dataset_version': datasetVersion,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (graphBuiltForVersion != null)
        'graph_built_for_version': graphBuiltForVersion,
    });
  }

  LocalManifestCompanion copyWith({
    Value<int>? id,
    Value<int>? datasetVersion,
    Value<int>? schemaVersion,
    Value<String>? updatedAt,
    Value<int>? graphBuiltForVersion,
  }) {
    return LocalManifestCompanion(
      id: id ?? this.id,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      graphBuiltForVersion: graphBuiltForVersion ?? this.graphBuiltForVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetVersion.present) {
      map['dataset_version'] = Variable<int>(datasetVersion.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (graphBuiltForVersion.present) {
      map['graph_built_for_version'] = Variable<int>(
        graphBuiltForVersion.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalManifestCompanion(')
          ..write('id: $id, ')
          ..write('datasetVersion: $datasetVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('graphBuiltForVersion: $graphBuiltForVersion')
          ..write(')'))
        .toString();
  }
}

class $LocalCollectionsTable extends LocalCollections
    with TableInfo<$LocalCollectionsTable, LocalCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionNameMeta = const VerificationMeta(
    'collectionName',
  );
  @override
  late final GeneratedColumn<String> collectionName = GeneratedColumn<String>(
    'collection_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docCountMeta = const VerificationMeta(
    'docCount',
  );
  @override
  late final GeneratedColumn<int> docCount = GeneratedColumn<int>(
    'doc_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    collectionName,
    docCount,
    contentHash,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_name')) {
      context.handle(
        _collectionNameMeta,
        collectionName.isAcceptableOrUnknown(
          data['collection_name']!,
          _collectionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionNameMeta);
    }
    if (data.containsKey('doc_count')) {
      context.handle(
        _docCountMeta,
        docCount.isAcceptableOrUnknown(data['doc_count']!, _docCountMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionName};
  @override
  LocalCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCollection(
      collectionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_name'],
      )!,
      docCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}doc_count'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalCollectionsTable createAlias(String alias) {
    return $LocalCollectionsTable(attachedDatabase, alias);
  }
}

class LocalCollection extends DataClass implements Insertable<LocalCollection> {
  final String collectionName;
  final int docCount;
  final String contentHash;
  final String syncedAt;
  const LocalCollection({
    required this.collectionName,
    required this.docCount,
    required this.contentHash,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_name'] = Variable<String>(collectionName);
    map['doc_count'] = Variable<int>(docCount);
    map['content_hash'] = Variable<String>(contentHash);
    map['synced_at'] = Variable<String>(syncedAt);
    return map;
  }

  LocalCollectionsCompanion toCompanion(bool nullToAbsent) {
    return LocalCollectionsCompanion(
      collectionName: Value(collectionName),
      docCount: Value(docCount),
      contentHash: Value(contentHash),
      syncedAt: Value(syncedAt),
    );
  }

  factory LocalCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCollection(
      collectionName: serializer.fromJson<String>(json['collectionName']),
      docCount: serializer.fromJson<int>(json['docCount']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      syncedAt: serializer.fromJson<String>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionName': serializer.toJson<String>(collectionName),
      'docCount': serializer.toJson<int>(docCount),
      'contentHash': serializer.toJson<String>(contentHash),
      'syncedAt': serializer.toJson<String>(syncedAt),
    };
  }

  LocalCollection copyWith({
    String? collectionName,
    int? docCount,
    String? contentHash,
    String? syncedAt,
  }) => LocalCollection(
    collectionName: collectionName ?? this.collectionName,
    docCount: docCount ?? this.docCount,
    contentHash: contentHash ?? this.contentHash,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  LocalCollection copyWithCompanion(LocalCollectionsCompanion data) {
    return LocalCollection(
      collectionName: data.collectionName.present
          ? data.collectionName.value
          : this.collectionName,
      docCount: data.docCount.present ? data.docCount.value : this.docCount,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCollection(')
          ..write('collectionName: $collectionName, ')
          ..write('docCount: $docCount, ')
          ..write('contentHash: $contentHash, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(collectionName, docCount, contentHash, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCollection &&
          other.collectionName == this.collectionName &&
          other.docCount == this.docCount &&
          other.contentHash == this.contentHash &&
          other.syncedAt == this.syncedAt);
}

class LocalCollectionsCompanion extends UpdateCompanion<LocalCollection> {
  final Value<String> collectionName;
  final Value<int> docCount;
  final Value<String> contentHash;
  final Value<String> syncedAt;
  final Value<int> rowid;
  const LocalCollectionsCompanion({
    this.collectionName = const Value.absent(),
    this.docCount = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCollectionsCompanion.insert({
    required String collectionName,
    this.docCount = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collectionName = Value(collectionName);
  static Insertable<LocalCollection> custom({
    Expression<String>? collectionName,
    Expression<int>? docCount,
    Expression<String>? contentHash,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionName != null) 'collection_name': collectionName,
      if (docCount != null) 'doc_count': docCount,
      if (contentHash != null) 'content_hash': contentHash,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCollectionsCompanion copyWith({
    Value<String>? collectionName,
    Value<int>? docCount,
    Value<String>? contentHash,
    Value<String>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalCollectionsCompanion(
      collectionName: collectionName ?? this.collectionName,
      docCount: docCount ?? this.docCount,
      contentHash: contentHash ?? this.contentHash,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionName.present) {
      map['collection_name'] = Variable<String>(collectionName.value);
    }
    if (docCount.present) {
      map['doc_count'] = Variable<int>(docCount.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCollectionsCompanion(')
          ..write('collectionName: $collectionName, ')
          ..write('docCount: $docCount, ')
          ..write('contentHash: $contentHash, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncDatabase extends GeneratedDatabase {
  _$SyncDatabase(QueryExecutor e) : super(e);
  $SyncDatabaseManager get managers => $SyncDatabaseManager(this);
  late final $LocalManifestTable localManifest = $LocalManifestTable(this);
  late final $LocalCollectionsTable localCollections = $LocalCollectionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localManifest,
    localCollections,
  ];
}

typedef $$LocalManifestTableCreateCompanionBuilder =
    LocalManifestCompanion Function({
      Value<int> id,
      Value<int> datasetVersion,
      Value<int> schemaVersion,
      Value<String> updatedAt,
      Value<int> graphBuiltForVersion,
    });
typedef $$LocalManifestTableUpdateCompanionBuilder =
    LocalManifestCompanion Function({
      Value<int> id,
      Value<int> datasetVersion,
      Value<int> schemaVersion,
      Value<String> updatedAt,
      Value<int> graphBuiltForVersion,
    });

class $$LocalManifestTableFilterComposer
    extends Composer<_$SyncDatabase, $LocalManifestTable> {
  $$LocalManifestTableFilterComposer({
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

  ColumnFilters<int> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get graphBuiltForVersion => $composableBuilder(
    column: $table.graphBuiltForVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalManifestTableOrderingComposer
    extends Composer<_$SyncDatabase, $LocalManifestTable> {
  $$LocalManifestTableOrderingComposer({
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

  ColumnOrderings<int> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get graphBuiltForVersion => $composableBuilder(
    column: $table.graphBuiltForVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalManifestTableAnnotationComposer
    extends Composer<_$SyncDatabase, $LocalManifestTable> {
  $$LocalManifestTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get graphBuiltForVersion => $composableBuilder(
    column: $table.graphBuiltForVersion,
    builder: (column) => column,
  );
}

class $$LocalManifestTableTableManager
    extends
        RootTableManager<
          _$SyncDatabase,
          $LocalManifestTable,
          LocalManifestData,
          $$LocalManifestTableFilterComposer,
          $$LocalManifestTableOrderingComposer,
          $$LocalManifestTableAnnotationComposer,
          $$LocalManifestTableCreateCompanionBuilder,
          $$LocalManifestTableUpdateCompanionBuilder,
          (
            LocalManifestData,
            BaseReferences<
              _$SyncDatabase,
              $LocalManifestTable,
              LocalManifestData
            >,
          ),
          LocalManifestData,
          PrefetchHooks Function()
        > {
  $$LocalManifestTableTableManager(_$SyncDatabase db, $LocalManifestTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalManifestTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalManifestTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalManifestTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> datasetVersion = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> graphBuiltForVersion = const Value.absent(),
              }) => LocalManifestCompanion(
                id: id,
                datasetVersion: datasetVersion,
                schemaVersion: schemaVersion,
                updatedAt: updatedAt,
                graphBuiltForVersion: graphBuiltForVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> datasetVersion = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> graphBuiltForVersion = const Value.absent(),
              }) => LocalManifestCompanion.insert(
                id: id,
                datasetVersion: datasetVersion,
                schemaVersion: schemaVersion,
                updatedAt: updatedAt,
                graphBuiltForVersion: graphBuiltForVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalManifestTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncDatabase,
      $LocalManifestTable,
      LocalManifestData,
      $$LocalManifestTableFilterComposer,
      $$LocalManifestTableOrderingComposer,
      $$LocalManifestTableAnnotationComposer,
      $$LocalManifestTableCreateCompanionBuilder,
      $$LocalManifestTableUpdateCompanionBuilder,
      (
        LocalManifestData,
        BaseReferences<_$SyncDatabase, $LocalManifestTable, LocalManifestData>,
      ),
      LocalManifestData,
      PrefetchHooks Function()
    >;
typedef $$LocalCollectionsTableCreateCompanionBuilder =
    LocalCollectionsCompanion Function({
      required String collectionName,
      Value<int> docCount,
      Value<String> contentHash,
      Value<String> syncedAt,
      Value<int> rowid,
    });
typedef $$LocalCollectionsTableUpdateCompanionBuilder =
    LocalCollectionsCompanion Function({
      Value<String> collectionName,
      Value<int> docCount,
      Value<String> contentHash,
      Value<String> syncedAt,
      Value<int> rowid,
    });

class $$LocalCollectionsTableFilterComposer
    extends Composer<_$SyncDatabase, $LocalCollectionsTable> {
  $$LocalCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collectionName => $composableBuilder(
    column: $table.collectionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get docCount => $composableBuilder(
    column: $table.docCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCollectionsTableOrderingComposer
    extends Composer<_$SyncDatabase, $LocalCollectionsTable> {
  $$LocalCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collectionName => $composableBuilder(
    column: $table.collectionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get docCount => $composableBuilder(
    column: $table.docCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCollectionsTableAnnotationComposer
    extends Composer<_$SyncDatabase, $LocalCollectionsTable> {
  $$LocalCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collectionName => $composableBuilder(
    column: $table.collectionName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get docCount =>
      $composableBuilder(column: $table.docCount, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalCollectionsTableTableManager
    extends
        RootTableManager<
          _$SyncDatabase,
          $LocalCollectionsTable,
          LocalCollection,
          $$LocalCollectionsTableFilterComposer,
          $$LocalCollectionsTableOrderingComposer,
          $$LocalCollectionsTableAnnotationComposer,
          $$LocalCollectionsTableCreateCompanionBuilder,
          $$LocalCollectionsTableUpdateCompanionBuilder,
          (
            LocalCollection,
            BaseReferences<
              _$SyncDatabase,
              $LocalCollectionsTable,
              LocalCollection
            >,
          ),
          LocalCollection,
          PrefetchHooks Function()
        > {
  $$LocalCollectionsTableTableManager(
    _$SyncDatabase db,
    $LocalCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collectionName = const Value.absent(),
                Value<int> docCount = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCollectionsCompanion(
                collectionName: collectionName,
                docCount: docCount,
                contentHash: contentHash,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionName,
                Value<int> docCount = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCollectionsCompanion.insert(
                collectionName: collectionName,
                docCount: docCount,
                contentHash: contentHash,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncDatabase,
      $LocalCollectionsTable,
      LocalCollection,
      $$LocalCollectionsTableFilterComposer,
      $$LocalCollectionsTableOrderingComposer,
      $$LocalCollectionsTableAnnotationComposer,
      $$LocalCollectionsTableCreateCompanionBuilder,
      $$LocalCollectionsTableUpdateCompanionBuilder,
      (
        LocalCollection,
        BaseReferences<_$SyncDatabase, $LocalCollectionsTable, LocalCollection>,
      ),
      LocalCollection,
      PrefetchHooks Function()
    >;

class $SyncDatabaseManager {
  final _$SyncDatabase _db;
  $SyncDatabaseManager(this._db);
  $$LocalManifestTableTableManager get localManifest =>
      $$LocalManifestTableTableManager(_db, _db.localManifest);
  $$LocalCollectionsTableTableManager get localCollections =>
      $$LocalCollectionsTableTableManager(_db, _db.localCollections);
}
