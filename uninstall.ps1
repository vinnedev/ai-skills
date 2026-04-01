$ErrorActionPreference = "Stop"

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$CodexHome = Join-Path $env:USERPROFILE ".codex"
$CodexSkillsHome = Join-Path $CodexHome "skills"

function Write-Info($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }

Write-Host ""
Write-Host "================================================"
Write-Host "  AI Skills Uninstaller (Windows)"
Write-Host "================================================"
Write-Host ""
Write-Host "This will remove AI skill configs from:" -ForegroundColor Yellow
Write-Host "  Claude: $ClaudeHome"
Write-Host "  Codex:  $CodexHome"
Write-Host "  Skills: $CodexSkillsHome"
Write-Host ""
$confirm = Read-Host "Are you sure? [y/N]"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Aborted."
    exit 0
}

Write-Host ""

$claudeFiles = @(
    (Join-Path $ClaudeHome "CLAUDE.md"),
    (Join-Path $ClaudeHome "GO.md"),
    (Join-Path $ClaudeHome "TYPESCRIPT.md"),
    (Join-Path $ClaudeHome "scripts\orchestrate.py")
)

foreach ($f in $claudeFiles) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Info "Removed $(Split-Path -Leaf $f)"
    }
}

foreach ($dir in @("agents", "commands", "memory")) {
    $path = Join-Path $ClaudeHome $dir
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter "*.md" | Remove-Item -Force
        Write-Info "Cleared $dir/"
    }
}

$codexFiles = @(
    (Join-Path $CodexHome "config.toml"),
    (Join-Path $CodexHome "instructions.md"),
    (Join-Path $CodexHome "AGENTS.md")
)

foreach ($f in $codexFiles) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Info "Removed $(Split-Path -Leaf $f)"
    }
}

$rulesDir = Join-Path $CodexHome "rules"
if (Test-Path $rulesDir) {
    Get-ChildItem -Path $rulesDir | Remove-Item -Force
    Write-Info "Cleared codex rules/"
}

foreach ($skill in @("orchestrator", "enterprise-code-architect", "code-reviewer", "security-auditor", "security-fix", "performance-auditor")) {
    $skillPath = Join-Path $CodexSkillsHome $skill
    if (Test-Path $skillPath) {
        Remove-Item $skillPath -Recurse -Force
        Write-Info "Removed skill $skill"
    }
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green
Write-Host "Note: Backup files (.bak.*) were NOT removed."
Write-Host ""
