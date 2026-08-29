
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/core/storage/sync_database.dart';
import 'package:wassla/core/sync/firebase_remote_data_source.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/dataset_sync/data/repositories/dataset_sync_repository_impl.dart';
import 'package:wassla/features/dataset_sync/domain/entities/sync_entities.dart';
import 'package:wassla/features/dataset_sync/data/repositories/firebase_dataset_publish_repository.dart';

class FakeFirebaseRemoteDataSource implements FirebaseRemoteDataSource {
  DatasetManifest? mockManifest;
  final Map<String, List<MapEntry<String, Map<String, dynamic>>>> mockFirestore = {};
  bool failNetwork = false;
  bool breakStream = false;

  @override
  Future<DatasetManifest?> fetchManifest() async {
    if (failNetwork) throw Exception('Simulated network failure');
    return mockManifest;
  }

  @override
  Future<List<MapEntry<String, Map<String, dynamic>>>> fetchFirestoreCollection(
    String name,
  ) async {
    if (failNetwork) throw Exception('Simulated network failure');
    if (breakStream) throw Exception('Interrupted stream during download');
    return mockFirestore[name] ?? [];
  }

  @override
  Future<void> publishManifest(Map<String, dynamic> manifestData) async {
    final collections = <String, CollectionMetadata>{};
    for (final entry
        in (manifestData['collections'] as Map<String, dynamic>).entries) {
      final c = entry.value as Map<String, dynamic>;
      collections[entry.key] = CollectionMetadata(
        count: c['count'],
        contentHash: c['contentHash'],
      );
    }
    mockManifest = DatasetManifest(
      datasetVersion: manifestData['datasetVersion'],
      schemaVersion: manifestData['schemaVersion'],
      updatedAt: DateTime.now(),
      generatedAt: manifestData['generatedAt'] != null
          ? DateTime.parse(manifestData['generatedAt'])
          : null,
      collections: collections,
    );
  }

  @override
  Future<void> uploadFirestoreCollection(
    String collectionName,
    List<MapEntry<String, Map<String, dynamic>>> docs,
  ) async {
    mockFirestore[collectionName] = docs;
  }
}

void main() {
  group('Synchronization Logic Tests (Mocked)', () {
    late SyncDatabase db;
    late LocalDataSource local;
    late FakeFirebaseRemoteDataSource remote;
    late DatasetSyncRepositoryImpl repo;
    late Directory tempDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('wassla_test_');
      db = SyncDatabase.forTesting(NativeDatabase.memory());
      local = LocalDataSource(db, basePath: tempDir.path);
      remote = FakeFirebaseRemoteDataSource();
      repo = DatasetSyncRepositoryImpl(remote, local);

      // Setup initial remote dataset
      final stopsData = [MapEntry('s1', <String, dynamic>{})];
      final stopsBytes = LocalDataSource.serializeDocuments(stopsData);
      final stopsHash = 'sha256:${sha256.convert(stopsBytes).toString()}';

      final routesData = [MapEntry('r1', <String, dynamic>{})];
      final routesBytes = LocalDataSource.serializeDocuments(routesData);
      final routesHash = 'sha256:${sha256.convert(routesBytes).toString()}';

      final emptyData = <MapEntry<String, Map<String, dynamic>>>[];
      final emptyBytes = LocalDataSource.serializeDocuments(emptyData);
      final emptyHash = 'sha256:${sha256.convert(emptyBytes).toString()}';

      remote.mockFirestore['stops'] = stopsData;
      remote.mockFirestore['routes'] = routesData;
      remote.mockFirestore['stations'] = emptyData;
      remote.mockFirestore['route_patterns'] = emptyData;
      remote.mockFirestore['transfers'] = emptyData;
      remote.mockFirestore['agencies'] = emptyData;

      remote.mockManifest = DatasetManifest(
        datasetVersion: 1,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: {
          'stops': CollectionMetadata(
            count: 1,
            contentHash: stopsHash,
          ),
          'routes': CollectionMetadata(
            count: 1,
            contentHash: routesHash,
          ),
          'stations': CollectionMetadata(
            count: 0,
            contentHash: emptyHash,
          ),
          'route_patterns': CollectionMetadata(
            count: 0,
            contentHash: emptyHash,
          ),
          'transfers': CollectionMetadata(
            count: 0,
            contentHash: emptyHash,
          ),
          'agencies': CollectionMetadata(
            count: 0,
            contentHash: emptyHash,
          ),
        },
      );
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. First install / initial bootstrap', () async {
      final hasLocalBefore = await repo.hasLocalDataset();
      expect(hasLocalBefore, isFalse);

      final result = await repo.sync();
      if (result.status == SyncStatusType.failed) {
        developer.log('Test 1 Failed with: ${result.errorMessage}');
      }
      expect(result.status, SyncStatusType.initialDownload);
      expect(result.collectionsDownloaded, 6);

      final hasLocalAfter = await repo.hasLocalDataset();
      expect(hasLocalAfter, isTrue);

      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 1);
    });

    test('2. No-change sync', () async {
      await repo.sync(); // Initial
      final result = await repo.sync(); // Second sync
      expect(result.status, SyncStatusType.noChanges);
      expect(result.collectionsDownloaded, 0);
    });

    test('3. Exactly one collection changed', () async {
      await repo.sync(); // Initial

      // Change remote stops
      final newStopsData = [MapEntry('s1', <String, dynamic>{'new': true})];
      final newStopsBytes = LocalDataSource.serializeDocuments(newStopsData);
      final newStopsHash = 'sha256:${sha256.convert(newStopsBytes).toString()}';
      remote.mockFirestore['stops'] = newStopsData;

      remote.mockManifest = DatasetManifest(
        datasetVersion: 2,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: {
          'stops': CollectionMetadata(
            count: 1,
            contentHash: newStopsHash,
          ),
          'routes': remote.mockManifest!.collections['routes']!,
          'stations': remote.mockManifest!.collections['stations']!,
          'route_patterns': remote.mockManifest!.collections['route_patterns']!,
          'transfers': remote.mockManifest!.collections['transfers']!,
          'agencies': remote.mockManifest!.collections['agencies']!,
        },
      );

      final result = await repo.sync();
      expect(result.status, SyncStatusType.updated);
      expect(result.collectionsDownloaded, 1); // Only downloaded stops

      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 2);
    });

    test('4. Multiple collections changed', () async {
      await repo.sync(); // Initial

      // Change both remote stops and routes
      final newStopsData = [MapEntry('s1', <String, dynamic>{'new': true})];
      final newStopsBytes = LocalDataSource.serializeDocuments(newStopsData);
      final newStopsHash = 'sha256:${sha256.convert(newStopsBytes).toString()}';
      remote.mockFirestore['stops'] = newStopsData;

      final newRoutesData = [MapEntry('r1', <String, dynamic>{'new': true})];
      final newRoutesBytes = LocalDataSource.serializeDocuments(newRoutesData);
      final newRoutesHash =
          'sha256:${sha256.convert(newRoutesBytes).toString()}';
      remote.mockFirestore['routes'] = newRoutesData;

      remote.mockManifest = DatasetManifest(
        datasetVersion: 2,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: {
          'stops': CollectionMetadata(
            count: 1,
            contentHash: newStopsHash,
          ),
          'routes': CollectionMetadata(
            count: 1,
            contentHash: newRoutesHash,
          ),
          'stations': remote.mockManifest!.collections['stations']!,
          'route_patterns': remote.mockManifest!.collections['route_patterns']!,
          'transfers': remote.mockManifest!.collections['transfers']!,
          'agencies': remote.mockManifest!.collections['agencies']!,
        },
      );

      final result = await repo.sync();
      expect(result.status, SyncStatusType.updated);
      expect(result.collectionsDownloaded, 2);

      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 2);
    });

    test('5. Network/remote failure', () async {
      await repo.sync(); // Initial
      remote.failNetwork = true;

      final result = await repo.sync();
      expect(result.status, SyncStatusType.failed);
      expect(result.errorMessage, contains('Simulated network failure'));

      final hasLocal = await repo.hasLocalDataset();
      expect(hasLocal, isTrue, reason: 'Dataset remains usable');

      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 1);
    });

    test('6. Hash mismatch / Corrupted file', () async {
      await repo.sync(); // Initial

      // Change remote stops but keep old hash in manifest (Simulates corruption/mismatch)
      final newStopsData = [MapEntry('s1', <String, dynamic>{'corrupted': true})];
      remote.mockFirestore['stops'] = newStopsData;

      remote.mockManifest = DatasetManifest(
        datasetVersion: 2,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: {
          'stops': CollectionMetadata(
            count: 1,
            contentHash: 'expected-hash',
          ),
          'routes': remote.mockManifest!.collections['routes']!,
          'stations': remote.mockManifest!.collections['stations']!,
          'route_patterns': remote.mockManifest!.collections['route_patterns']!,
          'transfers': remote.mockManifest!.collections['transfers']!,
          'agencies': remote.mockManifest!.collections['agencies']!,
        },
      );

      final result = await repo.sync();
      expect(result.status, SyncStatusType.failed);
      expect(result.errorMessage, contains('Hash mismatch'));

      final hasLocal = await repo.hasLocalDataset();
      expect(hasLocal, isTrue, reason: 'Previous dataset intact');
      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 1, reason: 'Local version unchanged');
    });

    test('7. Interrupted synchronization', () async {
      await repo.sync(); // Initial

      final newStopsData = [MapEntry('s1', <String, dynamic>{'new': true})];
      final newStopsBytes = LocalDataSource.serializeDocuments(newStopsData);
      final newStopsHash = 'sha256:${sha256.convert(newStopsBytes).toString()}';
      remote.mockFirestore['stops'] = newStopsData;

      remote.mockManifest = DatasetManifest(
        datasetVersion: 2,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: {
          'stops': CollectionMetadata(
            count: 1,
            contentHash: newStopsHash,
          ),
          'routes': remote.mockManifest!.collections['routes']!,
          'stations': remote.mockManifest!.collections['stations']!,
          'route_patterns': remote.mockManifest!.collections['route_patterns']!,
          'transfers': remote.mockManifest!.collections['transfers']!,
          'agencies': remote.mockManifest!.collections['agencies']!,
        },
      );

      remote.breakStream = true;

      final result = await repo.sync();
      expect(result.status, SyncStatusType.failed);
      expect(result.errorMessage, contains('Interrupted stream'));

      final hasLocal = await repo.hasLocalDataset();
      expect(hasLocal, isTrue);

      final manifest = await local.getManifest();
      expect(manifest.datasetVersion, 1, reason: 'Rolled back / untouched');
    });

    test('8. Preservation of staging folder state', () async {
      await repo.sync(); // Initial
      remote.breakStream = true;
      remote.mockManifest = DatasetManifest(
        datasetVersion: 2,
        schemaVersion: 1,
        updatedAt: DateTime.now(),
        collections: remote.mockManifest!.collections,
      );
      await repo.sync(); // Failed

      final stagingDir = Directory('${tempDir.path}/staging');
      expect(
        stagingDir.existsSync(),
        isFalse,
        reason: 'Staging directory is cleaned up on failure',
      );

      final activeDir = Directory('${tempDir.path}/active');
      expect(
        activeDir.existsSync(),
        isTrue,
        reason: 'Active directory remains intact',
      );
    });
  });

  group('Developer Import Local Verification', () {
    late FakeFirebaseRemoteDataSource remote;
    late FirebaseDatasetPublishRepository publishRepo;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      remote = FakeFirebaseRemoteDataSource();
      publishRepo = FirebaseDatasetPublishRepository(remote);
    });

    test(
      'Validates parsing and publishing using assets/transport_data',
      () async {
        // Mock testing the dev import. We don't want to actually upload anything to real firebase.
        await publishRepo.publishToFirebase();

        expect(remote.mockManifest, isNotNull);
        expect(remote.mockManifest!.datasetVersion, greaterThan(0));
        expect(
          remote.mockManifest!.collections.keys,
          containsAll([
            'stops',
            'stations',
            'routes',
            'route_patterns',
            'transfers',
          ]),
        );
        expect(
          remote.mockFirestore.keys.any((k) => k.contains('route_patterns')),
          isTrue,
        );
      },
      skip: 'Cannot load asset manifest in pure unit test environment',
    );
  });
}
