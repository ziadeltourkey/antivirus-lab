#!/bin/bash
# antivirusd.sh da simple antivirus daemon
# bnst5dmo fi ./antivirusd.sh dir malicious_dir interval-secs
#very imp
if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs" >&2
    exit 1
fi

dir="$1"
malicious_dir="$2"
interval="$3"

[ -d "$dir" ] || { echo "Error: '$dir' is not a directory" >&2; exit 1; }
[[ "$interval" =~ ^[1-9][0-9]*$ ]] || { echo "Error: interval-secs must be a positive integer" >&2; exit 1; }
mkdir -p "$malicious_dir" || exit 1

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

trap 'echo; echo "antivirusd stopped."; exit 0' INT TERM

echo "antivirusd started: watching '$dir' every ${interval}s (Ctrl+C to stop)"

while true; do
    check_and_scan "$dir" "$malicious_dir"
    sleep "$interval"
done
