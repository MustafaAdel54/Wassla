import '../entities/routing_entities.dart';

/// Abstraction over the routing engine.
/// Flutter presentation code accesses routing ONLY through this interface.
/// The V4 engine stays behind this adapter.
abstract interface class RoutingService {
  /// Find the best route between two geographic points.
  /// Returns null if no route is found.
  Future<RouteResult?> findRoute(RouteRequest request);

  /// Find the best route between two stop/station IDs.
  /// Returns null if no route is found.
  Future<RouteResult?> findRouteByStopIds(
    String originStopId,
    String destinationStopId,
  );

  /// Find stops near a geographic point.
  Future<List<NearbyStop>> findNearbyStops(
    LocationPoint location, {
    double radiusM = 1800,
    int limit = 12,
  });

  /// Whether the routing engine has been initialized with data.
  bool get isInitialized;

  /// Initialize/rebuild the routing graph from the local dataset.
  /// Should be called in an Isolate for heavy computation.
  Future<void> initialize();

  /// Invalidate the cached graph, forcing a rebuild on next use.
  void invalidate();
}
