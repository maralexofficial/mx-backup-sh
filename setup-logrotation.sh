#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -euo pipefail

source "$SCRIPT_DIR/lib/console.sh"

FORCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --force)
        FORCE=1
        shift
        ;;
    *)
        error "Unknown argument: $1"
        exit 1
        ;;
    esac
done

LOGROTATE_BIN="$(command -v logrotate)"
if [ -z "$LOGROTATE_BIN" ]; then
    error "logrotate not found."
    exit 1
fi

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    error "Env file not found: $ENV_FILE"
    exit 1
fi

LOGROTATE_DIR="${HOME}/.config/logrotate"
CONFIG_FILE="${LOGROTATE_DIR}/mx_backup_sh.conf"
STATUS_FILE="${LOGROTATE_DIR}/status"

setup_step "Logrotate installation started"

USER_NAME="$(whoami)"
setup_reply "Installing logrotate config for user: $USER_NAME"

setup_step "Preparing directories"

mkdir -p "$LOGROTATE_DIR"

setup_done "Directory ready: $LOGROTATE_DIR"
setup_step "Checking existing config"

if [ -f "$CONFIG_FILE" ] && [ "${FORCE:-0}" -ne 1 ]; then
    error "Config already exists: $CONFIG_FILE"
    info "Use --force to overwrite"
    exit 1
fi

setup_done "Config check passed"
setup_step "Writing logrotate configuration"

cat >"$CONFIG_FILE" <<EOF
$LOG_DIR/*.log {
  daily
  rotate 7
  compress
  missingok
  notifempty
  copytruncate
}
EOF

setup_done "Config created: $CONFIG_FILE"
setup_step "Configuring schedule"

setup_reply "Select logrotate schedule:"
setup_reply "1) Daily at 03:00 (default)"
setup_reply "2) Custom"

read -r -p "Choice [1]: " CHOICE
CHOICE="${CHOICE:-1}"

case "$CHOICE" in
1)
    CRON_SCHEDULE="0 3 * * *"
    ;;
2)
    read -r -p "Enter cron expression (e.g. '*/15 * * * *'): " CRON_SCHEDULE
    ;;
*)
    setup_reply "Invalid choice, using default"
    CRON_SCHEDULE="0 3 * * *"
    ;;
esac

setup_done "Schedule set: $CRON_SCHEDULE"
setup_step "Installing cron job"

CRON_JOB="$CRON_SCHEDULE $LOGROTATE_BIN -s $STATUS_FILE $CONFIG_FILE"

(
    crontab -l 2>/dev/null | grep -v "$CONFIG_FILE" || true
    echo "$CRON_JOB"
) | crontab -

setup_done "Cronjob installed"
setup_step "Testing logrotate"

"$LOGROTATE_BIN" -s "$STATUS_FILE" "$CONFIG_FILE"

setup_done "Test run completed"
setup_step "Finalizing"

setup_done "Setup complete ✅"
