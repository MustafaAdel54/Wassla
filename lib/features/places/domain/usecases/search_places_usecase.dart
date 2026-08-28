import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import '../repositories/place_repository.dart';

/// Use case: Search for places matching a query string.
/// Used by the autocomplete fields in route search.
class SearchPlacesUseCase {
  final PlaceRepository repository;

  const SearchPlacesUseCase(this.repository);

  Future<List<Place>> execute(String query) {
    return repository.searchPlaces(query);
  }
}
