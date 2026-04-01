#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
CODEX_SKILLS_HOME="${CODEX_HOME}/skills"
MANIFEST_PATH="${CODEX_HOME}/ai-skills-manifest.txt"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"
declare -a MANIFEST_ENTRIES=()
BACKUP_PATH=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

add_manifest_entry() {
    local path="$1"
    local backup="$2"
    [ -n "$path" ] && MANIFEST_ENTRIES+=("${path}\t${backup}")
}

backup_if_exists() {
    local target="$1"
    BACKUP_PATH=""
    if [ -e "$target" ]; then
        local backup="${target}.bak.${BACKUP_SUFFIX}"
        cp -r "$target" "$backup"
        warn "Backed up existing $(basename "$target") -> $(basename "$backup")"
        BACKUP_PATH="$backup"
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
    add_manifest_entry "$dest" "$BACKUP_PATH"
    info "Installed $(basename "$dest")"
}

copy_dir_entries() {
    local src="$1"
    local dest="$2"
    if [ ! -d "$src" ]; then
        warn "Source directory not found: $src (skipping)"
        return
    fi
    mkdir -p "$dest"
    shopt -s dotglob nullglob
    local count=0
    for f in "$src"/*; do
        local basename="$(basename "$f")"
        backup_if_exists "$dest/$basename"
        rm -rf "$dest/$basename"
        cp -R "$f" "$dest/$basename"
        add_manifest_entry "$dest/$basename" "$BACKUP_PATH"
        count=$((count + 1))
    done
    shopt -u dotglob nullglob
    info "Installed $count entries into $(basename "$dest")/"
}

verify_codex_skills() {
    local skills_source="$1"
    local skills_home="$2"
    if [ ! -d "$skills_source" ]; then
        return
    fi
    local missing=()
    for source_path in "$skills_source"/*; do
        [ -e "$source_path" ] || continue
        local skill
        skill="$(basename "$source_path")"
        if [ ! -f "$skills_home/$skill/SKILL.md" ]; then
            missing+=("$skill")
        fi
    done
    if [ ${#missing[@]} -eq 0 ]; then
        info "Verified Codex skills in $skills_home"
    else
        warn "Codex skills missing after install: ${missing[*]}"
    fi
}

write_manifest() {
    mkdir -p "$(dirname "$MANIFEST_PATH")"
    printf '%b\n' "${MANIFEST_ENTRIES[@]}" | awk -F '\t' 'NF { m[$1]=$2 } END { for (k in m) printf "%s\t%s\n", k, m[k] }' > "$MANIFEST_PATH"
    info "Wrote install manifest: $MANIFEST_PATH"
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
copy_dir_entries "$SCRIPT_DIR/claude/agents"   "$CLAUDE_HOME/agents"
copy_dir_entries "$SCRIPT_DIR/claude/commands"  "$CLAUDE_HOME/commands"
copy_dir_entries "$SCRIPT_DIR/claude/memory"    "$CLAUDE_HOME/memory"

copy_file "$SCRIPT_DIR/claude/scripts/orchestrate.py" "$CLAUDE_HOME/scripts/orchestrate.py"
chmod +x "$CLAUDE_HOME/scripts/orchestrate.py"

echo ""
echo "--- Codex CLI Configuration ---"
echo ""

mkdir -p "$CODEX_HOME"/rules "$CODEX_SKILLS_HOME"

copy_file "$SCRIPT_DIR/codex/config.toml"       "$CODEX_HOME/config.toml"
copy_file "$SCRIPT_DIR/codex/AGENTS.md"          "$CODEX_HOME/AGENTS.md"

copy_dir_entries "$SCRIPT_DIR/codex/rules"      "$CODEX_HOME/rules"
copy_dir_entries "$SCRIPT_DIR/codex/.agents/skills"   "$CODEX_SKILLS_HOME"
write_manifest
verify_codex_skills "$SCRIPT_DIR/codex/.agents/skills" "$CODEX_SKILLS_HOME"

echo ""
echo "================================================"
echo -e "  ${GREEN}Installation complete!${NC}"
echo ""
echo "  Claude: $CLAUDE_HOME"
echo "  Codex:  $CODEX_HOME"
echo "  Skills: $CODEX_SKILLS_HOME"
echo ""
echo "  Backups saved with suffix: .bak.$BACKUP_SUFFIX"
echo "================================================"
echo ""
echo "Next steps:"
echo "  - Run 'claude' to verify Claude Code picks up configs"
echo "  - Run 'codex' to verify Codex picks up AGENTS.md and user skills"
echo "  - Inside this repo, verify codex/AGENTS.md and codex/.agents/skills are visible"
echo "  - Add trusted projects in codex config.toml manually if needed"
echo "  - Auth tokens are NOT synced (run 'codex auth' on new machines)"
echo ""
