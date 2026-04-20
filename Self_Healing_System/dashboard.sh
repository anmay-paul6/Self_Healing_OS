#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

while true; do
    clear
    echo "======================================"
    echo "        AutoHeal-Linux Dashboard"
    echo "======================================"
    echo "1. Show local system status"
    echo "2. Run local monitor now"
    echo "3. Show full logs"
    echo "4. Create backup now"
    echo "5. Show blocked IPs"
    echo "6. Monitor remote systems"
    echo "7. Show last 20 log lines"
    echo "8. Exit"
    echo "======================================"
    read -rp "Enter choice: " choice

    case "$choice" in
        1)
            echo
            echo "Local System Status"
            echo "-------------------"
            echo "CPU Usage   : $(get_cpu_usage)%"
            echo "Memory Usage: $(get_mem_usage)%"
            echo "Disk Usage  : $(get_disk_usage_root)%"

            service_name="$(detect_service_name || true)"
            if [ -n "$service_name" ]; then
                if is_service_active "$service_name"; then
                    echo "SSH Service : running ($service_name)"
                else
                    echo "SSH Service : stopped ($service_name)"
                fi
            else
                echo "SSH Service : not found"
            fi
            echo
            read -rp "Press Enter to continue..."
            ;;
        2)
            echo
            bash "$SCRIPT_DIR/monitor.sh"
            echo
            read -rp "Press Enter to continue..."
            ;;
        3)
    echo
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
        echo
        read -rp "Press Enter to return to dashboard..."
    else
        echo "Log file not found."
        read -rp "Press Enter to continue..."
    fi
    ;;
        4)
            echo
            bash "$SCRIPT_DIR/backup.sh"
            echo
            read -rp "Press Enter to continue..."
            ;;
        5)
            echo
            if [ -f "$BLOCKLIST_FILE" ]; then
                cat "$BLOCKLIST_FILE"
            else
                echo "No blocked IPs found."
            fi
            echo
            read -rp "Press Enter to continue..."
            ;;
        6)
            echo
            bash "$SCRIPT_DIR/remote_monitor.sh"
            echo
            read -rp "Press Enter to continue..."
            ;;
        7)
            echo
            if [ -f "$LOG_FILE" ]; then
                tail -n 20 "$LOG_FILE"
            else
                echo "Log file not found."
            fi
            echo
            read -rp "Press Enter to continue..."
            ;;
        8)
            echo "Exiting dashboard."
            exit 0
            ;;
        *)
            echo "Invalid choice."
            sleep 1
            ;;
    esac
done
