#!/bin/bash

# =========================
# AutoHeal-Linux Config
# =========================

# Thresholds
CPU_THRESHOLD=95
MEM_THRESHOLD=85
DISK_THRESHOLD=90
FAILED_LOGIN_THRESHOLD=5

# SSH service candidates
SERVICE_CANDIDATES=("ssh" "sshd")

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
BACKUP_DIR="$PROJECT_DIR/backups"
SAMPLE_DIR="$PROJECT_DIR/sample_data"
LOG_FILE="$LOG_DIR/system.log"
BLOCKLIST_FILE="$LOG_DIR/blocked_ips.txt"

# Backup items
BACKUP_ITEMS=(
  "$LOG_DIR"
  "$PROJECT_DIR/config.sh"
  "$SAMPLE_DIR"
)

# Auth log candidates
AUTH_LOG_CANDIDATES=(
  "/var/log/auth.log"
  "/var/log/secure"
)

# Safe cleanup targets only
CLEANUP_TARGETS=(
  "$PROJECT_DIR/sample_data/temp"
)

# Cron schedule
CRON_SCHEDULE="* * * * *"

# Remote backup settings
ENABLE_REMOTE_BACKUP=0
REMOTE_USER="youruser"
REMOTE_HOST="192.168.1.100"
REMOTE_PATH="/home/youruser/remote_backups"

# Feature toggles
ENABLE_FIREWALL_BLOCK=1
ENABLE_SERVICE_RESTART=1
ENABLE_SAFE_CLEANUP=1
ENABLE_BACKUP_BEFORE_FIX=1
ENABLE_CPU_PROCESS_CONTROL=1

# Processes that should never be killed by CPU control
PROTECTED_PROCESSES=(
  "systemd"
  "init"
  "bash"
  "sshd"
  "ssh"
  "cron"
  "crond"
  "systemctl"
  "monitor.sh"
  "fixer.sh"
  "dashboard.sh"
  "ps"
  "awk"
  "grep"
  "sort"
  "head"
  "tail"
)
