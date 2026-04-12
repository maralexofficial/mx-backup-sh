#!/bin/bash

init_ntfy() {
  if [ -z "${NTFY:-}" ]; then
    NTFY="/usr/bin/ntfy-send"
    warn "NTFY not set. Using default: $NTFY"
  fi

  if [ ! -x "$NTFY" ]; then
    error "NTFY binary not executable: $NTFY"
    return 1
  fi

  info "NTFY provider initialized"
}

ntfy_send() {
  local title="$1"
  local message="$2"
  local priority="$3"
  local tags="$4"

  local RC=1
  local attempts=0
  local max_attempts=3

  while [ $attempts -lt $max_attempts ]; do
    local topic="${NTFY_TOPIC:-DEFAULT}"

    "$NTFY" "$topic" "$title" "$message" \
      --prio="$priority" \
      --tags="$tags"

    RC=$?

    if [ "$RC" -eq 0 ]; then
      success "NTFY sent successfully"
      return 0
    fi

    attempts=$((attempts + 1))
    warn "NTFY failed (attempt $attempts/$max_attempts)"

    sleep 1
  done

  error "NTFY failed after $max_attempts attempts"
  return "$RC"
}