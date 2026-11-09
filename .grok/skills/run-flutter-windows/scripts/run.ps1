# Thin wrapper: invoke monorepo scripts/run-flutter-windows.ps1 from skill dir.
# Usage: pwsh -File .grok/skills/run-flutter-windows/scripts/run.ps1 -Target app -Mode debug

param(
  [ValidateSet("app", "widgetbook")]
  [string]$Target = "app",
  [ValidateSet("run", "debug")]
  [string]$Mode = "run",
  [switch]$SkipPubGet,
  [switch]$Clean,
  [switch]$Gen,
  [string]$Device = "windows",
  [string]$StartDir = ""
)

$ErrorActionPreference = "Stop"
$skillDir = Split-Path -Parent $PSScriptRoot
# skill at <repo>/.grok/skills/run-flutter-windows → repo is ../../../
$repoRoot = (Resolve-Path (Join-Path $skillDir "..\..\..")).Path
$launcher = Join-Path $repoRoot "scripts\run-flutter-windows.ps1"
if (-not (Test-Path -LiteralPath $launcher)) {
  throw "Launcher not found: $launcher"
}
if (-not $StartDir) { $StartDir = (Get-Location).Path }

$argList = @(
  "-NoProfile", "-File", $launcher,
  "-Target", $Target,
  "-Mode", $Mode,
  "-StartDir", $StartDir,
  "-Device", $Device
)
if ($SkipPubGet) { $argList += "-SkipPubGet" }
if ($Clean) { $argList += "-Clean" }
if ($Gen) { $argList += "-Gen" }

& pwsh @argList
exit $LASTEXITCODE
