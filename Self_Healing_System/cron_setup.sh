#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

job="$CRON_SCHEDULE /bin/bash $SCRIPT_DIR/monitor.sh"

current_cron="$(crontab -l 2>/dev/null || true)"

if printf '%s\n' "$current_cron" | grep -Fqx "$job"; then
    echo "Cron job already exists:"
    echo "$job"
    exit 0
fi

{
    printf '%s\n' "$current_cron"
    printf '%s\n' "$job"
} | crontab -

echo "Cron job installed:"
echo "$job"
