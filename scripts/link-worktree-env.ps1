# Symlink gitignored local env/cert files from the primary monorepo checkout
# into one or more git worktrees so Flutter Windows (and optional Next/mobile)
# builds can load the same credentials without copying secrets.
#
# Usage (from monorepo root):
#   pwsh -File scripts/link-worktree-env.ps1
#   pwsh -File scripts/link-worktree-env.ps1 -WorktreeRoot "F:\Destiny2Creator-worktrees"
#   pwsh -File scripts/link-worktree-env.ps1 -Worktrees @("F:\...\feat-foo")
#
# Default source: parent of this scripts/ dir (primary checkout).
# Default worktrees: every immediate child of F:\Destiny2Creator-worktrees that
# looks like a repo (has .git file or directory).

[CmdletBinding()]
param(
  [string]$SourceRoot = "",
  [string]$WorktreeRoot = "F:\Destiny2Creator-worktrees",
  [string[]]$Worktrees = @(),
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

if (-not $SourceRoot) {
  $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

# Relative paths from monorepo root ΓåÆ symlink into each worktree at same path.
# Only files that exist on the source side are linked.
$RelativeFiles = @(
  # Flutter Windows Public OAuth + API key (run-windows.ps1)
  "flutter\apps\windows_host\.env.windows.local",
  # Optional backup; may contain confidential material ΓÇö still local-only
  "flutter\apps\windows_host\.env.windows.local.bak-next-confidential",
  # HTTPS loopback TLS (gitignored PEMs; cnf is tracked)
  "flutter\apps\windows_host\certs\loopback-cert.pem",
  "flutter\apps\windows_host\certs\loopback-key.pem",
  # Mobile Android SDK path (local machine)
  "flutter\apps\mobile_host\android\local.properties",
  # Next.js (if building web stack from a worktree)
  ".env.local",
  "web\NextJS\.env.local",
  # Shared local TLS material used by some Next/dev scripts
  "certificates\localhost.pem",
  "certificates\localhost-key.pem",
  # Legacy monorepo-root Windows env path (if present)
  "apps\windows_host\.env.windows.local"
)

function Get-WorktreeTargets {
  if ($Worktrees.Count -gt 0) {
    return $Worktrees | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }
  }
  if (-not (Test-Path -LiteralPath $WorktreeRoot)) {
    throw "Worktree root not found: $WorktreeRoot"
  }
  Get-ChildItem -LiteralPath $WorktreeRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName ".git")
  } | ForEach-Object { $_.FullName }
}

function Ensure-ParentDir([string]$Path) {
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    if ($WhatIf) {
      Write-Host "  [WhatIf] mkdir $parent"
      return
    }
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
}

function Link-File([string]$Source, [string]$Dest) {
  if (-not (Test-Path -LiteralPath $Source)) {
    return $false
  }

  Ensure-ParentDir $Dest

  if (Test-Path -LiteralPath $Dest) {
    $existing = Get-Item -LiteralPath $Dest -Force
    $isLink = $existing.LinkType -in @("SymbolicLink", "Junction", "HardLink")
    if ($isLink) {
      $target = $existing.Target
      if ($target -is [array]) { $target = $target[0] }
      $resolvedTarget = try {
        (Resolve-Path -LiteralPath $target -ErrorAction Stop).Path
      } catch {
        $target
      }
      $resolvedSource = (Resolve-Path -LiteralPath $Source).Path
      if ($resolvedTarget -eq $resolvedSource) {
        Write-Host "  OK already linked: $($existing.Name)"
        return $true
      }
      if ($WhatIf) {
        Write-Host "  [WhatIf] replace link $($existing.FullName) -> $Source"
        return $true
      }
      Remove-Item -LiteralPath $Dest -Force
    }
    else {
      Write-Warning "  Skip (real file exists, not a link): $Dest"
      return $false
    }
  }
  elseif ($WhatIf) {
    Write-Host "  [WhatIf] symlink $Dest -> $Source"
    return $true
  }

  New-Item -ItemType SymbolicLink -Path $Dest -Target $Source | Out-Null
  Write-Host "  Linked: $Dest"
  return $true
}

$targets = @(Get-WorktreeTargets)
if ($targets.Count -eq 0) {
  throw "No worktrees found under $WorktreeRoot (and -Worktrees not set)."
}

Write-Host "Source: $SourceRoot"
Write-Host "Worktrees ($($targets.Count)):"
$targets | ForEach-Object { Write-Host "  $_" }
Write-Host ""

$linked = 0
$missingSource = 0
$skipped = 0

foreach ($wt in $targets) {
  Write-Host "== $wt =="
  foreach ($rel in $RelativeFiles) {
    $src = Join-Path $SourceRoot $rel
    $dst = Join-Path $wt $rel
    if (-not (Test-Path -LiteralPath $src)) {
      $missingSource++
      continue
    }
    $ok = Link-File -Source $src -Dest $dst
    if ($ok) { $linked++ } else { $skipped++ }
  }
  Write-Host ""
}

Write-Host "Done. linked/ok=$linked skipped=$skipped source-missing-slots=$missingSource"
Write-Host "Note: only paths that exist on the source checkout are linked."
