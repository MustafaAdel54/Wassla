import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/route_search/data/datasources/routing_isolate_worker.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/route_search/domain/repositories/routing_service.dart';

/// Adapter: wraps the V4 Dart engine behind the RoutingService interface.
/// Presentation layer never sees the engine internals.
class DartV4RoutingService implements RoutingService {
  final RoutingIsolateWorker _worker;
  final LocalDataSource _localDataSource;

  int? _builtForVersion;

  DartV4RoutingService(this._worker, this._localDataSource);

  @override
  bool get isInitialized => _worker.isInitialized;

  @override
  Future<void> initialize() async {
    final manifest = await _localDataSource.getManifest();
    final version = manifest.datasetVersion;

    // Skip rebuild if already built for this version
    if (_builtForVersion == version && _worker.isInitialized) return;

    final activeDatasetPath = await _localDataSource.activePath;

    if (!_worker.isInitialized) {
      await _worker.initialize(activeDatasetPath, version);
    } else {
      await _worker.reload(activeDatasetPath, version);
    }

    _builtForVersion = version;

    // Record graph version in persistent storage
    await _localDataSource.setGraphBuiltForVersion(version);
  }

  @override
  void invalidate() {
    _builtForVersion = null;
    // Don't dispose worker here, just force a reload on next initialize()
  }

  @override
  Future<RouteResult?> findRoute(RouteRequest request) async {
    if (!_worker.isInitialized) return null;
    return _worker.findRoute(request.origin, request.destination);
  }

  @override
  Future<RouteResult?> findRouteByStopIds(
    String originStopId,
    String destinationStopId,
  ) async {
    if (!_worker.isInitialized) return null;
    return _worker.findRouteByStopIds(originStopId, destinationStopId);
  }

  @override
  Future<List<NearbyStop>> findNearbyStops(
    LocationPoint location, {
    double radiusM = 1800,
    int limit = 12,
  }) async {
    if (!_worker.isInitialized) return [];
    return _worker.findNearbyStops(location, radiusM: radiusM, limit: limit);
  }
}
