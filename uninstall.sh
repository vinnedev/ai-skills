#!/usr/bin/env bash
set -euo pipefail

FORCE=0
if [ "${1:-}" = "--force" ]; then
    FORCE=1
fi

CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
CODEX_SKILLS_HOME="${CODEX_HOME}/skills"
MANIFEST_PATH="${CODEX_HOME}/ai-skills-manifest.txt"

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
echo "  Skills: $CODEX_SKILLS_HOME"
echo "  Manifest: $MANIFEST_PATH"
echo ""
if [ "$FORCE" -ne 1 ]; then
    read -rp "Are you sure? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
else
    warn "Running in force mode (no confirmation prompt)."
fi

echo ""

if [ ! -f "$MANIFEST_PATH" ]; then
    warn "No install manifest found. Nothing will be removed to avoid deleting unmanaged files."
    echo ""
    exit 0
fi

while IFS=$'\t' read -r path backup; do
    [ -n "$path" ] || continue
    if [ -e "$path" ]; then
        if [ -d "$path" ]; then
            rm -rf "$path"
        else
            rm -f "$path"
        fi
        info "Removed $(basename "$path")"
    fi

    if [ -n "${backup:-}" ] && [ -e "$backup" ]; then
        mkdir -p "$(dirname "$path")"
        mv "$backup" "$path"
        info "Restored $(basename "$path") from backup"
    fi
done < <(awk -F '\t' 'NF { print length($1) "\t" $0 }' "$MANIFEST_PATH" | sort -rn -k1,1 | cut -f2-)

rm -f "$MANIFEST_PATH"
info "Removed install manifest"

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo "Note: Backup files (.bak.*) were NOT removed."
echo ""
exit 0
