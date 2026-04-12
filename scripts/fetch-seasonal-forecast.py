#!/usr/bin/env python3
"""
fetch-seasonal-forecast.py — Fetch 6-month seasonal forecast for Erichsfelde farm
and push ensemble percentile statistics to Supabase.

Uses the Open-Meteo Seasonal Forecast API which returns ECMWF SEAS5 data
with 51 ensemble members.  Daily values are aggregated to monthly totals
(precipitation) or monthly means (temperature), then percentiles P5–P95
are computed across all ensemble members.

Farm center coordinates (from KML "Aussengrenze Farm"):
  Latitude:  -21.6056
  Longitude:  16.9011

Target table: seasonal_forecasts
"""

import os
import sys
import time
from collections import defaultdict
from datetime import date, datetime

import requests


# ---------------------------------------------------------------------------
# Retry helper (same pattern as fetch-chirps.py)
# ---------------------------------------------------------------------------

def fetch_with_retry(url, params=None, max_retries=3, timeout=30):
    """Fetch URL with exponential backoff retry."""
    for attempt in range(max_retries):
        try:
            resp = requests.get(url, params=params, timeout=timeout)
            resp.raise_for_status()
            return resp.json()
        except (requests.RequestException, ValueError) as e:
            if attempt < max_retries - 1:
                wait = 2 ** attempt * 5  # 5s, 10s, 20s
                print(f"Retry {attempt+1}/{max_retries} after {wait}s: {e}")
                time.sleep(wait)
            else:
                raise


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

FARM_LAT = -21.6056
FARM_LON = 16.9011

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set", file=sys.stderr)
    sys.exit(1)

# Namibia climatological normals (approximate long-term monthly averages)
# Source: CRU / WorldClim data for Erichsfelde area
# Precipitation in mm/month, Temperature in deg C
CLIMATOLOGY = {
    # month: (precip_mm, temp_c)
    1:  (95.0, 24.5),
    2:  (85.0, 24.0),
    3:  (65.0, 23.0),
    4:  (25.0, 20.5),
    5:  (5.0,  17.5),
    6:  (1.0,  14.5),
    7:  (0.5,  14.0),
    8:  (1.0,  16.5),
    9:  (3.0,  20.0),
    10: (15.0, 23.0),
    11: (35.0, 24.0),
    12: (60.0, 24.5),
}

# Namibia rain season months (October–April)
RAIN_SEASON = {10, 11, 12, 1, 2, 3, 4}


# ---------------------------------------------------------------------------
# Percentile helper (no numpy dependency)
# ---------------------------------------------------------------------------

def percentile(values, pct):
    """Calculate the pct-th percentile of a list of numbers (linear interp)."""
    if not values:
        return None
    s = sorted(values)
    n = len(s)
    k = (pct / 100.0) * (n - 1)
    f = int(k)
    c = f + 1
    if c >= n:
        return round(s[-1], 2)
    d = k - f
    return round(s[f] + d * (s[c] - s[f]), 2)


# ---------------------------------------------------------------------------
# Outlook classification
# ---------------------------------------------------------------------------

def classify_outlook(variable, month, median, clim_mean):
    """Classify the forecast outlook based on Namibia-specific thresholds."""
    if clim_mean is None or clim_mean == 0:
        # For near-zero climatology (dry season precip), skip anomaly
        if variable == "precipitation_mm":
            return "normal", None
        # Temperature: use absolute diff
        if median is None:
            return "normal", None
        diff = median - clim_mean if clim_mean else 0
        if diff > 2:
            return "well_above", None
        elif diff > 1:
            return "above", None
        elif diff < -2:
            return "well_below", None
        elif diff < -1:
            return "below", None
        return "normal", None

    ratio_pct = (median / clim_mean) * 100.0
    anomaly_pct = round(ratio_pct - 100.0, 1)

    if variable == "precipitation_mm" and month in RAIN_SEASON:
        # Precipitation rain-season thresholds for Namibia
        if ratio_pct < 60:
            outlook = "well_below"
        elif ratio_pct < 80:
            outlook = "below"
        elif ratio_pct <= 120:
            outlook = "normal"
        elif ratio_pct <= 150:
            outlook = "above"
        else:
            outlook = "well_above"
    else:
        # Generic thresholds (temperature or dry-season precip)
        if ratio_pct < 80:
            outlook = "well_below"
        elif ratio_pct < 90:
            outlook = "below"
        elif ratio_pct <= 110:
            outlook = "normal"
        elif ratio_pct <= 120:
            outlook = "above"
        else:
            outlook = "well_above"

    return outlook, anomaly_pct


# ---------------------------------------------------------------------------
# Fetch seasonal forecast from Open-Meteo
# ---------------------------------------------------------------------------

def fetch_seasonal_forecast():
    """Fetch 6-month seasonal forecast with all ensemble members."""
    url = "https://seasonal-api.open-meteo.com/v1/seasonal"
    params = {
        "latitude": FARM_LAT,
        "longitude": FARM_LON,
        "daily": "temperature_2m_mean,precipitation_sum",
        "forecast_months": 6,
    }

    print(f"Fetching seasonal forecast from Open-Meteo...")
    print(f"  Location: lat={FARM_LAT}, lon={FARM_LON}")
    data = fetch_with_retry(url, params=params, timeout=60)

    if "daily" not in data or "time" not in data.get("daily", {}):
        raise ValueError(f"Unexpected API response structure: {list(data.keys())}")

    return data


# ---------------------------------------------------------------------------
# Process ensemble data into monthly percentiles
# ---------------------------------------------------------------------------

def process_ensemble_data(data):
    """
    Aggregate daily ensemble data to monthly statistics.

    The API returns:
      - temperature_2m_mean: ensemble mean (daily)
      - temperature_2m_mean_member01..member50: individual members (daily)
      - precipitation_sum: ensemble mean (daily)
      - precipitation_sum_member01..member50: individual members (daily)

    We aggregate each member to monthly values, then compute percentiles
    across all members for each month.
    """
    daily = data["daily"]
    dates = daily["time"]
    forecast_date = dates[0]  # when the forecast starts

    # Discover ensemble member keys
    temp_member_keys = sorted(
        k for k in daily if k.startswith("temperature_2m_mean_member")
    )
    precip_member_keys = sorted(
        k for k in daily if k.startswith("precipitation_sum_member")
    )

    # Include the base key (ensemble mean from API) as an additional member
    # for richer percentile computation
    all_temp_keys = ["temperature_2m_mean"] + temp_member_keys
    all_precip_keys = ["precipitation_sum"] + precip_member_keys

    num_members = len(all_temp_keys)
    print(f"  Ensemble members (incl. mean): {num_members}")
    print(f"  Forecast period: {dates[0]} to {dates[-1]}")

    # --- Aggregate daily values to monthly per member ---
    # Structure: { "YYYY-MM": { member_key: [daily_values] } }
    temp_monthly = defaultdict(lambda: defaultdict(list))
    precip_monthly = defaultdict(lambda: defaultdict(list))

    for i, d in enumerate(dates):
        ym = d[:7]  # "YYYY-MM"
        for key in all_temp_keys:
            val = daily[key][i]
            if val is not None:
                temp_monthly[ym][key].append(val)
        for key in all_precip_keys:
            val = daily[key][i]
            if val is not None:
                precip_monthly[ym][key].append(val)

    # --- Compute per-member monthly aggregates, then cross-member percentiles ---
    rows = []

    for ym in sorted(temp_monthly.keys()):
        month_num = int(ym.split("-")[1])
        target_month = f"{ym}-01"

        # Temperature: monthly mean per member -> percentiles across members
        member_means = []
        for key in all_temp_keys:
            vals = temp_monthly[ym][key]
            if vals:
                member_means.append(sum(vals) / len(vals))

        if member_means:
            clim_precip, clim_temp = CLIMATOLOGY.get(month_num, (None, None))
            p50 = percentile(member_means, 50)
            outlook, anomaly = classify_outlook(
                "temperature_c", month_num, p50, clim_temp
            )
            rows.append({
                "forecast_date": forecast_date,
                "target_month": target_month,
                "variable": "temperature_c",
                "p5": percentile(member_means, 5),
                "p25": percentile(member_means, 25),
                "p50": p50,
                "p75": percentile(member_means, 75),
                "p95": percentile(member_means, 95),
                "climatology_mean": clim_temp,
                "anomaly_pct": anomaly,
                "outlook": outlook,
                "model": "ecmwf-seas5",
            })

        # Precipitation: monthly total per member -> percentiles across members
        member_totals = []
        for key in all_precip_keys:
            vals = precip_monthly[ym][key]
            if vals:
                member_totals.append(sum(vals))

        if member_totals:
            # Floor at zero (small float artifacts possible)
            member_totals = [max(0, v) for v in member_totals]
            clim_precip, clim_temp = CLIMATOLOGY.get(month_num, (None, None))
            p50 = percentile(member_totals, 50)
            outlook, anomaly = classify_outlook(
                "precipitation_mm", month_num, p50, clim_precip
            )
            rows.append({
                "forecast_date": forecast_date,
                "target_month": target_month,
                "variable": "precipitation_mm",
                "p5": percentile(member_totals, 5),
                "p25": percentile(member_totals, 25),
                "p50": p50,
                "p75": percentile(member_totals, 75),
                "p95": percentile(member_totals, 95),
                "climatology_mean": clim_precip,
                "anomaly_pct": anomaly,
                "outlook": outlook,
                "model": "ecmwf-seas5",
            })

    return rows


# ---------------------------------------------------------------------------
# Push to Supabase
# ---------------------------------------------------------------------------

def upsert_to_supabase(rows):
    """Upsert seasonal forecast rows via Supabase PostgREST endpoint."""
    if not rows:
        print("No rows to upsert.")
        return

    url = f"{SUPABASE_URL}/rest/v1/seasonal_forecasts"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates",
    }

    resp = requests.post(url, headers=headers, json=rows, timeout=30)
    if resp.status_code not in (200, 201):
        print(f"ERROR: Supabase returned {resp.status_code}: {resp.text}", file=sys.stderr)
        sys.exit(1)

    print(f"Upserted {len(rows)} seasonal forecast rows.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Verify Supabase connection before main work
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
    }
    test_resp = requests.get(
        f"{SUPABASE_URL}/rest/v1/farms?select=name&limit=1",
        headers=headers, timeout=10,
    )
    if test_resp.status_code != 200:
        raise RuntimeError(f"Supabase auth failed: {test_resp.status_code}")
    print(f"Supabase connected: {test_resp.json()}")

    data = fetch_seasonal_forecast()
    rows = process_ensemble_data(data)

    # Print summary
    print(f"\n--- Seasonal Forecast Summary ---")
    for row in rows:
        symbol = {"well_below": "🔴", "below": "🟡", "normal": "🟢",
                  "above": "🟢", "well_above": "🔵"}.get(row["outlook"], "⚪")
        anom = f"{row['anomaly_pct']:+.1f}%" if row["anomaly_pct"] is not None else "n/a"
        print(f"  {row['target_month']} {row['variable']:>18s}  "
              f"P50={row['p50']:7.1f}  clim={row['climatology_mean'] or 0:7.1f}  "
              f"anom={anom:>7s}  {symbol} {row['outlook']}")

    upsert_to_supabase(rows)
    print("\nDone.")


if __name__ == "__main__":
    main()
