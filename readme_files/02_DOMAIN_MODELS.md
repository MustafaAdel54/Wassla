# Egypt Transit — Domain Models V5

Domain models describe business concepts, not Firebase documents, local-storage records, or raw GTFS rows.

The existing routing models remain the core domain contract:

```dart
class LocationPoint {
  final double latitude;
  final double longitude;
  const LocationPoint({required this.latitude, required this.longitude});
}

class Place {
  final String id;
  final String name;
  final LocationPoint location;
  const Place({required this.id, required this.name, required this.location});
}

enum TransportMode { metro, bus, microbus, minibus, walking, other }

class RouteRequest {
  final LocationPoint origin;
  final LocationPoint destination;
  const RouteRequest({required this.origin, required this.destination});
}

class RouteResult {
  final int durationMinutes;
  final int walkingMinutes;
  final int transfers;
  final double? estimatedFare;
  final List<RouteSegment> segments;

  const RouteResult({
    required this.durationMinutes,
    required this.walkingMinutes,
    required this.transfers,
    required this.estimatedFare,
    required this.segments,
  });
}

class RouteSegment {
  final TransportMode mode;
  final String? routeId;
  final String? routeName;
  final String fromName;
  final String toName;
  final int durationMinutes;

  const RouteSegment({
    required this.mode,
    required this.routeId,
    required this.routeName,
    required this.fromName,
    required this.toName,
    required this.durationMinutes,
  });
}

class TransportRoute {
  final String id;
  final String name;
  final TransportMode mode;
  final String? agencyId;

  const TransportRoute({
    required this.id,
    required this.name,
    required this.mode,
    required this.agencyId,
  });
}

class TransportStop {
  final String id;
  final String name;
  final LocationPoint location;
  final String? stationId;

  const TransportStop({
    required this.id,
    required this.name,
    required this.location,
    required this.stationId,
  });
}

class TransportStation {
  final String id;
  final String name;
  final LocationPoint location;

  const TransportStation({
    required this.id,
    required this.name,
    required this.location,
  });
}
```

## Sync domain concepts

The sync layer needs domain-level concepts for deciding whether local data is current. These must not expose Firebase SDK classes.

A minimal abstraction can represent:

```text
DatasetManifest
  - datasetVersion
  - generatedAt / updatedAt
  - assets[]

DatasetAsset
  - assetId
  - relativePath / logicalName
  - size
  - contentHash
  - datasetVersion
```

The exact Dart representation may vary, but the domain must be able to answer:

- What remote dataset version is current?
- Which assets are present locally?
- Which assets are missing?
- Which assets changed?

## Local persistence rule

The local manifest must be stored alongside the local dataset/cache. It is used to avoid downloading unchanged assets on every app launch.

## Routing time model

The routing request intentionally has NO departure time because routing is schedule-independent.
