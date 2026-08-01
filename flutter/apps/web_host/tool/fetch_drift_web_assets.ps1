# Fetch Drift web assets into apps/web_host/web/ (DART-043).
# Pins worker + wasm to releases matching workspace drift / sqlite3 3.x.

$ErrorActionPreference = "Stop"
$webDir = Join-Path (Join-Path $PSScriptRoot "..") "web"
New-Item -ItemType Directory -Force -Path $webDir | Out-Null

# drift 2.34.x ships drift_worker.js; sqlite3 3.x wasm is on sqlite3.dart releases.
$workerUrl = "https://github.com/simolus3/drift/releases/download/drift-2.34.2/drift_worker.js"
$wasmUrl = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.0/sqlite3.wasm"

$workerPath = Join-Path $webDir "drift_worker.js"
$wasmPath = Join-Path $webDir "sqlite3.wasm"

Write-Host "Downloading drift_worker.js ..."
Invoke-WebRequest -Uri $workerUrl -OutFile $workerPath -UseBasicParsing
Write-Host "Downloading sqlite3.wasm ..."
Invoke-WebRequest -Uri $wasmUrl -OutFile $wasmPath -UseBasicParsing

Write-Host "OK:"
Get-Item $workerPath, $wasmPath | Format-Table Name, Length, FullName
