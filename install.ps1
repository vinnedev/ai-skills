$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$CodexHome = Join-Path $env:USERPROFILE ".codex"
$CodexSkillsHome = Join-Path $CodexHome "skills"
$BackupSuffix = Get-Date -Format "yyyyMMdd_HHmmss"

function Write-Info($msg)  { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

function Backup-IfExists($target) {
    if (Test-Path $target) {
        $backup = "${target}.bak.${BackupSuffix}"
        Copy-Item -Path $target -Destination $backup -Recurse -Force
        Write-Warn "Backed up $(Split-Path -Leaf $target) -> $(Split-Path -Leaf $backup)"
    }
}

function Copy-ConfigFile($src, $dest) {
    if (-not (Test-Path $src)) {
        Write-Warn "Source not found: $src (skipping)"
        return
    }
    Backup-IfExists $dest
    Copy-Item -Path $src -Destination $dest -Force
    Write-Info "Installed $(Split-Path -Leaf $dest)"
}

function Copy-DirEntries($src, $dest) {
    if (-not (Test-Path $src)) {
        Write-Warn "Source directory not found: $src (skipping)"
        return
    }
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    $entries = Get-ChildItem -Path $src
    $count = 0
    foreach ($entry in $entries) {
        $destEntry = Join-Path $dest $entry.Name
        Backup-IfExists $destEntry
        if (Test-Path $destEntry) {
            Remove-Item $destEntry -Recurse -Force
        }
        Copy-Item -Path $entry.FullName -Destination $destEntry -Recurse -Force
        $count++
    }
    Write-Info "Installed $count entries into $(Split-Path -Leaf $dest)/"
}

function Test-CodexSkillsInstalled($skillsHome) {
    $required = @(
        ".system\skill-creator",
        ".system\skill-installer",
        "code-reviewer",
        "enterprise-code-architect",
        "openai-docs",
        "orchestrator",
        "performance-auditor",
        "screenshot",
        "security-auditor",
        "security-fix",
        "speech",
        "transcribe"
    )
    $missing = @()
    foreach ($skill in $required) {
        $skillFile = Join-Path $skillsHome "$skill\SKILL.md"
        if (-not (Test-Path $skillFile)) {
            $missing += $skill
        }
    }
    return $missing
}

Write-Host ""
Write-Host "================================================"
Write-Host "  AI Skills Installer (Windows)"
Write-Host "================================================"
Write-Host ""

$claudeExists = Get-Command claude -ErrorAction SilentlyContinue
$codexExists = Get-Command codex -ErrorAction SilentlyContinue
if (-not $claudeExists -and -not $codexExists) {
    Write-Warn "Neither 'claude' nor 'codex' CLI found in PATH."
    Write-Warn "Install them first, or configs will be ready when you do."
    Write-Host ""
}

Write-Host "--- Claude Code Configuration ---"
Write-Host ""

foreach ($dir in @("agents", "commands", "scripts", "memory")) {
    $path = Join-Path $ClaudeHome $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

Copy-ConfigFile (Join-Path $ScriptDir "claude\CLAUDE.md")       (Join-Path $ClaudeHome "CLAUDE.md")
Copy-ConfigFile (Join-Path $ScriptDir "claude\GO.md")            (Join-Path $ClaudeHome "GO.md")
Copy-ConfigFile (Join-Path $ScriptDir "claude\TYPESCRIPT.md")    (Join-Path $ClaudeHome "TYPESCRIPT.md")

Write-Host ""
Copy-DirEntries (Join-Path $ScriptDir "claude\agents")   (Join-Path $ClaudeHome "agents")
Copy-DirEntries (Join-Path $ScriptDir "claude\commands")  (Join-Path $ClaudeHome "commands")
Copy-DirEntries (Join-Path $ScriptDir "claude\memory")    (Join-Path $ClaudeHome "memory")

Copy-ConfigFile (Join-Path $ScriptDir "claude\scripts\orchestrate.py") (Join-Path $ClaudeHome "scripts\orchestrate.py")

Write-Host ""
Write-Host "--- Codex CLI Configuration ---"
Write-Host ""

foreach ($path in @($CodexHome, (Join-Path $CodexHome "rules"), $CodexSkillsHome)) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

Copy-ConfigFile (Join-Path $ScriptDir "codex\config.toml")       (Join-Path $CodexHome "config.toml")
Copy-ConfigFile (Join-Path $ScriptDir "codex\AGENTS.md")          (Join-Path $CodexHome "AGENTS.md")

Copy-DirEntries (Join-Path $ScriptDir "codex\rules")     (Join-Path $CodexHome "rules")
Copy-DirEntries (Join-Path $ScriptDir "codex\.agents\skills")  $CodexSkillsHome

$missingSkills = Test-CodexSkillsInstalled $CodexSkillsHome
if ($missingSkills.Count -eq 0) {
    Write-Info "Verified Codex skills in $CodexSkillsHome"
} else {
    Write-Warn ("Codex skills missing after install: " + ($missingSkills -join ", "))
}

Write-Host ""
Write-Host "================================================"
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Claude: $ClaudeHome"
Write-Host "  Codex:  $CodexHome"
Write-Host "  Skills: $CodexSkillsHome"
Write-Host ""
Write-Host "  Backups saved with suffix: .bak.$BackupSuffix"
Write-Host "================================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Run 'claude' to verify Claude Code picks up configs"
Write-Host "  - Run 'codex' to verify Codex picks up AGENTS.md and user skills"
Write-Host "  - Inside this repo, verify codex/AGENTS.md and codex/.agents/skills are visible"
Write-Host "  - Add trusted projects in codex config.toml manually if needed"
Write-Host "  - Auth tokens are NOT synced (run 'codex auth' on new machines)"
Write-Host ""
