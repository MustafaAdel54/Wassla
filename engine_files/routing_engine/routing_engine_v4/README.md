# Routing Engine V4 — Schedule Independent

This engine returns one best route based on the static transport network.

## Critical policy

Vehicle departure times, service calendars, frequencies, waiting time and the current date/time are NOT used for route existence or route ranking. GTFS stop_times are used only to estimate the duration of each consecutive stop-to-stop segment.

The engine returns one route only:
1. shortest estimated total journey time
2. fewer transfers on ties
3. less walking on ties

## Data
Use the normalized transport data package supplied with the project. The graph is derived from routes, route patterns, stops and transfers.

## CLI
```bash
python route_cli.py <data_dir> <origin_stop_or_station_id> <destination_stop_or_station_id>
```

The optional `--departure` argument is accepted for backwards compatibility but intentionally ignored.
