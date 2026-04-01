#!/usr/bin/env bash
set -euo pipefail

CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "================================================"
echo "  AI Skills Uninstaller (macOS / Linux)"
echo "================================================"
echo ""
echo -e "${YELLOW}This will remove AI skill configs from:${NC}"
echo "  Claude: $CLAUDE_HOME"
echo "  Codex:  $CODEX_HOME"
echo ""
read -rp "Are you sure? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

CLAUDE_FILES=(
    "$CLAUDE_HOME/CLAUDE.md"
    "$CLAUDE_HOME/GO.md"
    "$CLAUDE_HOME/TYPESCRIPT.md"
    "$CLAUDE_HOME/settings.json"
    "$CLAUDE_HOME/settings.local.json"
    "$CLAUDE_HOME/scripts/orchestrate.py"
    "$CLAUDE_HOME/plugins/installed_plugins.json"
    "$CLAUDE_HOME/plugins/blocklist.json"
    "$CLAUDE_HOME/plugins/known_marketplaces.json"
)

for f in "${CLAUDE_FILES[@]}"; do
    if [ -f "$f" ]; then
        rm "$f"
        info "Removed $(basename "$f")"
    fi
done

for dir in agents commands memory; do
    target="$CLAUDE_HOME/$dir"
    if [ -d "$target" ] && [ "$(ls -A "$target" 2>/dev/null)" ]; then
        rm -f "$target"/*.md
        info "Cleared $dir/"
    fi
done

CODEX_FILES=(
    "$CODEX_HOME/config.toml"
    "$CODEX_HOME/instructions.md"
)

for f in "${CODEX_FILES[@]}"; do
    if [ -f "$f" ]; then
        rm "$f"
        info "Removed $(basename "$f")"
    fi
done

if [ -d "$CODEX_HOME/rules" ] && [ "$(ls -A "$CODEX_HOME/rules" 2>/dev/null)" ]; then
    rm -f "$CODEX_HOME/rules"/*
    info "Cleared codex rules/"
fi

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo "Note: Backup files (.bak.*) were NOT removed."
echo ""
