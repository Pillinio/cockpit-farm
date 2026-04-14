#!/usr/bin/env python3
"""
sync-gdrive.py — Sync bank statements and income statements from Google Drive.

Downloads new/updated files from the shared GDrive folder into Data_Input/,
organized by type and year.

Env vars (optional, defaults to local paths):
  GDRIVE_KEY_FILE   — Path to service account JSON key
  GDRIVE_FOLDER_ID  — Root folder ID in Google Drive

Usage:
  python3 scripts/sync-gdrive.py              # sync all new files
  python3 scripts/sync-gdrive.py --list       # list remote files only
  python3 scripts/sync-gdrive.py --year 2026  # sync only 2026 files
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io

# ── Config ───────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DATA_DIR = PROJECT_DIR / "Data_Input"

DEFAULT_KEY_FILE = str(Path.home() / "Downloads" / "farm-controlling-1a5d580c9d89.json")
DEFAULT_FOLDER_ID = "15SwpYlcFORVgsztDOE9a4lq0dLL2EgTo"

# Folder name → local subdirectory mapping
FOLDER_MAP = {
    "NED Bank Statements": "Kontoauszüge/Nedbank",
    "Pointbreak Statements": "Kontoauszüge/Pointbreak",
    "Buchhaltung Income Statements": "Income_Statements",
    "Bank_Import": "Bank_Import",
}

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]

# ── State tracking ───────────────────────────────────────────────
STATE_FILE = DATA_DIR / ".gdrive-sync-state.json"


def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"synced_files": {}}


def save_state(state):
    STATE_FILE.write_text(json.dumps(state, indent=2))


# ── GDrive helpers ───────────────────────────────────────────────
def get_service(key_file):
    creds = service_account.Credentials.from_service_account_file(
        key_file, scopes=SCOPES
    )
    return build("drive", "v3", credentials=creds)


def list_folder(service, folder_id):
    """List all files in a folder (handles pagination)."""
    files = []
    page_token = None
    while True:
        resp = (
            service.files()
            .list(
                q=f"'{folder_id}' in parents and trashed = false",
                fields="nextPageToken, files(id, name, mimeType, modifiedTime, size)",
                orderBy="name",
                pageSize=100,
                pageToken=page_token,
            )
            .execute()
        )
        files.extend(resp.get("files", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return files


def download_file(service, file_id, dest_path):
    """Download a file from GDrive to local path."""
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    request = service.files().get_media(fileId=file_id)
    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    dest_path.write_bytes(fh.getvalue())
    return dest_path.stat().st_size


def match_folder(name):
    """Match a GDrive folder name to local subdirectory."""
    for prefix, local_dir in FOLDER_MAP.items():
        if name.startswith(prefix):
            # Extract year suffix if present
            year_part = name.replace(prefix, "").strip()
            if year_part:
                return f"{local_dir}/{year_part.strip()}"
            return local_dir
    return None


# ── Main ─────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Sync GDrive → Data_Input")
    parser.add_argument("--list", action="store_true", help="List remote files only")
    parser.add_argument("--year", type=str, help="Only sync folders matching year")
    parser.add_argument("--force", action="store_true", help="Re-download all files")
    parser.add_argument(
        "--key", default=os.environ.get("GDRIVE_KEY_FILE", DEFAULT_KEY_FILE)
    )
    parser.add_argument(
        "--folder", default=os.environ.get("GDRIVE_FOLDER_ID", DEFAULT_FOLDER_ID)
    )
    args = parser.parse_args()

    if not Path(args.key).exists():
        print(f"ERROR: Key file not found: {args.key}")
        sys.exit(1)

    service = get_service(args.key)
    state = load_state()
    synced = state["synced_files"]

    # List top-level folders
    top_files = list_folder(service, args.folder)
    folders = [f for f in top_files if f["mimeType"] == "application/vnd.google-apps.folder"]

    total_new = 0
    total_skipped = 0
    total_bytes = 0

    for folder in sorted(folders, key=lambda f: f["name"]):
        folder_name = folder["name"]

        # Year filter
        if args.year and args.year not in folder_name:
            continue

        local_subdir = match_folder(folder_name)
        if not local_subdir:
            continue

        # List files in this subfolder
        files = list_folder(service, folder["id"])
        pdf_files = [f for f in files if f["name"].lower().endswith(".pdf")]

        if not pdf_files:
            continue

        if args.list:
            print(f"\n{folder_name}/ ({len(pdf_files)} PDFs)")
            for f in pdf_files:
                size_kb = int(f.get("size", 0)) / 1024
                already = "synced" if f["id"] in synced else "NEW"
                print(f"  [{already:>6}] {f['name']:<45} {size_kb:>6.0f} KB  {f['modifiedTime'][:10]}")
            continue

        # Download new/updated files
        dest_dir = DATA_DIR / local_subdir
        for f in pdf_files:
            file_id = f["id"]
            modified = f["modifiedTime"]

            # Skip if already synced and not force
            if not args.force and file_id in synced and synced[file_id] == modified:
                total_skipped += 1
                continue

            dest_path = dest_dir / f["name"]
            size = download_file(service, file_id, dest_path)
            total_bytes += size
            total_new += 1

            synced[file_id] = modified
            print(f"  [NEW] {folder_name}/{f['name']} → {dest_path.relative_to(PROJECT_DIR)} ({size/1024:.0f} KB)")

    if args.list:
        return

    # Save state
    state["synced_files"] = synced
    state["last_sync"] = datetime.utcnow().isoformat() + "Z"
    save_state(state)

    print(f"\nSync complete: {total_new} new, {total_skipped} skipped, {total_bytes/1024:.0f} KB downloaded")
    if total_new > 0:
        print(f"State saved to {STATE_FILE.relative_to(PROJECT_DIR)}")


if __name__ == "__main__":
    main()
