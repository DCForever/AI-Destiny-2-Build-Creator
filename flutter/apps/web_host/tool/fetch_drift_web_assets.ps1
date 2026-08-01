# Fetch Drift web assets into apps/web_host/web/ (DART-043).
# Pins worker to drift release matching package when possible; wasm from
# sqlite3_flutter_libs (or drift) release that ships sqlite3.wasm.

$ErrorActionPreference = "Stop"
$webDir = Join-Path (Join-Path $PSScriptRoot "..") "web"
New-Item -ItemType Directory -Force -Path $webDir | Out-Null

# drift 2.31.0 ships drift_worker.js; sqlite3.wasm is on sqlite3_flutter_libs-0.5.42
# (matches workspace lock) and on newer drift releases (e.g. 2.34.2).
$workerUrl = "https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js"
$wasmUrl = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3_flutter_libs-0.5.42/sqlite3.wasm"

$workerPath = Join-Path $webDir "drift_worker.js"
$wasmPath = Join-Path $webDir "sqlite3.wasm"

Write-Host "Downloading drift_worker.js ..."
Invoke-WebRequest -Uri $workerUrl -OutFile $workerPath -UseBasicParsing
Write-Host "Downloading sqlite3.wasm ..."
Invoke-WebRequest -Uri $wasmUrl -OutFile $wasmPath -UseBasicParsing

Write-Host "OK:"
Get-Item $workerPath, $wasmPath | Format-Table Name, Length, FullName
