load_provider() {
  case "${NOTIFY_TYPE:-}" in
    ntfy)
      source "$(dirname "$0")/lib/providers/ntfy.sh"
      init_ntfy
      PROVIDER_SEND="ntfy_send"
      ;;
    smtp)
      source "$(dirname "$0")/lib/providers/smtp.sh"
      init_smtp
      PROVIDER_SEND="smtp_send"
      ;;
    discord)
      source "$(dirname "$0")/lib/providers/discord.sh"
      init_discord
      PROVIDER_SEND="discord_send"
      ;;
    *)
      error "Unknown NOTIFY_TYPE: ${NOTIFY_TYPE:-}"
      return 1
      ;;
  esac
}

notify() {
  local title="$1"
  local message="$2"
  local priority="$3"
  local tags="$4"

  if [ -z "${NOTIFY_PROVIDER_LOADED:-}" ]; then
    if ! load_provider; then
      error "Failed to load notification provider"
      return 1
    fi
    NOTIFY_PROVIDER_LOADED=1
  fi

  "$PROVIDER_SEND" "$title" "$message" "$priority" "$tags"
}