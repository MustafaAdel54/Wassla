import 'dart:convert';
import 'dart:developer' as developer;

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

  FirebaseDatasetPublishRepository(this._remoteDataSource, {this.onProgress});

  @override
  Future<void> publishToFirebase() async {
    assert(kEnableDevImport, 'Dev import is disabled');

    final manifestCollections = <String, Map<String, dynamic>>{};
    int totalFiles = 0;

    // Fetch current manifest to determine next version
    onProgress?.call('Fetching current manifest to determine version...');
    final currentManifest = await _remoteDataSource.fetchManifest();
    final datasetVersion = (currentManifest?.datasetVersion ?? 0) + 1;
    onProgress?.call('Publishing as dataset version: $datasetVersion');

    // Process each collection
    for (final collectionName in kDatasetCollections) {
      onProgress?.call('Processing $collectionName...');

      // Load all JSON files for this collection from assets
      final docs = await _loadCollectionFromAssets(collectionName);
      developer.log('$collectionName: ${docs.length}', name: 'DatasetPublish');
      totalFiles += docs.length;
      onProgress?.call('  Loaded ${docs.length} documents from assets');

      // Serialize to canonical JSON for hash computation
      final bytes = LocalDataSource.serializeDocuments(docs);
      final hash = 'sha256:${sha256.convert(bytes).toString()}';

      // Upload to Firestore
      onProgress?.call('  Uploading to Firestore...');
      await _remoteDataSource.uploadFirestoreCollection(collectionName, docs);

      manifestCollections[collectionName] = {
        'count': docs.length,
        'contentHash': hash,
      };

      onProgress?.call(
        '  Done: ${docs.length} docs, hash: ${hash.substring(0, 20)}...',
      );
    }
    developer.log('Total transport asset count: $totalFiles', name: 'DatasetPublish');

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
    onProgress?.call(
      'Dataset published successfully! '
      'Version: $datasetVersion',
    );
  }

  /// Load all documents for a collection from bundled assets.
  /// Reads the asset manifest to find all JSON files in the collection folder.
  Future<List<MapEntry<String, Map<String, dynamic>>>>
  _loadCollectionFromAssets(String collectionName) async {
    final docs = <MapEntry<String, Map<String, dynamic>>>[];

    // Load the asset manifest to discover files using the modern API
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    // Find all JSON files for this collection
    final prefix = 'assets/transport_data/$collectionName/';
    final assetPaths = manifest.listAssets()
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
