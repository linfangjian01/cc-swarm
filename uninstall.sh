#!/bin/bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

success() {
  echo -e "  ${GREEN}✓${NC} $1"
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
}

echo ""
echo -e "${BOLD}CC-Swarm Uninstaller${NC}"
echo "================================================"
echo ""

# ─── Remove hook scripts ─────────────────────────────────────────────
echo -e "${BOLD}[1/4]${NC} Removing hook scripts..."

if [[ -f "$HOOKS_DIR/architect-session-init.sh" ]]; then
  rm "$HOOKS_DIR/architect-session-init.sh"
  success "Removed architect-session-init.sh"
else
  warn "architect-session-init.sh not found, skipping"
fi

if [[ -f "$HOOKS_DIR/enforce-architect.sh" ]]; then
  rm "$HOOKS_DIR/enforce-architect.sh"
  success "Removed enforce-architect.sh"
else
  warn "enforce-architect.sh not found, skipping"
fi

# ─── Remove hooks config from settings.json ──────────────────────────
echo ""
echo -e "${BOLD}[2/4]${NC} Removing hooks config from settings.json..."

if [[ -f "$SETTINGS_FILE" ]]; then
  if command -v jq &>/dev/null; then
    CLEANED=$(jq 'del(.hooks)' "$SETTINGS_FILE")
    echo "$CLEANED" > "$SETTINGS_FILE"
    success "Removed hooks config from settings.json"
  else
    warn "jq not found, cannot clean settings.json automatically"
    warn "Please manually remove the \"hooks\" key from $SETTINGS_FILE"
  fi
else
  warn "settings.json not found, skipping"
fi

# ─── Remove CLAUDE.md ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[3/4]${NC} Removing CLAUDE.md..."

if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  rm "$CLAUDE_DIR/CLAUDE.md"
  success "Removed ~/.claude/CLAUDE.md"
else
  warn "~/.claude/CLAUDE.md not found, skipping"
fi

# ─── Done ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[4/4]${NC} Uninstall complete!"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  CC-Swarm uninstalled successfully.${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "  ${YELLOW}Please restart Claude Code for changes to take effect.${NC}"
echo ""
