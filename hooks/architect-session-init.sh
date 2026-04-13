#!/bin/bash
set -euo pipefail
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
[ -z "$session_id" ] && exit 0

# Persist session_id as environment variable
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export ARCHITECT_SESSION_ID='$session_id'" >> "$CLAUDE_ENV_FILE"
fi

# Create session communication directory
session_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}/cc-swarm/${session_id}"
mkdir -p "$session_dir"

# Create initial STATUS.md
if [ ! -f "$session_dir/STATUS.md" ]; then
  cat > "$session_dir/STATUS.md" << EOF
# Session: $session_id
- Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Status: Active
EOF
fi
exit 0
