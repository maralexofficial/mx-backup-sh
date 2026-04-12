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

USER_NAME="$(whoami)"
success "Installing logrotate config for user: $USER_NAME"

mkdir -p "$LOGROTATE_DIR"
success "Logrotate directory ready: $LOGROTATE_DIR"

if [ -f "$CONFIG_FILE" ] && [ "${FORCE:-0}" -ne 1 ]; then
    error "Config already exists: $CONFIG_FILE"
    info "Use --force to overwrite"
    exit 1
fi

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

success "Created logrotate config: $CONFIG_FILE"

success "Select logrotate schedule:"
info "1) Daily at 03:00 (default)"
info "2) Custom"

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
    warn "Invalid choice, using default"
    CRON_SCHEDULE="0 3 * * *"
    ;;
esac

info "Using cron schedule: $CRON_SCHEDULE"

CRON_JOB="$CRON_SCHEDULE $LOGROTATE_BIN -s $STATUS_FILE $CONFIG_FILE"

(
    crontab -l 2>/dev/null | grep -v "$CONFIG_FILE" || true
    echo "$CRON_JOB"
) | crontab -

success "Cronjob installed"

info "Running test logrotate..."
"$LOGROTATE_BIN" -s "$STATUS_FILE" "$CONFIG_FILE"

success "Done ✅"
