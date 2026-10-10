#!/bin/bash
##hna bncron elantivirus
if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

dir="$1"
malicious_dir="$2"

[ -d "$dir" ] || { echo "Error: '$dir' isn't a directory" >&2; exit 1; }
mkdir -p "$malicious_dir" || exit 1
# elcron hna byrun mn unpredictable cwd f 34an kda m5lyin elsnapshots gamb elscripts
state_dir="$(cd "$(dirname "$0")" && pwd)"
source "$state_dir/common.sh"

check_and_scan "$dir" "$malicious_dir"
