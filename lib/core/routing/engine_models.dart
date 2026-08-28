/// V4 routing engine data models — direct Dart port from Python models.py.
///
/// These are internal engine types, NOT domain entities.
/// The RoutingService adapter converts between these and domain types.
library;

/// A transit stop (graph node).
class EngineStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? stationId;
  final List<String> modes;

  const EngineStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.stationId,
    this.modes = const [],
  });
}

/// A transit station (logical grouping of stops).
class EngineStation {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const EngineStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

/// A transit route definition.
class EngineRoute {
  final String id;
  final String name;
  final String mode;
  final String? agencyId;
  final double fare;

  const EngineRoute({
    required this.id,
    required this.name,
    required this.mode,
    this.agencyId,
    this.fare = 0.0,
  });
}

/// A stop within a route pattern, with sequence and timing.
class PatternStop {
  final String stopId;
  final int sequence;
  final int? arrivalSec;
  final int? departureSec;

  const PatternStop({
    required this.stopId,
    required this.sequence,
    this.arrivalSec,
    this.departureSec,
  });
}

/// A route pattern (trip shape) — ordered sequence of stops with timing.
class EnginePattern {
  final String id;
  final String routeId;
  final String tripId;
  final String? directionId;
  final String? headsign;
  final String? serviceId;
  final List<PatternStop> stops;

  const EnginePattern({
    required this.id,
    required this.routeId,
    required this.tripId,
    this.directionId,
    this.headsign,
    this.serviceId,
    required this.stops,
  });
}

/// A directed edge in the transit graph.
class Connection {
  final String fromStop;
  final String toStop;
  final String? routeId;
  final String mode;
  final int departureSec;
  final int arrivalSec;
  final double distanceM;
  final bool isTransfer;
  final String? transferConfidence;

  const Connection({
    required this.fromStop,
    required this.toStop,
    this.routeId,
    required this.mode,
    required this.departureSec,
    required this.arrivalSec,
    this.distanceM = 0.0,
    this.isTransfer = false,
    this.transferConfidence,
  });
}

/// A leg (segment) in a route result.
class EngineLeg {
  String fromStop;
  String toStop;
  final String? routeId;
  final String? routeName;
  final String mode;
  int durationSec;
  double distanceM;
  int? departureSec;
  int? arrivalSec;
  int waitSec;
  final bool isTransfer;

  EngineLeg({
    required this.fromStop,
    required this.toStop,
    this.routeId,
    this.routeName,
    required this.mode,
    required this.durationSec,
    required this.distanceM,
    this.departureSec,
    this.arrivalSec,
    this.waitSec = 0,
    this.isTransfer = false,
  });
}

/// The result of a routing search — one best route.
class EngineRouteResult {
  final int departureSec;
  int arrivalSec;
  int transfers;
  int walkingSec;
  double fare;
  double generalizedCost;
  final List<EngineLeg> legs;

  EngineRouteResult({
    required this.departureSec,
    required this.arrivalSec,
    required this.transfers,
    required this.walkingSec,
    required this.fare,
    required this.generalizedCost,
    List<EngineLeg>? legs,
  }) : legs = legs ?? [];

  int get durationSec => (arrivalSec - departureSec).clamp(0, 1 << 30);
  int get durationMinutes => (durationSec / 60).round();
  int get walkingMinutes => (walkingSec / 60).round();
}
