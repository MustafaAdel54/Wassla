# Egypt Transit — New App Foundation Pack V5

This V5 pack is the updated source of truth for building the new Flutter application.

It preserves the existing V4 routing engine and normalized transport data, while adding the new requirements:

- Firebase is the shared remote source of truth for transport data/assets.
- The app keeps a local persistent copy/cache of already-downloaded assets.
- On every app launch, the app checks a lightweight remote manifest/version and downloads only new or changed assets.
- Existing local assets must not be downloaded again on every launch.
- First install / missing-data cases may show a loading/bootstrap UI while required data is prepared.
- Route search must remain responsive and show a loading state while the route is being calculated/fetched.
- A temporary developer/admin import action may upload bundled assets to Firebase during development and must be removable/disableable before production.
- The initial UI is intentionally simple for data/routing validation. Final visual design will be implemented later from the provided Figma file, including text styles and app colors.
- Architecture remains SOLID + OOP + Clean Architecture and must remain easy to modify.

## Read in order

1. `01_NEW_APP_FOUNDATION.md`
2. `02_DOMAIN_MODELS.md`
3. `03_DOMAIN_INTERFACES_AND_USECASES.md`
4. `04_ROUTING_INTEGRATION.md`
5. `05_ROUTE_SEARCH_CUBIT.md`
6. `06_PROJECT_STRUCTURE_AND_BUILD_ORDER.md`
7. `07_FIREBASE_ASSET_SYNC.md`

## First production-oriented vertical slice

```text
App launch
↓
Read local cached data immediately
↓
Start lightweight Firebase manifest check in background
↓
Download only new/changed assets
↓
Update local data atomically
↓
Invalidate/rebuild V4 graph only when dataset changed
↓
From
→ one-tap autocomplete
→ To
→ one-tap autocomplete
→ Find Route
→ loading state (no UI freeze)
→ V4 RoutingService
→ ONE RouteResult
→ readable UI
```
