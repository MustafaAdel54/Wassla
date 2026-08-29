import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:wassla/core/constants/sync_constants.dart';
import 'package:wassla/core/storage/sync_database.dart';
import 'package:wassla/features/dataset_sync/domain/entities/sync_entities.dart';

/// Data source for local dataset persistence.
/// Manages the active/ and staging/ directories and the drift database.
class LocalDataSource {
  final SyncDatabase _db;
  String? _basePath;

  // ignore: prefer_initializing_formals
  LocalDataSource(this._db, {String? basePath}) : _basePath = basePath;

  /// Get the base path for dataset storage.
  Future<String> get basePath async {
    if (_basePath != null) return _basePath!;
    final docs = await getApplicationDocumentsDirectory();
    _basePath = p.join(docs.path, kLocalDatasetDir);
    return _basePath!;
  }

  /// Get the path to the active dataset directory.
  Future<String> get activePath async => p.join(await basePath, kActiveDir);

  /// Get the path to the staging directory.
  Future<String> get stagingPath async => p.join(await basePath, kStagingDir);

  /// Whether a local dataset exists and has at least the core collections.
  Future<bool> hasLocalDataset() async {
    final active = Directory(await activePath);
    if (!active.existsSync()) return false;

    // Check that all 6 required collections exist
    for (final name in kDatasetCollections) {
      final file = File(p.join(active.path, '$name.json'));
      if (!file.existsSync()) return false;
    }
    return true;
  }

  /// Get the local manifest metadata.
  Future<LocalManifestData> getManifest() => _db.getManifest();

  /// Get the content hashes for all locally cached collections.
  Future<Map<String, String>> getLocalCollectionHashes() async {
    final metadata = await _db.getCollectionMetadata();
    return {
      for (final entry in metadata.entries) entry.key: entry.value.contentHash,
    };
  }

  /// Stage a collection file for atomic commit.
  Future<void> stageCollection(String name, List<int> bytes) async {
    final staging = Directory(await stagingPath);
    if (!staging.existsSync()) staging.createSync(recursive: true);
    final file = File(p.join(staging.path, '$name.json'));
    await file.writeAsBytes(bytes);
  }

  /// Compute SHA-256 hash of a staged collection file.
  Future<String> hashStagedCollection(String name) async {
    final file = File(p.join(await stagingPath, '$name.json'));
    final bytes = await file.readAsBytes();
    return 'sha256:${sha256.convert(bytes).toString()}';
  }

  /// Atomically commit staged collections to active.
  /// Moves each staged file to active/ and updates the database.
  Future<void> commitStaged({
    required int newVersion,
    required Map<String, CollectionMetadata> updatedCollections,
  }) async {
    final active = Directory(await activePath);
    if (!active.existsSync()) active.createSync(recursive: true);

    final staging = Directory(await stagingPath);

    // Move each staged file to active
    for (final name in updatedCollections.keys) {
      final stagedFile = File(p.join(staging.path, '$name.json'));
      final activeFile = File(p.join(active.path, '$name.json'));

      if (stagedFile.existsSync()) {
        // File.rename is atomic on the same filesystem
        if (activeFile.existsSync()) activeFile.deleteSync();
        stagedFile.renameSync(activeFile.path);
      }
    }

    // Update database in a transaction
    await _db.transaction(() async {
      for (final entry in updatedCollections.entries) {
        await _db.upsertCollection(
          name: entry.key,
          docCount: entry.value.count,
          contentHash: entry.value.contentHash,
        );
      }
      await _db.updateManifestVersion(newVersion);
    });

    // Clean up staging
    await cleanupStaging();
  }

  /// Read the contents of a local collection file.
  Future<String> readCollectionFile(String name) async {
    final file = File(p.join(await activePath, '$name.json'));
    return file.readAsString();
  }

  /// Read all collection files and return as a map of name → JSON string.
  Future<Map<String, String>> readAllCollections() async {
    final result = <String, String>{};
    for (final name in kDatasetCollections) {
      final file = File(p.join(await activePath, '$name.json'));
      if (file.existsSync()) {
        result[name] = await file.readAsString();
      }
    }
    return result;
  }

  /// Get the dataset version that the graph was last built for.
  Future<int> getGraphBuiltForVersion() async {
    final manifest = await _db.getManifest();
    return manifest.graphBuiltForVersion;
  }

  /// Update the graph-built-for version.
  Future<void> setGraphBuiltForVersion(int version) async {
    await _db.updateGraphVersion(version);
  }

  /// Clean up the staging directory.
  Future<void> cleanupStaging() async {
    final staging = Directory(await stagingPath);
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
  }

  /// Compute SHA-256 hash of a byte array.
  static String computeHash(List<int> bytes) {
    return 'sha256:${sha256.convert(bytes).toString()}';
  }

  /// Write a collection directly to the active directory.
  /// Used during first-time bootstrap and dev import.
  Future<void> writeActiveCollection(String name, List<int> bytes) async {
    final active = Directory(await activePath);
    if (!active.existsSync()) active.createSync(recursive: true);
    final file = File(p.join(active.path, '$name.json'));
    await file.writeAsBytes(bytes);
  }

  /// Serialize a list of Firestore documents to a canonical JSON array.
  /// Each element is {"id": docId, "data": docData}.
  static List<int> serializeDocuments(
    List<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    // Sort by ID for deterministic hash
    final sorted = List<MapEntry<String, Map<String, dynamic>>>.from(docs)
      ..sort((a, b) => a.key.compareTo(b.key));
    final list = sorted.map((e) => {
      'id': e.key, 
      'data': _canonicalize(e.value),
    }).toList();
    return utf8.encode(jsonEncode(list));
  }

  /// Recursively sorts map keys to ensure deterministic JSON serialization.
  /// Converts all maps to LinkedHashMaps with sorted keys before encoding.
  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final sortedKeys = value.keys.toList()..sort();
      final result = <String, dynamic>{};
      for (final key in sortedKeys) {
        result[key.toString()] = _canonicalize(value[key]);
      }
      return result;
    } else if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}
