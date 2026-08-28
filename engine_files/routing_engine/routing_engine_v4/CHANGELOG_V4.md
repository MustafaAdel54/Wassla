# Routing Engine V4 — Changes

## Critical change: schedule-independent routing

The engine no longer uses vehicle departure times, service calendars, frequencies, waiting time, or the current date/time to decide whether a route exists.

GTFS `stop_times` are still used to estimate the duration of each consecutive stop-to-stop segment. For each `(from_stop, to_stop, route, mode)` edge, the engine uses the median duration observed across the GTFS trips.

The graph is therefore static:

```text
Stop A -- 5 min --> Stop B -- 8 min --> Stop C
```

A search at 03:00 and a search at 15:00 should return the same route and estimated duration.

## Single best route

The engine returns one route only.

Ranking:

1. shortest estimated total journey time
2. fewer transfers on a tie
3. less walking on a tie

## API compatibility

`departure_time_sec` remains accepted by the Python methods only for backwards compatibility. It is intentionally ignored.

The CLI `--departure` argument is also retained but ignored.

## Result cleanup

- Consecutive edges on the same route are merged into one user-facing segment.
- Logical station names are used where available.
- Redundant walking inside the same logical station is hidden from formatted output.
- The response contains one `RouteResult`, not a list of alternatives.
