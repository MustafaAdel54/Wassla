import 'package:equatable/equatable.dart';

/// A geographic coordinate point.
class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;

  const LocationPoint({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// A searchable place (stop or station) for autocomplete.
class Place extends Equatable {
  final String id;
  final String name;
  final LocationPoint location;
  final List<String> transportModes;
  final String? stationId;

  const Place({
    required this.id,
    required this.name,
    required this.location,
    this.transportModes = const [],
    this.stationId,
  });

  @override
  List<Object?> get props => [id, name, location, transportModes, stationId];
}

/// Transport modes supported by the system.
enum TransportMode {
  metro,
  bus,
  microbus,
  minibus,
  walking,
  paratransit,
  other;

  static TransportMode fromString(String mode) {
    return TransportMode.values.firstWhere(
      (e) => e.name == mode.toLowerCase(),
      orElse: () => TransportMode.other,
    );
  }
}

/// A route search request — schedule-independent, no departure time.
class RouteRequest extends Equatable {
  final LocationPoint origin;
  final LocationPoint destination;

  const RouteRequest({required this.origin, required this.destination});

  @override
  List<Object?> get props => [origin, destination];
}

/// A single segment of a route result.
class RouteSegment extends Equatable {
  final String mode;
  final String? routeId;
  final String? routeName;
  final String fromName;
  final String toName;
  final int durationMinutes;

  const RouteSegment({
    required this.mode,
    this.routeId,
    this.routeName,
    required this.fromName,
    required this.toName,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [
    mode,
    routeId,
    routeName,
    fromName,
    toName,
    durationMinutes,
  ];
}

/// The result of a route search — one best route.
class RouteResult extends Equatable {
  final int durationMinutes;
  final int walkingMinutes;
  final int transfers;
  final double? estimatedFare;
  final List<RouteSegment> segments;

  const RouteResult({
    required this.durationMinutes,
    required this.walkingMinutes,
    required this.transfers,
    this.estimatedFare,
    required this.segments,
  });

  @override
  List<Object?> get props => [
    durationMinutes,
    walkingMinutes,
    transfers,
    estimatedFare,
    segments,
  ];
}

/// A nearby stop with distance information.
class NearbyStop extends Equatable {
  final String stopId;
  final String name;
  final double distanceMeters;
  final LocationPoint location;

  const NearbyStop({
    required this.stopId,
    required this.name,
    required this.distanceMeters,
    required this.location,
  });

  @override
  List<Object?> get props => [stopId, name, distanceMeters, location];
}
