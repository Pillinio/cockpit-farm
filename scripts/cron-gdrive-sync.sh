#!/bin/bash
# GDrive sync cron job — runs daily, logs to Data_Input/.gdrive-sync.log
cd /Users/philipp/Projekte/Farm_Controlling/farm-bonusrechner-1
echo "=== $(date) ===" >> Data_Input/.gdrive-sync.log
python3 scripts/sync-gdrive.py 2>&1 >> Data_Input/.gdrive-sync.log
