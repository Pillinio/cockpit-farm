#!/bin/bash
# Daily cron job:
#   1. Sync PDFs from GDrive → Data_Input/<subfolder>/
#   2. Run auto-ingest.js → parse & push new files into Supabase
# Logs to Data_Input/.gdrive-sync.log and Data_Input/.auto-ingest.log.
#
# Requirements:
#   - scripts/secrets/gdrive-service-account.json  (or GDRIVE_KEY_FILE env)
#   - SUPABASE_SERVICE_KEY env var (set below via ~/.farm-controlling.env)

set -u

REPO="/Users/philipp/Projekte/Farm_Controlling/farm-bonusrechner-1"
cd "$REPO" || exit 1

# Load environment (service key, etc.). File must set SUPABASE_SERVICE_KEY.
if [ -f "$HOME/.farm-controlling.env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.farm-controlling.env"
fi

SYNC_LOG="Data_Input/.gdrive-sync.log"
INGEST_LOG="Data_Input/.auto-ingest.log"

{
  echo ""
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') — GDrive sync ==="
  python3 scripts/sync-gdrive.py 2>&1
} >> "$SYNC_LOG"

{
  echo ""
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') — auto-ingest ==="
  if [ -z "${SUPABASE_SERVICE_KEY:-}" ]; then
    echo "WARN: SUPABASE_SERVICE_KEY not set — skipping auto-ingest"
  else
    node scripts/auto-ingest.js 2>&1
  fi
} >> "$INGEST_LOG"
