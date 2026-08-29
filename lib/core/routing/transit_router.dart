import 'dart:math';

import 'package:collection/collection.dart';

import 'dataset_loader.dart';
import 'engine_models.dart';
import 'geo.dart';

/// V4 routing engine constants — preserved exactly from Python.
const double walkingSpeedMps = 1.35;
const int transferPenaltySec = 4 * 60; // 240 seconds
const double maxAccessRadiusM = 1800;

/// Dijkstra search state: current stop + current route.
class _SearchState {
  final String stopId;
  final String? currentRouteId;

  const _SearchState(this.stopId, this.currentRouteId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SearchState &&
          stopId == other.stopId &&
          currentRouteId == other.currentRouteId;

  @override
  int get hashCode => Object.hash(stopId, currentRouteId);
}

/// Search label: (arrival, transfers, walking) — used for priority ordering.
class _Label implements Comparable<_Label> {
  final int arrival;
  final int transfers;
  final int walking;

  const _Label(this.arrival, this.transfers, this.walking);

  @override
  int compareTo(_Label other) {
    var cmp = arrival.compareTo(other.arrival);
    if (cmp != 0) return cmp;
    cmp = transfers.compareTo(other.transfers);
    if (cmp != 0) return cmp;
    return walking.compareTo(other.walking);
  }

  bool operator >=(_Label other) => compareTo(other) >= 0;
  bool operator <(_Label other) => compareTo(other) < 0;

  static const infinity = _Label(1 << 30, 1 << 30, 1 << 30);
}

/// Priority queue entry.
class _PQEntry implements Comparable<_PQEntry> {
  final _Label label;
  final int counter; // tie-break for stable ordering
  final _SearchState state;

  const _PQEntry(this.label, this.counter, this.state);

  @override
  int compareTo(_PQEntry other) {
    final cmp = label.compareTo(other.label);
    if (cmp != 0) return cmp;
    return counter.compareTo(other.counter);
  }
}

/// Previous-state metadata for path reconstruction.
class _PrevInfo {
  final _SearchState? prevState;
  final Connection? connection;
  final int arrivalBefore;
  final int arrivalAfter;
  final int walkingTotal;
  final int transfers;
  final int wait;
  final int accessSec;
  final int transferPenalty;

  const _PrevInfo({
    this.prevState,
    this.connection,
    required this.arrivalBefore,
    required this.arrivalAfter,
    required this.walkingTotal,
    required this.transfers,
    this.wait = 0,
    this.accessSec = 0,
    this.transferPenalty = 0,
  });
}

/// Schedule-independent static transit router.
/// Direct Dart port of V4 Python router.py.
///
/// V4 policy: return ONE best route only.
/// GTFS schedules are used only to estimate segment durations.
/// Vehicle departure times, service calendars, frequencies and waiting
/// times are deliberately ignored.
///
/// Primary objective: shortest estimated journey time.
/// Tie-breakers: fewer transfers, then less walking.
class TransitRouter {
  final TransitDataset ds;

  const TransitRouter(this.ds);

  /// Find stops near a geographic point.
  List<(double distance, EngineStop stop)> nearestStops(
    double lat,
    double lng, {
    double radiusM = maxAccessRadiusM,
    int limit = 12,
  }) {
    final vals = <(double, EngineStop)>[];
    for (final s in ds.stops.values) {
      final d = haversineM(lat, lng, s.lat, s.lng);
      if (d <= radiusM) {
        vals.add((d, s));
      }
    }
    vals.sort((a, b) => a.$1.compareTo(b.$1));
    return vals.take(limit).toList();
  }

  /// Expand a location ID to a set of stop IDs.
  /// If the ID is a stop → returns {id}.
  /// If the ID is a station → returns all stops belonging to that station.
  Set<String> _expandLocationId(String locationId) {
    if (ds.stops.containsKey(locationId)) {
      return {locationId};
    }
    if (ds.stations.containsKey(locationId)) {
      return ds.stops.values
          .where((s) => s.stationId == locationId)
          .map((s) => s.id)
          .toSet();
    }
    throw ArgumentError('Unknown stop/station id: $locationId');
  }

  /// Core Dijkstra search.
  ({_SearchState goal, Map<_SearchState, _PrevInfo> prev})? _search(
    List<(String stopId, int accessSec)> starts,
    Set<String> destIds, {
    int startTimeSec = 0,
    Set<String>? blockedRoutes,
    int maxStates = 300000,
  }) {
    blockedRoutes ??= {};
    final pq = PriorityQueue<_PQEntry>();
    final best = <_SearchState, _Label>{};
    final prev = <_SearchState, _PrevInfo>{};
    var counter = 0;
    var seen = 0;

    for (final (sid, accessSec) in starts) {
      final arr = startTimeSec + accessSec;
      final st = _SearchState(sid, null);
      final label = _Label(arr, 0, accessSec);
      final old = best[st];
      if (old == null || label < old) {
        best[st] = label;
        prev[st] = _PrevInfo(
          arrivalBefore: startTimeSec,
          arrivalAfter: arr,
          walkingTotal: accessSec,
          transfers: 0,
          accessSec: accessSec,
        );
        pq.add(_PQEntry(label, counter++, st));
      }
    }

    _SearchState? goal;
    while (pq.isNotEmpty && seen < maxStates) {
      final entry = pq.removeFirst();
      final key = entry.label;
      final state = entry.state;

      if (best[state] != key) continue;
      seen++;

      if (destIds.contains(state.stopId)) {
        goal = state;
        break;
      }

      final currentLabel = key;
      final arrival = currentLabel.arrival;
      final transfers = currentLabel.transfers;
      final walking = currentLabel.walking;

      final connections = ds.connectionsByFrom[state.stopId];
      if (connections == null) continue;

      for (final c in connections) {
        if (!c.isTransfer && blockedRoutes.contains(c.routeId)) {
          continue;
        }

        final int nArrival;
        final int nTransfers;
        final int nWalking;
        final String? nRoute;
        final int wait;
        final int tPenalty;

        if (c.isTransfer) {
          nArrival = arrival + c.arrivalSec;
          nTransfers = transfers;
          nWalking = walking + c.arrivalSec;
          nRoute = state.currentRouteId;
          wait = 0;
          tPenalty = 0;
        } else {
          // Static graph: c.arrivalSec is edge duration, not a clock time.
          wait = 0;
          final switched =
              state.currentRouteId != null && state.currentRouteId != c.routeId;
          nTransfers = transfers + (switched ? 1 : 0);
          tPenalty = switched ? transferPenaltySec : 0;
          nArrival = arrival + c.arrivalSec + tPenalty;
          nWalking = walking;
          nRoute = c.routeId;
        }

        final ns = _SearchState(c.toStop, nRoute);
        final nl = _Label(nArrival, nTransfers, nWalking);
        if (nl >= (best[ns] ?? _Label.infinity)) continue;
        best[ns] = nl;
        prev[ns] = _PrevInfo(
          prevState: state,
          connection: c,
          arrivalBefore: arrival,
          arrivalAfter: nArrival,
          walkingTotal: nWalking,
          transfers: nTransfers,
          wait: wait,
          transferPenalty: tPenalty,
        );
        pq.add(_PQEntry(nl, counter++, ns));
      }
    }

    if (goal == null) return null;
    return (goal: goal, prev: prev);
  }

  String _stopName(String stopId) {
    return ds.stops[stopId]?.name ?? stopId;
  }

  String _canonicalStationName(String stopId) {
    final s = ds.stops[stopId];
    if (s != null &&
        s.stationId != null &&
        ds.stations.containsKey(s.stationId)) {
      return ds.stations[s.stationId!]!.name;
    }
    return _stopName(stopId);
  }

  /// Convert a static-graph path into one clean user-facing result.
  EngineRouteResult _buildResult(
    _SearchState goal,
    Map<_SearchState, _PrevInfo> prev,
    int startTimeSec, {
    int destAccessSec = 0,
  }) {
    final steps = <(_SearchState, _SearchState, Connection, _PrevInfo)>[];
    var cur = goal;
    var initialAccess = 0;
    late String firstStopId;

    while (true) {
      final info = prev[cur]!;
      if (info.prevState == null) {
        initialAccess = info.accessSec;
        firstStopId = cur.stopId;
        break;
      }
      steps.add((info.prevState!, cur, info.connection!, info));
      cur = info.prevState!;
    }
    steps.reversed; // Need to reverse
    final reversedSteps = steps.reversed.toList();

    final legs = <EngineLeg>[];
    var walkingSec = initialAccess;
    var transfers = 0;
    var fare = 0.0;
    String? lastRoute;
    var elapsed = startTimeSec;

    if (initialAccess > 0) {
      legs.add(
        EngineLeg(
          fromStop: 'ORIGIN',
          toStop: firstStopId,
          routeId: null,
          routeName: null,
          mode: 'walking',
          durationSec: initialAccess,
          distanceM: initialAccess * walkingSpeedMps,
          departureSec: elapsed,
          arrivalSec: elapsed + initialAccess,
          waitSec: 0,
          isTransfer: true,
        ),
      );
      elapsed += initialAccess;
    }

    for (final (_, _, c, _) in reversedSteps) {
      if (c.isTransfer) {
        final dur = c.arrivalSec;
        legs.add(
          EngineLeg(
            fromStop: c.fromStop,
            toStop: c.toStop,
            routeId: null,
            routeName: null,
            mode: 'walking',
            durationSec: dur,
            distanceM: c.distanceM,
            departureSec: elapsed,
            arrivalSec: elapsed + dur,
            waitSec: 0,
            isTransfer: true,
          ),
        );
        elapsed += dur;
        walkingSec += dur;
        continue;
      }

      final switched = lastRoute != null && lastRoute != c.routeId;
      final tPenalty = switched ? transferPenaltySec : 0;
      if (switched) transfers++;
      lastRoute = c.routeId;

      // Static edge: c.arrivalSec is estimated duration.
      final travelSec = max(0, c.arrivalSec);
      final dep = elapsed;
      elapsed += tPenalty + travelSec;

      final newLeg = EngineLeg(
        fromStop: c.fromStop,
        toStop: c.toStop,
        routeId: c.routeId,
        routeName: c.routeId != null ? ds.routes[c.routeId]?.name : null,
        mode: c.mode,
        durationSec: travelSec + tPenalty,
        distanceM: c.distanceM,
        departureSec: dep,
        arrivalSec: elapsed,
        waitSec: 0,
        isTransfer: false,
      );

      // Merge consecutive edges on the same route
      if (legs.isNotEmpty &&
          !legs.last.isTransfer &&
          legs.last.routeId == newLeg.routeId &&
          legs.last.mode == newLeg.mode) {
        legs.last.toStop = newLeg.toStop;
        legs.last.durationSec += newLeg.durationSec;
        legs.last.distanceM += newLeg.distanceM;
        legs.last.arrivalSec = newLeg.arrivalSec;
      } else {
        legs.add(newLeg);
      }
    }

    if (destAccessSec > 0) {
      walkingSec += destAccessSec;
      legs.add(
        EngineLeg(
          fromStop: goal.stopId,
          toStop: 'DESTINATION',
          routeId: null,
          routeName: null,
          mode: 'walking',
          durationSec: destAccessSec,
          distanceM: destAccessSec * walkingSpeedMps,
          departureSec: elapsed,
          arrivalSec: elapsed + destAccessSec,
          waitSec: 0,
          isTransfer: true,
        ),
      );
      elapsed += destAccessSec;
    }

    // Merge consecutive walking legs
    final cleaned = <EngineLeg>[];
    for (final leg in legs) {
      if (cleaned.isNotEmpty &&
          leg.isTransfer &&
          cleaned.last.isTransfer &&
          cleaned.last.mode == 'walking') {
        cleaned.last.toStop = leg.toStop;
        cleaned.last.durationSec += leg.durationSec;
        cleaned.last.distanceM += leg.distanceM;
        cleaned.last.arrivalSec = leg.arrivalSec;
      } else {
        cleaned.add(leg);
      }
    }

    return EngineRouteResult(
      departureSec: startTimeSec,
      arrivalSec: elapsed,
      transfers: transfers,
      walkingSec: walkingSec,
      fare: fare,
      generalizedCost: (elapsed - startTimeSec).toDouble(),
      legs: cleaned,
    );
  }

  /// Route between two stop IDs.
  EngineRouteResult? routeBetweenStopIds(
    String originStopId,
    String destinationStopId, {
    int departureTimeSec = 0,
  }) {
    // V4 is schedule-independent: departureTimeSec is intentionally ignored.
    final origins = _expandLocationId(originStopId);
    final dests = _expandLocationId(destinationStopId);
    EngineRouteResult? best;

    for (final o in origins) {
      for (final d in dests) {
        final res = _search([(o, 0)], {d}, startTimeSec: 0);
        if (res == null) continue;
        final r = _buildResult(res.goal, res.prev, 0);
        final key = (r.arrivalSec, r.transfers, r.walkingSec);
        if (best == null ||
            _compareTuple(key, (
                  best.arrivalSec,
                  best.transfers,
                  best.walkingSec,
                )) <
                0) {
          best = r;
        }
      }
    }
    return best;
  }

  /// Route between two geographic points.
  EngineRouteResult? route(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    int departureTimeSec = 0,
    double accessRadiusM = maxAccessRadiusM,
    int limitOriginStops = 10,
    int limitDestinationStops = 10,
  }) {
    // V4 is schedule-independent: departureTimeSec is intentionally ignored.
    const startTime = 0;
    final origins = nearestStops(
      originLat,
      originLng,
      radiusM: accessRadiusM,
      limit: limitOriginStops,
    );
    final dests = nearestStops(
      destLat,
      destLng,
      radiusM: accessRadiusM,
      limit: limitDestinationStops,
    );

    if (origins.isEmpty || dests.isEmpty) return null;

    EngineRouteResult? best;
    for (final (od, os) in origins) {
      for (final (dd, dStop) in dests) {
        final res = _search(
          [(os.id, (od / walkingSpeedMps).round())],
          {dStop.id},
          startTimeSec: startTime,
        );
        if (res == null) continue;
        final r = _buildResult(
          res.goal,
          res.prev,
          startTime,
          destAccessSec: (dd / walkingSpeedMps).round(),
        );
        final key = (r.arrivalSec, r.transfers, r.walkingSec);
        if (best == null ||
            _compareTuple(key, (
                  best.arrivalSec,
                  best.transfers,
                  best.walkingSec,
                )) <
                0) {
          best = r;
        }
      }
    }
    return best;
  }

  /// Format a result into a clean, UI-ready map.
  /// Direct port of V4 Python format_result().
  Map<String, dynamic> formatResult(EngineRouteResult? result) {
    if (result == null) {
      return {'found': false, 'message': 'No route found'};
    }

    final segments = <Map<String, dynamic>>[];
    for (final leg in result.legs) {
      final fromName = leg.fromStop == 'ORIGIN'
          ? 'Your location'
          : _canonicalStationName(leg.fromStop);
      final toName = leg.toStop == 'DESTINATION'
          ? 'Destination'
          : _canonicalStationName(leg.toStop);

      // Hide meaningless internal walking inside the same logical station.
      if (leg.isTransfer) {
        if (fromName == toName) continue;
        segments.add({
          'mode': 'walking',
          'title': 'Walk',
          'from': fromName,
          'to': toName,
          'durationMinutes': max(1, (leg.durationSec / 60).round()),
        });
      } else {
        segments.add({
          'mode': leg.mode,
          'title':
              leg.routeName ??
              leg.mode[0].toUpperCase() + leg.mode.substring(1),
          'from': fromName,
          'to': toName,
          'durationMinutes': max(1, (leg.durationSec / 60).round()),
        });
      }
    }

    return {
      'found': true,
      'durationMinutes': max(1, (result.durationSec / 60).round()),
      'walkingMinutes': (result.walkingSec / 60).round(),
      'transfers': result.transfers,
      'segments': segments,
    };
  }

  /// Compare tuples of (int, int, int) for routing priority.
  static int _compareTuple((int, int, int) a, (int, int, int) b) {
    var cmp = a.$1.compareTo(b.$1);
    if (cmp != 0) return cmp;
    cmp = a.$2.compareTo(b.$2);
    if (cmp != 0) return cmp;
    return a.$3.compareTo(b.$3);
  }
}
