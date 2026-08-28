# Egypt Transit — Firebase Asset Sync V5

This document defines the new shared-data requirement introduced for the new application.

## Objective

All app installations must share the same remote transport dataset.

Firebase is the remote source of truth. Each phone keeps a persistent local copy so the application starts quickly and does not redownload the complete dataset on every run.

## Recommended separation

Use Firebase services according to responsibility:

```text
Firestore
  → dataset/manifest metadata
  → lightweight searchable/structured metadata where appropriate

Cloud Storage
  → large dataset files/assets

Local persistent storage
  → downloaded files/assets
  → local manifest metadata
  → cached/processed routing dataset
```

The exact Firebase collection/bucket names are implementation details and should not leak into domain models.

## Manifest concept

Maintain a lightweight remote manifest describing the current dataset.

Conceptually:

```text
DatasetManifest
├── datasetVersion
├── updatedAt
└── assets[]
    ├── assetId
    ├── logicalPath
    ├── size
    ├── contentHash
    └── datasetVersion
```

The local device stores the same manifest information (or the minimum subset required for comparison).

## Startup behavior

### Existing installation

```text
Open app
   ↓
Read local manifest/data
   ↓
App becomes usable immediately from local data
   ↓
Async remote manifest check
   ↓
Compare manifests
   ↓
No differences?
   → Do nothing

Differences?
   ↓
Download only missing/changed assets
   ↓
Validate download
   ↓
Write new local data safely
   ↓
Update local manifest
   ↓
Trigger one dataset-changed event
   ↓
Rebuild/reinitialize routing data if required
```

### First installation

If required local data is not present:

```text
Open app
↓
Detect missing required dataset
↓
Show bootstrap/loading UI
↓
Download required dataset from Firebase
↓
Validate + persist
↓
Initialize V4 routing data
↓
Open normal route-search UI
```

This is the only case where a full initial dataset download is expected.

## Critical non-negotiable behavior

The app must NOT:

- download every asset on every startup
- clear and redownload the full dataset just because the app was reopened
- rebuild the routing graph on every startup when the dataset is unchanged
- block the UI while checking the remote manifest
- make route search responsible for Firebase synchronization

## Incremental update rules

### New asset

Remote manifest has an assetId the local manifest does not have.

Action:
- download that asset only
- validate it
- persist it
- update local manifest

### Changed asset

The remote assetId exists locally but the content/version/hash differs.

Action:
- download the changed asset only
- validate it
- replace the local version atomically
- update local manifest

### Unchanged asset

The remote and local metadata match.

Action:
- do not download it
- do not rewrite it

### Failed update

If a new/changed asset fails validation or download:

- keep the previous valid local copy
- keep the previous valid local manifest
- report/log the sync failure
- do not destroy a working dataset

## Atomic dataset update

Do not partially replace the active dataset while the app is using it.

Use a safe staging/update flow:

```text
current dataset
      ↓
new assets downloaded to staging
      ↓
validate
      ↓
commit new dataset metadata/files
      ↓
activate new dataset
```

The exact storage mechanism is an implementation detail.

## Graph invalidation rule

The V4 engine graph is derived from the transport dataset.

Therefore:

```text
Dataset unchanged
→ reuse existing graph

Dataset changed in relevant routing data
→ invalidate graph
→ rebuild once
→ cache the rebuilt graph
```

Avoid rebuilding the graph for changes that do not affect routing data when the implementation can safely determine that.

## User-generated data later

The architecture must allow future user-created transport data to be written to Firebase through repositories/use cases.

Other installations must be able to consume approved/new shared data through the same synchronization mechanism.

Do not tightly couple future user-generated data writes to the route-search UI.

## Temporary developer/admin upload flow

The new app should include a development-only/admin-only path capable of:

```text
Bundled/local assets
      ↓
Developer/Admin action
      ↓
Upload assets to Cloud Storage
      ↓
Publish/update Firestore manifest
      ↓
Other phones detect new manifest
      ↓
Only required assets download
```

The upload action must be clearly separated from ordinary end-user UX and must be easy to remove/disable before production.

## Security boundary

Do not make a permanent public client-side "upload everything" button in production.

The final production design should use a properly authorized Firebase write path for administrative publishing/user-generated writes. The exact authorization design can be implemented after the first functional slice, but the architecture must not assume unrestricted client writes.

## Testing matrix

1. Fresh install, no local data → bootstrap download works.
2. Reopen app with unchanged manifest → zero asset downloads.
3. Remote adds one file → exactly one file downloads.
4. Remote changes one file → exactly one file downloads.
5. Remote unchanged but app opened 20 times → no repeated full downloads.
6. Partial network failure → old dataset remains usable.
7. Successful routing-data update → graph updates once.
8. User on another phone sees the newly published dataset after sync.
9. Route search shows loading and UI remains responsive while routing runs.
10. Developer/admin import publishes assets and manifest correctly.
