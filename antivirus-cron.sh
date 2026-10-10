#!/bin/bash
##hna bncron elantivirus
if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"

[ -d "$DIR" ] || { echo "Error: '$DIR' is not a directory" >&2; exit 1; }
mkdir -p "$MAL_DIR" || exit 1

# elcron hna byrun mn unpredictable cwd f 34an kda m5lyin elsnapshots gamb elscripts
STATE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$STATE_DIR/common.sh"

check_and_scan "$DIR" "$MAL_DIR"
