from __future__ import annotations
import heapq
import itertools
from dataclasses import dataclass
from math import inf
from .models import RouteResult, Leg, Connection
from .geo import haversine_m
from .loaders import Dataset

WALKING_SPEED_MPS = 1.35
TRANSFER_PENALTY_SEC = 4 * 60
MAX_ACCESS_RADIUS_M = 1800

@dataclass(frozen=True)
class SearchState:
    stop_id: str
    current_route_id: str | None

class Router:
    """Schedule-independent static transit router.

    V4 policy: return ONE best route only.
    GTFS schedules are used only to estimate segment durations.
    Vehicle departure times, service calendars, frequencies and waiting
    times are deliberately ignored.

    Primary objective: shortest estimated journey time.
    Tie-breakers: fewer transfers, then less walking.
    """
    def __init__(self, dataset: Dataset):
        self.ds = dataset

    def nearest_stops(self, lat: float, lng: float, radius_m: float = MAX_ACCESS_RADIUS_M, limit: int = 12):
        vals=[]
        for s in self.ds.stops.values():
            d=haversine_m(lat,lng,s.lat,s.lng)
            if d <= radius_m:
                vals.append((d,s))
        vals.sort(key=lambda x:x[0])
        return vals[:limit]

    def _expand_location_id(self, location_id: str) -> set[str]:
        if location_id in self.ds.stops:
            return {location_id}
        if location_id in self.ds.stations:
            return {s.id for s in self.ds.stops.values() if s.station_id == location_id}
        raise ValueError(f"Unknown stop/station id: {location_id}")

    def _best_label(self, arrival, transfers, walking):
        # Earliest arrival is the ONLY primary objective.
        # Transfers and walking are deterministic tie-breakers only.
        return (arrival, transfers, walking)

    def _search(self, starts, dest_ids, start_time_sec=0, blocked_routes=None, max_states=300000):
        blocked_routes = blocked_routes or set()
        pq=[]
        counter=itertools.count()
        best={}
        prev={}
        seen=0

        for sid, access_sec in starts:
            arr=start_time_sec+access_sec
            st=SearchState(sid,None)
            label=(arr,0,access_sec)
            old=best.get(st)
            if old is None or self._best_label(*label) < old:
                best[st]=self._best_label(*label)
                prev[st]=(None,None,{
                    'arrival_before': start_time_sec,
                    'arrival_after': arr,
                    'walking_total': access_sec,
                    'transfers': 0,
                    'wait': 0,
                    'access_sec': access_sec,
                })
                heapq.heappush(pq,(best[st],next(counter),st))

        goal=None
        while pq and seen < max_states:
            key,_,state=heapq.heappop(pq)
            if best.get(state) != key:
                continue
            seen += 1

            if state.stop_id in dest_ids:
                goal=state
                break

            current_label=key
            arrival, transfers, walking=current_label

            for c in self.ds.connections_by_from.get(state.stop_id,[]):
                if (not c.is_transfer) and c.route_id in blocked_routes:
                    continue

                if c.is_transfer:
                    n_arrival=arrival+c.arrival_sec
                    n_transfers=transfers
                    n_walking=walking+c.arrival_sec
                    n_route=state.current_route_id
                    wait=0
                    transfer_penalty=0
                else:
                    # Static graph: c.arrival_sec is edge duration, not a clock time.
                    wait=0
                    switched=(state.current_route_id is not None and state.current_route_id != c.route_id)
                    n_transfers=transfers+(1 if switched else 0)
                    transfer_penalty=TRANSFER_PENALTY_SEC if switched else 0
                    n_arrival=arrival+c.arrival_sec+transfer_penalty
                    n_walking=walking
                    n_route=c.route_id

                ns=SearchState(c.to_stop,n_route)
                nl=self._best_label(n_arrival,n_transfers,n_walking)
                if nl >= best.get(ns,(inf,inf,inf)):
                    continue
                best[ns]=nl
                prev[ns]=(state,c,{
                    'arrival_before': arrival,
                    'arrival_after': n_arrival,
                    'walking_total': n_walking,
                    'transfers': n_transfers,
                    'wait': wait,
                    'transfer_penalty': transfer_penalty,
                })
                heapq.heappush(pq,(nl,next(counter),ns))

        if goal is None:
            return None
        return goal, prev

    def _stop_name(self, stop_id: str) -> str:
        s=self.ds.stops.get(stop_id)
        if not s:
            return stop_id
        return s.name

    def _canonical_station_name(self, stop_id: str) -> str:
        s=self.ds.stops.get(stop_id)
        if s and s.station_id and s.station_id in self.ds.stations:
            return self.ds.stations[s.station_id].name
        return self._stop_name(stop_id)

    def _build_result(self, goal, prev, start_time_sec, dest_access_sec=0):
        """Convert a static-graph path into one clean user-facing result."""
        steps=[]
        cur=goal
        initial_access=0
        first_stop_id=None
        while True:
            p,c,meta=prev[cur]
            if p is None:
                initial_access=int(meta.get('access_sec',0))
                first_stop_id=cur.stop_id
                break
            steps.append((p,cur,c,meta))
            cur=p
        steps.reverse()

        legs=[]
        walking_sec=initial_access
        transfers=0
        fare=0.0
        last_route=None
        elapsed=start_time_sec

        if initial_access:
            legs.append(Leg(
                from_stop='ORIGIN',
                to_stop=first_stop_id,
                route_id=None,
                route_name=None,
                mode='walking',
                duration_sec=initial_access,
                distance_m=initial_access*WALKING_SPEED_MPS,
                departure_sec=elapsed,
                arrival_sec=elapsed+initial_access,
                wait_sec=0,
                is_transfer=True,
            ))
            elapsed += initial_access

        for p,st,c,meta in steps:
            if c.is_transfer:
                dur=c.arrival_sec
                legs.append(Leg(
                    from_stop=c.from_stop,
                    to_stop=c.to_stop,
                    route_id=None,
                    route_name=None,
                    mode='walking',
                    duration_sec=dur,
                    distance_m=c.distance_m,
                    departure_sec=elapsed,
                    arrival_sec=elapsed+dur,
                    wait_sec=0,
                    is_transfer=True,
                ))
                elapsed += dur
                walking_sec += dur
                continue

            switched=(last_route is not None and last_route != c.route_id)
            transfer_penalty=TRANSFER_PENALTY_SEC if switched else 0
            if switched:
                transfers += 1
            last_route=c.route_id

            # Static edge: c.arrival_sec is estimated duration, c.departure_sec is 0.
            travel_sec=max(0,c.arrival_sec)
            dep=elapsed
            elapsed += transfer_penalty + travel_sec

            new_leg=Leg(
                from_stop=c.from_stop,
                to_stop=c.to_stop,
                route_id=c.route_id,
                route_name=self.ds.routes[c.route_id].name if c.route_id in self.ds.routes else None,
                mode=c.mode,
                duration_sec=travel_sec + transfer_penalty,
                distance_m=c.distance_m,
                departure_sec=dep,
                arrival_sec=elapsed,
                wait_sec=0,
                is_transfer=False,
            )

            if legs and (not legs[-1].is_transfer) and legs[-1].route_id == new_leg.route_id and legs[-1].mode == new_leg.mode:
                legs[-1].to_stop=new_leg.to_stop
                legs[-1].duration_sec += new_leg.duration_sec
                legs[-1].distance_m += new_leg.distance_m
                legs[-1].arrival_sec=new_leg.arrival_sec
            else:
                legs.append(new_leg)

        if dest_access_sec:
            walking_sec += dest_access_sec
            legs.append(Leg(
                from_stop=goal.stop_id,
                to_stop='DESTINATION',
                route_id=None,
                route_name=None,
                mode='walking',
                duration_sec=dest_access_sec,
                distance_m=dest_access_sec*WALKING_SPEED_MPS,
                departure_sec=elapsed,
                arrival_sec=elapsed+dest_access_sec,
                wait_sec=0,
                is_transfer=True,
            ))
            elapsed += dest_access_sec

        # Merge consecutive walking legs and hide zero-distance/internal hops later in formatting.
        cleaned=[]
        for leg in legs:
            if cleaned and leg.is_transfer and cleaned[-1].is_transfer and cleaned[-1].mode == 'walking':
                cleaned[-1].to_stop=leg.to_stop
                cleaned[-1].duration_sec += leg.duration_sec
                cleaned[-1].distance_m += leg.distance_m
                cleaned[-1].arrival_sec=leg.arrival_sec
            else:
                cleaned.append(leg)
        legs=cleaned

        return RouteResult(
            departure_sec=start_time_sec,
            arrival_sec=elapsed,
            transfers=transfers,
            walking_sec=walking_sec,
            fare=fare,
            generalized_cost=elapsed-start_time_sec,
            legs=legs,
        )

    def _route_stops(self, origin_stop_id, destination_stop_id, start_time):
        # start_time is retained only for API compatibility and is ignored.
        start_time = 0
        res=self._search([(origin_stop_id,0)],{destination_stop_id},start_time)
        if not res:
            return None
        goal,prev=res
        return self._build_result(goal,prev,start_time,0)

    def route_between_stop_ids(self, origin_stop_id, destination_stop_id, departure_time_sec=0):
        # V4 is schedule-independent: departure_time_sec is intentionally ignored.
        origins=self._expand_location_id(origin_stop_id)
        dests=self._expand_location_id(destination_stop_id)
        best=None
        for o in origins:
            for d in dests:
                res=self._route_stops(o,d,departure_time_sec)
                if res is None:
                    continue
                key=(res.arrival_sec,res.transfers,res.walking_sec)
                if best is None or key < (best.arrival_sec,best.transfers,best.walking_sec):
                    best=res
        return best

    def route(self, origin_lat,origin_lng,dest_lat,dest_lng,departure_time_sec=0,access_radius_m=MAX_ACCESS_RADIUS_M,limit_origin_stops=10,limit_destination_stops=10):
        # V4 is schedule-independent: departure_time_sec is intentionally ignored.
        departure_time_sec = 0
        origins=self.nearest_stops(origin_lat,origin_lng,access_radius_m,limit_origin_stops)
        dests=self.nearest_stops(dest_lat,dest_lng,access_radius_m,limit_destination_stops)
        if not origins or not dests:
            return None
        best=None
        for od,os in origins:
            for dd,ds in dests:
                res=self._search(
                    [(os.id,int(round(od/WALKING_SPEED_MPS)))],
                    {ds.id},
                    departure_time_sec,
                )
                if not res:
                    continue
                goal,prev=res
                r=self._build_result(
                    goal,
                    prev,
                    departure_time_sec,
                    int(round(dd/WALKING_SPEED_MPS)),
                )
                key=(r.arrival_sec,r.transfers,r.walking_sec)
                if best is None or key < (best.arrival_sec,best.transfers,best.walking_sec):
                    best=r
        return best

    def format_result(self, result: RouteResult) -> dict:
        """Return one clean, UI-ready recommendation."""
        if result is None:
            return {'found': False, 'message': 'No route found'}

        segments=[]
        for leg in result.legs:
            from_name = 'Your location' if leg.from_stop == 'ORIGIN' else self._canonical_station_name(leg.from_stop)
            to_name = 'Destination' if leg.to_stop == 'DESTINATION' else self._canonical_station_name(leg.to_stop)

            # Hide meaningless internal walking inside the same logical station.
            if leg.is_transfer:
                if from_name == to_name:
                    continue
                segments.append({
                    'mode': 'walking',
                    'title': 'Walk',
                    'from': from_name,
                    'to': to_name,
                    'durationMinutes': max(1, round(leg.duration_sec / 60)),
                })
            else:
                segments.append({
                    'mode': leg.mode,
                    'title': leg.route_name or leg.mode.title(),
                    'from': from_name,
                    'to': to_name,
                    'durationMinutes': max(1, round(leg.duration_sec / 60)),
                })

        return {
            'found': True,
            'durationMinutes': max(1, round(result.duration_sec / 60)),
            'walkingMinutes': round(result.walking_sec / 60),
            'transfers': result.transfers,
            'segments': segments,
        }
