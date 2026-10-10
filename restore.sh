#!/bin/bash
# restore.sh - review quarantined files
# Usage: ./restore.sh dir malicious_dir

if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"

[ -d "$DIR" ]     || { echo "Error: '$DIR' is not a directory" >&2; exit 1; }
[ -d "$MAL_DIR" ] || { echo "Error: '$MAL_DIR' is not a directory" >&2; exit 1; }

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

while true; do
    # Build the list of files currently in quarantine
    files=()
    for f in "$MAL_DIR"/*; do
        [ -f "$f" ] && files+=("$(basename "$f")")
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo
    echo "Quarantined files:"
    for i in "${!files[@]}"; do
        echo "  $((i+1))) ${files[$i]}"
    done
    read -r -p "Pick a file number (or q to quit): " choice || exit 0   # exit on EOF (Ctrl+D)

    [ "$choice" = "q" ] && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
        echo "Invalid choice."
        continue
    fi

    file="${files[$((choice-1))]}"
    echo
    echo "Selected: $file"
    echo "  1) Restore this file back into $DIR (false positive)"
    echo "  2) Permanently delete this file (genuinely malicious)"
    echo "  3) Leave it as-is and go back to the list"
    read -r -p "Your choice [1-3]: " action || exit 0

    case "$action" in
        1)
            if [ -e "$DIR/$file" ]; then
                echo "Cannot restore: $DIR/$file already exists."
            else
                # Whitelist (name + content hash) BEFORE moving so the daemon skips it
                echo "$(file_hash "$MAL_DIR/$file")  $file" >> "$WHITELIST"
                mv -- "$MAL_DIR/$file" "$DIR/$file"
                echo "Restored $file to $DIR."
            fi
            ;;
        2)
            rm -f -- "$MAL_DIR/$file"
            echo "$file permanently deleted."
            ;;
        3)
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
