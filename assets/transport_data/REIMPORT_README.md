# Egypt Transit — Clean Transport Data Reimport

This is the clean Firebase transport-data package for the current project.

## Upload these Firestore collections

- agencies — 12
- stations — 61
- stops — 3,186
- routes — 1,014
- route_patterns — 1,789
- transfers — 558

## Do NOT upload as source-of-truth collections

- graph_edges
- routing_tests
- routing_tests_corrected
- summary files

The routing graph is derived by Routing Engine V4 and should be rebuilt from the normalized collections.

## Important routing policy

The new Routing Engine V4 is schedule-independent. GTFS schedule fields may exist in `route_patterns`, but the engine uses them only to estimate stop-to-stop duration. It does NOT use departure time, service date, frequency, waiting time, or current time to decide whether a route exists.

## Development reset

1. Delete the old transport collections from the development Firestore project.
2. Deploy the current project code.
3. Use the protected/admin/debug `Upload Transport Data` action to import these six collections from this package.
4. Verify the document counts above.
5. Run the routing smoke tests.

Never expose the transport-data upload action to normal users.
