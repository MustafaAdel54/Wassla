import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';

/// Domain interface for searching places (stops/stations) for autocomplete.
abstract interface class PlaceRepository {
  /// Search for places matching the query string.
  Future<List<Place>> searchPlaces(String query);

  /// Get all places (for offline autocomplete).
  Future<List<Place>> getAllPlaces();
}
