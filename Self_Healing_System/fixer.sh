#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

issue="${1:-}"
detail="${2:-}"

if [ -z "$issue" ]; then
    log_msg "ERROR" "No issue type provided to fixer.sh"
    exit 1
fi

case "$issue" in
    cpu)
        if [ "$ENABLE_CPU_PROCESS_CONTROL" -ne 1 ]; then
            log_msg "INFO" "CPU process control disabled."
            exit 0
        fi

        if [ "$ENABLE_BACKUP_BEFORE_FIX" -eq 1 ]; then
            "$SCRIPT_DIR/backup.sh" || log_msg "WARNING" "Backup before CPU fix failed."
        fi

        top_info="$(get_top_cpu_process)"
        top_pid="$(echo "$top_info" | awk '{print $1}')"
        top_name="$(echo "$top_info" | awk '{print $2}')"
        top_cpu="$(echo "$top_info" | awk '{print $3}')"

        if [ -z "${top_pid:-}" ] || [ -z "${top_name:-}" ]; then
            log_msg "WARNING" "No CPU-heavy process found."
            exit 0
        fi

        if is_protected_process "$top_name"; then
            log_msg "WARNING" "Skipped protected process: $top_name (PID $top_pid)"
            exit 0
        fi

        if kill -15 "$top_pid" 2>/dev/null; then
            log_msg "SUCCESS" "Stopped high CPU process: $top_name (PID $top_pid, CPU ${top_cpu}%)"
        else
            log_msg "ERROR" "Failed to stop high CPU process: $top_name (PID $top_pid)"
            exit 1
        fi
        ;;

    disk)
        if [ "$ENABLE_BACKUP_BEFORE_FIX" -eq 1 ]; then
            "$SCRIPT_DIR/backup.sh" || log_msg "WARNING" "Backup before disk fix failed."
        fi

        if [ "$ENABLE_SAFE_CLEANUP" -ne 1 ]; then
            log_msg "INFO" "Safe cleanup disabled."
            exit 0
        fi

        cleaned_any=0
        for target in "${CLEANUP_TARGETS[@]}"; do
            if [ -d "$target" ]; then
                find "$target" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
                log_msg "ACTION" "Cleaned safe target: $target"
                cleaned_any=1
            fi
        done

        if [ "$cleaned_any" -eq 0 ]; then
            log_msg "WARNING" "No cleanup targets found."
        fi
        ;;

    service)
        service_name="${detail:-}"

        if [ -z "$service_name" ]; then
            service_name="$(detect_service_name || true)"
        fi

        if [ -z "$service_name" ]; then
            log_msg "WARNING" "No known SSH service found to restart."
            exit 0
        fi

        if [ "$ENABLE_SERVICE_RESTART" -ne 1 ]; then
            log_msg "INFO" "Service restart disabled."
            exit 0
        fi

        if ! need_root_for_action; then
            log_msg "WARNING" "Root privileges required to restart service: $service_name"
            exit 0
        fi

        if systemctl restart "$service_name"; then
            if is_service_active "$service_name"; then
                log_msg "SUCCESS" "Service restarted successfully: $service_name"
            else
                log_msg "ERROR" "Service restart command ran but service is still inactive: $service_name"
                exit 1
            fi
        else
            log_msg "ERROR" "Failed to restart service: $service_name"
            exit 1
        fi
        ;;
    login)
        ip="$detail"

        if ! is_valid_ipv4 "$ip"; then
            log_msg "WARNING" "Skipping invalid IP: $ip"
            exit 0
        fi

        if is_ip_already_recorded "$ip"; then
            log_msg "INFO" "IP already recorded as blocked: $ip"
            exit 0
        fi

        if [ "$ENABLE_BACKUP_BEFORE_FIX" -eq 1 ]; then
            "$SCRIPT_DIR/backup.sh" || log_msg "WARNING" "Backup before login fix failed."
        fi

        if [ "$ENABLE_FIREWALL_BLOCK" -ne 1 ]; then
            log_msg "INFO" "Firewall blocking disabled. Recording IP only: $ip"
            record_blocked_ip "$ip"
            exit 0
        fi

        if ! need_root_for_action; then
            log_msg "WARNING" "Root privileges required to block IP: $ip"
            exit 0
        fi

        if block_ip_firewall "$ip"; then
            record_blocked_ip "$ip"
            log_msg "SUCCESS" "Blocked suspicious IP: $ip"
        else
            log_msg "ERROR" "Failed to block suspicious IP: $ip"
            exit 1
        fi
        ;;

    *)
        log_msg "ERROR" "Unknown issue type: $issue"
        exit 1
        ;;
esac
