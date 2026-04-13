#!/bin/bash
set -euo pipefail
input=$(cat)
agent_id=$(echo "$input" | jq -r '.agent_id // empty')
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# Subagent (has agent_id) → allow
[ -n "$agent_id" ] && exit 0

# Main agent → only allow ~/.claude/ system files (plans, memory, etc.)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
if [ -n "$file_path" ] && [[ "$file_path" == "$HOME/.claude/"* ]]; then
  exit 0
fi

# Deny main-agent file mutations
echo "ARCHITECT MODE: Main agent cannot use ${tool_name} directly. Delegate to a subagent via the Agent tool. The subagent will write results to claude_dev/\$ARCHITECT_SESSION_ID/." >&2
exit 2
