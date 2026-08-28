# V3 Changes

## Product decision

The router now returns **one route only**.

The primary objective is:

> earliest arrival = shortest total journey time for the requested departure time.

Transfers and walking are tie-breakers only when arrival time is equal.

## Removed behavior

The engine no longer exposes or ranks:

- fastest vs cheapest vs fewest transfers
- balanced generalized cost
- 3–5 alternatives

Those can be reintroduced later as explicit user preferences, but they are not part of the default experience.

## Readability

`Router.format_result()` returns UI-ready segments:

- one segment per transport leg
- same-route consecutive GTFS connections are merged
- logical station names are used where available
- redundant walking inside the same logical station is hidden
- route name + from + to + duration are returned

## Correctness

V3 uses earliest-arrival labels rather than a generalized score that could make a longer journey win because of transfer penalties.

The graph still preserves actual GTFS trip/pattern ordering.
