# Launch Flutter Windows host with Public OAuth defines.
# Credentials: fill .env.windows.local (gitignored) or pass -ApiKey / -ClientId.
# Never pass BUNGIE_CLIENT_SECRET. Never use the Next.js port-3000 redirect.

param(
  [string]$ApiKey,
  [string]$ClientId,
  [string]$RedirectUri = "https://127.0.0.1:8765/callback",
  [string]$EnvFile = "$PSScriptRoot\.env.windows.local"
)

$ErrorActionPreference = "Stop"

function Read-DotEnv([string]$Path) {
  $map = @{}
  if (-not (Test-Path $Path)) { return $map }
  Get-Content $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $i = $line.IndexOf("=")
    if ($i -lt 1) { return }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
    $map[$k] = $v
  }
  return $map
}

$envMap = Read-DotEnv $EnvFile
if (-not $ApiKey) { $ApiKey = $envMap["BUNGIE_API_KEY"] }
if (-not $ClientId) { $ClientId = $envMap["BUNGIE_CLIENT_ID"] }
if ($envMap["BUNGIE_REDIRECT_URI"]) { $RedirectUri = $envMap["BUNGIE_REDIRECT_URI"] }
if (-not $ApiKey) { $ApiKey = $env:BUNGIE_API_KEY }
if (-not $ClientId) { $ClientId = $env:BUNGIE_PUBLIC_CLIENT_ID }
if (-not $ClientId) { $ClientId = $env:BUNGIE_CLIENT_ID }

if (-not $ClientId) {
  Write-Host @"
Missing BUNGIE_CLIENT_ID.

1. Create a Public Bungie app with redirect exactly:
   $RedirectUri
2. Edit: $EnvFile
   BUNGIE_API_KEY=<api key>
   BUNGIE_CLIENT_ID=<public client id>
   BUNGIE_REDIRECT_URI=$RedirectUri
3. Run: .\run-windows.ps1

Do not use only the Confidential Next.js app (redirect ends in :3000/api/auth/callback).
"@
  exit 1
}

if (-not $ApiKey) {
  Write-Host "Warning: BUNGIE_API_KEY empty — sign-in may work; inventory/manifest will not."
}

if ($RedirectUri -match "3000") {
  Write-Error "Redirect URI must not be the Next.js callback (port 3000)."
  exit 1
}

if ($RedirectUri -ne "https://127.0.0.1:8765/callback") {
  Write-Host "Using non-default redirect: $RedirectUri (must match Bungie app exactly)"
}

if (-not (Test-Path (Join-Path $PSScriptRoot "certs\loopback-cert.pem"))) {
  Write-Error "Missing certs/loopback-cert.pem — HTTPS loopback cannot start."
  exit 1
}

Write-Host "Launching windows_host"
Write-Host "  CLIENT_ID set: $([bool]$ClientId) (len $($ClientId.Length))"
Write-Host "  API_KEY set:   $([bool]$ApiKey) (len $($ApiKey.Length))"
Write-Host "  REDIRECT:      $RedirectUri"

Set-Location $PSScriptRoot
flutter pub get
flutter run -d windows `
  --dart-define=BUNGIE_API_KEY=$ApiKey `
  --dart-define=BUNGIE_CLIENT_ID=$ClientId `
  --dart-define=BUNGIE_REDIRECT_URI=$RedirectUri
