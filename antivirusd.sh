#!/bin/bash
# antivirusd.sh da simple antivirus daemon
# bnst5dmo fi ./antivirusd.sh dir malicious_dir interval-secs

if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"
INTERVAL="$3"

[ -d "$DIR" ] || { echo "Error: '$DIR' is not a directory" >&2; exit 1; }
[[ "$INTERVAL" =~ ^[1-9][0-9]*$ ]] || { echo "Error: interval-secs must be a positive integer" >&2; exit 1; }
mkdir -p "$MAL_DIR" || exit 1

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

trap 'echo; echo "antivirusd stopped."; exit 0' INT TERM

echo "antivirusd started: watching '$DIR' every ${INTERVAL}s (Ctrl+C to stop)"

while true; do
    check_and_scan "$DIR" "$MAL_DIR"
    sleep "$INTERVAL"
done
