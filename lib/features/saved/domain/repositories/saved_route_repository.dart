import '../entities/saved_route.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

abstract class SavedRouteRepository {
  Future<List<SavedRoute>> getSavedRoutes();
  Future<void> saveRoute({
    required String originName,
    required String destName,
    required RouteResult routeResult,
    String? userId,
  });
  Future<void> removeSavedRoute(String id);
  Future<bool> isRouteSaved(String id);
  String generateRouteId(String originName, String destName);
}
