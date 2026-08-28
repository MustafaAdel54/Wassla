import '../../core/routing/transit_router.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/route_search/data/datasources/routing_graph_cache.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/route_search/domain/repositories/routing_service.dart';

/// Adapter: wraps the V4 Dart engine behind the RoutingService interface.
/// Presentation layer never sees the engine internals.
class DartV4RoutingService implements RoutingService {
  final RoutingGraphCache _graphCache;
  final LocalDataSource _localDataSource;

  DartV4RoutingService(this._graphCache, this._localDataSource);

  @override
  bool get isInitialized => _graphCache.isInitialized;

  @override
  Future<void> initialize() async {
    final manifest = await _localDataSource.getManifest();
    final version = manifest.datasetVersion;

    // Skip rebuild if already built for this version
    if (_graphCache.builtForVersion == version) return;

    final collections = await _localDataSource.readAllCollections();
    await _graphCache.getOrBuild(
      collectionJsons: collections,
      datasetVersion: version,
    );

    // Record graph version in persistent storage
    await _localDataSource.setGraphBuiltForVersion(version);
  }

  @override
  void invalidate() => _graphCache.invalidate();

  @override
  Future<RouteResult?> findRoute(RouteRequest request) async {
    final router = await _ensureRouter();
    if (router == null) return null;

    final engineResult = router.route(
      request.origin.latitude,
      request.origin.longitude,
      request.destination.latitude,
      request.destination.longitude,
    );

    return _toRouteResult(router, engineResult);
  }

  @override
  Future<RouteResult?> findRouteByStopIds(
    String originStopId,
    String destinationStopId,
  ) async {
    final router = await _ensureRouter();
    if (router == null) return null;

    final engineResult = router.routeBetweenStopIds(
      originStopId,
      destinationStopId,
    );

    return _toRouteResult(router, engineResult);
  }

  @override
  Future<List<NearbyStop>> findNearbyStops(
    LocationPoint location, {
    double radiusM = 1800,
    int limit = 12,
  }) async {
    final router = await _ensureRouter();
    if (router == null) return [];

    final results = router.nearestStops(
      location.latitude,
      location.longitude,
      radiusM: radiusM,
      limit: limit,
    );

    return results.map((e) {
      final (distance, stop) = e;
      return NearbyStop(
        stopId: stop.id,
        name: stop.name,
        distanceMeters: distance,
        location: LocationPoint(latitude: stop.lat, longitude: stop.lng),
      );
    }).toList();
  }

  /// Ensure the router is initialized.
  Future<TransitRouter?> _ensureRouter() async {
    if (!_graphCache.isInitialized) {
      try {
        await initialize();
      } catch (e) {
        return null;
      }
    }
    return _graphCache.router;
  }

  /// Convert engine result to domain RouteResult.
  RouteResult? _toRouteResult(
    TransitRouter router,
    dynamic engineResult,
  ) {
    if (engineResult == null) return null;

    final formatted = router.formatResult(engineResult);
    if (formatted['found'] != true) return null;

    final segments = (formatted['segments'] as List<dynamic>)
        .map((s) => RouteSegment(
              mode: s['mode'] as String,
              routeName: s['title'] as String?,
              fromName: s['from'] as String,
              toName: s['to'] as String,
              durationMinutes: s['durationMinutes'] as int,
            ))
        .toList();

    return RouteResult(
      durationMinutes: formatted['durationMinutes'] as int,
      walkingMinutes: formatted['walkingMinutes'] as int,
      transfers: formatted['transfers'] as int,
      segments: segments,
    );
  }
}
