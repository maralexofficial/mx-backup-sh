#!/bin/bash

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

_write_log() {
  echo "[$(date '+%F %T')] $1" >>"$LOG_FILE"
}

log() {
  local msg="$1"
  echo "[$(date '+%F %T')] $msg"
  _write_log "$msg"
}

info() {
  local msg="[INFO] $1"
  echo -e "${CYAN}$msg${RESET}"
  _write_log "$msg"
}

success() {
  local msg="[SUCCESS] $1"
  echo -e "${GREEN}$msg${RESET}"
  _write_log "$msg"
}

warn() {
  local msg="[WARN] $1"
  echo -e "${YELLOW}$msg${RESET}"
  _write_log "$msg"
}

error() {
  local msg="[ERROR] $1"
  echo -e "${RED}$msg${RESET}" >&2
  _write_log "$msg"
}