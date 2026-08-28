# Transport Data V2 — Firebase-ready

This package contains the normalized Cairo transport dataset built from the uploaded surface + metro GTFS feeds.

## Collections to import
- agencies: 12
- stations: 61
- stops: 3,186
- routes: 1,014
- route_patterns: 1,789
- transfers: 558

`graph_edges` is intentionally **not** part of the default Firestore import. It is derived data for the routing engine and should be rebuilt from the source-of-truth collections when needed.

## Import
```bash
pip install firebase-admin
export GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json
python import_to_firestore.py --input /path/to/transport_data_v2 --project-id YOUR_PROJECT_ID
```

Dry run:
```bash
python import_to_firestore.py --input /path/to/transport_data_v2 --dry-run
```

## Recommended Firestore role
Firestore is the source of truth for transport entities and community contributions.
The routing graph is derived data and should not be treated as the canonical database.

## Production caveats
1. Surface feed service dates are 2025; do not present it as guaranteed-current 2026 data.
2. Metro feed is historical/old; use it for architecture validation until a fresher feed is obtained.
3. Surface↔Metro transfers in `transfers/` are proximity candidates, not verified walking paths.
4. Do not allow client-side writes to official GTFS-derived collections.
