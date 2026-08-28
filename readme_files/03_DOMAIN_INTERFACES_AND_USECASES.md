# Egypt Transit — Domain Interfaces and Use Cases V5

## RoutingService
```dart
abstract interface class RoutingService {
  Future<RouteResult> findRoute(RouteRequest request);
}
```

Possible implementations:
```text
V4RoutingService
MockRoutingService
OfflineRoutingService
```

## PlaceRepository
```dart
abstract interface class PlaceRepository {
  Future<List<Place>> searchPlaces(String query);
}
```

## TransportRepository
Only add this if the app actually needs transport-data reads:
```dart
abstract interface class TransportRepository {
  Future<TransportStop?> getStopById(String id);
  Future<TransportRoute?> getRouteById(String id);
}
```

## DatasetSyncRepository

Add a domain-level abstraction for incremental dataset synchronization:

```dart
abstract interface class DatasetSyncRepository {
  Future<DatasetSyncStatus> sync();
}
```

The implementation must:

- compare remote manifest metadata with local manifest metadata
- identify missing/changed assets
- download only required assets
- preserve unchanged local files
- update local metadata after successful validation
- expose whether the dataset actually changed

The exact status model can include values such as:

```text
noChanges
updated
initialDownloadRequired
failed
```

## SearchRouteUseCase
```dart
class SearchRouteUseCase {
  final RoutingService routingService;

  const SearchRouteUseCase(this.routingService);

  Future<RouteResult> execute(RouteRequest request) {
    return routingService.findRoute(request);
  }
}
```

## SearchPlacesUseCase
```dart
class SearchPlacesUseCase {
  final PlaceRepository repository;

  const SearchPlacesUseCase(this.repository);

  Future<List<Place>> execute(String query) {
    return repository.searchPlaces(query);
  }
}
```

## Sync use case

Provide a small orchestration use case so startup synchronization is not embedded in widgets:

```dart
class SyncDatasetUseCase {
  final DatasetSyncRepository repository;

  const SyncDatasetUseCase(this.repository);

  Future<DatasetSyncStatus> execute() => repository.sync();
}
```

## Dependency direction
```text
Presentation
    ↓
Use Case
    ↓
Domain Interface
    ↓
Concrete Implementation
```

Widgets/Cubits should not directly call Firebase SDKs or local database/file APIs.

## Separation of concerns

The Firebase implementation may use Firestore/Cloud Storage SDKs, but those dependencies must remain in the data/infrastructure layer.

The local implementation may use a file/database/cache package, but the domain layer must know only the repository/data-source contract.
