from __future__ import annotations
import json
from pathlib import Path
from collections import defaultdict
from statistics import median
from .models import Stop, Route, Pattern, PatternStop, Connection, Station
from .geo import haversine_m

class Dataset:
    def __init__(self):
        self.stops: dict[str, Stop] = {}
        self.stations: dict[str, Station] = {}
        self.routes: dict[str, Route] = {}
        self.patterns: dict[str, Pattern] = {}
        self.connections_by_from: dict[str, list[Connection]] = defaultdict(list)
        self.transfers: list[Connection] = []

    def add_connection(self, c: Connection) -> None:
        self.connections_by_from[c.from_stop].append(c)

    def finalize(self) -> None:
        for k in self.connections_by_from:
            self.connections_by_from[k].sort(key=lambda c: (c.departure_sec, c.arrival_sec))


def _files(path: Path, folder: str):
    return (path / folder).glob('*.json')


def load_dataset(root: str | Path) -> Dataset:
    root = Path(root)
    ds = Dataset()
    for f in _files(root, 'stops'):
        w = json.loads(f.read_text())
        o = w['data']
        ds.stops[w['id']] = Stop(w['id'], o['name'], float(o['lat']), float(o['lng']), o.get('stationId'), tuple(o.get('transportModes', [])))
    for f in _files(root, 'stations'):
        w = json.loads(f.read_text()); o = w['data']
        ds.stations[w['id']] = Station(w['id'], o['name'], float(o['lat']), float(o['lng']))
    for f in _files(root, 'routes'):
        w = json.loads(f.read_text()); o = w['data']
        ds.routes[w['id']] = Route(w['id'], o['name'], o['transportMode'], o.get('agencyId'))
    for f in _files(root, 'route_patterns'):
        w = json.loads(f.read_text()); o = w['data']
        ps = tuple(PatternStop(s['stopId'], int(s['sequence']), s.get('arrivalSec'), s.get('departureSec')) for s in o['stops'])
        ds.patterns[w['id']] = Pattern(w['id'], o['routeId'], o.get('tripId', w['id']), o.get('directionId'), o.get('headsign'), o.get('serviceId'), ps)
    # Build a STATIC, schedule-independent transit graph.
    # GTFS stop_times are used only to estimate segment duration.
    # Departure times, service calendars, frequencies and waiting times are
    # intentionally NOT used by the routing search.
    duration_samples = defaultdict(list)
    distance_by_edge = {}

    for p in ds.patterns.values():
        ps = sorted(p.stops, key=lambda x: x.sequence)
        route = ds.routes.get(p.route_id)
        mode = route.mode if route else 'unknown'
        for a, b in zip(ps, ps[1:]):
            if a.stop_id == b.stop_id or a.departure_sec is None or b.arrival_sec is None:
                continue
            dep, arr = int(a.departure_sec), int(b.arrival_sec)
            if arr < dep:
                arr += 86400
            duration = arr - dep
            if duration <= 0:
                continue
            key = (a.stop_id, b.stop_id, p.route_id, mode)
            duration_samples[key].append(duration)
            sa, sb = ds.stops.get(a.stop_id), ds.stops.get(b.stop_id)
            distance_by_edge[key] = haversine_m(sa.lat, sa.lng, sb.lat, sb.lng) if sa and sb else 0.0

    # Median duration is robust to outlier trips. Each edge is now static:
    # departure_sec=0 and arrival_sec=estimated segment duration.
    for key, samples in duration_samples.items():
        a, b, route_id, mode = key
        duration = max(1, int(round(median(samples))))
        ds.add_connection(
            Connection(a, b, route_id, mode, 0, duration,
                       distance_by_edge.get(key, 0.0), False, None)
        )
    # Existing transfer candidates are duplicated in both directions and kept time-independent.
    for f in _files(root, 'transfers'):
        w = json.loads(f.read_text()); o = w['data']
        a, b = o.get('fromStopId'), o.get('toStopId')
        if a not in ds.stops or b not in ds.stops:
            continue
        mins = int(o.get('estimatedMinutes', max(1, round(float(o.get('distanceMeters', 100.0))/80.0))))
        sec = mins * 60
        dist = float(o.get('distanceMeters', 0.0))
        for x,y in ((a,b),(b,a)):
            c = Connection(x, y, None, 'walking', 0, sec, dist, True, o.get('confidence'))
            ds.transfers.append(c); ds.add_connection(c)
    ds.finalize()
    return ds
