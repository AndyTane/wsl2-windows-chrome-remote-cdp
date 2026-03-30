#!/usr/bin/env bash
set -euo pipefail
HOST_IP="$(ip route | awk '/default/ {print $3; exit}')"
if [[ -z "${HOST_IP}" ]]; then
  echo "ERROR: failed to detect WSL default gateway IP" >&2
  exit 1
fi
CDP_URL="http://${HOST_IP}:9223"
echo "HOST_IP=${HOST_IP}"
echo "CDP_URL=${CDP_URL}"
curl --connect-timeout 3 --max-time 5 "${CDP_URL}/json/version"
