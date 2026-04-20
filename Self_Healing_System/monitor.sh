#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
echo "[AUTO RUN $(date)" >> $SCRIPT_DIR/logs/sytem.log

mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$SAMPLE_DIR"
touch "$LOG_FILE"

log_msg "INFO" "Monitoring cycle started."

# CPU
cpu_usage="$(get_cpu_usage || echo 0)"
if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
    log_msg "WARNING" "High CPU usage detected: ${cpu_usage}%"
    "$SCRIPT_DIR/fixer.sh" cpu || log_msg "ERROR" "CPU fix failed."
else
    log_msg "INFO" "CPU usage normal: ${cpu_usage}%"
fi

# Memory
mem_usage="$(get_mem_usage || echo 0)"
if [ "$mem_usage" -gt "$MEM_THRESHOLD" ]; then
    log_msg "WARNING" "High memory usage detected: ${mem_usage}%"
else
    log_msg "INFO" "Memory usage normal: ${mem_usage}%"
fi

# Disk
disk_usage="$(get_disk_usage_root || echo 0)"
if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    log_msg "WARNING" "High disk usage detected on / : ${disk_usage}%"
    "$SCRIPT_DIR/fixer.sh" disk || log_msg "ERROR" "Disk fix failed."
else
    log_msg "INFO" "Disk usage normal on / : ${disk_usage}%"
fi

# SSH service
service_name="$(detect_service_name || true)"
if [ -n "$service_name" ]; then
    if is_service_active "$service_name"; then
        log_msg "INFO" "Service is running: $service_name"
    else
        log_msg "WARNING" "Service is down: $service_name"
        "$SCRIPT_DIR/fixer.sh" service "$service_name" || log_msg "ERROR" "Service fix failed."
    fi
else
    log_msg "WARNING" "No SSH service found from configured candidates."
fi

# Unauthorized login detection
auth_log="$(find_auth_log || true)"
if [ -n "${auth_log:-}" ] && [ -f "$auth_log" ]; then
    while read -r count ip; do
        [ -n "${count:-}" ] || continue
        [ -n "${ip:-}" ] || continue

        if [ "$count" -gt "$FAILED_LOGIN_THRESHOLD" ] && is_valid_ipv4 "$ip"; then
            log_msg "WARNING" "Suspicious failed login attempts detected from $ip : count=$count"
            "$SCRIPT_DIR/fixer.sh" login "$ip" || log_msg "ERROR" "Login fix failed for IP: $ip"
        fi
    done < <(extract_failed_login_ips "$auth_log")
else
    log_msg "WARNING" "Authentication log not found. Login detection skipped."
fi

log_msg "INFO" "Monitoring cycle finished."
