# Egypt Transit — New Flutter App Foundation V5

## Goal
Start a completely new Flutter application with SOLID + OOP + Clean Architecture while reusing the existing transport data and V4 routing engine. Restart the Flutter app layer only; do not rebuild the transport system.

The application must treat Firebase as the shared remote source of truth and maintain a persistent local copy of the transport data/assets for fast startup and offline-friendly reads.

## Existing assets
- V4 schedule-independent routing engine
- Clean normalized transport data
- Cairo Metro GTFS source
- Firebase/Firestore transport-data model
- Local asset/data files bundled with the app for the initial/bootstrap dataset

## New data synchronization requirements

The app is not allowed to behave as a local-only installation.

The intended model is:

```text
Firebase / Cloud Storage
        ↓
 shared source of truth
        ↓
   sync metadata
        ↓
 local persistent cache on each phone
        ↓
 V4 routing + places/search
```

Every installation must be able to consume new data published to Firebase by another installation/admin process.

### Persistent local cache

- Downloaded assets/data must be stored persistently on the device.
- Opening the app again must reuse the existing local copy.
- The app must NOT download the complete dataset again on every run.
- Local reads should be the fast path for normal app usage.

### Incremental synchronization

On app startup:

1. Open the local dataset/cache immediately.
2. Check a lightweight Firebase manifest/version.
3. Compare the remote manifest against the locally stored manifest.
4. Download only files/assets that are new or changed.
5. Keep unchanged files untouched.
6. Update local metadata only after a successful download/validation.
7. If the dataset changed, invalidate/rebuild the V4 graph exactly once for the new dataset.
8. If nothing changed, do not redownload assets and do not rebuild the graph unnecessarily.

The sync must be asynchronous and must not freeze the UI.

### Temporary developer/admin import

For development/testing, provide a temporary protected action that can take bundled/local assets and publish them to Firebase.

This is a development/admin utility, not a normal end-user feature.

Requirements:
- Keep it behind a clear development/admin boundary.
- It may be a temporary button or developer-only screen.
- It should upload the dataset/assets plus the metadata required by the incremental sync system.
- It must be easy to disable/remove before production release.

Do not make the normal user flow depend on this button existing.

## Source of truth by concern
| Concern | Source |
|---|---|
| Remote transport data/assets | Firebase / Cloud Storage + Firestore metadata |
| Local fast-read copy | Device persistent cache/storage |
| Routing logic | V4 routing engine |
| UI state | Cubit / Bloc |
| UI rendering | Flutter |
| Authentication | Firebase Auth |
| User-generated transport data | Firestore |
| Dataset sync metadata | Firestore/remote manifest |

## Architecture

```text
Flutter Presentation
        ↓
    Cubit / Bloc
        ↓
      UseCases
        ↓
 Domain Interfaces
      /        \
     /          \
Routing      Repositories
 Service          ↓
    ↓       Remote + Local Data Sources
 V4 Engine          ↓
              Firebase / Cache
```

The presentation layer must never call Firebase SDKs directly.

## Rules

Flutter must not implement A*, build the graph, parse raw GTFS, or download the full transport graph for every search.

Routing engine must not know about Flutter widgets, Cubit, or UI state.

Domain models must not depend directly on Firebase SDK classes.

Firebase-specific models/adapters belong in the data/infrastructure layer.

Local cache/storage implementation must also stay behind an abstraction so it can be replaced later without changing domain logic.

## Initial UI requirement

For the first implementation, build only a simple functional UI needed to validate:

- local data availability
- Firebase synchronization
- From autocomplete
- To autocomplete
- Find Route
- loading state
- one readable RouteResult

Do NOT spend time implementing the final Figma design yet.

The final Figma will be supplied later and then used to extract/apply:

- app colors
- text styles/typography
- spacing/layout rules
- component styling
- screens and interaction details

## Route-search responsiveness

Starting a route search must not freeze the Flutter UI.

The user must see a visible loading state while the route is being calculated/fetched. The implementation must use asynchronous operations and proper Cubit/Bloc state transitions.

## First vertical slice

```text
App startup
↓
Local cached data available immediately
↓
Background manifest sync
↓
Incremental asset update if needed
↓
From
↓
One-tap location selection
↓
To
↓
One-tap location selection
↓
Find Route
↓
Loading state
↓
RoutingService
↓
ONE best RouteResult
↓
Readable route UI
```

## SOLID goals
- Single Responsibility
- Open/Closed
- Liskov Substitution
- Interface Segregation
- Dependency Inversion
