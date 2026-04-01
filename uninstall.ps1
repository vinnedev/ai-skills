param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$CodexHome = Join-Path $env:USERPROFILE ".codex"
$CodexSkillsHome = Join-Path $CodexHome "skills"
$ManifestPath = Join-Path $CodexHome "ai-skills-manifest.txt"

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
Write-Host "  Manifest: $ManifestPath"
Write-Host ""
if (-not $Force) {
    $confirm = Read-Host "Are you sure? [y/N]"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Aborted."
        exit 0
    }
} else {
    Write-Host "Running in force mode (no confirmation prompt)." -ForegroundColor Yellow
}

Write-Host ""

if (-not (Test-Path $ManifestPath)) {
    Write-Host "No install manifest found. Nothing will be removed to avoid deleting unmanaged files." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

$manifestEntries = Get-Content -Path $ManifestPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$manifestEntries = $manifestEntries | Sort-Object { ($_ -split "`t", 2)[0].Length } -Descending

foreach ($entry in $manifestEntries) {
    $parts = $entry -split "`t", 2
    $path = $parts[0]
    $backup = if ($parts.Count -gt 1) { $parts[1] } else { "" }

    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Info "Removed $(Split-Path -Leaf $path)"
    }

    if (-not [string]::IsNullOrWhiteSpace($backup) -and (Test-Path $backup)) {
        $parent = Split-Path -Parent $path
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Move-Item -Path $backup -Destination $path -Force
        Write-Info "Restored $(Split-Path -Leaf $path) from backup"
    }
}

if (Test-Path $ManifestPath) {
    Remove-Item -Path $ManifestPath -Force
    Write-Info "Removed install manifest"
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green
Write-Host "Note: Backup files (.bak.*) were NOT removed."
Write-Host ""
exit 0
