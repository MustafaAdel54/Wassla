import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';

void main() {
  group('Deterministic Hashing End-to-End', () {
    test('Publisher canonical serialization equals Verifier canonical serialization (Simulated Firestore ordering)', () {
      // 1. Local transport data (JSON parsing preserves original key order: id, name, location, metadata)
      final localTransportDoc = MapEntry('stop_123', <String, dynamic>{
        'id': 'stop_123',
        'name': 'Central Station',
        'location': {
          'lat': 30.0444,
          'lng': 31.2357,
        },
        'metadata': {
          'zone': 1,
          'active': true,
        },
      });

      // 2. Publisher canonical serialization -> Publisher SHA-256
      final publisherBytes = LocalDataSource.serializeDocuments([localTransportDoc]);
      final publisherHash = LocalDataSource.computeHash(publisherBytes);

      // 3. Simulated Firestore document ordering (Firestore native SDKs do NOT preserve map key order)
      //    This simulates the Map<String, dynamic> returned by doc.data() during Sync Verifier download.
      final firestoreDoc = MapEntry('stop_123', <String, dynamic>{
        'name': 'Central Station',
        'metadata': {
          'active': true,
          'zone': 1,
        },
        'id': 'stop_123',
        'location': {
          'lng': 31.2357,
          'lat': 30.0444,
        },
      });

      // 4. Verifier canonical serialization -> Verifier SHA-256
      final verifierBytes = LocalDataSource.serializeDocuments([firestoreDoc]);
      final verifierHash = LocalDataSource.computeHash(verifierBytes);

      // 5. Expected: publisherHash == verifierHash
      expect(
        String.fromCharCodes(publisherBytes), 
        equals(String.fromCharCodes(verifierBytes)),
        reason: 'Canonical JSON strings must be identical',
      );
      expect(
        publisherHash, 
        equals(verifierHash),
        reason: 'SHA-256 hashes must be identical regardless of Map key order',
      );
    });

    test('Multiple documents are deterministically sorted by ID', () {
      final docA = MapEntry('stop_A', <String, dynamic>{'val': 1});
      final docB = MapEntry('stop_B', <String, dynamic>{'val': 2});

      final bytes1 = LocalDataSource.serializeDocuments([docA, docB]);
      final bytes2 = LocalDataSource.serializeDocuments([docB, docA]); // Shuffled list order

      expect(LocalDataSource.computeHash(bytes1), equals(LocalDataSource.computeHash(bytes2)));
    });
  });
}
