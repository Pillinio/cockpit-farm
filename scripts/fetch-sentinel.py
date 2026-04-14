#!/usr/bin/env python3
"""
fetch-sentinel.py — Fetch Sentinel-2 NDVI imagery for Erichsfelde farm.

Authenticates with Copernicus Sentinel Hub (OAuth2), requests a colored
NDVI image via the Process API, and stores the result as a PNG tile
suitable for Leaflet overlay.

Env vars required:
  COPERNICUS_CLIENT_ID      — Sentinel Hub OAuth2 client ID
  COPERNICUS_CLIENT_SECRET  — Sentinel Hub OAuth2 client secret

Env vars optional:
  SUPABASE_URL              — Supabase project URL
  SUPABASE_SERVICE_KEY      — Supabase service-role key

Output:
  app/data/ndvi-latest.png  — Colored NDVI PNG (512×512, RGBA)
  app/data/ndvi-meta.json   — Metadata (date, bbox, cloud %)
"""

import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

import requests

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

TOKEN_URL = (
    "https://identity.dataspace.copernicus.eu"
    "/auth/realms/CDSE/protocol/openid-connect/token"
)
PROCESS_URL = "https://sh.dataspace.copernicus.eu/api/v1/process"

# Erichsfelde farm bounding box (from KML)
BBOX = [16.82, -21.70, 16.99, -21.55]

# Output paths (relative to repo root)
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
DATA_DIR = REPO_ROOT / "app" / "data"
PNG_PATH = DATA_DIR / "ndvi-latest.png"
META_PATH = DATA_DIR / "ndvi-meta.json"

# Evalscript: compute NDVI from B04/B08, apply color ramp, mask clouds
EVALSCRIPT = """//VERSION=3
function setup() {
  return {
    input: [{ bands: ["B04", "B08", "SCL"], units: "DN" }],
    output: { bands: 4, sampleType: "UINT8" }
  };
}

function evaluatePixel(sample) {
  // Skip clouds (SCL 8,9,10) and no-data (SCL 0)
  if ([0, 8, 9, 10].includes(sample.SCL)) {
    return [0, 0, 0, 0]; // transparent
  }

  var ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);

  // Color ramp: red -> orange -> yellow -> light green -> green -> dark green
  if (ndvi < 0)    return [255, 0, 0, 180];
  if (ndvi < 0.15) return [255, 128, 0, 180];
  if (ndvi < 0.3)  return [255, 255, 0, 180];
  if (ndvi < 0.5)  return [128, 255, 0, 180];
  if (ndvi < 0.7)  return [0, 200, 0, 180];
  return [0, 128, 0, 180];
}
"""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def log(msg: str) -> None:
    """Print timestamped log message."""
    ts = datetime.now(timezone.utc).strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


def get_oauth_token(client_id: str, client_secret: str) -> str:
    """Obtain an OAuth2 access token from Copernicus identity service."""
    log("Requesting OAuth2 token …")
    try:
        resp = requests.post(
            TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": client_id,
                "client_secret": client_secret,
            },
            timeout=30,
        )
    except requests.RequestException as exc:
        raise SystemExit(f"Token request failed (network): {exc}") from exc

    if resp.status_code != 200:
        raise SystemExit(
            f"Token request failed (HTTP {resp.status_code}): {resp.text[:500]}"
        )

    token = resp.json().get("access_token")
    if not token:
        raise SystemExit("Token response missing 'access_token' field.")

    log("OAuth2 token obtained.")
    return token


def request_ndvi_png(token: str, bbox: list, days_back: int = 30) -> bytes:
    """Call Sentinel Hub Process API and return NDVI PNG bytes."""
    now = datetime.now(timezone.utc)
    time_from = (now - timedelta(days=days_back)).strftime("%Y-%m-%dT00:00:00Z")
    time_to = now.strftime("%Y-%m-%dT23:59:59Z")

    log(f"Requesting NDVI image for {time_from[:10]} … {time_to[:10]}")
    log(f"Bounding box: {bbox}")

    payload = {
        "input": {
            "bounds": {
                "bbox": bbox,
                "properties": {
                    "crs": "http://www.opengis.net/def/crs/EPSG/0/4326",
                },
            },
            "data": [
                {
                    "type": "sentinel-2-l2a",
                    "dataFilter": {
                        "timeRange": {"from": time_from, "to": time_to},
                        "maxCloudCoverage": 30,
                    },
                    "processing": {"upsampling": "BILINEAR"},
                }
            ],
        },
        "output": {
            "width": 512,
            "height": 512,
            "responses": [
                {
                    "identifier": "default",
                    "format": {"type": "image/png"},
                }
            ],
        },
        "evalscript": EVALSCRIPT,
    }

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "image/png",
    }

    # Retry up to 3 times with back-off
    last_err = None
    for attempt in range(3):
        try:
            resp = requests.post(
                PROCESS_URL,
                headers=headers,
                json=payload,
                timeout=120,
            )
        except requests.RequestException as exc:
            last_err = exc
            wait = 2 ** attempt * 5
            log(f"Request error (attempt {attempt + 1}/3): {exc}. Retrying in {wait}s …")
            time.sleep(wait)
            continue

        if resp.status_code == 200:
            content_type = resp.headers.get("Content-Type", "")
            if "png" in content_type or len(resp.content) > 1000:
                log(f"Received PNG: {len(resp.content):,} bytes")
                return resp.content
            else:
                raise SystemExit(
                    f"Expected PNG but got {content_type}: {resp.text[:300]}"
                )

        if resp.status_code == 429:
            wait = 2 ** attempt * 10
            log(f"Rate limited (429). Waiting {wait}s …")
            time.sleep(wait)
            continue

        if resp.status_code in (502, 503, 504):
            wait = 2 ** attempt * 5
            log(f"Server error ({resp.status_code}). Retrying in {wait}s …")
            time.sleep(wait)
            continue

        # Non-retryable error
        raise SystemExit(
            f"Process API error (HTTP {resp.status_code}): {resp.text[:500]}"
        )

    raise SystemExit(f"Process API failed after 3 attempts. Last error: {last_err}")


def save_png(data: bytes, path: Path) -> None:
    """Write PNG bytes to disk, creating parent dirs as needed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    log(f"Saved PNG → {path}  ({len(data):,} bytes)")


def save_metadata(path: Path, bbox: list) -> None:
    """Write a small JSON sidecar with fetch metadata."""
    meta = {
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "bbox": bbox,
        "bbox_label": "Erichsfelde farm extent",
        "image_width": 512,
        "image_height": 512,
        "max_cloud_coverage": 30,
        "time_range_days": 30,
        "leaflet_bounds": [[bbox[1], bbox[0]], [bbox[3], bbox[2]]],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    log(f"Saved metadata → {path}")


def update_supabase(supabase_url: str, supabase_key: str) -> None:
    """Upsert an NDVI fetch record into Supabase alert_history."""
    if not supabase_url or not supabase_key:
        log("Supabase credentials not set — skipping DB update.")
        return

    headers = {
        "apikey": supabase_key,
        "Authorization": f"Bearer {supabase_key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates",
    }

    row = {
        "alert_type": "ndvi_fetch",
        "severity": "info",
        "message": f"NDVI image fetched at {datetime.now(timezone.utc).isoformat()}",
        "payload": json.dumps({
            "bbox": BBOX,
            "fetched_at": datetime.now(timezone.utc).isoformat(),
        }),
    }

    try:
        resp = requests.post(
            f"{supabase_url.rstrip('/')}/rest/v1/alert_history",
            headers=headers,
            json=row,
            timeout=15,
        )
        if resp.status_code in (200, 201):
            log("Supabase alert_history updated.")
        else:
            log(f"Supabase insert returned HTTP {resp.status_code}: {resp.text[:200]}")
    except requests.RequestException as exc:
        log(f"Supabase update failed: {exc}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    log("=== Sentinel-2 NDVI fetch for Erichsfelde ===")

    # 1. Read credentials
    client_id = os.environ.get("COPERNICUS_CLIENT_ID", "")
    client_secret = os.environ.get("COPERNICUS_CLIENT_SECRET", "")

    if not client_id or not client_secret:
        log("ERROR: COPERNICUS_CLIENT_ID and COPERNICUS_CLIENT_SECRET must be set.")
        sys.exit(1)

    supabase_url = os.environ.get("SUPABASE_URL", "")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY", "")

    # 2. Authenticate
    token = get_oauth_token(client_id, client_secret)

    # 3. Request NDVI PNG
    png_data = request_ndvi_png(token, BBOX)

    # 4. Save outputs
    save_png(png_data, PNG_PATH)
    save_metadata(META_PATH, BBOX)

    # 5. Update Supabase
    update_supabase(supabase_url, supabase_key)

    log("Done.")


if __name__ == "__main__":
    main()
