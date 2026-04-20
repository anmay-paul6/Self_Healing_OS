#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p \
    "$SCRIPT_DIR/logs" \
    "$SCRIPT_DIR/backups" \
    "$SCRIPT_DIR/sample_data/temp"

touch \
    "$SCRIPT_DIR/logs/system.log" \
    "$SCRIPT_DIR/logs/blocked_ips.txt" \
    "$SCRIPT_DIR/servers.conf"

chmod +x \
    "$SCRIPT_DIR/config.sh" \
    "$SCRIPT_DIR/utils.sh" \
    "$SCRIPT_DIR/monitor.sh" \
    "$SCRIPT_DIR/fixer.sh" \
    "$SCRIPT_DIR/backup.sh" \
    "$SCRIPT_DIR/dashboard.sh" \
    "$SCRIPT_DIR/remote_monitor.sh" \
    "$SCRIPT_DIR/cron_setup.sh" \
    "$SCRIPT_DIR/install.sh"

echo "Project initialized successfully."
echo
echo "Created:"
echo " - logs/"
echo " - backups/"
echo " - sample_data/temp/"
echo
echo "Next steps:"
echo "1. Edit servers.conf if you want remote monitoring"
echo "2. Run: bash monitor.sh"
echo "3. Run: bash dashboard.sh"
echo "4. Run: bash cron_setup.sh"
echo
echo "For service restart and IP blocking, use root:"
echo "sudo bash monitor.sh"
