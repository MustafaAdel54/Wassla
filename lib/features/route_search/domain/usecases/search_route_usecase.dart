import '../entities/routing_entities.dart';
import '../repositories/routing_service.dart';

/// Use case: Search for the best route between two points.
/// Presentation layer calls this, never the RoutingService directly.
class SearchRouteUseCase {
  final RoutingService routingService;

  const SearchRouteUseCase(this.routingService);

  Future<RouteResult?> execute(RouteRequest request) {
    return routingService.findRoute(request);
  }
}
