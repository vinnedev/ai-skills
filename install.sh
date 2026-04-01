#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ]; then
        local backup="${target}.bak.${BACKUP_SUFFIX}"
        cp -r "$target" "$backup"
        warn "Backed up existing $(basename "$target") -> $(basename "$backup")"
    fi
}

copy_file() {
    local src="$1"
    local dest="$2"
    if [ ! -f "$src" ]; then
        warn "Source not found: $src (skipping)"
        return
    fi
    backup_if_exists "$dest"
    cp "$src" "$dest"
    info "Installed $(basename "$dest")"
}

copy_dir_contents() {
    local src="$1"
    local dest="$2"
    if [ ! -d "$src" ]; then
        warn "Source directory not found: $src (skipping)"
        return
    fi
    mkdir -p "$dest"
    local count=0
    for f in "$src"/*; do
        [ -e "$f" ] || continue
        local basename="$(basename "$f")"
        backup_if_exists "$dest/$basename"
        cp "$f" "$dest/$basename"
        count=$((count + 1))
    done
    info "Installed $count files into $(basename "$dest")/"
}

echo ""
echo "================================================"
echo "  AI Skills Installer (macOS / Linux)"
echo "================================================"
echo ""

if ! command -v claude &>/dev/null && ! command -v codex &>/dev/null; then
    warn "Neither 'claude' nor 'codex' CLI found in PATH."
    warn "Install them first, or configs will be ready when you do."
    echo ""
fi

echo "--- Claude Code Configuration ---"
echo ""

mkdir -p "$CLAUDE_HOME"/{agents,commands,scripts,memory}

copy_file "$SCRIPT_DIR/claude/CLAUDE.md"       "$CLAUDE_HOME/CLAUDE.md"
copy_file "$SCRIPT_DIR/claude/GO.md"            "$CLAUDE_HOME/GO.md"
copy_file "$SCRIPT_DIR/claude/TYPESCRIPT.md"    "$CLAUDE_HOME/TYPESCRIPT.md"

echo ""
copy_dir_contents "$SCRIPT_DIR/claude/agents"   "$CLAUDE_HOME/agents"
copy_dir_contents "$SCRIPT_DIR/claude/commands"  "$CLAUDE_HOME/commands"
copy_dir_contents "$SCRIPT_DIR/claude/memory"    "$CLAUDE_HOME/memory"

copy_file "$SCRIPT_DIR/claude/scripts/orchestrate.py" "$CLAUDE_HOME/scripts/orchestrate.py"
chmod +x "$CLAUDE_HOME/scripts/orchestrate.py"

echo ""
echo "--- Codex CLI Configuration ---"
echo ""

mkdir -p "$CODEX_HOME"/rules

copy_file "$SCRIPT_DIR/codex/config.toml"       "$CODEX_HOME/config.toml"
copy_file "$SCRIPT_DIR/codex/instructions.md"    "$CODEX_HOME/instructions.md"

copy_dir_contents "$SCRIPT_DIR/codex/rules"     "$CODEX_HOME/rules"

echo ""
echo "================================================"
echo -e "  ${GREEN}Installation complete!${NC}"
echo ""
echo "  Claude: $CLAUDE_HOME"
echo "  Codex:  $CODEX_HOME"
echo ""
echo "  Backups saved with suffix: .bak.$BACKUP_SUFFIX"
echo "================================================"
echo ""
echo "Next steps:"
echo "  - Run 'claude' to verify Claude Code picks up configs"
echo "  - Run 'codex' to verify Codex picks up configs"
echo "  - Add trusted projects in codex config.toml manually"
echo "  - Auth tokens are NOT synced (run 'codex auth' on new machines)"
echo ""
