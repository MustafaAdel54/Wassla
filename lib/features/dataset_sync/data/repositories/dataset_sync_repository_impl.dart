import 'package:wassla/core/constants/sync_constants.dart';
import 'package:wassla/core/sync/firebase_remote_data_source.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/dataset_sync/domain/entities/sync_entities.dart';
import 'package:wassla/features/dataset_sync/domain/repositories/dataset_sync_repository.dart';

/// Implementation of the incremental dataset sync algorithm.
///
/// 1. Fetch remote manifest (1 Firestore read)
/// 2. Compare collection hashes
/// 3. Download only changed collections
/// 4. Verify SHA-256 hashes
/// 5. Atomic commit: staging → active + SQLite transaction
class DatasetSyncRepositoryImpl implements DatasetSyncRepository {
  final FirebaseRemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  DatasetSyncRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<bool> hasLocalDataset() => _localDataSource.hasLocalDataset();

  @override
  Future<SyncResult> sync() async {
    try {
      // 1. Get local manifest
      final localManifest = await _localDataSource.getManifest();
      final localVersion = localManifest.datasetVersion;

      // 2. Fetch remote manifest (1 Firestore read)
      final remoteManifest = await _remoteDataSource.fetchManifest();
      if (remoteManifest == null) {
        return const SyncResult.failed(
          'No remote manifest found. Dataset not yet published to Firebase.',
        );
      }

      // 3. Quick version check
      if (remoteManifest.datasetVersion == localVersion) {
        return const SyncResult.noChanges();
      }

      // 4. Compare per-collection content hashes
      final localHashes = await _localDataSource.getLocalCollectionHashes();
      final changedCollections = <String, CollectionMetadata>{};

      for (final entry in remoteManifest.collections.entries) {
        final name = entry.key;
        final remoteMeta = entry.value;
        final localHash = localHashes[name];

        if (localHash != remoteMeta.contentHash) {
          changedCollections[name] = remoteMeta;
        }
      }

      if (changedCollections.isEmpty) {
        // Version changed but no content changes — just update version
        await _localDataSource.commitStaged(
          newVersion: remoteManifest.datasetVersion,
          updatedCollections: {},
        );
        return const SyncResult.noChanges();
      }

      // 5. Clean up any leftover staging from previous failed sync
      await _localDataSource.cleanupStaging();

      // 6. Download each changed collection
      for (final entry in changedCollections.entries) {
        final name = entry.key;
        final meta = entry.value;

        try {
          List<int> bytes;

          // Read all docs from Firestore
          final docs = await _remoteDataSource.fetchFirestoreCollection(name);
          bytes = LocalDataSource.serializeDocuments(docs);

          // Stage the downloaded file
          await _localDataSource.stageCollection(name, bytes);

          // Verify hash
          final stagedHash = await _localDataSource.hashStagedCollection(name);
          if (stagedHash != meta.contentHash) {
            // Hash mismatch — abort
            await _localDataSource.cleanupStaging();
            return SyncResult.failed(
              'Hash mismatch for collection $name. '
              'Expected: ${meta.contentHash}, Got: $stagedHash',
            );
          }
        } catch (e) {
          // Download failed — abort, keep previous dataset
          await _localDataSource.cleanupStaging();
          return SyncResult.failed('Failed to download collection $name: $e');
        }
      }

      // 7. Atomic commit
      await _localDataSource.commitStaged(
        newVersion: remoteManifest.datasetVersion,
        updatedCollections: changedCollections,
      );

      // 8. Determine if routing data changed
      final routingChanged = changedCollections.keys.any(
        (name) => kRoutingCollections.contains(name),
      );

      return SyncResult(
        status: localVersion == 0
            ? SyncStatusType.initialDownload
            : SyncStatusType.updated,
        routingDataChanged: routingChanged,
        collectionsDownloaded: changedCollections.length,
      );
    } catch (e) {
      return SyncResult.failed('Sync failed: $e');
    }
  }
}
