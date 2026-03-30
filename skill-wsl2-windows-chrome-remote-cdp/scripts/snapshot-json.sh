#!/bin/bash
# snapshot-json.sh - Wrapper for OpenClaw browser snapshot with unified JSON envelope
#
# Usage:
#   ./snapshot-json.sh [target-id] [format]
#
# Examples:
#   ./snapshot-json.sh                              # Default AI snapshot
#   ./snapshot-json.sh abcd1234                     # Snapshot specific tab
#   ./snapshot-json.sh abcd1234 aria                # Aria format
#   ./snapshot-json.sh --interactive --limit 200    # Pass-through flags

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if first arg is a target-id or a flag
if [[ "${1:-}" == --* ]]; then
  # All args are flags, pass through
  EXTRA_ARGS=("$@")
  TARGET_ID=""
else
  TARGET_ID="${1:-}"
  FORMAT="${2:-ai}"
  EXTRA_ARGS=("${@:3}")
fi

# Build command
CMD=(openclaw browser --browser-profile remote snapshot)

if [[ -n "$TARGET_ID" && "$TARGET_ID" != --* ]]; then
  CMD+=(--target-id "$TARGET_ID")
fi

if [[ -n "${FORMAT:-}" && "$FORMAT" != --* ]]; then
  CMD+=(--format "$FORMAT")
fi

# Add extra flags
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

# Execute and wrap in unified envelope
"${CMD[@]}" | jq --slurp '{
  success: true,
  timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
  data: {
    snapshot: (.[0] // ""),
    refs: (.[0] | scan("@e[0-9]+") | unique)
  },
  command: ($ARGS.positional | join(" "))
}'
