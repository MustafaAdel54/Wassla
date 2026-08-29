import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wassla/features/places/domain/usecases/search_places_usecase.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';

// --- State ---

class AutocompleteState extends Equatable {
  final String query;
  final List<Place> suggestions;
  final Place? selectedPlace;
  final bool isLoading;

  const AutocompleteState({
    this.query = '',
    this.suggestions = const [],
    this.selectedPlace,
    this.isLoading = false,
  });

  AutocompleteState copyWith({
    String? query,
    List<Place>? suggestions,
    Place? selectedPlace,
    bool clearSelectedPlace = false,
    bool? isLoading,
  }) {
    return AutocompleteState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      selectedPlace: clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [query, suggestions, selectedPlace, isLoading];
}

// --- Cubit ---

class AutocompleteCubit extends Cubit<AutocompleteState> {
  final SearchPlacesUseCase _searchPlacesUseCase;
  Timer? _debounceTimer;

  AutocompleteCubit(this._searchPlacesUseCase) : super(const AutocompleteState());

  void onQueryChanged(String query) {
    // If the query is identical, do nothing (avoids resetting suggestions unnecessarily)
    if (query == state.query && !state.isLoading) return;

    // Any text change immediately invalidates the selected place
    emit(state.copyWith(
      query: query,
      clearSelectedPlace: true,
      isLoading: query.isNotEmpty, // Only load if there's text
    ));

    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      emit(state.copyWith(suggestions: [], isLoading: false));
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (isClosed) return;

      final currentQuery = state.query;
      final results = await _searchPlacesUseCase.execute(currentQuery);
      
      if (isClosed) return;

      // Prevent race conditions: only update if the query hasn't changed since the request started
      if (state.query == currentQuery) {
        emit(state.copyWith(
          suggestions: results,
          isLoading: false,
        ));
      }
    });
  }

  void onSuggestionSelected(Place place) {
    _debounceTimer?.cancel();
    emit(state.copyWith(
      selectedPlace: place,
      query: place.name,
      suggestions: [], // Hide suggestions after selection
      isLoading: false,
    ));
  }

  void onFocusLost() {
    // Optionally clear suggestions when losing focus, but preserving selectedPlace
    emit(state.copyWith(suggestions: []));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
