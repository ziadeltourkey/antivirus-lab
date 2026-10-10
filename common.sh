#!/bin/bash
# hna elcommon.sh byshare elfunctions l antivirusd.sh w antivirus-cron.sh
# hna ana mb3ml4 run directly..hya 7aga sourced mn elscripts eltania.

# di b2a elflagged lists "required" the only place they live <3
flagged_extensions=(".exe" ".bat" ".vbs" ".scr" ".ps1")
flagged_keywords=("virus" "trojan" "malware" "worm" "ransomware")

# folder gwah elscripts "w kda elwhitelistlive htb2a mawgooda fi mkan m3roof"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# whitelist: persistent file shared with restore.sh
whitelist_file="${whitelist_file:-$script_dir/whitelist.txt}"

# fiha eldirectory-info.last wkman eldirectory-info.new are kept
state_dir="${state_dir:-.}"

# include dotfiles in globs and make an empty glob expand to nothing
shopt -s dotglob nullglob

# hna bnprint elthe SHA-256 hash of a file
file_hash() {
    sha256sum "$1" | cut -d' ' -f1
}

# succeeds if the file"same name and same content" is whitelisted
is_whitelisted() {
    local file="$1" name hash
    [ -f "$whitelist_file" ] || return 1
    name="$(basename "$file")"
    hash="$(file_hash "$file")"
    grep -qxF -- "$hash  $name" "$whitelist_file"
}

# succeeds if the file matche flagged extension
is_malicious() {
    local file="$1" name extension keyword
    name="$(basename "$file")"

    # extension llflag
    for extension in "${flagged_extensions[@]}"; do
        [[ "$name" == *"$extension" ]] && return 0
    done

    # flagged keyword in content 
    for keyword in "${flagged_keywords[@]}"; do
        grep -qiaF -- "$keyword" "$file" 2>/dev/null && return 0
    done
    return 1
}

# 1) scan every file directly inside $1
# 2) quarantine malicious ones into $2
scan_directory() {
    local dir="$1" malicious_dir="$2" file name
    for file in "$dir"/*; do
        [ -f "$file" ] || continue            # bs files m4 7aga tania
        name="$(basename "$file")"

        is_whitelisted "$file" && continue    # by3dy elsafe files

        if is_malicious "$file"; then
            echo "$name is malicious and it is DELETED"       # 1) print
            if cp -- "$file" "$malicious_dir/$name"; then               # 2) copy
                rm -f -- "$file"                              # 3) delete (only if copy worked)
            else
                echo "ERROR: could not copy $name to $malicious_dir, not deleting it" >&2
            fi
        fi
    done
}

# hna ana ba5od elsnapshots w bkarenha bb3d
check_and_scan() {
    local dir="$1" malicious_dir="$2"
    local last="$state_dir/directory-info.last"
    local new="$state_dir/directory-info.new"

    ls -l --time-style=full-iso "$dir" > "$new"

    if [ ! -f "$last" ]; then
        scan_directory "$dir" "$malicious_dir"
        cp "$new" "$last"
    elif ! diff -q "$last" "$new" > /dev/null; then
        scan_directory "$dir" "$malicious_dir"
        cp "$new" "$last"
    fi
}
