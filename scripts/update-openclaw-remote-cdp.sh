#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${HOME}/.openclaw/openclaw.json"
BACKUP_DIR="${HOME}/.openclaw/backups"
PROFILE_NAME="remote"
CDP_PORT="9223"
SET_DEFAULT="false"
MODE="apply"

usage() {
  cat <<'EOF'
Usage:
  update-openclaw-remote-cdp.sh [--dry-run|--apply] [--set-default] [--port <port>]

Options:
  --dry-run      Detect and validate only; do not modify config
  --apply        Detect, validate, backup, update config, restart gateway, validate
  --set-default  Also set browser.defaultProfile=remote
  --port <port>  Override CDP bridge port (default: 9223)
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $1" >&2
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --set-default) SET_DEFAULT="true"; shift ;;
    --port)
      [[ $# -ge 2 ]] || { echo "ERROR: --port requires a value" >&2; exit 1; }
      CDP_PORT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

need_cmd ip
need_cmd awk
need_cmd curl
need_cmd jq
need_cmd cp
need_cmd mkdir
need_cmd date
need_cmd mktemp
need_cmd mv

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: OpenClaw config not found: $CONFIG_FILE" >&2
  exit 1
fi

HOST_IP="$(ip route | awk '/default/ {print $3; exit}')"
if [[ -z "${HOST_IP}" ]]; then
  echo "ERROR: failed to detect WSL default gateway IP" >&2
  exit 1
fi

CDP_URL="http://${HOST_IP}:${CDP_PORT}"

echo "Detected Windows host IP : ${HOST_IP}"
echo "Target CDP URL          : ${CDP_URL}"

echo "Checking CDP endpoint: ${CDP_URL}/json/version"
curl --connect-timeout 3 --max-time 5 -fsS "${CDP_URL}/json/version" >/dev/null

echo "Checking CDP target list: ${CDP_URL}/json/list"
curl --connect-timeout 3 --max-time 5 -fsS "${CDP_URL}/json/list" >/dev/null

if [[ "$MODE" == "dry-run" ]]; then
  echo
  echo "Dry run only. No config changes made."
  echo "Suggested profile : ${PROFILE_NAME}"
  echo "Suggested cdpUrl  : ${CDP_URL}"
  echo "Suggested default : ${SET_DEFAULT}"
  exit 0
fi

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="${BACKUP_DIR}/openclaw.json.$(date +%Y%m%d-%H%M%S).bak"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

TMP_FILE="$(mktemp)"
if [[ "$SET_DEFAULT" == "true" ]]; then
  jq --arg profile "$PROFILE_NAME" --arg cdpUrl "$CDP_URL" '
    .browser = (.browser // {}) |
    .browser.defaultProfile = $profile |
    .browser.profiles = (.browser.profiles // {}) |
    .browser.profiles[$profile] = ((.browser.profiles[$profile] // {}) + {
      "cdpUrl": $cdpUrl,
      "attachOnly": true,
      "color": "#00AA00"
    })
  ' "$CONFIG_FILE" > "$TMP_FILE"
else
  jq --arg profile "$PROFILE_NAME" --arg cdpUrl "$CDP_URL" '
    .browser = (.browser // {}) |
    .browser.profiles = (.browser.profiles // {}) |
    .browser.profiles[$profile] = ((.browser.profiles[$profile] // {}) + {
      "cdpUrl": $cdpUrl,
      "attachOnly": true,
      "color": "#00AA00"
    })
  ' "$CONFIG_FILE" > "$TMP_FILE"
fi

mv "$TMP_FILE" "$CONFIG_FILE"

echo "Updated: $CONFIG_FILE"
echo "Profile : $PROFILE_NAME"
echo "cdpUrl  : $CDP_URL"
if [[ "$SET_DEFAULT" == "true" ]]; then
  echo "defaultProfile set to: $PROFILE_NAME"
fi

echo "Restarting OpenClaw gateway..."
if command -v openclaw >/dev/null 2>&1; then
  openclaw gateway restart || true
elif command -v systemctl >/dev/null 2>&1; then
  systemctl --user restart openclaw-gateway.service || true
fi

sleep 2

echo
echo "Validation:"
openclaw browser profiles || true
echo
openclaw browser --browser-profile "$PROFILE_NAME" status || true

echo
echo "Done."
