# Antigravity Build Instruction — Egypt Transit V5

Use all files in this pack as the current source of truth for the new Flutter application.

## Mission
Build a completely new Flutter application layer for Egypt Transit using SOLID, OOP, and Clean Architecture. Reuse the existing V4 schedule-independent routing engine and normalized transport data. Do not rebuild the transport system or implement routing algorithms in Flutter.

## Mandatory changes from the previous foundation

1. Firebase is the shared remote source of truth for transport data/assets.
2. The application must maintain a persistent local copy/cache of downloaded assets/data.
3. On every launch, use existing local data immediately. Do not redownload the dataset merely because the app was reopened.
4. Perform a lightweight remote manifest/version check asynchronously.
5. Download only new or changed files/assets. Do not redownload unchanged files.
6. Persist successful updates safely and keep the previous valid dataset if an update fails.
7. If routing data changes, invalidate/rebuild the V4 graph once; otherwise reuse the cached graph.
8. Provide a temporary protected developer/admin import action that can publish bundled/local assets to Firebase. It must be easy to disable/remove before production.
9. Route search must never freeze the UI. Show a loading state while route calculation/fetching is running.
10. For the first milestone, use a deliberately simple functional UI to validate data, sync, autocomplete, routing, and results.
11. Do not implement the final Figma design yet. The final Figma will be supplied later and should then provide the app colors, typography/text styles, spacing, components, and final screens.
12. Keep Firebase SDKs, local storage, and infrastructure details outside the domain layer.

## First milestone

```text
Existing local dataset
↓
Open app without unnecessary downloads
↓
Async Firebase manifest check
↓
Incremental sync only when needed
↓
From autocomplete
↓
To autocomplete
↓
Find Route
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
Readable functional UI
```

## Do not start with

- onboarding
- profile
- favorites
- advanced map UX
- final Figma styling

Start with the data lifecycle, incremental Firebase sync, V4 integration, route search Cubit, and simple test UI.

Before implementation, read all files in this V5 pack in the order defined by `README.md`.
