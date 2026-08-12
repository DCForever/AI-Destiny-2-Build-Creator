# Launch product Windows host or Widgetbook from monorepo root OR any worktree.
# Handles long-path worktrees via F:\d2w\<slug> junctions (MAX_PATH / MSB3491).
#
# Usage:
#   pwsh -File scripts/run-flutter-windows.ps1 -Target app
#   pwsh -File scripts/run-flutter-windows.ps1 -Target app -Mode debug
#   pwsh -File scripts/run-flutter-windows.ps1 -Target widgetbook -Mode run -SkipPubGet
#   pwsh -File scripts/run-flutter-windows.ps1 -Target widgetbook -Mode debug -Gen
#
# Modes:
#   run   → lib/main.dart (everyday)
#   debug → lib/main_mcp.dart + Flutter Driver (agent observe / MCP screenshots)
#
# Resolve root: walk up from -StartDir (default: cwd) for flutter/ melos root.

[CmdletBinding()]
param(
  [ValidateSet("app", "widgetbook")]
  [string]$Target = "app",

  [ValidateSet("run", "debug")]
  [string]$Mode = "run",

  [string]$StartDir = "",

  # Optional explicit Melos root (…/flutter)
  [string]$FlutterRoot = "",

  [switch]$SkipPubGet,
  [switch]$Clean,
  [switch]$Gen,
  [string]$Device = "windows",

  # Short junction parent for long worktree paths
  [string]$ShortRoot = "F:\d2w",

  # Force short junction even if path is short
  [switch]$ForceShortPath
)

$ErrorActionPreference = "Stop"

function Find-FlutterRoot([string]$From) {
  $dir = (Resolve-Path -LiteralPath $From).Path
  while ($true) {
    $melos = Join-Path $dir "melos.yaml"
    $pub = Join-Path $dir "pubspec.yaml"
    if ((Test-Path -LiteralPath $melos) -and (Test-Path -LiteralPath $pub)) {
      return $dir
    }
    # Nested monorepo: …/Destiny2BuildCreator/flutter
    $nested = Join-Path $dir "flutter"
    $nMelos = Join-Path $nested "melos.yaml"
    if ((Test-Path -LiteralPath $nMelos)) {
      return (Resolve-Path -LiteralPath $nested).Path
    }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
  }
  return $null
}

function Get-ShortSlug([string]$FlutterRootPath) {
  # Prefer worktree folder name under Destiny2Creator-worktrees, else leaf of parent
  $norm = $FlutterRootPath -replace '/', '\'
  if ($norm -match 'Destiny2Creator-worktrees\\([^\\]+)\\flutter') {
    $leaf = $Matches[1]
  }
  else {
    $parent = Split-Path -Parent $FlutterRootPath
    $leaf = Split-Path -Leaf $parent
    if ($leaf -eq "Destiny2BuildCreator" -or $leaf -eq "flutter") {
      $leaf = "main"
    }
  }
  $map = @{
    "feat-catalog-entity-descriptions" = "entity"
    "feat-catalog-nested-group-by"     = "nested"
    "feat-catalog-filter-collections"  = "filters"
  }
  if ($map.ContainsKey($leaf)) { return $map[$leaf] }
  $slug = $leaf -replace '^feat-catalog-', '' -replace '^feat-', ''
  if ($slug.Length -gt 16) { $slug = $slug.Substring(0, 16) }
  if ([string]::IsNullOrWhiteSpace($slug)) { $slug = "app" }
  return $slug
}

function Ensure-ShortFlutterRoot([string]$FlutterRootPath) {
  $probe = Join-Path $FlutterRootPath "apps\windows_host\build\windows\x64\plugins\flutter_secure_storage_windows\flutter_secure_storage_windows_plugin.dir\Debug\flutter_.BBC29857.tlog\flutter_secure_storage_windows_plugin.lastbuildstate"
  $needsShort = $ForceShortPath -or ($probe.Length -ge 250)
  if (-not $needsShort) {
    Write-Host "Path OK (probe len=$($probe.Length) < 250) — using native Melos root."
    return $FlutterRootPath
  }

  if (-not (Test-Path -LiteralPath $ShortRoot)) {
    New-Item -ItemType Directory -Path $ShortRoot -Force | Out-Null
  }
  $slug = Get-ShortSlug $FlutterRootPath
  $link = Join-Path $ShortRoot $slug
  $target = (Resolve-Path -LiteralPath $FlutterRootPath).Path

  if (Test-Path -LiteralPath $link) {
    $item = Get-Item -LiteralPath $link -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
      $existing = $null
      if ($item.LinkType) {
        $t = $item.Target
        if ($t -is [array]) { $t = $t[0] }
        $existing = try { (Resolve-Path -LiteralPath $t -ErrorAction Stop).Path } catch { "$t" }
      }
      if ($existing -ne $target) {
        cmd /c rmdir "$link" | Out-Null
        $null = cmd /c mklink /J "$link" "$target"
      }
    }
    else {
      throw "Short path exists and is not a junction: $link"
    }
  }
  else {
    $null = cmd /c mklink /J "$link" "$target"
    if ($LASTEXITCODE -ne 0) { throw "mklink /J failed: $link -> $target" }
  }

  $shortProbe = Join-Path $link "apps\windows_host\build\windows\x64\plugins\flutter_secure_storage_windows\flutter_secure_storage_windows_plugin.dir\Debug\flutter_.BBC29857.tlog\flutter_secure_storage_windows_plugin.lastbuildstate"
  Write-Host "Long path mitigated: $link (probe len=$($shortProbe.Length); native was $($probe.Length))"
  return (Resolve-Path -LiteralPath $link).Path
}

# --- resolve roots ---
if (-not $StartDir) { $StartDir = (Get-Location).Path }
if (-not $FlutterRoot) {
  $FlutterRoot = Find-FlutterRoot $StartDir
}
if (-not $FlutterRoot -or -not (Test-Path -LiteralPath $FlutterRoot)) {
  throw "Could not find Melos flutter/ root from StartDir=$StartDir. Pass -FlutterRoot."
}
$FlutterRoot = (Resolve-Path -LiteralPath $FlutterRoot).Path
$FlutterRoot = Ensure-ShortFlutterRoot $FlutterRoot

$relHost = if ($Target -eq "app") { "apps\windows_host" } else { "apps\widgetbook" }
$HostRoot = Join-Path $FlutterRoot $relHost
if (-not (Test-Path -LiteralPath (Join-Path $HostRoot "pubspec.yaml"))) {
  throw "Host not found: $HostRoot"
}

$driver = ($Mode -eq "debug")
Write-Host "=== run-flutter-windows ==="
Write-Host "  Melos:   $FlutterRoot"
Write-Host "  Host:    $HostRoot"
Write-Host "  Target:  $Target"
Write-Host "  Mode:    $Mode $(if ($driver) { '(Flutter Driver / main_mcp)' } else { '(main.dart)' })"
Write-Host "  Device:  $Device"

if (-not $SkipPubGet) {
  Write-Host "dart pub get (workspace)…"
  Push-Location $FlutterRoot
  try {
    dart pub get
    if ($LASTEXITCODE -ne 0) { throw "dart pub get failed ($LASTEXITCODE)" }
  }
  finally { Pop-Location }
}

$runScript = Join-Path $HostRoot "run-windows.ps1"
if (-not (Test-Path -LiteralPath $runScript)) {
  throw "Missing run-windows.ps1 at $runScript"
}

# Hashtable splat only — string-array splat can bind "-SkipPubGet" into [string]
# params (ClientId) on windows_host run-windows.ps1 and poison OAuth.
$hostArgs = @{}
if ($driver) { $hostArgs["EnableFlutterDriver"] = $true }
if ($SkipPubGet) { $hostArgs["SkipPubGet"] = $true }
if ($Clean) { $hostArgs["Clean"] = $true }
if ($Gen -and $Target -eq "widgetbook") { $hostArgs["Gen"] = $true }
if ($Device -ne "windows" -and $Target -eq "widgetbook") {
  $hostArgs["Device"] = $Device
}

$argSummary = ($hostArgs.GetEnumerator() | ForEach-Object {
  if ($_.Value -is [bool] -and $_.Value) { "-$($_.Key)" }
  else { "-$($_.Key) $($_.Value)" }
}) -join " "
Write-Host "Launch: $runScript $argSummary"
Set-Location $HostRoot
& $runScript @hostArgs
exit $LASTEXITCODE
