import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wassla/features/places/domain/repositories/place_repository.dart';
import 'package:wassla/features/places/domain/usecases/search_places_usecase.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/route_search/presentation/cubit/autocomplete_cubit.dart';

class MockPlaceRepository implements PlaceRepository {
  List<Place> mockPlaces = [
    const Place(id: '1', name: 'Helwan Metro', location: LocationPoint(latitude: 0, longitude: 0), transportModes: []),
    const Place(id: '2', name: 'Maadi Metro', location: LocationPoint(latitude: 0, longitude: 0), transportModes: []),
  ];

  @override
  Future<List<Place>> getAllPlaces() async {
    return mockPlaces;
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    return mockPlaces.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}

class DelayedMockPlaceRepository extends MockPlaceRepository {
  @override
  Future<List<Place>> searchPlaces(String query) async {
    // Artificial delay to simulate race conditions
    await Future.delayed(const Duration(milliseconds: 100));
    return super.searchPlaces(query);
  }
}

void main() {
  group('AutocompleteCubit', () {
    late AutocompleteCubit cubit;
    late SearchPlacesUseCase useCase;

    setUp(() {
      useCase = SearchPlacesUseCase(MockPlaceRepository());
      cubit = AutocompleteCubit(useCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is correct', () {
      expect(cubit.state.query, '');
      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.selectedPlace, isNull);
      expect(cubit.state.isLoading, false);
    });

    test('Query changed immediately updates state and clears selectedPlace', () {
      // Simulate selection
      cubit.onSuggestionSelected(const Place(id: '1', name: 'Hel', location: LocationPoint(latitude: 0, longitude: 0), transportModes: []));
      expect(cubit.state.selectedPlace, isNotNull);

      // Change query
      cubit.onQueryChanged('Helw');
      expect(cubit.state.query, 'Helw');
      expect(cubit.state.selectedPlace, isNull);
      expect(cubit.state.isLoading, true);
    });

    test('Debounce timer triggers search', () async {
      cubit.onQueryChanged('Helwan');
      expect(cubit.state.isLoading, true);
      expect(cubit.state.suggestions, isEmpty);

      // Wait for debounce (250ms) + small buffer
      await Future.delayed(const Duration(milliseconds: 300));

      expect(cubit.state.isLoading, false);
      expect(cubit.state.suggestions.length, 1);
      expect(cubit.state.suggestions.first.name, 'Helwan Metro');
    });

    test('Race condition: stale query does not overwrite latest query', () async {
      final delayedUseCase = SearchPlacesUseCase(DelayedMockPlaceRepository());
      final raceCubit = AutocompleteCubit(delayedUseCase);

      raceCubit.onQueryChanged('Helwan');
      // Wait for first debounce to trigger the request
      await Future.delayed(const Duration(milliseconds: 260));

      // Before the first request finishes, user types more
      raceCubit.onQueryChanged('Helwan Metro');

      // Wait for second request to finish
      await Future.delayed(const Duration(milliseconds: 400));

      // The final state should match 'Helwan Metro', not the first stale query 'Helwan'
      // If the race condition was not handled, the first query might have overwritten the second.
      // But because query changed, debounce cancels it, and the cubit explicitly checks `if (state.query == currentQuery)`.
      expect(raceCubit.state.query, 'Helwan Metro');
      expect(raceCubit.state.isLoading, false);
      
      raceCubit.close();
    });

    test('onSuggestionSelected updates field and hides suggestions', () async {
      cubit.onQueryChanged('Helwan');
      await Future.delayed(const Duration(milliseconds: 300));
      expect(cubit.state.suggestions, isNotEmpty);

      final selected = cubit.state.suggestions.first;
      cubit.onSuggestionSelected(selected);

      expect(cubit.state.selectedPlace, selected);
      expect(cubit.state.query, selected.name);
      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.isLoading, false);
    });

    test('Empty query hides suggestions immediately', () {
      cubit.onQueryChanged(' ');
      expect(cubit.state.suggestions, isEmpty);
      expect(cubit.state.isLoading, false);
    });
  });
}
