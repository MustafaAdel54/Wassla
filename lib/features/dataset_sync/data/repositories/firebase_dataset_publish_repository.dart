import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'package:wassla/core/constants/sync_constants.dart';
import 'package:wassla/core/sync/firebase_remote_data_source.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/dataset_sync/domain/repositories/dataset_publish_repository.dart';

/// Publishes the bundled transport dataset to Firebase.
/// Development/admin action only — behind kEnableDevImport flag.
///
/// Flow:
/// 1. Read bundled JSON files from assets
/// 2. Upload Firestore collections (agencies, stations, stops, routes)
/// 3. Upload Cloud Storage bundles (route_patterns, transfers)
/// 4. Compute per-collection SHA-256 hashes
/// 5. Generate and publish dataset_manifest/current
class FirebaseDatasetPublishRepository implements DatasetPublishRepository {
  final FirebaseRemoteDataSource _remoteDataSource;

  /// Optional progress callback.
  final void Function(String message)? onProgress;

  FirebaseDatasetPublishRepository(
    this._remoteDataSource, {
    this.onProgress,
  });

  @override
  Future<void> publishToFirebase() async {
    assert(kEnableDevImport, 'Dev import is disabled');

    final manifestCollections = <String, Map<String, dynamic>>{};
    const datasetVersion = 1;

    // Process each collection
    for (final collectionName in kDatasetCollections) {
      onProgress?.call('Processing $collectionName...');

      // Load all JSON files for this collection from assets
      final docs = await _loadCollectionFromAssets(collectionName);
      onProgress?.call(
          '  Loaded ${docs.length} documents from assets');

      // Serialize to canonical JSON for hash computation
      final bytes = LocalDataSource.serializeDocuments(docs);
      final hash = 'sha256:${sha256.convert(bytes).toString()}';

      if (kFirestoreCollections.contains(collectionName)) {
        // Upload to Firestore
        onProgress?.call('  Uploading to Firestore...');
        await _remoteDataSource.uploadFirestoreCollection(
            collectionName, docs);
      }

      if (kCloudStorageCollections.contains(collectionName)) {
        // Upload to Cloud Storage
        final storagePath =
            '$kStorageDatasetPrefix/v$datasetVersion/$collectionName.json';
        onProgress?.call('  Uploading to Cloud Storage: $storagePath');
        await _remoteDataSource.uploadStorageFile(storagePath, bytes);

        manifestCollections[collectionName] = {
          'count': docs.length,
          'contentHash': hash,
          'storage': 'cloud_storage',
          'storagePath': storagePath,
          'sizeBytes': bytes.length,
        };
      } else {
        manifestCollections[collectionName] = {
          'count': docs.length,
          'contentHash': hash,
          'storage': 'firestore',
        };
      }

      onProgress?.call(
          '  Done: ${docs.length} docs, hash: ${hash.substring(0, 20)}...');
    }

    // Publish manifest
    onProgress?.call('Publishing manifest...');
    final manifestData = {
      'datasetVersion': datasetVersion,
      'schemaVersion': kSchemaVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'generatedAt': FieldValue.serverTimestamp(),
      'collections': manifestCollections,
    };

    await _remoteDataSource.publishManifest(manifestData);
    onProgress?.call('Dataset published successfully! '
        'Version: $datasetVersion');
  }

  /// Load all documents for a collection from bundled assets.
  /// Reads the asset manifest to find all JSON files in the collection folder.
  Future<List<MapEntry<String, Map<String, dynamic>>>>
      _loadCollectionFromAssets(String collectionName) async {
    final docs = <MapEntry<String, Map<String, dynamic>>>[];

    // Load the asset manifest to discover files
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    // Find all JSON files for this collection
    final prefix = 'assets/transport_data/$collectionName/';
    final assetPaths = manifest.keys
        .where((key) => key.startsWith(prefix) && key.endsWith('.json'))
        .toList();

    for (final assetPath in assetPaths) {
      final content = await rootBundle.loadString(assetPath);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final id = json['id'] as String;
      final data = json['data'] as Map<String, dynamic>;
      docs.add(MapEntry(id, data));
    }

    return docs;
  }
}
