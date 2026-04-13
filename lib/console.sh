#!/bin/bash

HOST="$(hostname -s)"
DATE="$(date '+%F %T')"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

LOG_DIR="${LOG_DIR:-$HOME/.mx-backup-sh}"
mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_FILE:-$LOG_DIR/app.log}"

confirm() {
  local prompt="${1:-Are you sure?} [y/N]: "
  read -r -p "$prompt" response

  case "$response" in
  [yY][eE][sS] | [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

setup_reply() {
  local msg="🛠️ $1"
  echo -e "$msg"
}

setup_step() {
  echo -e "➡️  $1"
}

setup_done() {
  echo -e "✅ $1"
}

_write_log() {
  echo "$1" >>"$LOG_FILE"
}

log() {
  local msg="$1"
  echo "$msg"
  _write_log "$msg"
}

info() {
  local msg="[$DATE] [$HOSTNAME] [INFO]  $1"
  echo -e "${CYAN}$msg${RESET}"
  _write_log "$msg"
}

success() {
  local msg="[$DATE] [$HOSTNAME] [SUCCESS] $1"
  echo -e "${GREEN}$msg${RESET}"
  _write_log "$msg"
}

warn() {
  local msg="[$DATE] [$HOSTNAME] [WARN] $1"
  echo -e "${YELLOW}$msg${RESET}"
  _write_log "$msg"
}

error() {
  local msg="[$DATE] [$HOSTNAME] [ERROR] $1"
  echo -e "${RED}$msg${RESET}" >&2
  _write_log "$msg"
}
