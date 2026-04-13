#!/bin/bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── Defaults ─────────────────────────────────────────────────────────
LANG_CHOICE="en"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ─── Parse arguments ──────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)
      LANG_CHOICE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--lang en|cn]"
      exit 1
      ;;
  esac
done

if [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "cn" ]]; then
  echo -e "${RED}Invalid language: $LANG_CHOICE (must be 'en' or 'cn')${NC}"
  exit 1
fi

TOTAL_STEPS=6
STEP=0

step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BOLD}[${STEP}/${TOTAL_STEPS}]${NC} $1"
}

success() {
  echo -e "  ${GREEN}✓${NC} $1"
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  exit 1
}

echo ""
echo -e "${BOLD}CC-Swarm Installer${NC}"
echo "================================================"

# ─── Step 1: Check dependencies ──────────────────────────────────────
step "Checking dependencies..."

if ! command -v jq &>/dev/null; then
  fail "jq is not installed. Please install jq first (e.g. apt install jq / brew install jq)."
fi
success "jq is installed"

# ─── Step 2: Create hooks directory & copy hook scripts ──────────────
step "Installing hook scripts..."

mkdir -p "$HOOKS_DIR"
success "Created $HOOKS_DIR"

cp "$SCRIPT_DIR/hooks/architect-session-init.sh" "$HOOKS_DIR/architect-session-init.sh"
chmod +x "$HOOKS_DIR/architect-session-init.sh"
success "Installed architect-session-init.sh"

cp "$SCRIPT_DIR/hooks/enforce-architect.sh" "$HOOKS_DIR/enforce-architect.sh"
chmod +x "$HOOKS_DIR/enforce-architect.sh"
success "Installed enforce-architect.sh"

# ─── Step 3: Copy CLAUDE.md template ─────────────────────────────────
step "Installing CLAUDE.md (lang=${LANG_CHOICE})..."

if [[ "$LANG_CHOICE" == "cn" ]]; then
  TEMPLATE_FILE="$SCRIPT_DIR/templates/CLAUDE_CN.md"
else
  TEMPLATE_FILE="$SCRIPT_DIR/templates/CLAUDE.md"
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  fail "Template not found: $TEMPLATE_FILE"
fi

cp "$TEMPLATE_FILE" "$CLAUDE_DIR/CLAUDE.md"
success "Copied $(basename "$TEMPLATE_FILE") -> ~/.claude/CLAUDE.md"

# ─── Step 4: Merge hooks config into settings.json ───────────────────
step "Merging hooks config into settings.json..."

HOOKS_CONFIG='{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/architect-session-init.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/enforce-architect.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}'

if [[ -f "$SETTINGS_FILE" ]]; then
  # Backup existing settings
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
  success "Backed up settings.json -> settings.json.bak"

  # Deep merge: existing settings * (overwrite with hooks config)
  MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOKS_CONFIG"))
  echo "$MERGED" > "$SETTINGS_FILE"
  success "Merged hooks config into existing settings.json"
else
  mkdir -p "$CLAUDE_DIR"
  echo "$HOOKS_CONFIG" | jq '.' > "$SETTINGS_FILE"
  success "Created new settings.json with hooks config"
fi

# ─── Step 5: Update .gitignore ───────────────────────────────────────
step "Checking .gitignore..."

GITIGNORE_FILE="$(pwd)/.gitignore"
if [[ -f "$GITIGNORE_FILE" ]]; then
  if ! grep -qx 'claude_dev/' "$GITIGNORE_FILE" 2>/dev/null; then
    echo 'claude_dev/' >> "$GITIGNORE_FILE"
    success "Added 'claude_dev/' to .gitignore"
  else
    warn "'claude_dev/' already in .gitignore, skipping"
  fi
else
  warn "No .gitignore found in current directory, skipping"
fi

# ─── Step 6: Done ────────────────────────────────────────────────────
step "Installation complete!"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  CC-Swarm installed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "  Installed files:"
echo "    - $HOOKS_DIR/architect-session-init.sh"
echo "    - $HOOKS_DIR/enforce-architect.sh"
echo "    - $CLAUDE_DIR/CLAUDE.md"
echo "    - $SETTINGS_FILE (hooks config merged)"
if [[ -f "${SETTINGS_FILE}.bak" ]]; then
echo "    - ${SETTINGS_FILE}.bak (backup)"
fi
echo ""
echo -e "  ${YELLOW}Please restart Claude Code for changes to take effect.${NC}"
echo ""
