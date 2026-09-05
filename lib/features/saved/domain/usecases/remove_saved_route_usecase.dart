import '../repositories/saved_route_repository.dart';

class RemoveSavedRouteUseCase {
  final SavedRouteRepository repository;

  RemoveSavedRouteUseCase(this.repository);

  Future<void> call(String id) {
    return repository.removeSavedRoute(id);
  }
}
