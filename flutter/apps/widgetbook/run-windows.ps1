# Launch Widgetbook (catalog isolation) on Windows.
# No OAuth, inventory, or secrets — pure design catalog for destiny2_ui_flutter.
#
# Usage (from this directory):
#   .\run-windows.ps1
#   .\run-windows.ps1 -SkipPubGet            # fast re-launch (recommended while iterating)
#   .\run-windows.ps1 -EnableFlutterDriver   # MCP / Driver screenshots (main_mcp.dart)
#   .\run-windows.ps1 -Gen                   # regen main.directories.g.dart first
#   .\run-windows.ps1 -Clean                 # flutter clean + wipe stale Windows ephemeral
#   .\run-windows.ps1 -Device chrome         # faster cold start (less product-faithful)
#
# Day-to-day UI loop: ITERATE.md (keep app running → edit ui_flutter → press r).
#
# From monorepo:
#   pwsh -File flutter/apps/widgetbook/run-windows.ps1 -SkipPubGet
#
# If MSBuild fails with C1083 on windows/flutter/ephemeral/cpp_client_wrapper/*.cc,
# re-run with -Clean (stale/empty ephemeral after interrupted builds).

param(
  # Enables Flutter Driver for Dart MCP / screenshots + taps.
  # Uses -t lib/main_mcp.dart (do not also pass ENABLE_FLUTTER_DRIVER with main_mcp).
  [switch]$EnableFlutterDriver,

  # Run build_runner before launch (after adding/changing @UseCase annotations).
  [switch]$Gen,

  # Wipe Flutter build + windows/flutter/ephemeral (repairs C1083 / empty wrapper).
  [switch]$Clean,

  # Skip workspace dart pub get (use after first successful launch of the day).
  [switch]$SkipPubGet,

  # Flutter device id (default: windows).
  [string]$Device = "windows"
)

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

Write-Host "Launching destiny2_widgetbook"
Write-Host "  DEVICE:         $Device"
Write-Host "  FLUTTER_DRIVER: $EnableFlutterDriver"
Write-Host "  GEN:            $Gen"
Write-Host "  CLEAN:          $Clean"
Write-Host "  SKIP_PUB_GET:   $SkipPubGet"
Write-Host "  ROOT:           $PSScriptRoot"
Write-Host "  Tip: leave this process running; edit packages/ui_flutter and press r (hot reload)."

function Test-WindowsEphemeralHealthy {
  $wrapper = Join-Path $PSScriptRoot "windows\flutter\ephemeral\cpp_client_wrapper"
  $probe = Join-Path $wrapper "core_implementations.cc"
  return (Test-Path -LiteralPath $probe)
}

function Repair-WindowsEphemeral {
  Write-Host "Repairing Windows Flutter ephemeral (flutter clean + remove build/ephemeral)…"
  flutter clean
  $paths = @(
    (Join-Path $PSScriptRoot "build"),
    (Join-Path $PSScriptRoot "windows\flutter\ephemeral")
  )
  foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p) {
      Write-Host "  Removing $p"
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

# Workspace pub get from flutter/ so path deps resolve cleanly.
if (-not $SkipPubGet) {
  $workspaceRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
  Push-Location $workspaceRoot
  try {
    dart pub get
    if ($LASTEXITCODE -ne 0) {
      Write-Error "dart pub get failed in workspace (exit $LASTEXITCODE)."
      exit $LASTEXITCODE
    }
  } finally {
    Pop-Location
  }
} else {
  Write-Host "  Skipping dart pub get (-SkipPubGet)."
}

if ($Clean) {
  Repair-WindowsEphemeral
} elseif ($Device -eq "windows" -and -not (Test-WindowsEphemeralHealthy)) {
  Write-Warning "windows/flutter/ephemeral/cpp_client_wrapper looks empty or missing — auto-repairing."
  Repair-WindowsEphemeral
}

if ($Gen) {
  Write-Host "Generating Widgetbook directories (build_runner)…"
  dart run build_runner build -d
  if ($LASTEXITCODE -ne 0) {
    Write-Error "build_runner failed (exit $LASTEXITCODE)."
    exit $LASTEXITCODE
  }
}

$runArgs = @("run", "-d", $Device)

if ($EnableFlutterDriver) {
  if ($Device -eq "chrome" -or $Device -eq "edge" -or $Device -eq "web-server") {
    Write-Warning "Flutter Driver finders/screenshots are not supported on web. Launching main_mcp anyway for DTD-only."
  }
  # Dedicated MCP entrypoint — enables driver once (see main_mcp.dart).
  $runArgs += @("-t", "lib/main_mcp.dart")
  Write-Host "  TARGET:         lib/main_mcp.dart"
} else {
  Write-Host "  TARGET:         lib/main.dart"
}

# After clean, first build regenerates ephemeral; give a clear log line.
if ($Device -eq "windows") {
  Write-Host "  Note: first Windows build after clean regenerates cpp_client_wrapper (may take a minute)."
}

flutter @runArgs
exit $LASTEXITCODE
