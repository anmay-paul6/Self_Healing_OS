#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

SERVERS_FILE="$SCRIPT_DIR/servers.conf"

if [ ! -f "$SERVERS_FILE" ]; then
    log_msg "ERROR" "servers.conf not found."
    exit 1
fi

echo "================ Remote System Summary ================"

while IFS=',' read -r name user host; do
    [ -n "${name:-}" ] || continue
    [ -n "${user:-}" ] || continue
    [ -n "${host:-}" ] || continue

    echo
    echo "Checking: $name ($user@$host)"

    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$user@$host" '
        cpu=$(awk '"'"'
            /^cpu / {
                idle=$5
                total=$2+$3+$4+$5+$6+$7+$8
                if (total > 0) {
                    printf "%d\n", 100 - (idle * 100 / total)
                } else {
                    print 0
                }
                exit
            }
        '"'"' /proc/stat)

        mem=$(awk '"'"'
            /^MemTotal:/ {total=$2}
            /^MemAvailable:/ {avail=$2}
            END {
                if (total > 0) {
                    printf "%d\n", ((total-avail) * 100 / total)
                } else {
                    print 0
                }
            }
        '"'"' /proc/meminfo)

        disk=$(df -P / | awk '"'"'NR==2 {gsub("%","",$5); print $5}'"'"')

        service_state="not found"
        if systemctl list-unit-files 2>/dev/null | grep -q "^ssh.service"; then
            systemctl is-active --quiet ssh && service_state="running" || service_state="stopped"
        elif systemctl list-unit-files 2>/dev/null | grep -q "^sshd.service"; then
            systemctl is-active --quiet sshd && service_state="running" || service_state="stopped"
        fi

        echo "CPU: ${cpu}%"
        echo "MEMORY: ${mem}%"
        echo "DISK: ${disk}%"
        echo "SSH_SERVICE: ${service_state}"
    '; then
        log_msg "INFO" "Remote monitoring successful for $name ($host)"
    else
        echo "Connection failed."
        log_msg "WARNING" "Failed to connect to remote server: $name ($host)"
    fi
done < "$SERVERS_FILE"

echo
echo "======================================================="
