#!/bin/bash
# restore.sh by3ml review ll quarantined files
# bst5dmo fi ./restore.sh dir malicious_dir

if [ $# -ne 2 ]; then
    echo "usage: $0 dir malicious_dir" >&2
    exit 1
fi

dir="$1"
malicious_dir="$2"

[ -d "$dir" ]     || { echo "error: '$dir' isn't a directory" >&2; exit 1; }
[ -d "$malicious_dir" ] || { echo "error: '$malicious_dir' isn't a directory" >&2; exit 1; }

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

while true; do
    # hna bnbuild ellist of files elly btb2a mwgooda sa3tha felquar
    files=()
    for f in "$malicious_dir"/*; do
        [ -f "$f" ] && files+=("$(basename "$f")")
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo
    echo "quarantined files:"
    for i in "${!files[@]}"; do
        echo "  $((i+1))) ${files[$i]}"
    done
    read -r -p "pick a file number (or q to quit): " choice || exit 0   

    [ "$choice" = "q" ] && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
        echo "invalid choice."
        continue
    fi

    file="${files[$((choice-1))]}"
    echo
    echo "Selected: $file"
    echo "  1) this file restore it into $dir (false positive)"
    echo "  2) delete this file permanently (genuinely malicious)"
    echo "  3) leave it as-is & go back to the list"
    read -r -p "your choice [1-3]: " action || exit 0

    case "$action" in
        1)
            if [ -e "$dir/$file" ]; then
                echo "can't restore: $dir/$file already exists"
            else
                # Whitelist (name + content hash) BEFORE moving so the daemon skips it
                echo "$(file_hash "$malicious_dir/$file")  $file" >> "$whitelist_file"
                mv -- "$malicious_dir/$file" "$dir/$file"
                echo "Restored $file to $dir."
            fi ;;
        2)
            rm -f -- "$malicious_dir/$file"
            echo "$file permanently deleted." ;;
        3) ;;
        *)
            echo "option invalid" ;;
    esac
done
