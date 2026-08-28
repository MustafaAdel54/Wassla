import 'dart:isolate';

import 'package:wassla/core/routing/dataset_loader.dart';
import 'package:wassla/core/routing/transit_router.dart';

/// Caches the in-memory routing graph and manages rebuilds.
/// Graph is built from local dataset files in an Isolate.
class RoutingGraphCache {
  TransitRouter? _router;
  int? _builtForVersion;

  bool get isInitialized => _router != null;
  TransitRouter? get router => _router;
  int? get builtForVersion => _builtForVersion;

  /// Build or return the cached routing graph.
  /// If the graph was already built for this version, returns it immediately.
  /// Otherwise, builds it from the provided JSON strings in an Isolate.
  Future<TransitRouter> getOrBuild({
    required Map<String, String> collectionJsons,
    required int datasetVersion,
  }) async {
    if (_router != null && _builtForVersion == datasetVersion) {
      return _router!;
    }

    // Build graph in an Isolate to avoid blocking UI
    final dataset = await Isolate.run(() {
      return loadDatasetFromJsonArrays(
        stopsJson: collectionJsons['stops']!,
        stationsJson: collectionJsons['stations']!,
        routesJson: collectionJsons['routes']!,
        routePatternsJson: collectionJsons['route_patterns']!,
        transfersJson: collectionJsons['transfers']!,
      );
    });

    _router = TransitRouter(dataset);
    _builtForVersion = datasetVersion;
    return _router!;
  }

  /// Invalidate the cached graph, forcing rebuild on next access.
  void invalidate() {
    _router = null;
    _builtForVersion = null;
  }
}
