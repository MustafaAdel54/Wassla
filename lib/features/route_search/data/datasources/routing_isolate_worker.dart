import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:wassla/core/routing/dataset_loader.dart';
import 'package:wassla/core/routing/engine_models.dart';
import 'package:wassla/core/routing/transit_router.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';

// --- Messaging Protocol ---

abstract class WorkerCommand {}

class InitCommand extends WorkerCommand {
  final SendPort replyPort;
  final String activeDatasetPath;
  final int datasetVersion;
  InitCommand(this.replyPort, this.activeDatasetPath, this.datasetVersion);
}

class ReloadCommand extends WorkerCommand {
  final int requestId;
  final String activeDatasetPath;
  final int datasetVersion;
  ReloadCommand(this.requestId, this.activeDatasetPath, this.datasetVersion);
}

class RouteCoordinateCommand extends WorkerCommand {
  final int requestId;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  RouteCoordinateCommand(
    this.requestId,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
  );
}

class RouteStopCommand extends WorkerCommand {
  final int requestId;
  final String originStopId;
  final String destinationStopId;
  RouteStopCommand(this.requestId, this.originStopId, this.destinationStopId);
}

class NearbyStopsCommand extends WorkerCommand {
  final int requestId;
  final double latitude;
  final double longitude;
  final double radiusM;
  final int limit;
  NearbyStopsCommand(
    this.requestId,
    this.latitude,
    this.longitude,
    this.radiusM,
    this.limit,
  );
}

abstract class WorkerResponse {
  final int requestId;
  WorkerResponse(this.requestId);
}

class RouteSuccessResponse extends WorkerResponse {
  final RouteResult? result;
  final int datasetVersion;
  RouteSuccessResponse(super.requestId, this.result, this.datasetVersion);
}

class NearbyStopsResponse extends WorkerResponse {
  final List<NearbyStop> stops;
  NearbyStopsResponse(super.requestId, this.stops);
}

class ErrorResponse extends WorkerResponse {
  final String error;
  ErrorResponse(super.requestId, this.error);
}

class SuccessResponse extends WorkerResponse {
  final int datasetVersion;
  SuccessResponse(super.requestId, this.datasetVersion);
}

// --- Background Isolate Entry Point ---

Future<void> _routingIsolateEntryPoint(SendPort initialReplyPort) async {
  final receivePort = ReceivePort();
  initialReplyPort.send(receivePort.sendPort);

  TransitRouter? router;
  int currentDatasetVersion = 0;

  Future<void> loadDataset(String activeDatasetPath, int version) async {
    developer.log(
      '[RoutingIsolate] Loading dataset v$version from $activeDatasetPath',
    );

    final stopsFile = File(p.join(activeDatasetPath, 'stops.json'));
    final stationsFile = File(p.join(activeDatasetPath, 'stations.json'));
    final routesFile = File(p.join(activeDatasetPath, 'routes.json'));
    final patternsFile = File(p.join(activeDatasetPath, 'route_patterns.json'));
    final transfersFile = File(p.join(activeDatasetPath, 'transfers.json'));

    final stopsJson = await stopsFile.readAsString();
    final stationsJson = await stationsFile.readAsString();
    final routesJson = await routesFile.readAsString();
    final patternsJson = await patternsFile.readAsString();
    final transfersJson = await transfersFile.readAsString();

    developer.log('[RoutingIsolate] Parsing JSON arrays...');
    final dataset = loadDatasetFromJsonArrays(
      stopsJson: stopsJson,
      stationsJson: stationsJson,
      routesJson: routesJson,
      routePatternsJson: patternsJson,
      transfersJson: transfersJson,
    );

    developer.log('[RoutingIsolate] Building TransitRouter...');
    router = TransitRouter(dataset);
    currentDatasetVersion = version;
    developer.log('[RoutingIsolate] TransitRouter v$version ready.');
  }

  // Using await-for ensures strict sequential processing of asynchronous tasks.
  // A ReloadCommand will complete loadDataset BEFORE the next RouteCommand is processed.
  await for (final message in receivePort) {
    if (message is InitCommand) {
      try {
        await loadDataset(message.activeDatasetPath, message.datasetVersion);
        message.replyPort.send(true);
      } catch (e, stack) {
        developer.log('[RoutingIsolate] Init error: $e\n$stack');
        message.replyPort.send(false);
      }
    } else if (message is ReloadCommand) {
      try {
        await loadDataset(message.activeDatasetPath, message.datasetVersion);
        initialReplyPort.send(
          SuccessResponse(message.requestId, currentDatasetVersion),
        );
      } catch (e) {
        initialReplyPort.send(ErrorResponse(message.requestId, e.toString()));
      }
    } else if (message is RouteCoordinateCommand) {
      if (router == null) {
        initialReplyPort.send(
          ErrorResponse(message.requestId, 'Router not initialized'),
        );
        continue;
      }
      try {
        developer.log(
          '[RoutingIsolate] Executing coordinate search (req ${message.requestId}, v$currentDatasetVersion)...',
        );
        final stopwatch = Stopwatch()..start();
        final engineResult = router!.route(
          message.originLat,
          message.originLng,
          message.destLat,
          message.destLng,
        );

        final routeResult = _toRouteResult(router!, engineResult);
        developer.log(
          '[RoutingIsolate] Search completed in ${stopwatch.elapsedMilliseconds}ms.',
        );
        initialReplyPort.send(
          RouteSuccessResponse(
            message.requestId,
            routeResult,
            currentDatasetVersion,
          ),
        );
      } catch (e, stack) {
        developer.log('[RoutingIsolate] Route error: $e\n$stack');
        initialReplyPort.send(ErrorResponse(message.requestId, e.toString()));
      }
    } else if (message is RouteStopCommand) {
      if (router == null) {
        initialReplyPort.send(
          ErrorResponse(message.requestId, 'Router not initialized'),
        );
        continue;
      }
      try {
        developer.log(
          '[RoutingIsolate] Executing stop-ID search (req ${message.requestId}, v$currentDatasetVersion)...',
        );
        final stopwatch = Stopwatch()..start();
        final engineResult = router!.routeBetweenStopIds(
          message.originStopId,
          message.destinationStopId,
        );

        final routeResult = _toRouteResult(router!, engineResult);
        developer.log(
          '[RoutingIsolate] Search completed in ${stopwatch.elapsedMilliseconds}ms.',
        );
        initialReplyPort.send(
          RouteSuccessResponse(
            message.requestId,
            routeResult,
            currentDatasetVersion,
          ),
        );
      } catch (e, stack) {
        developer.log('[RoutingIsolate] Route error: $e\n$stack');
        initialReplyPort.send(ErrorResponse(message.requestId, e.toString()));
      }
    } else if (message is NearbyStopsCommand) {
      if (router == null) {
        initialReplyPort.send(
          ErrorResponse(message.requestId, 'Router not initialized'),
        );
        continue;
      }
      try {
        final engineStops = router!.nearestStops(
          message.latitude,
          message.longitude,
          radiusM: message.radiusM,
          limit: message.limit,
        );

        final nearbyStops = engineStops.map((e) {
          final distance = e.$1;
          final stop = e.$2;
          return NearbyStop(
            stopId: stop.id,
            name: stop.name,
            distanceMeters: distance,
            location: LocationPoint(latitude: stop.lat, longitude: stop.lng),
          );
        }).toList();

        initialReplyPort.send(
          NearbyStopsResponse(message.requestId, nearbyStops),
        );
      } catch (e, stack) {
        developer.log('[RoutingIsolate] NearbyStops error: $e\n$stack');
        initialReplyPort.send(ErrorResponse(message.requestId, e.toString()));
      }
    }
  }
}

/// Convert V4 engine result to Domain result
RouteResult? _toRouteResult(
  TransitRouter router,
  EngineRouteResult? engineResult,
) {
  if (engineResult == null) return null;

  return RouteResult(
    durationMinutes: engineResult.durationMinutes,
    walkingMinutes: engineResult.walkingMinutes,
    transfers: engineResult.transfers,
    estimatedFare: engineResult.fare,
    segments: engineResult.legs.map((leg) {
      final routeModel = leg.routeId != null
          ? router.ds.routes[leg.routeId!]
          : null;

      final boardStop = router.ds.stops[leg.fromStop]!;
      final alightStop = router.ds.stops[leg.toStop]!;

      return RouteSegment(
        mode: leg.mode,
        routeId: leg.routeId,
        routeName: routeModel?.name,
        fromName: boardStop.name,
        toName: alightStop.name,
        durationMinutes: (leg.durationSec / 60).round(),
      );
    }).toList(),
  );
}

// --- Main Isolate Worker ---

class RoutingIsolateWorker {
  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;

  final Map<int, Completer<dynamic>> _pendingRequests = {};
  int _requestIdCounter = 0;

  bool get isInitialized => _commandPort != null;

  /// Spawns the isolate and initializes the graph from the given dataset directory.
  Future<void> initialize(String activeDatasetPath, int datasetVersion) async {
    if (isInitialized) return;

    developer.log('[RoutingIsolateWorker] Spawning background isolate...');
    _responsePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _routingIsolateEntryPoint,
      _responsePort!.sendPort,
      debugName: 'RoutingIsolate',
    );

    final completer = Completer<SendPort>();

    _responsePort!.listen(
      (message) {
        if (message is SendPort) {
          completer.complete(message);
        } else if (message is WorkerResponse) {
          final pendingCompleter = _pendingRequests.remove(message.requestId);
          if (pendingCompleter != null) {
            if (message is ErrorResponse) {
              pendingCompleter.completeError(Exception(message.error));
            } else if (message is RouteSuccessResponse) {
              pendingCompleter.complete(message.result);
            } else if (message is NearbyStopsResponse) {
              pendingCompleter.complete(message.stops);
            } else if (message is SuccessResponse) {
              pendingCompleter.complete(null);
            }
          }
        }
      },
      onError: (error) {
        developer.log('[RoutingIsolateWorker] Uncaught isolate error: $error');
        dispose();
      },
      onDone: () {
        developer.log('[RoutingIsolateWorker] Isolate terminated.');
        dispose();
      },
    );

    _commandPort = await completer.future;

    // Send init command to load dataset
    final initCompleter = Completer<bool>();
    final initReceivePort = ReceivePort();
    initReceivePort.listen((success) {
      initCompleter.complete(success as bool);
      initReceivePort.close();
    });

    _commandPort!.send(
      InitCommand(initReceivePort.sendPort, activeDatasetPath, datasetVersion),
    );
    final success = await initCompleter.future;
    if (!success) {
      dispose();
      throw Exception('Routing isolate failed to initialize dataset');
    }
  }

  /// Reloads the dataset without respawning the isolate.
  Future<void> reload(String activeDatasetPath, int datasetVersion) async {
    if (!isInitialized) return;

    final requestId = ++_requestIdCounter;
    final completer = Completer<void>();
    _pendingRequests[requestId] = completer;

    _commandPort!.send(
      ReloadCommand(requestId, activeDatasetPath, datasetVersion),
    );
    await completer.future;
  }

  /// Computes a route via coordinates.
  Future<RouteResult?> findRoute(
    LocationPoint origin,
    LocationPoint destination,
  ) async {
    if (!isInitialized) throw Exception('Routing Isolate not initialized');

    final requestId = ++_requestIdCounter;
    final completer = Completer<RouteResult?>();
    _pendingRequests[requestId] = completer;

    _commandPort!.send(
      RouteCoordinateCommand(
        requestId,
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      ),
    );

    return completer.future;
  }

  /// Computes a route via stop IDs.
  Future<RouteResult?> findRouteByStopIds(
    String originStopId,
    String destinationStopId,
  ) async {
    if (!isInitialized) throw Exception('Routing Isolate not initialized');

    final requestId = ++_requestIdCounter;
    final completer = Completer<RouteResult?>();
    _pendingRequests[requestId] = completer;

    _commandPort!.send(
      RouteStopCommand(requestId, originStopId, destinationStopId),
    );

    return completer.future;
  }

  /// Finds stops near a location.
  Future<List<NearbyStop>> findNearbyStops(
    LocationPoint location, {
    double radiusM = 1800,
    int limit = 12,
  }) async {
    if (!isInitialized) throw Exception('Routing Isolate not initialized');

    final requestId = ++_requestIdCounter;
    final completer = Completer<List<NearbyStop>>();
    _pendingRequests[requestId] = completer;

    _commandPort!.send(
      NearbyStopsCommand(
        requestId,
        location.latitude,
        location.longitude,
        radiusM,
        limit,
      ),
    );

    return completer.future;
  }

  /// Terminates the isolate cleanly.
  void dispose() {
    _commandPort = null;
    _responsePort?.close();
    _responsePort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    // Fail all pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Routing Isolate terminated'));
      }
    }
    _pendingRequests.clear();
  }
}
