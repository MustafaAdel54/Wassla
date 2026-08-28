# Egypt Transit — V4 Routing Integration V5

## Boundary
Flutter should depend on:
```dart
abstract interface class RoutingService {
  Future<RouteResult> findRoute(RouteRequest request);
}
```

The existing V4 engine stays behind an adapter.

```dart
class V4RoutingService implements RoutingService {
  final V4Engine engine;

  const V4RoutingService(this.engine);

  @override
  Future<RouteResult> findRoute(RouteRequest request) async {
    // Convert domain request → V4 request
    // Call V4 engine
    // Convert V4 output → RouteResult
  }
}
```

The exact adapter depends on the current V4 package API.

## Preserve V4 rules
- Schedule-independent
- No current time constraints
- No operating-hour filtering
- No waiting-time routing
- One best route
- Shortest estimated duration first
- Fewer transfers as tie-breaker
- Less walking as next tie-breaker

## Performance and local-data lifecycle

Do not build the graph per search.

The graph should be initialized once and cached.

The new local-data sync changes the lifecycle to:

```text
App start
↓
Load existing local dataset
↓
Initialize/use cached V4 graph
↓
Check Firebase manifest asynchronously
↓
If unchanged → keep using current graph
If changed → download changed assets
↓
Validate + persist new local dataset
↓
Invalidate old graph
↓
Build the new graph once
↓
Use new graph for future searches
```

The graph must NOT be rebuilt on every app launch if the dataset did not change.

If routing is server-side, Flutter calls the routing API instead of downloading the graph. For this new app, the implementation should follow the actual existing V4 deployment boundary and preserve the same domain contract.

## Result mapping
Map raw engine output to:
```text
RouteResult
  └── RouteSegment[]
```

## Search UI requirement

Route calculation/fetching must be asynchronous and must never block the Flutter UI thread.

The presentation layer should expose a loading state while `findRoute()` is running.

## Integration tests
```text
Helwan → Ramses
Helwan → Maadi
Salam → Helwan
Wadi Hof → MSA University
Helwan → MSA University
```

Also add synchronization tests for:

- initial install with no local manifest
- startup with identical remote/local manifest → zero asset downloads
- one new remote asset → download only that asset
- one changed remote asset → download only that asset
- failed download → keep previous valid local dataset
- successful dataset update → graph invalidated/rebuilt once
