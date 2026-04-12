#!/bin/bash

init_discord() {
  if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    error "DISCORD_WEBHOOK_URL not set"
    return 1
  fi

  command -v curl >/dev/null 2>&1 || {
    error "curl not found"
    return 1
  }

  info "Discord provider initialized"
}

discord_send() {
  local title="$1"
  local message="$2"
  local priority="$3"
  local tags="$4"
  local color=3066993

  if [ "$priority" -ge 5 ]; then
    color=15158332
  fi

  payload=$(cat <<EOF
{
  "embeds": [
    {
      "title": "$title",
      "description": "$message\n\nTags: $tags",
      "color": $color,
      "footer": {
        "text": "[RCLONE-BACKUP-SYNC] github.com/maralexofficial"
      }
    }
  ]
}
EOF
)

  [ -z "${DISCORD_WEBHOOK_URL:-}" ] && {
    error "DISCORD_WEBHOOK_URL not set"
    return 1
  }

  local RC=1
  local attempts=0
  local max_attempts=3

  while [ $attempts -lt $max_attempts ]; do
    curl -s \
      -H "Content-Type: application/json" \
      -X POST \
      -d "$payload" \
      "$DISCORD_WEBHOOK_URL"

    RC=$?

    if [ "$RC" -eq 0 ]; then
      success "Discord notification sent"
      return 0
    fi

    attempts=$((attempts + 1))
    warn "Discord send failed (attempt $attempts/$max_attempts)"

    sleep 2
  done

  error "Discord failed after $max_attempts attempts (exit code: $RC)"
  return "$RC"
}