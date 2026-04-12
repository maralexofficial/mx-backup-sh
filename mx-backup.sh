#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -euo pipefail

source "$SCRIPT_DIR/lib/console.sh"

ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  error "Env file not found: $ENV_FILE"
  exit 1
fi

CONFIG="$SCRIPT_DIR/.config"

if [ ! -f "$CONFIG" ]; then
  error "Config not found: $CONFIG"
  exit 1
fi

source "$CONFIG"

HOST="$(hostname -s)"
DATE="$(date '+%F %T')"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

TARGET_DIR="$TARGET_BASE/$TARGET_DIR"
BACKUP_FILE="$TARGET_DIR/${BACKUP_NAME}_$TIMESTAMP.tar.gz"

mkdir -p "$TARGET_DIR"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_DIR"

source "$SCRIPT_DIR/lib/notifications.sh"

info "[$HOSTNAME][$DATE] Backup job started"

EXCLUDE_ARGS=()
for ex in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=("--exclude=$ex")
done

tar -czf "$BACKUP_FILE" "${EXCLUDE_ARGS[@]}" "${BACKUP_PATHS[@]}"

RC=$?

if [ $RC -eq 0 ]; then
  chown "$TARGET_USER:$TARGET_USER" "$BACKUP_FILE"

  MSG="Backup job on $HOSTNAME finished: $DATE"
  PRIO="3"
  STATUS="SUCCESS"
  success "$MSG"
else
  MSG="Backup job on $HOSTNAME FAILED: $DATE"
  PRIO="5"
  STATUS="ERROR"
  error "$MSG"
fi

notify "$TITLE_SYNC" "$MSG" "$PRIO" "$TAGS_SYNC"
