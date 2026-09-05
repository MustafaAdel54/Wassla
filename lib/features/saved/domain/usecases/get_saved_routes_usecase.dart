import '../entities/saved_route.dart';
import '../repositories/saved_route_repository.dart';

class GetSavedRoutesUseCase {
  final SavedRouteRepository repository;

  GetSavedRoutesUseCase(this.repository);

  Future<List<SavedRoute>> call() {
    return repository.getSavedRoutes();
  }
}
