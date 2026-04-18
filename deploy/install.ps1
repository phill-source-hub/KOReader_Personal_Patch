# ============================================================================
# KOReader Personal Patch - installer (Windows / PowerShell)
# ----------------------------------------------------------------------------
# Usage:
#   .\deploy\install.ps1 E:\koreader
#
# Or without arguments to auto-detect:
#   .\deploy\install.ps1
# ============================================================================
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Target
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Resolve-Path (Join-Path $ScriptDir '..')

# Auto-detect if not provided
if (-not $Target) {
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $candidate = Join-Path $_.Root 'koreader'
        if (Test-Path $candidate) {
            Write-Host "-> Auto-detected KOReader at: $candidate"
            $Target = $candidate
        }
    }
}

if (-not $Target) {
    Write-Error "Usage: .\deploy\install.ps1 X:\koreader  (could not auto-detect a Kindle)"
    exit 1
}
if (-not (Test-Path $Target -PathType Container)) {
    Write-Error "$Target is not a directory"
    exit 1
}

# Sanity check
$looksOk = (Test-Path (Join-Path $Target 'reader.lua')) `
        -or (Test-Path (Join-Path $Target 'common.lua')) `
        -or (Test-Path (Join-Path $Target 'frontend'))
if (-not $looksOk) {
    Write-Warning "$Target does not look like a KOReader install."
    $ans = Read-Host "Continue anyway? [y/N]"
    if ($ans -notmatch '^[Yy]') { exit 1 }
}

$TS = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$BackupDir = Join-Path $Target "patches\.phill-backup\$TS"

function Copy-WithBackup {
    param([string]$Src, [string]$Dst)
    if (Test-Path $Dst) {
        $rel = [IO.Path]::GetRelativePath($Target, $Dst)
        $backupPath = Join-Path $BackupDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupPath) | Out-Null
        Copy-Item $Dst $backupPath -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dst) | Out-Null
    Copy-Item $Src $Dst -Force
    $rel = [IO.Path]::GetRelativePath($Target, $Dst)
    Write-Host "  [+] $rel"
}

Write-Host ""
Write-Host "KOReader Personal Patch installer"
Write-Host "  repo:   $RepoRoot"
Write-Host "  target: $Target"
Write-Host "  backup: $BackupDir (created only if files are overwritten)"
Write-Host ""

# 1. Patches
Write-Host "Installing patches..."
New-Item -ItemType Directory -Force -Path (Join-Path $Target 'patches') | Out-Null
Get-ChildItem -Path (Join-Path $RepoRoot 'patches') -Filter '*.lua' | ForEach-Object {
    Copy-WithBackup $_.FullName (Join-Path $Target "patches\$($_.Name)")
}

# 2. Icons (flat)
Write-Host "Installing icons..."
New-Item -ItemType Directory -Force -Path (Join-Path $Target 'icons') | Out-Null
Get-ChildItem -Path (Join-Path $RepoRoot 'icons') -Filter '*.svg' -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-WithBackup $_.FullName (Join-Path $Target "icons\$($_.Name)")
}

# 3. mdlight icon OVERRIDES
# KOReader ships a stock theme at /koreader/resources/icons/mdlight/.
# Files in /koreader/icons/ override them. Installing to the override
# layer means uninstalling cleanly restores the stock look.
$mdlightSrc = Join-Path $RepoRoot 'icons\mdlight'
if (Test-Path $mdlightSrc) {
    Write-Host "Installing mdlight icon overrides -> /koreader/icons/ ..."
    Get-ChildItem -Path $mdlightSrc -Filter '*.svg' | ForEach-Object {
        $name = $_.Name
        # Collision check
        if (Test-Path (Join-Path $RepoRoot "icons\$name")) {
            Write-Host "  [!] Name collision: $name exists in BOTH icons/ and icons/mdlight/ - mdlight copy will win"
        }
        Copy-WithBackup $_.FullName (Join-Path $Target "icons\$name")
    }
}

# 4. Fonts
$fontsSrc = Join-Path $RepoRoot 'fonts'
if (Test-Path $fontsSrc) {
    Write-Host "Installing fonts..."
    Get-ChildItem -Path $fontsSrc -Directory | ForEach-Object {
        $dstDir = Join-Path $Target "fonts\$($_.Name)"
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
        Get-ChildItem -Path $_.FullName -Include *.ttf,*.otf,*.txt -File | ForEach-Object {
            Copy-WithBackup $_.FullName (Join-Path $dstDir $_.Name)
        }
    }
}

# 5. Sanity warnings
Write-Host ""
Write-Host "Sanity checks:"
foreach ($icon in 'rounded.corner.tl.svg','rounded.corner.tr.svg','rounded.corner.bl.svg','rounded.corner.br.svg') {
    if (-not (Test-Path (Join-Path $Target "icons\$icon"))) {
        Write-Host "  [!] Missing $icon - rounded-corner covers wont render. See icons_needed.md"
    }
}
foreach ($icon in 'favorites.svg','go_up.svg','hero.svg','history.svg','last_document.svg') {
    if (-not (Test-Path (Join-Path $Target "icons\$icon"))) {
        Write-Host "  [!] Missing $icon - minimalist top-bar wont render. See icons_needed.md"
    }
}
if (-not (Test-Path (Join-Path $Target 'fonts\montserratstatic'))) {
    Write-Host "  [!] No montserratstatic font folder on device. See fonts_needed.md"
}

Write-Host ""
Write-Host "Done. Safely eject your Kindle, then open KOReader to pick up the changes."
Write-Host "If anything looks wrong, run .\deploy\uninstall.ps1 `"$Target`" to restore backups."
