import '../repositories/saved_route_repository.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class SaveRouteUseCase {
  final SavedRouteRepository repository;

  SaveRouteUseCase(this.repository);

  Future<void> call({
    required String originName,
    required String destName,
    required RouteResult routeResult,
    String? userId,
  }) {
    return repository.saveRoute(
      originName: originName,
      destName: destName,
      routeResult: routeResult,
      userId: userId,
    );
  }
}
