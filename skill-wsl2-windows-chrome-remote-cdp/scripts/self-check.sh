#!/usr/bin/env bash
set -euo pipefail

missing=0

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK   command: $cmd -> $(command -v "$cmd")"
  else
    echo "MISS command: $cmd"
    missing=1
  fi
}

echo "Current directory: $(pwd)"

echo
if [[ -f "./SKILL.md" && -d "./scripts" && -d "./references" ]]; then
  echo "OK   current directory looks like the skill root"
else
  echo "MISS current directory is not the expected skill root"
  echo "Expected to see: ./SKILL.md ./scripts ./references"
  missing=1
fi

echo
echo "Checking required commands..."
check_cmd ip
check_cmd awk
check_cmd curl
check_cmd jq
check_cmd openclaw

echo
if [[ $missing -ne 0 ]]; then
  echo "Preflight check failed."
  echo
  echo "If jq is missing on Ubuntu/WSL, install it with:"
  echo "  sudo apt update"
  echo "  sudo apt install -y jq"
  echo
  echo "Common base tools if needed:"
  echo "  sudo apt update"
  echo "  sudo apt install -y jq curl iproute2"
  echo
  echo "Then re-run:"
  echo "  ./scripts/self-check.sh"
  exit 1
fi

echo "Preflight check passed."
echo "Suggested next steps:"
echo "  ./scripts/update-openclaw-remote-cdp.sh --dry-run"
echo "  ./scripts/update-openclaw-remote-cdp.sh --apply --set-default"
