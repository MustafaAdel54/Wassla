import 'dart:convert';

import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/places/domain/repositories/place_repository.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';

/// PlaceRepository implementation that searches the local cached dataset.
/// No network calls — purely offline autocomplete.
class LocalPlaceRepository implements PlaceRepository {
  final LocalDataSource _localDataSource;
  List<Place>? _cachedPlaces;

  LocalPlaceRepository(this._localDataSource);

  @override
  Future<List<Place>> getAllPlaces() async {
    if (_cachedPlaces != null) return _cachedPlaces!;

    final places = <Place>[];

    // Load stations
    try {
      final stationsJson =
          await _localDataSource.readCollectionFile('stations');
      final stations = jsonDecode(stationsJson) as List<dynamic>;
      for (final w in stations) {
        final id = w['id'] as String;
        final o = w['data'] as Map<String, dynamic>;
        places.add(Place(
          id: id,
          name: o['name'] as String,
          location: LocationPoint(
            latitude: (o['lat'] as num).toDouble(),
            longitude: (o['lng'] as num).toDouble(),
          ),
          transportModes: ['metro'],
          stationId: id,
        ));
      }
    } catch (_) {
      // stations file may not exist
    }

    // Load stops (surface stops that aren't just metro platform variants)
    try {
      final stopsJson = await _localDataSource.readCollectionFile('stops');
      final stops = jsonDecode(stopsJson) as List<dynamic>;
      // Track station IDs we already added
      final stationIds = places.map((p) => p.id).toSet();

      for (final w in stops) {
        final id = w['id'] as String;
        final o = w['data'] as Map<String, dynamic>;
        final stationId = o['stationId'] as String?;

        // For stops belonging to a station, only add if station not already present
        if (stationId != null && stationIds.contains(stationId)) continue;

        // Only include stops that are "hub" stops or have a null stationId
        // (surface stops without a parent station)
        if (stationId == null) {
          places.add(Place(
            id: id,
            name: o['name'] as String,
            location: LocationPoint(
              latitude: (o['lat'] as num).toDouble(),
              longitude: (o['lng'] as num).toDouble(),
            ),
            transportModes: (o['transportModes'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
          ));
        }
      }
    } catch (_) {
      // stops file may not exist
    }

    _cachedPlaces = places;
    return places;
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final allPlaces = await getAllPlaces();
    final lowerQuery = query.toLowerCase();

    // Simple contains-based search
    final results = allPlaces
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .take(20)
        .toList();

    // Sort: exact prefix matches first, then by name length
    results.sort((a, b) {
      final aPrefix = a.name.toLowerCase().startsWith(lowerQuery);
      final bPrefix = b.name.toLowerCase().startsWith(lowerQuery);
      if (aPrefix && !bPrefix) return -1;
      if (!aPrefix && bPrefix) return 1;
      return a.name.length.compareTo(b.name.length);
    });

    return results;
  }

  /// Invalidate the cache (called after sync updates).
  void invalidate() {
    _cachedPlaces = null;
  }
}
