# V2 changes

1. Replaced static edges with scheduled GTFS connections carrying departure and arrival times.
2. Added current-route state to ensure route changes are counted as transfers.
3. Added station expansion: one logical station can map to multiple platform/direction stop IDs.
4. Added walking transfer support from the normalized transfer dataset.
5. Fixed output so waiting time is attached to the transit leg instead of appearing as an empty leg.
6. Merged adjacent segments that use the same transit route.
7. Added alternative-route generation through multiple objectives plus blocked-route reruns.
8. Added tests for station-based routing and deduplicated alternatives.
