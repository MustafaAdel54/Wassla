import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/saved/data/datasources/local_saved_route_data_source.dart';
import 'package:wassla/features/saved/data/repositories/local_saved_route_repository_impl.dart';
import 'package:wassla/features/saved/domain/entities/saved_route.dart';

class MockLocalSavedRouteDataSource extends LocalSavedRouteDataSource {
  List<SavedRoute> memoryStorage = [];

  @override
  Future<List<SavedRoute>> readSavedRoutes() async {
    return List.from(memoryStorage);
  }

  @override
  Future<void> writeSavedRoutes(List<SavedRoute> entries) async {
    memoryStorage = List.from(entries);
  }
}

void main() {
  late MockLocalSavedRouteDataSource mockDataSource;
  late LocalSavedRouteRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockLocalSavedRouteDataSource();
    repository = LocalSavedRouteRepositoryImpl(mockDataSource);
  });

  final dummyRouteResult = RouteResult(
    durationMinutes: 10,
    walkingMinutes: 5,
    transfers: 1,
    estimatedFare: 10.0,
    segments: [],
  );

  test('generateRouteId should return deterministic hash', () {
    final id1 = repository.generateRouteId('Helwan', 'Maadi');
    final id2 = repository.generateRouteId(' helwan ', ' MAADI');
    expect(id1, equals(id2));
  });

  test('saveRoute should add new route to top', () async {
    await repository.saveRoute(
      originName: 'Helwan',
      destName: 'Maadi',
      routeResult: dummyRouteResult,
    );
    final routes = await repository.getSavedRoutes();
    expect(routes.length, 1);
    expect(routes.first.originName, 'Helwan');
  });

  test('saveRoute should replace duplicate and move to top', () async {
    await repository.saveRoute(
      originName: 'Helwan',
      destName: 'Maadi',
      routeResult: dummyRouteResult,
    );
    // Add another
    await repository.saveRoute(
      originName: 'Maadi',
      destName: 'Ramses',
      routeResult: dummyRouteResult,
    );

    // Save duplicate
    await repository.saveRoute(
      originName: 'helwan',
      destName: 'maadi',
      routeResult: dummyRouteResult,
    );

    final routes = await repository.getSavedRoutes();
    expect(routes.length, 2);
    expect(routes.first.originName, 'helwan'); // New one should be at top
    expect(routes[1].originName, 'Maadi');
  });

  test('saveRoute should enforce 20 item limit', () async {
    for (var i = 0; i < 25; i++) {
      await repository.saveRoute(
        originName: 'Origin $i',
        destName: 'Dest $i',
        routeResult: dummyRouteResult,
      );
    }
    final routes = await repository.getSavedRoutes();
    expect(routes.length, 20);
    expect(routes.first.originName, 'Origin 24'); // Most recent
    expect(routes.last.originName, 'Origin 5');
  });
}
