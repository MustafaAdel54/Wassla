# Egypt Transit — Project Structure and Build Order V5

## Structure
```text
lib/
├── core/
│   ├── errors/
│   ├── network/
│   ├── firebase/
│   ├── routing/
│   ├── location/
│   ├── storage/
│   ├── sync/
│   └── utils/
│
├── features/
│   ├── route_search/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── dataset_sync/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── cubit/
│   │       └── pages/
│   │
│   ├── places/
│   ├── route_details/
│   ├── map/
│   ├── favorites/
│   ├── community/
│   └── profile/
│
└── main.dart
```

## Suggested data responsibilities

```text
RemoteDataSource
  → Firebase/Cloud Storage

LocalDataSource
  → persistent device cache

DatasetSyncRepository
  → compares remote manifest vs local manifest
  → downloads only missing/changed files
  → persists validated updates

RoutingService
  → V4 engine adapter
```

## Build order

1. Create clean Flutter project.
2. Configure Firebase and basic DI.
3. Create domain models.
4. Create domain interfaces.
5. Create local persistent dataset/cache abstraction.
6. Create Firebase remote data/manifest abstraction.
7. Implement incremental `DatasetSyncRepository`.
8. Add temporary protected developer/admin asset-import action.
9. Integrate V4 behind `RoutingService`.
10. Implement `SearchRouteUseCase`.
11. Implement `SyncDatasetUseCase`.
12. Implement startup sync orchestration outside widgets.
13. Implement `RouteSearchCubit`.
14. Build the simple first route-search screen.
15. Build the one-route result UI.
16. Add visible route-search loading state.
17. Connect Firebase/place search through repositories.
18. Verify incremental startup synchronization.
19. Verify graph cache invalidation only when dataset changes.
20. Add map later.
21. Add favorites/community/profile later.
22. Apply the supplied Figma design only after the functional data/routing slice is stable.

## First definition of done
```text
Existing local assets
 ↓
Open app without redownloading them
 ↓
Lightweight Firebase manifest check
 ↓
Only new/changed assets downloaded
 ↓
Local dataset updated if needed
 ↓
V4 graph reused or rebuilt only when needed
 ↓
From
 ↓
One-tap autocomplete
 ↓
To
 ↓
One-tap autocomplete
 ↓
Find Route
 ↓
RouteSearchCubit
 ↓
Loading state
 ↓
SearchRouteUseCase
 ↓
RoutingService
 ↓
V4 Engine
 ↓
ONE RouteResult
 ↓
Readable UI
```

## Do not begin with

- onboarding
- profile
- favorites
- advanced map UX
- final Figma styling

The first milestone is data + sync + routing + functional UI.
