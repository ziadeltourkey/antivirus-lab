#!/bin/bash
# restore.sh by3ml review ll quarantined files
# bst5dmo fi ./restore.sh dir malicious_dir

if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

dir="$1"
malicious_dir="$2"

[ -d "$dir" ]     || { echo "Error: '$dir' is not a directory" >&2; exit 1; }
[ -d "$malicious_dir" ] || { echo "Error: '$malicious_dir' is not a directory" >&2; exit 1; }

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

while true; do
    # hna bnbuild ellist of files elly btb2a mwgooda sa3tha felquar
    files=()
    for f in "$malicious_dir"/*; do
        [ -f "$f" ] && files+=("$(basename "$f")")
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo "no malicious files to review"
        exit 0
    fi

    echo
    echo "quarantined files:"
    for i in "${!files[@]}"; do
        echo "  $((i+1))) ${files[$i]}"
    done
    read -r -p "Pick a file number (or q to quit): " choice || exit 0   

    [ "$choice" = "q" ] && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
        echo "Invalid choice."
        continue
    fi

    file="${files[$((choice-1))]}"
    echo
    echo "Selected: $file"
    echo "  1) restore this file back into $dir (false positive)"
    echo "  2) permanently delete this file (genuinely malicious)"
    echo "  3) leave it as-is and go back to the list"
    read -r -p "your choice [1-3]: " action || exit 0

    case "$action" in
        1)
            if [ -e "$dir/$file" ]; then
                echo "can't restore: $dir/$file already exists"
            else
                # Whitelist (name + content hash) BEFORE moving so the daemon skips it
                echo "$(file_hash "$malicious_dir/$file")  $file" >> "$whitelist_file"
                mv -- "$malicious_dir/$file" "$dir/$file"
                echo "restored $file to $dir"
            fi ;;
        2)
            rm -f -- "$malicious_dir/$file"
            echo "$file permanently deleted" ;;
        3) ;;
        *)
            echo "invalid option" ;;
    esac
done
