from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional, Tuple

@dataclass(frozen=True)
class Stop:
    id: str
    name: str
    lat: float
    lng: float
    station_id: Optional[str] = None
    modes: Tuple[str, ...] = ()

@dataclass(frozen=True)
class Station:
    id: str
    name: str
    lat: float
    lng: float

@dataclass(frozen=True)
class Route:
    id: str
    name: str
    mode: str
    agency_id: Optional[str] = None
    fare: float = 0.0

@dataclass(frozen=True)
class PatternStop:
    stop_id: str
    sequence: int
    arrival_sec: Optional[int] = None
    departure_sec: Optional[int] = None

@dataclass(frozen=True)
class Pattern:
    id: str
    route_id: str
    trip_id: str
    direction_id: Optional[str]
    headsign: Optional[str]
    service_id: Optional[str]
    stops: Tuple[PatternStop, ...]

@dataclass(frozen=True)
class Connection:
    from_stop: str
    to_stop: str
    route_id: Optional[str]
    mode: str
    departure_sec: int
    arrival_sec: int
    distance_m: float = 0.0
    is_transfer: bool = False
    transfer_confidence: Optional[str] = None

@dataclass
class Leg:
    from_stop: str
    to_stop: str
    route_id: Optional[str]
    route_name: Optional[str]
    mode: str
    duration_sec: int
    distance_m: float
    departure_sec: Optional[int] = None
    arrival_sec: Optional[int] = None
    wait_sec: int = 0
    is_transfer: bool = False

@dataclass
class RouteResult:
    departure_sec: int
    arrival_sec: int
    transfers: int
    walking_sec: int
    fare: float
    generalized_cost: float
    legs: list[Leg] = field(default_factory=list)

    @property
    def duration_sec(self) -> int:
        return max(0, self.arrival_sec - self.departure_sec)

    @property
    def duration_minutes(self) -> int:
        return round(self.duration_sec / 60)

    @property
    def walking_minutes(self) -> int:
        return round(self.walking_sec / 60)
