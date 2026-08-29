import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/core/routing/dataset_loader.dart';
import 'package:wassla/core/routing/transit_router.dart';

void main() {
  group('V4 Engine Parity Tests', () {
    late TransitRouter router;

    Future<String> loadCollectionArray(String collectionName) async {
      final dir = Directory('assets/transport_data/$collectionName');
      if (!dir.existsSync()) return '[]';
      final files = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      );
      final allDocs = [];
      for (final file in files) {
        final content = file.readAsStringSync();
        allDocs.add(jsonDecode(content));
      }
      return jsonEncode(allDocs);
    }

    setUpAll(() async {
      final stopsJson = await loadCollectionArray('stops');
      final stationsJson = await loadCollectionArray('stations');
      final routesJson = await loadCollectionArray('routes');
      final routePatternsJson = await loadCollectionArray('route_patterns');
      final transfersJson = await loadCollectionArray('transfers');

      final ds = loadDatasetFromJsonArrays(
        stopsJson: stopsJson,
        stationsJson: stationsJson,
        routesJson: routesJson,
        routePatternsJson: routePatternsJson,
        transfersJson: transfersJson,
      );
      router = TransitRouter(ds);
    });

    test('station_metro_10_AHL_METRO -> station_metro_23_MAD_METRO', () {
      final result = router.routeBetweenStopIds(
        'station_metro_10_AHL_METRO',
        'station_metro_23_MAD_METRO',
      );
      expect(result, isNotNull);

      expect(result!.durationMinutes, 18);
      expect(result.transfers, 0);
      expect(result.walkingMinutes, 0);
      expect(result.legs.length, 1);
      expect(result.legs[0].routeId, 'metro_L1');
      expect(result.legs[0].fromStop, 'metro_10_AHL_METRO_N');
      expect(result.legs[0].toStop, 'metro_23_MAD_METRO_N');
    });

    test('surface_793 -> surface_807', () {
      final result = router.routeBetweenStopIds('surface_793', 'surface_807');
      expect(result, isNotNull);

      expect(result!.durationMinutes, 96);
      expect(result.transfers, 2);
      expect(result.legs.length, 3);

      expect(result.legs[0].routeId, 'surface_Ci3EuISJ24C8rXJIGK05p');
      expect(result.legs[0].fromStop, 'surface_793');
      expect(result.legs[0].toStop, 'surface_2818');

      expect(result.legs[1].routeId, 'surface_P_O_14_CA010');
      expect(result.legs[1].fromStop, 'surface_2818');
      expect(result.legs[1].toStop, 'surface_505');

      expect(result.legs[2].routeId, 'surface_P_O_14_CA076');
      expect(result.legs[2].fromStop, 'surface_505');
      expect(result.legs[2].toStop, 'surface_807');
    });

    test('surface_793 -> surface_556', () {
      final result = router.routeBetweenStopIds('surface_793', 'surface_556');
      expect(result, isNotNull);

      expect(result!.durationMinutes, 110);
      expect(result.transfers, 3);
      expect(result.legs.length, 4);

      expect(result.legs[0].routeId, 'surface_P_O_14_CA159');
      expect(result.legs[1].routeId, 'surface_CTA_1005');
      expect(result.legs[2].routeId, 'surface_qQ8CZf6wkbvSMMGKizEwd');
      expect(result.legs[3].routeId, 'surface_2EAwBcn3IACPZ0xefVHUM');
    });
  });
}
