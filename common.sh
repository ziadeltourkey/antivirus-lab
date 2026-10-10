#!/bin/bash
# common.sh - shared functions for antivirusd.sh and antivirus-cron.sh
# Do not run directly; it is sourced by the other scripts.

# ---------------------------------------------------------------
# FLAGGED LISTS (required by the lab) - the ONLY place they live
# ---------------------------------------------------------------
FLAGGED_EXTENSIONS=(".exe" ".bat" ".vbs" ".scr" ".ps1")
FLAGGED_KEYWORDS=("virus" "trojan" "malware" "worm" "ransomware")

# Folder containing the scripts (so whitelist/state live in a known place)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Whitelist (Bonus 2): persistent file shared with restore.sh
WHITELIST="${WHITELIST:-$SCRIPT_DIR/whitelist.txt}"

# Where directory-info.last / directory-info.new are kept
STATE_DIR="${STATE_DIR:-.}"

# Include dotfiles in globs, and make an empty glob expand to nothing
shopt -s dotglob nullglob

# Print the SHA-256 hash of a file
file_hash() {
    sha256sum "$1" | cut -d' ' -f1
}

# Succeeds if the file (same name AND same content) is whitelisted
is_whitelisted() {
    local file="$1" name hash
    [ -f "$WHITELIST" ] || return 1
    name="$(basename "$file")"
    hash="$(file_hash "$file")"
    grep -qxF -- "$hash  $name" "$WHITELIST"
}

# Succeeds if the file matches a flagged extension or keyword
is_malicious() {
    local file="$1" name ext kw
    name="$(basename "$file")"

    # Rule 1: flagged extension
    for ext in "${FLAGGED_EXTENSIONS[@]}"; do
        [[ "$name" == *"$ext" ]] && return 0
    done

    # Rule 2: flagged keyword in content (case-insensitive, binary treated as text)
    for kw in "${FLAGGED_KEYWORDS[@]}"; do
        grep -qiaF -- "$kw" "$file" 2>/dev/null && return 0
    done
    return 1
}

# Scan every file directly inside $1, quarantine malicious ones into $2
scan_directory() {
    local dir="$1" mal="$2" file name
    for file in "$dir"/*; do
        [ -f "$file" ] || continue            # files only, no subdirectories
        name="$(basename "$file")"

        is_whitelisted "$file" && continue    # Bonus 2: skip safe files

        if is_malicious "$file"; then
            echo "$name is malicious and it is DELETED"       # 1. print
            if cp -- "$file" "$mal/$name"; then               # 2. copy
                rm -f -- "$file"                              # 3. delete (only if copy worked)
            else
                echo "ERROR: could not copy $name to $mal, not deleting it" >&2
            fi
        fi
    done
}

# Compare snapshots; scan only if something changed (or first run)
check_and_scan() {
    local dir="$1" mal="$2"
    local last="$STATE_DIR/directory-info.last"
    local new="$STATE_DIR/directory-info.new"

    ls -l --time-style=full-iso "$dir" > "$new"

    if [ ! -f "$last" ]; then
        # First run: no previous snapshot -> scan immediately
        scan_directory "$dir" "$mal"
        cp "$new" "$last"
    elif ! diff -q "$last" "$new" > /dev/null; then
        # Something changed -> scan, then make the new state the reference
        scan_directory "$dir" "$mal"
        cp "$new" "$last"
    fi
}
