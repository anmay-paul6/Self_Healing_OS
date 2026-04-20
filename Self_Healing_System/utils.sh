#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$SAMPLE_DIR"
touch "$LOG_FILE" "$BLOCKLIST_FILE"

log_msg() {
    local level="$1"
    local msg="$2"
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$msg" | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

find_auth_log() {
    local file
    for file in "${AUTH_LOG_CANDIDATES[@]}"; do
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    return 1
}

detect_service_name() {
    local svc
    for svc in "${SERVICE_CANDIDATES[@]}"; do
        if systemctl list-unit-files 2>/dev/null | awk '{print $1}' | grep -qx "${svc}.service"; then
            echo "$svc"
            return 0
        fi
    done
    return 1
}

is_service_active() {
    local svc="$1"
    systemctl is-active --quiet "$svc"
}

get_cpu_usage() {
    local user1 nice1 sys1 idle1 iow1 irq1 sirq1 steal1
    local user2 nice2 sys2 idle2 iow2 irq2 sirq2 steal2
    local total1 total2 idle_total1 idle_total2 total_diff idle_diff usage

    read -r _ user1 nice1 sys1 idle1 iow1 irq1 sirq1 steal1 _ < /proc/stat
    sleep 1
    read -r _ user2 nice2 sys2 idle2 iow2 irq2 sirq2 steal2 _ < /proc/stat

    total1=$((user1 + nice1 + sys1 + idle1 + iow1 + irq1 + sirq1 + steal1))
    total2=$((user2 + nice2 + sys2 + idle2 + iow2 + irq2 + sirq2 + steal2))
    idle_total1=$((idle1 + iow1))
    idle_total2=$((idle2 + iow2))

    total_diff=$((total2 - total1))
    idle_diff=$((idle_total2 - idle_total1))

    if [ "$total_diff" -le 0 ]; then
        echo 0
        return
    fi

    usage=$((100 * (total_diff - idle_diff) / total_diff))
    echo "$usage"
}

get_mem_usage() {
    awk '
        /^MemTotal:/ {total=$2}
        /^MemAvailable:/ {avail=$2}
        END {
            if (total > 0) {
                used = total - avail
                printf "%d\n", (used * 100 / total)
            } else {
                print 0
            }
        }
    ' /proc/meminfo
}

get_disk_usage_root() {
    df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

extract_failed_login_ips() {
    local auth_log="$1"

    grep "Failed password" "$auth_log" 2>/dev/null | \
    awk '
        {
            for (i = 1; i <= NF; i++) {
                if ($i == "from" && (i+1) <= NF) {
                    print $(i+1)
                }
            }
        }
    ' | sort | uniq -c
}

is_valid_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    local IFS=.
    local a b c d
    read -r a b c d <<< "$ip"

    for octet in "$a" "$b" "$c" "$d"; do
        if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
            return 1
        fi
    done

    return 0
}

is_ip_already_recorded() {
    local ip="$1"
    grep -qx "$ip" "$BLOCKLIST_FILE" 2>/dev/null
}

record_blocked_ip() {
    local ip="$1"
    if ! is_ip_already_recorded "$ip"; then
        echo "$ip" >> "$BLOCKLIST_FILE"
    fi
}

firewall_backend() {
    if command_exists iptables; then
        echo "iptables"
        return 0
    fi

    if command_exists nft; then
        echo "nft"
        return 0
    fi

    return 1
}

block_ip_firewall() {
    local ip="$1"
    local backend

    backend="$(firewall_backend)" || return 1

    if [ "$backend" = "iptables" ]; then
        if iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
            return 0
        fi
        iptables -A INPUT -s "$ip" -j DROP
        return $?
    fi

    if [ "$backend" = "nft" ]; then
        nft list table inet selfheal >/dev/null 2>&1 || nft add table inet selfheal
        nft list chain inet selfheal input >/dev/null 2>&1 || \
            nft add chain inet selfheal input "{ type filter hook input priority 0 ; }"

        nft list ruleset | grep -q "ip saddr $ip drop" && return 0
        nft add rule inet selfheal input ip saddr "$ip" drop
        return $?
    fi

    return 1
}

need_root_for_action() {
    [ "$(id -u)" -eq 0 ]
}

is_protected_process() {
    local pname="$1"
    local item

    for item in "${PROTECTED_PROCESSES[@]}"; do
        if [ "$pname" = "$item" ]; then
            return 0
        fi
    done

    return 1
}

get_top_cpu_process() {
    ps -eo pid=,comm=,%cpu= --sort=-%cpu | awk '
        {
            pname=$2
            if (pname != "ps" &&
                pname != "awk" &&
                pname != "grep" &&
                pname != "sort" &&
                pname != "head" &&
                pname != "tail" &&
                pname != "bash" &&
                pname != "monitor.sh" &&
                pname != "fixer.sh") {
                print $1, $2, $3
                exit
            }
        }
    '
}
