#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
backup_file="$BACKUP_DIR/backup_${timestamp}.tar.gz"

items_to_backup=()
for item in "${BACKUP_ITEMS[@]}"; do
    if [ -e "$item" ]; then
        items_to_backup+=("$item")
    fi
done

if [ "${#items_to_backup[@]}" -eq 0 ]; then
    log_msg "WARNING" "No backup items found. Backup skipped."
    exit 0
fi

if tar -czf "$backup_file" "${items_to_backup[@]}" 2>/dev/null; then
    log_msg "INFO" "Backup created successfully: $backup_file"
else
    log_msg "ERROR" "Backup creation failed."
    exit 1
fi

if [ "$ENABLE_REMOTE_BACKUP" -eq 1 ]; then
    if command_exists rsync; then
        if rsync -az "$backup_file" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/" >/dev/null 2>&1; then
            log_msg "INFO" "Remote backup synced successfully."
        else
            log_msg "WARNING" "Remote backup sync failed."
        fi
    else
        log_msg "WARNING" "rsync not installed. Remote backup skipped."
    fi
fi
