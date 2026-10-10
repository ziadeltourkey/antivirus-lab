#!/bin/bash
# hna elcommon.sh byshare elfunctions l antivirusd.sh w antivirus-cron.sh
# hna ana mb3ml4 run directly; hya 7aga sourced mn elscripts eltania.

# di b2a elflagged lists "required" the only place they live <3
FLAGGED_EXTENSIONS=(".exe" ".bat" ".vbs" ".scr" ".ps1")
FLAGGED_KEYWORDS=("virus" "trojan" "malware" "worm" "ransomware")

# folder gwah elscripts "w kda elwhitelistlive htb2a mawgooda fi mkan m3roof"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# whitelist: persistent file shared with restore.sh
WHITELIST="${WHITELIST:-$SCRIPT_DIR/whitelist.txt}"

# fiha eldirectory-info.last wkman eldirectory-info.new are kept
STATE_DIR="${STATE_DIR:-.}"

# include dotfiles in globs and make an empty glob expand to nothing
shopt -s dotglob nullglob

# hna bnprint elthe SHA-256 hash of a file
file_hash() {
    sha256sum "$1" | cut -d' ' -f1
}

# succeeds if the file"same name and same content" is whitelisted
is_whitelisted() {
    local file="$1" name hash
    [ -f "$WHITELIST" ] || return 1
    name="$(basename "$file")"
    hash="$(file_hash "$file")"
    grep -qxF -- "$hash  $name" "$WHITELIST"
}

# succeeds if the file matche flagged extension
is_malicious() {
    local file="$1" name ext kw
    name="$(basename "$file")"

    # extension llflag
    for ext in "${FLAGGED_EXTENSIONS[@]}"; do
        [[ "$name" == *"$ext" ]] && return 0
    done

    # flagged keyword in content 
    for kw in "${FLAGGED_KEYWORDS[@]}"; do
        grep -qiaF -- "$kw" "$file" 2>/dev/null && return 0
    done
    return 1
}

# 1) scan every file directly inside $1
# 2) quarantine malicious ones into $2
scan_directory() {
    local dir="$1" mal="$2" file name
    for file in "$dir"/*; do
        [ -f "$file" ] || continue            # bs files m4 7aga tania
        name="$(basename "$file")"

        is_whitelisted "$file" && continue    # by3dy elsafe files

        if is_malicious "$file"; then
            echo "$name is malicious and it is DELETED"       # 1) print
            if cp -- "$file" "$mal/$name"; then               # 2) copy
                rm -f -- "$file"                              # 3) delete (only if copy worked)
            else
                echo "ERROR: could not copy $name to $mal, not deleting it" >&2
            fi
        fi
    done
}

# hna ana ba5od elsnapshots w bkarenha bb3d
check_and_scan() {
    local dir="$1" mal="$2"
    local last="$STATE_DIR/directory-info.last"
    local new="$STATE_DIR/directory-info.new"

    ls -l --time-style=full-iso "$dir" > "$new"

    if [ ! -f "$last" ]; then
        scan_directory "$dir" "$mal"
        cp "$new" "$last"
    elif ! diff -q "$last" "$new" > /dev/null; then
        scan_directory "$dir" "$mal"
        cp "$new" "$last"
    fi
}
