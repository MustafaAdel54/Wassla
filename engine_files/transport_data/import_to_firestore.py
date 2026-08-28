#!/usr/bin/env python3
"""Import normalized transport_data_v2 into Firestore.

Usage:
  pip install firebase-admin
  export GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json
  python import_to_firestore.py --input ./transport_data_v2 --project-id YOUR_PROJECT_ID

The script uses Firestore batched writes (max 400 ops/batch) and upserts documents.
It intentionally does NOT import graph_edges by default because graph edges are derived data.
Use --include-graph-edges only when you explicitly want them in Firestore.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

COLLECTIONS = (
    "agencies",
    "stations",
    "stops",
    "routes",
    "route_patterns",
    "transfers",
)


def load_doc(path: Path) -> tuple[str, dict[str, Any]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    doc_id = raw.get("id")
    if not isinstance(doc_id, str) or not doc_id:
        raise ValueError(f"Missing id in {path}")
    data = raw.get("data")
    if not isinstance(data, dict):
        raise ValueError(f"Missing data object in {path}")
    return doc_id, data


def iter_docs(root: Path, collection: str):
    folder = root / collection
    if not folder.exists():
        return
    for path in sorted(folder.glob("*.json")):
        yield load_doc(path)


def batched(items, size: int = 400):
    batch = []
    for item in items:
        batch.append(item)
        if len(batch) >= size:
            yield batch
            batch = []
    if batch:
        yield batch


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--project-id", default=None)
    parser.add_argument("--include-graph-edges", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    root = Path(args.input).resolve()
    collections = list(COLLECTIONS)
    if args.include_graph_edges:
        collections.append("graph_edges")

    db = None
    if not args.dry_run:
        import firebase_admin
        from firebase_admin import credentials, firestore

        if not firebase_admin._apps:
            if args.project_id:
                firebase_admin.initialize_app(options={"projectId": args.project_id})
            else:
                firebase_admin.initialize_app()
        db = firestore.client()

    totals: dict[str, int] = {}
    for collection in collections:
        docs = list(iter_docs(root, collection))
        totals[collection] = len(docs)
        print(f"{collection}: {len(docs)} documents")
        if args.dry_run or not docs:
            continue

        for chunk in batched(docs):
            batch = db.batch()
            for doc_id, data in chunk:
                batch.set(db.collection(collection).document(doc_id), data, merge=True)
            batch.commit()
            print(f"  committed {len(chunk)}")

    print("\nImport complete")
    print(json.dumps(totals, indent=2))


if __name__ == "__main__":
    main()
