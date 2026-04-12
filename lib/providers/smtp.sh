#!/bin/bash

init_smtp() {
  [ -z "${SMTP_TO:-}" ] && {
    error "SMTP_TO not set"
    return 1
  }

  [ -z "${SMTP_FROM:-}" ] && {
    error "SMTP_FROM not set"
    return 1
  }

  command -v mail >/dev/null 2>&1 || {
    error "mail command not found"
    return 1
  }

  warn "SMTP provider initialized"
}

smtp_send() {
  local title="$1"
  local message="$2"
  local priority="$3"
  local tags="$4"

  [ -z "${SMTP_TO:-}" ] && {
    error "SMTP_TO not set"
    return 1
  }

  [ -z "${SMTP_FROM:-}" ] && {
    error "SMTP_FROM not set"
    return 1
  }

  local subject="${SMTP_SUBJECT_PREFIX:-} $title"

  local RC=1
  local attempts=0
  local max_attempts=3

  while [ $attempts -lt $max_attempts ]; do
    echo "$message" | mail \
      -s "$subject" \
      -r "$SMTP_FROM" \
      "$SMTP_TO"

    RC=$?

    if [ "$RC" -eq 0 ]; then
      success "SMTP sent successfully"
      return 0
    fi

    attempts=$((attempts + 1))
    warn "SMTP failed (attempt $attempts/$max_attempts)"

    sleep 1
  done

  error "SMTP failed after $max_attempts attempts"
  return "$RC"
}