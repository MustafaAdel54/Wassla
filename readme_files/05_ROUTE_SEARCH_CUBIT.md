# Egypt Transit — Route Search Cubit V5

## Responsibility
Cubit handles route-search UI state only.

It must NOT implement:
- A*
- graph construction
- GTFS parsing
- Firestore transport queries
- Firebase synchronization logic
- local file/database synchronization logic

## States
```text
initial
loading
success
empty
failure
```

Example:
```dart
sealed class RouteSearchState {}

class RouteSearchInitial extends RouteSearchState {}

class RouteSearchLoading extends RouteSearchState {}

class RouteSearchSuccess extends RouteSearchState {
  final RouteResult result;
  RouteSearchSuccess(this.result);
}

class RouteSearchEmpty extends RouteSearchState {}

class RouteSearchFailure extends RouteSearchState {
  final String message;
  RouteSearchFailure(this.message);
}
```

## Cubit
```dart
class RouteSearchCubit extends Cubit<RouteSearchState> {
  final SearchRouteUseCase searchRoute;

  RouteSearchCubit({required this.searchRoute})
      : super(RouteSearchInitial());

  Future<void> findRoute({
    required LocationPoint origin,
    required LocationPoint destination,
  }) async {
    emit(RouteSearchLoading());

    try {
      final result = await searchRoute.execute(
        RouteRequest(origin: origin, destination: destination),
      );
      emit(RouteSearchSuccess(result));
    } catch (error) {
      emit(RouteSearchFailure(error.toString()));
    }
  }

  void reset() => emit(RouteSearchInitial());
}
```

## Input state
Keep separate:
```text
fromText
selectedFrom
toText
selectedTo
```

Clearing a field must clear both its text and selected location.

Autocomplete selection must complete in one tap.

## Loading UX

When the user taps `Find Route`:

1. Immediately enter `loading` state.
2. Keep the UI responsive.
3. Show a simple loading/progress UI in the first implementation.
4. Do not block the Flutter main/UI thread.
5. Render the route only after a successful result.

The first UI does not need the final Figma loading animation. A simple functional loading indicator is sufficient for data/routing testing.
