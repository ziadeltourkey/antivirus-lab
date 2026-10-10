#!/bin/bash
# antivirus-cron.sh - one-shot version of the daemon, meant to be run by cron.
# Usage: ./antivirus-cron.sh dir malicious_dir
# Use ABSOLUTE paths in the crontab entry.

if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"

[ -d "$DIR" ] || { echo "Error: '$DIR' is not a directory" >&2; exit 1; }
mkdir -p "$MAL_DIR" || exit 1

# Cron runs from an unpredictable cwd, so keep snapshots next to the scripts
STATE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$STATE_DIR/common.sh"

check_and_scan "$DIR" "$MAL_DIR"
