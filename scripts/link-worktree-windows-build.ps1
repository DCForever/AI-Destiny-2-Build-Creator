# Create short directory junctions so Flutter Windows MSBuild stays under
# MAX_PATH (260). Long worktree paths cause MSB3491 on plugins such as
# flutter_secure_storage_windows (missing .tlog / lastbuildstate).
#
# Usage (from monorepo root):
#   pwsh -File scripts/link-worktree-windows-build.ps1
#   pwsh -File scripts/link-worktree-windows-build.ps1 -CleanLongBuilds
#
# Then build from the SHORT path, not the worktree path:
#   cd F:\d2w\entity\apps\windows_host
#   .\run-windows.ps1
#
# Junction layout (default):
#   F:\d2w\<short>  ->  <worktree>\flutter   (Melos root)

[CmdletBinding()]
param(
  [string]$WorktreeRoot = "F:\Destiny2Creator-worktrees",
  [string]$ShortRoot = "F:\d2w",
  [string[]]$Worktrees = @(),
  # Optional explicit map: "shortName=fullWorktreePath"
  [string[]]$Map = @(),
  [switch]$CleanLongBuilds,
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Default short-name map for current Catalog feature worktrees.
$DefaultShortNames = @{
  "feat-catalog-entity-descriptions" = "entity"
  "feat-catalog-nested-group-by"     = "nested"
  "feat-catalog-filter-collections"  = "filters"
}

function Get-WorktreeDirs {
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

function Resolve-ShortName([string]$WorktreePath) {
  $leaf = Split-Path -Leaf $WorktreePath
  if ($DefaultShortNames.ContainsKey($leaf)) {
    return $DefaultShortNames[$leaf]
  }
  # Fallback: compress feat-catalog-foo-bar -> first letters / tail
  $slug = $leaf -replace '^feat-catalog-', '' -replace '^feat-', ''
  if ($slug.Length -gt 12) { $slug = $slug.Substring(0, 12) }
  return $slug
}

function Ensure-Junction([string]$LinkPath, [string]$TargetPath) {
  if (-not (Test-Path -LiteralPath $TargetPath)) {
    throw "Target missing: $TargetPath"
  }
  $targetResolved = (Resolve-Path -LiteralPath $TargetPath).Path

  if (Test-Path -LiteralPath $LinkPath) {
    $item = Get-Item -LiteralPath $LinkPath -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if (-not $isReparse) {
      throw "Refusing to replace non-junction path: $LinkPath"
    }
    $existingTarget = $null
    if ($item.LinkType) {
      $t = $item.Target
      if ($t -is [array]) { $t = $t[0] }
      $existingTarget = try { (Resolve-Path -LiteralPath $t -ErrorAction Stop).Path } catch { "$t" }
    }
    if ($existingTarget -eq $targetResolved) {
      Write-Host "  OK already linked: $LinkPath"
      return
    }
    if ($WhatIf) {
      Write-Host "  [WhatIf] recreate $LinkPath -> $targetResolved"
      return
    }
    cmd /c rmdir "$LinkPath" | Out-Null
  }
  elseif ($WhatIf) {
    Write-Host "  [WhatIf] mklink /J $LinkPath $targetResolved"
    return
  }

  $parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  # Directory junction (no admin required)
  $null = cmd /c mklink /J "$LinkPath" "$targetResolved"
  if ($LASTEXITCODE -ne 0) {
    throw "mklink /J failed for $LinkPath"
  }
  Write-Host "  Linked: $LinkPath -> $targetResolved"
}

function Remove-LongBuildTree([string]$WorktreePath) {
  $build = Join-Path $WorktreePath "flutter\apps\windows_host\build"
  if (-not (Test-Path -LiteralPath $build)) { return }
  if ($WhatIf) {
    Write-Host "  [WhatIf] remove long build tree: $build"
    return
  }
  Write-Host "  Cleaning long-path build: $build"
  # Use cmd rmdir for deep trees that may already be path-corrupted
  cmd /c "rmdir /s /q `"$build`"" 2>$null | Out-Null
}

# Parse optional -Map short=path
$explicitMap = @{}
foreach ($entry in $Map) {
  $i = $entry.IndexOf("=")
  if ($i -lt 1) { throw "Bad -Map entry (want short=path): $entry" }
  $short = $entry.Substring(0, $i).Trim()
  $path = $entry.Substring($i + 1).Trim()
  $explicitMap[$short] = (Resolve-Path -LiteralPath $path).Path
}

if (-not (Test-Path -LiteralPath $ShortRoot)) {
  if ($WhatIf) {
    Write-Host "[WhatIf] mkdir $ShortRoot"
  }
  else {
    New-Item -ItemType Directory -Path $ShortRoot -Force | Out-Null
  }
}

Write-Host "Short root: $ShortRoot"
Write-Host ""

$pairs = @()
if ($explicitMap.Count -gt 0) {
  foreach ($k in $explicitMap.Keys) {
    $pairs += [pscustomobject]@{ Short = $k; Worktree = $explicitMap[$k] }
  }
}
else {
  foreach ($wt in (Get-WorktreeDirs)) {
    $pairs += [pscustomobject]@{ Short = (Resolve-ShortName $wt); Worktree = $wt }
  }
}

if ($pairs.Count -eq 0) {
  throw "No worktrees to link."
}

foreach ($p in $pairs) {
  $flutterRoot = Join-Path $p.Worktree "flutter"
  if (-not (Test-Path -LiteralPath $flutterRoot)) {
    Write-Warning "Skip (no flutter/): $($p.Worktree)"
    continue
  }
  $link = Join-Path $ShortRoot $p.Short
  Write-Host "== $($p.Short) =="
  Write-Host "  worktree: $($p.Worktree)"
  Ensure-Junction -LinkPath $link -TargetPath $flutterRoot

  # Probe MAX_PATH for the worst plugin tlog path
  $probe = Join-Path $link "apps\windows_host\build\windows\x64\plugins\flutter_secure_storage_windows\flutter_secure_storage_windows_plugin.dir\Debug\flutter_.BBC29857.tlog\flutter_secure_storage_windows_plugin.lastbuildstate"
  $longProbe = Join-Path $p.Worktree "flutter\apps\windows_host\build\windows\x64\plugins\flutter_secure_storage_windows\flutter_secure_storage_windows_plugin.dir\Debug\flutter_.BBC29857.tlog\flutter_secure_storage_windows_plugin.lastbuildstate"
  Write-Host ("  short path len={0} (need < 260)" -f $probe.Length)
  Write-Host ("  long  path len={0}" -f $longProbe.Length)
  if ($probe.Length -ge 260) {
    Write-Warning "  Short path still >= 260; use a shorter -ShortRoot or short name."
  }

  if ($CleanLongBuilds) {
    Remove-LongBuildTree -WorktreePath $p.Worktree
  }

  Write-Host "  Build with:"
  Write-Host "    cd $link\apps\windows_host"
  Write-Host "    .\run-windows.ps1"
  Write-Host ""
}

Write-Host "Done. Always flutter run / run-windows.ps1 from F:\d2w\<short>\apps\windows_host ΓÇö not the long worktree path."
