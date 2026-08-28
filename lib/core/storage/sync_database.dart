import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'sync_database.g.dart';

/// Local manifest — singleton row tracking the active dataset version.
class LocalManifest extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get datasetVersion => integer().withDefault(const Constant(0))();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  TextColumn get updatedAt => text().withDefault(const Constant(''))();
  IntColumn get graphBuiltForVersion =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-collection metadata — tracks hash and sync state for each collection.
class LocalCollections extends Table {
  TextColumn get collectionName => text()();
  IntColumn get docCount => integer().withDefault(const Constant(0))();
  TextColumn get contentHash => text().withDefault(const Constant(''))();
  TextColumn get storageType =>
      text().withDefault(const Constant('firestore'))();
  TextColumn get localFilePath => text().nullable()();
  TextColumn get syncedAt => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {collectionName};
}

@DriftDatabase(tables: [LocalManifest, LocalCollections])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase() : super(_openConnection());

  /// For testing — accepts any QueryExecutor.
  SyncDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  /// Get the current local manifest (or create default if missing).
  Future<LocalManifestData> getManifest() async {
    final row = await (select(localManifest)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    // Insert default row
    await into(localManifest).insert(
      LocalManifestCompanion.insert(),
      mode: InsertMode.insertOrReplace,
    );
    return (select(localManifest)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Update the dataset version after a successful sync.
  Future<void> updateManifestVersion(int version) async {
    await (update(localManifest)..where((t) => t.id.equals(1))).write(
      LocalManifestCompanion(
        datasetVersion: Value(version),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Update the graph-built-for version.
  Future<void> updateGraphVersion(int version) async {
    await (update(localManifest)..where((t) => t.id.equals(1))).write(
      LocalManifestCompanion(
        graphBuiltForVersion: Value(version),
      ),
    );
  }

  /// Get all local collection metadata as a map.
  Future<Map<String, LocalCollection>> getCollectionMetadata() async {
    final rows = await select(localCollections).get();
    return {for (final r in rows) r.collectionName: r};
  }

  /// Upsert a collection's metadata after sync.
  Future<void> upsertCollection({
    required String name,
    required int docCount,
    required String contentHash,
    required String storageType,
    String? localFilePath,
  }) async {
    await into(localCollections).insertOnConflictUpdate(
      LocalCollectionsCompanion.insert(
        collectionName: name,
        docCount: Value(docCount),
        contentHash: Value(contentHash),
        storageType: Value(storageType),
        localFilePath: Value(localFilePath),
        syncedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wassla_sync.db'));
    return NativeDatabase.createInBackground(file);
  });
}
