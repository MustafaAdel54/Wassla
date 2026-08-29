import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/dataset_sync/domain/entities/sync_entities.dart';

/// Data source for accessing the remote Firebase dataset.
/// Handles Firestore collections.
class FirebaseRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseRemoteDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch the remote dataset manifest.
  /// 1 Firestore read.
  Future<DatasetManifest?> fetchManifest() async {
    final doc = await _firestore
        .collection('dataset_manifest')
        .doc('current')
        .get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    final collectionsMap = data['collections'] as Map<String, dynamic>? ?? {};

    final collections = <String, CollectionMetadata>{};
    for (final entry in collectionsMap.entries) {
      final c = entry.value as Map<String, dynamic>;
      collections[entry.key] = CollectionMetadata(
        count: (c['count'] as num).toInt(),
        contentHash: c['contentHash'] as String,
      );
    }

    return DatasetManifest(
      datasetVersion: (data['datasetVersion'] as num).toInt(),
      schemaVersion: (data['schemaVersion'] as num).toInt(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      generatedAt: data['generatedAt'] != null
          ? (data['generatedAt'] as Timestamp).toDate()
          : null,
      collections: collections,
    );
  }

  /// Read all documents from a Firestore collection.
  /// Returns a list of (docId, docData) pairs in Firestore-document format.
  Future<List<MapEntry<String, Map<String, dynamic>>>> fetchFirestoreCollection(
    String name,
  ) async {
    final snapshot = await _firestore.collection(name).get();
    return snapshot.docs.map((doc) {
      return MapEntry(doc.id, doc.data());
    }).toList();
  }


  /// Upload a Firestore collection from a list of documents.
  /// Used by the developer import action.
  Future<void> uploadFirestoreCollection(
    String collectionName,
    List<MapEntry<String, Map<String, dynamic>>> docs,
  ) async {
    // Use batched writes (max 400 per batch)
    for (var i = 0; i < docs.length; i += 400) {
      final batch = _firestore.batch();
      final chunk = docs.sublist(i, (i + 400).clamp(0, docs.length));
      for (final doc in chunk) {
        batch.set(
          _firestore.collection(collectionName).doc(doc.key),
          doc.value,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }


  /// Publish the dataset manifest document.
  Future<void> publishManifest(Map<String, dynamic> manifestData) async {
    await _firestore
        .collection('dataset_manifest')
        .doc('current')
        .set(manifestData);
  }
}
