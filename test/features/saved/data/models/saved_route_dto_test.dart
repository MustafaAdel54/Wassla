import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/saved/data/models/saved_route_dto.dart';
import 'package:wassla/features/saved/domain/entities/saved_route.dart';

void main() {
  group('SavedRouteDto', () {
    final tSavedRoute = SavedRoute(
      id: 'test_id',
      originName: 'Helwan',
      destName: 'Maadi',
      routeResult: RouteResult(
        durationMinutes: 10,
        walkingMinutes: 5,
        transfers: 1,
        estimatedFare: 10.0,
        segments: [
          RouteSegment(
            mode: 'bus',
            routeId: 'b1',
            routeName: 'Bus 1',
            fromName: 'Helwan',
            toName: 'Maadi',
            durationMinutes: 10,
          ),
        ],
      ),
      savedAt: DateTime.utc(2023, 1, 1),
      userId: 'user1',
    );

    final tJson = {
      'id': 'test_id',
      'originName': 'Helwan',
      'destName': 'Maadi',
      'routeResult': {
        'durationMinutes': 10,
        'walkingMinutes': 5,
        'transfers': 1,
        'estimatedFare': 10.0,
        'segments': [
          {
            'mode': 'bus',
            'routeId': 'b1',
            'routeName': 'Bus 1',
            'fromName': 'Helwan',
            'toName': 'Maadi',
            'durationMinutes': 10,
          }
        ],
      },
      'savedAt': '2023-01-01T00:00:00.000Z',
      'userId': 'user1',
    };

    test('toJson should return a valid JSON map', () {
      final result = SavedRouteDto.toJson(tSavedRoute);
      expect(result, equals(tJson));
    });

    test('fromJson should return a valid SavedRoute entity', () {
      final result = SavedRouteDto.fromJson(tJson);
      expect(result, equals(tSavedRoute));
    });
  });
}
