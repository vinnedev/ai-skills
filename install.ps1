$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$CodexHome = Join-Path $env:USERPROFILE ".codex"
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

function Copy-DirContents($src, $dest) {
    if (-not (Test-Path $src)) {
        Write-Warn "Source directory not found: $src (skipping)"
        return
    }
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    $files = Get-ChildItem -Path $src -File
    $count = 0
    foreach ($f in $files) {
        $destFile = Join-Path $dest $f.Name
        Backup-IfExists $destFile
        Copy-Item -Path $f.FullName -Destination $destFile -Force
        $count++
    }
    Write-Info "Installed $count files into $(Split-Path -Leaf $dest)\"
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

foreach ($dir in @("agents", "commands", "scripts", "memory", "plugins")) {
    $path = Join-Path $ClaudeHome $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

Copy-ConfigFile (Join-Path $ScriptDir "claude\CLAUDE.md")       (Join-Path $ClaudeHome "CLAUDE.md")
Copy-ConfigFile (Join-Path $ScriptDir "claude\GO.md")            (Join-Path $ClaudeHome "GO.md")
Copy-ConfigFile (Join-Path $ScriptDir "claude\TYPESCRIPT.md")    (Join-Path $ClaudeHome "TYPESCRIPT.md")
Copy-ConfigFile (Join-Path $ScriptDir "claude\settings.json")    (Join-Path $ClaudeHome "settings.json")

Write-Host ""
$installLocal = Read-Host "Install settings.local.json? (contains machine-specific permissions) [y/N]"
if ($installLocal -eq "y" -or $installLocal -eq "Y") {
    Copy-ConfigFile (Join-Path $ScriptDir "claude\settings.local.json") (Join-Path $ClaudeHome "settings.local.json")
} else {
    Write-Info "Skipped settings.local.json"
}

Write-Host ""
Copy-DirContents (Join-Path $ScriptDir "claude\agents")   (Join-Path $ClaudeHome "agents")
Copy-DirContents (Join-Path $ScriptDir "claude\commands")  (Join-Path $ClaudeHome "commands")
Copy-DirContents (Join-Path $ScriptDir "claude\memory")    (Join-Path $ClaudeHome "memory")

Copy-ConfigFile (Join-Path $ScriptDir "claude\scripts\orchestrate.py") (Join-Path $ClaudeHome "scripts\orchestrate.py")

Write-Host ""
$installPlugins = Read-Host "Install plugin configs? (installed_plugins, blocklist, marketplaces) [y/N]"
if ($installPlugins -eq "y" -or $installPlugins -eq "Y") {
    Copy-ConfigFile (Join-Path $ScriptDir "claude\plugins\installed_plugins.json")   (Join-Path $ClaudeHome "plugins\installed_plugins.json")
    Copy-ConfigFile (Join-Path $ScriptDir "claude\plugins\blocklist.json")           (Join-Path $ClaudeHome "plugins\blocklist.json")
    Copy-ConfigFile (Join-Path $ScriptDir "claude\plugins\known_marketplaces.json")  (Join-Path $ClaudeHome "plugins\known_marketplaces.json")
} else {
    Write-Info "Skipped plugin configs"
}

Write-Host ""
Write-Host "--- Codex CLI Configuration ---"
Write-Host ""

foreach ($dir in @("rules", "skills")) {
    $path = Join-Path $CodexHome $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

Copy-ConfigFile (Join-Path $ScriptDir "codex\config.toml")       (Join-Path $CodexHome "config.toml")
Copy-ConfigFile (Join-Path $ScriptDir "codex\instructions.md")    (Join-Path $CodexHome "instructions.md")

Copy-DirContents (Join-Path $ScriptDir "codex\rules")     (Join-Path $CodexHome "rules")

Write-Host ""
Write-Host "================================================"
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Claude: $ClaudeHome"
Write-Host "  Codex:  $CodexHome"
Write-Host ""
Write-Host "  Backups saved with suffix: .bak.$BackupSuffix"
Write-Host "================================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Run 'claude' to verify Claude Code picks up configs"
Write-Host "  - Run 'codex' to verify Codex picks up configs"
Write-Host "  - Add trusted projects in codex config.toml manually"
Write-Host "  - Auth tokens are NOT synced (run 'codex auth' on new machines)"
Write-Host ""
