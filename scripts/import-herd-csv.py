#!/usr/bin/env python3
"""
import-herd-csv.py — Import herd CSV from farm management system into herd_animals table.

Reads a CSV exported from the herd management system with columns:
  #, IDnr, Sex, Sire, Dam, Traceability No, lWDate, lWgt, Birthdate, # Calvings, pLCDat, p#Wean

Usage:
    python3 scripts/import-herd-csv.py /path/to/Herde-29-07-25.csv

Uses the Supabase Management API for database access.
"""

import csv
import io
import json
import sys
from datetime import date, datetime

import requests


# ---------------------------------------------------------------------------
# Configuration — Supabase Management API
# ---------------------------------------------------------------------------

API = "https://api.supabase.com/v1/projects/vhwlcnfxslkftswksqrw/database/query"
TOKEN = "sbp_f7ebf70138f3d904bef2d63ee80a3f268a1a1c85"
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
}


def run_sql(sql: str):
    """Execute SQL via the Supabase Management API and return the result."""
    resp = requests.post(API, headers=HEADERS, json={"query": sql}, timeout=60)
    if resp.status_code not in (200, 201):
        print(f"SQL ERROR ({resp.status_code}): {resp.text[:500]}", file=sys.stderr)
        sys.exit(1)
    return resp.json()


# ---------------------------------------------------------------------------
# CSV parsing
# ---------------------------------------------------------------------------

def parse_date(val: str) -> str | None:
    """Parse YYYY/MM/DD date to ISO format YYYY-MM-DD, or return None."""
    if not val or not val.strip():
        return None
    val = val.strip()
    try:
        dt = datetime.strptime(val, "%Y/%m/%d")
        return dt.strftime("%Y-%m-%d")
    except ValueError:
        return None


def parse_int(val: str) -> int | None:
    """Parse integer value, or return None."""
    if not val or not val.strip():
        return None
    try:
        return int(val.strip())
    except ValueError:
        return None


def parse_weight(val: str) -> float | None:
    """Parse weight value (kg), or return None."""
    if not val or not val.strip():
        return None
    try:
        return float(val.strip())
    except ValueError:
        return None


def parse_csv(filepath: str) -> list[dict]:
    """Parse the herd CSV file, skipping preamble lines until the header row."""
    animals = []

    with open(filepath, "r", encoding="utf-8-sig") as f:
        lines = f.readlines()

    # Find header row (contains "IDnr")
    header_idx = None
    for i, line in enumerate(lines):
        if "IDnr" in line:
            header_idx = i
            break

    if header_idx is None:
        print("ERROR: Could not find header row with 'IDnr' column", file=sys.stderr)
        sys.exit(1)

    # Parse from header onwards
    reader = csv.DictReader(lines[header_idx:])

    for row in reader:
        animal_id = row.get("IDnr", "").strip()
        if not animal_id:
            continue

        sex = row.get("Sex", "").strip().upper()
        if sex not in ("M", "F"):
            print(f"  SKIP: {animal_id} — invalid sex '{sex}'")
            continue

        animals.append({
            "animal_id": animal_id,
            "sex": sex,
            "sire": row.get("Sire", "").strip() or None,
            "dam": row.get("Dam", "").strip() or None,
            "traceability_no": row.get("Traceability No", "").strip() or None,
            "birth_date": parse_date(row.get("Birthdate", "")),
            "last_weigh_date": parse_date(row.get("lWDate", "")),
            "last_weight_kg": parse_weight(row.get("lWgt", "")),
            "calvings": parse_int(row.get("# Calvings", "")) or 0,
        })

    return animals


# ---------------------------------------------------------------------------
# Database upsert
# ---------------------------------------------------------------------------

def escape_sql(val) -> str:
    """Escape a value for SQL insertion."""
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    # Escape single quotes
    return "'" + str(val).replace("'", "''") + "'"


def upsert_animals(animals: list[dict]) -> dict:
    """Upsert animals into herd_animals via SQL. Returns stats dict."""
    if not animals:
        return {"imported": 0, "updated": 0, "skipped": 0}

    # Build a single upsert statement using INSERT ... ON CONFLICT
    # Process in batches of 50 to avoid overly long SQL statements
    batch_size = 50
    total_affected = 0

    for i in range(0, len(animals), batch_size):
        batch = animals[i:i + batch_size]

        values_parts = []
        for a in batch:
            vals = (
                f"(default_farm_id(), "
                f"{escape_sql(a['animal_id'])}, "
                f"{escape_sql(a['sex'])}, "
                f"{escape_sql(a['sire'])}, "
                f"{escape_sql(a['dam'])}, "
                f"{escape_sql(a['traceability_no'])}, "
                f"{escape_sql(a['birth_date'])}::date, "
                f"{escape_sql(a['last_weigh_date'])}::date, "
                f"{escape_sql(a['last_weight_kg'])}::numeric, "
                f"{a['calvings']}, "
                f"true, now(), now())"
            )
            values_parts.append(vals)

        sql = f"""
INSERT INTO herd_animals
  (farm_id, animal_id, sex, sire, dam, traceability_no,
   birth_date, last_weigh_date, last_weight_kg, calvings,
   active, created_at, updated_at)
VALUES
  {', '.join(values_parts)}
ON CONFLICT (farm_id, animal_id) DO UPDATE SET
  sex = EXCLUDED.sex,
  sire = EXCLUDED.sire,
  dam = EXCLUDED.dam,
  traceability_no = EXCLUDED.traceability_no,
  birth_date = EXCLUDED.birth_date,
  last_weigh_date = EXCLUDED.last_weigh_date,
  last_weight_kg = EXCLUDED.last_weight_kg,
  calvings = EXCLUDED.calvings,
  active = true,
  updated_at = now();
"""
        result = run_sql(sql)
        batch_num = i // batch_size + 1
        total_batches = (len(animals) + batch_size - 1) // batch_size
        print(f"  Batch {batch_num}/{total_batches}: {len(batch)} records")

    return {"total": len(animals)}


# ---------------------------------------------------------------------------
# Update herd_snapshots with current totals
# ---------------------------------------------------------------------------

def update_snapshot():
    """Insert/update a herd_snapshots row with counts derived from herd_animals."""
    today = date.today().isoformat()

    sql = f"""
INSERT INTO herd_snapshots (farm_id, snapshot_date, cows, bulls, heifers, calves, oxen, total_lsu, notes)
SELECT
  default_farm_id(),
  '{today}'::date,
  -- Cows: female with calvings > 0
  COUNT(*) FILTER (WHERE sex = 'F' AND calvings > 0),
  -- Bulls: male 24+ months
  COUNT(*) FILTER (WHERE sex = 'M' AND birth_date <= CURRENT_DATE - INTERVAL '24 months'),
  -- Heifers: female 18+ months, 0 calvings
  COUNT(*) FILTER (WHERE sex = 'F' AND calvings = 0 AND birth_date <= CURRENT_DATE - INTERVAL '18 months'),
  -- Calves: < 12 months
  COUNT(*) FILTER (WHERE birth_date > CURRENT_DATE - INTERVAL '12 months'),
  -- Oxen: placeholder (we don't track castration status)
  0,
  -- LSU approximation: adults=1.0, young=0.7, calves=0.4
  ROUND(
    COUNT(*) FILTER (WHERE birth_date <= CURRENT_DATE - INTERVAL '18 months') * 1.0 +
    COUNT(*) FILTER (WHERE birth_date > CURRENT_DATE - INTERVAL '18 months' AND birth_date <= CURRENT_DATE - INTERVAL '6 months') * 0.7 +
    COUNT(*) FILTER (WHERE birth_date > CURRENT_DATE - INTERVAL '6 months') * 0.4,
    1
  ),
  'Auto-generated from herd_animals CSV import'
FROM herd_animals
WHERE active = true
ON CONFLICT (farm_id, snapshot_date) DO UPDATE SET
  cows = EXCLUDED.cows,
  bulls = EXCLUDED.bulls,
  heifers = EXCLUDED.heifers,
  calves = EXCLUDED.calves,
  oxen = EXCLUDED.oxen,
  total_lsu = EXCLUDED.total_lsu,
  notes = EXCLUDED.notes,
  updated_at = now();
"""
    run_sql(sql)
    print(f"  Snapshot updated for {today}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 import-herd-csv.py <path-to-csv>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    print(f"Parsing CSV: {filepath}")

    animals = parse_csv(filepath)
    print(f"Parsed {len(animals)} animals from CSV")

    if not animals:
        print("No animals found. Check the CSV format.")
        sys.exit(1)

    print("Upserting to herd_animals...")
    stats = upsert_animals(animals)
    print(f"Done: {stats['total']} animals upserted")

    print("Updating herd_snapshots...")
    update_snapshot()

    # Print summary stats
    result = run_sql("""
        SELECT
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE sex = 'F') as females,
            COUNT(*) FILTER (WHERE sex = 'M') as males,
            COUNT(*) FILTER (WHERE last_weight_kg IS NOT NULL) as with_weight,
            ROUND(AVG(last_weight_kg) FILTER (WHERE last_weight_kg IS NOT NULL), 1) as avg_weight
        FROM herd_animals WHERE active = true;
    """)
    if result:
        r = result[0]
        print(f"\nHerd summary:")
        print(f"  Total active: {r['total']}")
        print(f"  Females: {r['females']}")
        print(f"  Males: {r['males']}")
        print(f"  With weight data: {r['with_weight']}")
        print(f"  Avg weight (weighed): {r['avg_weight']} kg")


if __name__ == "__main__":
    main()
