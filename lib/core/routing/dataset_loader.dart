import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'engine_models.dart';
import 'geo.dart';

/// The loaded transit dataset with the pre-computed static graph.
/// Direct Dart port of V4 Python loaders.py Dataset class.
class TransitDataset {
  final Map<String, EngineStop> stops = {};
  final Map<String, EngineStation> stations = {};
  final Map<String, EngineRoute> routes = {};
  final Map<String, EnginePattern> patterns = {};
  final Map<String, List<Connection>> connectionsByFrom = {};
  final List<Connection> transfers = [];

  void addConnection(Connection c) {
    connectionsByFrom.putIfAbsent(c.fromStop, () => []).add(c);
  }

  void finalize() {
    for (final key in connectionsByFrom.keys) {
      connectionsByFrom[key]!.sort((a, b) {
        final cmp = a.departureSec.compareTo(b.departureSec);
        if (cmp != 0) return cmp;
        return a.arrivalSec.compareTo(b.arrivalSec);
      });
    }
  }
}

/// Load the transit dataset from a directory of JSON files.
/// Direct port of V4 Python load_dataset().
///
/// [root] must be a directory containing subdirectories:
///   stops/, stations/, routes/, route_patterns/, transfers/ (optional)
///
/// This function is designed to be called inside an Isolate.
TransitDataset loadDatasetFromDirectory(String root) {
  final ds = TransitDataset();

  // Load stops
  for (final f in _jsonFiles(root, 'stops')) {
    final w = _readJsonFile(f);
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.stops[id] = EngineStop(
      id: id,
      name: o['name'] as String,
      lat: (o['lat'] as num).toDouble(),
      lng: (o['lng'] as num).toDouble(),
      stationId: o['stationId'] as String?,
      modes:
          (o['transportModes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // Load stations
  for (final f in _jsonFiles(root, 'stations')) {
    final w = _readJsonFile(f);
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.stations[id] = EngineStation(
      id: id,
      name: o['name'] as String,
      lat: (o['lat'] as num).toDouble(),
      lng: (o['lng'] as num).toDouble(),
    );
  }

  // Load routes
  for (final f in _jsonFiles(root, 'routes')) {
    final w = _readJsonFile(f);
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.routes[id] = EngineRoute(
      id: id,
      name: o['name'] as String,
      mode: o['transportMode'] as String,
      agencyId: o['agencyId'] as String?,
    );
  }

  // Load route patterns
  for (final f in _jsonFiles(root, 'route_patterns')) {
    final w = _readJsonFile(f);
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    final stops = (o['stops'] as List<dynamic>)
        .map(
          (s) => PatternStop(
            stopId: s['stopId'] as String,
            sequence: (s['sequence'] as num).toInt(),
            arrivalSec: (s['arrivalSec'] as num?)?.toInt(),
            departureSec: (s['departureSec'] as num?)?.toInt(),
          ),
        )
        .toList();
    ds.patterns[id] = EnginePattern(
      id: id,
      routeId: o['routeId'] as String,
      tripId: (o['tripId'] as String?) ?? id,
      directionId: o['directionId'] as String?,
      headsign: o['headsign'] as String?,
      serviceId: o['serviceId'] as String?,
      stops: stops,
    );
  }

  _buildStaticGraph(ds);
  _loadTransfers(ds, root);
  ds.finalize();

  return ds;
}

/// Load the dataset from pre-loaded JSON arrays (from local cache files).
/// Each collection is a JSON array of {"id": "...", "data": {...}} objects.
///
/// This function is designed to be called inside an Isolate.
TransitDataset loadDatasetFromJsonArrays({
  required String stopsJson,
  required String stationsJson,
  required String routesJson,
  required String routePatternsJson,
  required String transfersJson,
}) {
  final ds = TransitDataset();

  // Parse stops
  for (final w in (jsonDecode(stopsJson) as List<dynamic>)) {
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.stops[id] = EngineStop(
      id: id,
      name: o['name'] as String,
      lat: (o['lat'] as num).toDouble(),
      lng: (o['lng'] as num).toDouble(),
      stationId: o['stationId'] as String?,
      modes:
          (o['transportModes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // Parse stations
  for (final w in (jsonDecode(stationsJson) as List<dynamic>)) {
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.stations[id] = EngineStation(
      id: id,
      name: o['name'] as String,
      lat: (o['lat'] as num).toDouble(),
      lng: (o['lng'] as num).toDouble(),
    );
  }

  // Parse routes
  for (final w in (jsonDecode(routesJson) as List<dynamic>)) {
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    ds.routes[id] = EngineRoute(
      id: id,
      name: o['name'] as String,
      mode: o['transportMode'] as String,
      agencyId: o['agencyId'] as String?,
    );
  }

  // Parse route patterns
  for (final w in (jsonDecode(routePatternsJson) as List<dynamic>)) {
    final id = w['id'] as String;
    final o = w['data'] as Map<String, dynamic>;
    final stops = (o['stops'] as List<dynamic>)
        .map(
          (s) => PatternStop(
            stopId: s['stopId'] as String,
            sequence: (s['sequence'] as num).toInt(),
            arrivalSec: (s['arrivalSec'] as num?)?.toInt(),
            departureSec: (s['departureSec'] as num?)?.toInt(),
          ),
        )
        .toList();
    ds.patterns[id] = EnginePattern(
      id: id,
      routeId: o['routeId'] as String,
      tripId: (o['tripId'] as String?) ?? id,
      directionId: o['directionId'] as String?,
      headsign: o['headsign'] as String?,
      serviceId: o['serviceId'] as String?,
      stops: stops,
    );
  }

  _buildStaticGraph(ds);

  // Parse transfers from JSON array
  for (final w in (jsonDecode(transfersJson) as List<dynamic>)) {
    final o = w['data'] as Map<String, dynamic>;
    final a = o['fromStopId'] as String?;
    final b = o['toStopId'] as String?;
    if (a == null || b == null) continue;
    if (!ds.stops.containsKey(a) || !ds.stops.containsKey(b)) continue;

    final distanceMeters = (o['distanceMeters'] as num?)?.toDouble() ?? 0.0;
    final estimatedMinutes = (o['estimatedMinutes'] as num?)?.toInt();
    final mins = estimatedMinutes ?? max(1, (distanceMeters / 80.0).round());
    final sec = mins * 60;
    final confidence = o['confidence'] as String?;

    for (final pair in [
      [a, b],
      [b, a],
    ]) {
      final c = Connection(
        fromStop: pair[0],
        toStop: pair[1],
        routeId: null,
        mode: 'walking',
        departureSec: 0,
        arrivalSec: sec,
        distanceM: distanceMeters,
        isTransfer: true,
        transferConfidence: confidence,
      );
      ds.transfers.add(c);
      ds.addConnection(c);
    }
  }

  ds.finalize();
  return ds;
}

/// Build the static, schedule-independent transit graph.
/// Direct port of V4 Python loaders.py graph building logic.
///
/// For each (from_stop, to_stop, route, mode) edge, computes the
/// MEDIAN duration observed across all GTFS trips. This produces
/// time-independent edge weights.
void _buildStaticGraph(TransitDataset ds) {
  // Collect duration samples per edge
  final durationSamples = <String, List<int>>{};
  final distanceByEdge = <String, double>{};

  for (final p in ds.patterns.values) {
    final ps = List<PatternStop>.from(p.stops)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final route = ds.routes[p.routeId];
    final mode = route?.mode ?? 'unknown';

    for (int i = 0; i < ps.length - 1; i++) {
      final a = ps[i];
      final b = ps[i + 1];
      if (a.stopId == b.stopId ||
          a.departureSec == null ||
          b.arrivalSec == null) {
        continue;
      }

      var dep = a.departureSec!;
      var arr = b.arrivalSec!;
      if (arr < dep) arr += 86400; // Handle midnight wrap
      final duration = arr - dep;
      if (duration <= 0) continue;

      final key = '${a.stopId}|${b.stopId}|${p.routeId}|$mode';
      durationSamples.putIfAbsent(key, () => []).add(duration);

      final sa = ds.stops[a.stopId];
      final sb = ds.stops[b.stopId];
      distanceByEdge[key] = (sa != null && sb != null)
          ? haversineM(sa.lat, sa.lng, sb.lat, sb.lng)
          : 0.0;
    }
  }

  // Create static connections using median duration per edge
  for (final entry in durationSamples.entries) {
    final parts = entry.key.split('|');
    final fromStop = parts[0];
    final toStop = parts[1];
    final routeId = parts[2];
    final mode = parts[3];
    final samples = entry.value;

    // Compute median — matches Python statistics.median behavior
    final duration = max(1, _median(samples).round());

    ds.addConnection(
      Connection(
        fromStop: fromStop,
        toStop: toStop,
        routeId: routeId,
        mode: mode,
        departureSec: 0,
        arrivalSec: duration,
        distanceM: distanceByEdge[entry.key] ?? 0.0,
        isTransfer: false,
      ),
    );
  }
}

/// Load transfers from the transfers/ directory.
void _loadTransfers(TransitDataset ds, String root) {
  for (final f in _jsonFiles(root, 'transfers')) {
    final w = _readJsonFile(f);
    final o = w['data'] as Map<String, dynamic>;
    final a = o['fromStopId'] as String?;
    final b = o['toStopId'] as String?;
    if (a == null || b == null) continue;
    if (!ds.stops.containsKey(a) || !ds.stops.containsKey(b)) continue;

    final distanceMeters = (o['distanceMeters'] as num?)?.toDouble() ?? 0.0;
    final estimatedMinutes = (o['estimatedMinutes'] as num?)?.toInt();
    final mins = estimatedMinutes ?? max(1, (distanceMeters / 80.0).round());
    final sec = mins * 60;
    final confidence = o['confidence'] as String?;

    for (final pair in [
      [a, b],
      [b, a],
    ]) {
      final c = Connection(
        fromStop: pair[0],
        toStop: pair[1],
        routeId: null,
        mode: 'walking',
        departureSec: 0,
        arrivalSec: sec,
        distanceM: distanceMeters,
        isTransfer: true,
        transferConfidence: confidence,
      );
      ds.transfers.add(c);
      ds.addConnection(c);
    }
  }
}

/// Compute the median of a list of integers.
/// Matches Python statistics.median behavior.
double _median(List<int> values) {
  final sorted = List<int>.from(values)..sort();
  final n = sorted.length;
  if (n == 0) return 0;
  if (n % 2 == 1) {
    return sorted[n ~/ 2].toDouble();
  }
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
}

/// List all .json files in a subdirectory.
List<File> _jsonFiles(String root, String folder) {
  final dir = Directory(p.join(root, folder));
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
}

/// Read and parse a single JSON file.
Map<String, dynamic> _readJsonFile(File f) {
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}
