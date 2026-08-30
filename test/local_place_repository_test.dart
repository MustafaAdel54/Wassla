import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/features/places/data/repositories/local_place_repository.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/core/storage/sync_database.dart';

class FakeLocalDataSource extends LocalDataSource {
  String stationsJson = '[]';
  String stopsJson = '[]';

  FakeLocalDataSource() : super(SyncDatabase());

  @override
  Future<String> readCollectionFile(String name) async {
    if (name == 'stations') return stationsJson;
    if (name == 'stops') return stopsJson;
    return '[]';
  }
}

void main() {
  group('LocalPlaceRepository Deduplication', () {
    late LocalPlaceRepository repository;
    late FakeLocalDataSource fakeDataSource;

    setUp(() {
      fakeDataSource = FakeLocalDataSource();
      repository = LocalPlaceRepository(fakeDataSource);
    });

    test('Deduplicates multiple identical names and prioritizes parent station', () async {
      // Create fake JSON data simulating the duplicates
      final stationsJson = '''
      [
        {
          "id": "station_metro_10_HLW_METRO",
          "data": {
            "name": "Helwan",
            "lat": 29.8,
            "lng": 31.3,
            "transportModes": ["metro"]
          }
        }
      ]
      ''';

      // Simulating child stops and independent surface stops
      final stopsJson = '''
      [
        {
          "id": "metro_10_HLW_METRO_N",
          "data": {
            "name": "Helwan",
            "lat": 29.8,
            "lng": 31.3,
            "stationId": "station_metro_10_HLW_METRO"
          }
        },
        {
          "id": "surface_1774",
          "data": {
            "name": "Helwan Metro",
            "lat": 29.8,
            "lng": 31.3,
            "transportModes": ["bus"]
          }
        },
        {
          "id": "surface_1775",
          "data": {
            "name": "Helwan Metro",
            "lat": 29.8,
            "lng": 31.3,
            "transportModes": ["bus"]
          }
        }
      ]
      ''';

      fakeDataSource.stationsJson = stationsJson;
      fakeDataSource.stopsJson = stopsJson;

      // Search for 'helwan'
      final results = await repository.searchPlaces('helwan');

      // The results should contain:
      // 1. "Helwan" (from station, should be deduplicated)
      // 2. "Helwan Metro" (from surface stop, deduplicated from 2 duplicates)
      expect(results.length, 2);

      // Verify canonical selection for "Helwan"
      final helwan = results.firstWhere((p) => p.name == 'Helwan');
      // It should be the station, because stationId == id for stations parsed from stations collection
      expect(helwan.id, 'station_metro_10_HLW_METRO');
      expect(helwan.stationId, 'station_metro_10_HLW_METRO');

      // Verify canonical selection for "Helwan Metro"
      final helwanMetro = results.firstWhere((p) => p.name == 'Helwan Metro');
      // It should fallback to alphabetical ID ordering because they are both surface stops with null stationId
      // surface_1774 < surface_1775
      expect(helwanMetro.id, 'surface_1774');
      expect(helwanMetro.stationId, isNull);
    });

    test('Limits results to 20 AFTER deduplication', () async {
      // Simulate 40 unique names and 40 duplicate names
      final stationsList = List.generate(40, (i) => {
        "id": "station_$i",
        "data": {
          "name": "UniqueStation $i",
          "lat": 0.0,
          "lng": 0.0
        }
      });
      // Add duplicates
      for (int i = 0; i < 40; i++) {
        stationsList.add({
          "id": "station_dup_$i",
          "data": {
            "name": "UniqueStation $i",
            "lat": 0.0,
            "lng": 0.0
          }
        });
      }

      final stationsJson = jsonEncode(stationsList);

      fakeDataSource.stationsJson = stationsJson;
      fakeDataSource.stopsJson = '[]';

      final results = await repository.searchPlaces('UniqueStation');
      
      // If limit was applied before deduplication, we might get fewer than 20 unique results 
      // if duplicates consumed the limit. Since we deduplicate first, we should get exactly 20.
      expect(results.length, 20);
      
      // All 20 should be unique
      final names = results.map((p) => p.name).toSet();
      expect(names.length, 20);
    });
  });
}
