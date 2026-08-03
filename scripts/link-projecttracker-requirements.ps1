# Creates a local directory junction:
#   <repo>/requirements  ->  Obsidian ProjectTracker vault
#
# High-level product requirements for this product live under:
#   requirements/Projects/Destiny 2 Build Creator/
#     Products.md, Domains/, Areas/, Destiny Objects/
#
# Usage (from repo root):
#   pwsh -File scripts/link-projecttracker-requirements.ps1
#   pwsh -File scripts/link-projecttracker-requirements.ps1 -VaultPath "D:\path\to\ProjectTracker"

[CmdletBinding()]
param(
  [string]$VaultPath = "C:\Users\Owner\SyncThing\Obsidian\ProjectTracker",
  [string]$LinkName = "requirements"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$linkPath = Join-Path $repoRoot $LinkName

if (-not (Test-Path -LiteralPath $VaultPath)) {
  throw "Vault not found: $VaultPath"
}

$productHub = Join-Path $VaultPath "Projects\Destiny 2 Build Creator\Products.md"
if (-not (Test-Path -LiteralPath $productHub)) {
  Write-Warning "Expected product hub missing: $productHub"
}

if (Test-Path -LiteralPath $linkPath) {
  $item = Get-Item -LiteralPath $linkPath -Force
  $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
  if (-not $isReparse) {
    throw "Refusing to replace non-link path: $linkPath"
  }
  # Remove existing junction/symlink then recreate (target may have changed).
  cmd /c rmdir "$linkPath" | Out-Null
}

$null = New-Item -ItemType Junction -Path $linkPath -Target $VaultPath
Write-Host "Linked: $linkPath -> $VaultPath"
Write-Host "Product requirements: $(Join-Path $linkPath 'Projects\Destiny 2 Build Creator')"
