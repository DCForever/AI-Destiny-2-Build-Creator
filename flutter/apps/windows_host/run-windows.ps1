# Launch Flutter Windows host with Public OAuth defines.
# Credentials: fill .env.windows.local (gitignored) or pass -ApiKey / -ClientId.
# Never pass BUNGIE_CLIENT_SECRET. Never use the Next.js port-3000 redirect.
# Missing certs/loopback-*.pem are generated automatically via openssl + certs/loopback.cnf.

param(
  [string]$ApiKey,
  [string]$ClientId,
  [string]$RedirectUri = "https://127.0.0.1:8765/callback",
  [string]$EnvFile = "$PSScriptRoot\.env.windows.local",
  # Enables Flutter Driver for Dart MCP / impeccable-flutter screenshots + taps.
  # Real keyboard typing may be emulated while this is on.
  [switch]$EnableFlutterDriver
)

$ErrorActionPreference = "Stop"

function Read-DotEnv([string]$Path) {
  $map = @{}
  if (-not (Test-Path -LiteralPath $Path)) { return $map }
  # UTF-8 with/without BOM; last assignment wins for duplicate keys.
  Get-Content -LiteralPath $Path -Encoding utf8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    # Support optional "export KEY=value"
    if ($line.StartsWith("export ")) { $line = $line.Substring(7).Trim() }
    $i = $line.IndexOf("=")
    if ($i -lt 1) { return }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim()
    # Strip matching surrounding quotes
    if (
      ($v.Length -ge 2) -and (
        ($v.StartsWith('"') -and $v.EndsWith('"')) -or
        ($v.StartsWith("'") -and $v.EndsWith("'"))
      )
    ) {
      $v = $v.Substring(1, $v.Length - 2)
    }
    # Ignore unfilled placeholders from copy-paste templates
    if ($v -match '^(<.*|your[_ -].*|changeme)$') { return }
    if ($k) { $map[$k] = $v }
  }
  return $map
}

function Resolve-OpenSslPath {
  $cmd = Get-Command openssl -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    "${env:ProgramFiles}\Git\usr\bin\openssl.exe",
    "${env:ProgramFiles(x86)}\Git\usr\bin\openssl.exe",
    "${env:LOCALAPPDATA}\Programs\Git\usr\bin\openssl.exe",
    "${env:ProgramFiles}\OpenSSL-Win64\bin\openssl.exe",
    "${env:ProgramFiles}\OpenSSL-Win32\bin\openssl.exe"
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $null
}

function Ensure-LoopbackCerts {
  $certsDir = Join-Path $PSScriptRoot "certs"
  $certPem = Join-Path $certsDir "loopback-cert.pem"
  $keyPem = Join-Path $certsDir "loopback-key.pem"
  $cnf = Join-Path $certsDir "loopback.cnf"

  $needGenerate = -not ((Test-Path -LiteralPath $certPem) -and (Test-Path -LiteralPath $keyPem))

  if ($needGenerate) {
    if (-not (Test-Path -LiteralPath $cnf)) {
      Write-Error @"
Missing OAuth loopback TLS material and config:
  $certPem
  $keyPem
  $cnf
"@
      exit 1
    }

    $openssl = Resolve-OpenSslPath
    if (-not $openssl) {
      Write-Error @"
Missing certs/loopback-cert.pem (and/or loopback-key.pem) and openssl was not found.

Install Git for Windows (includes openssl) or OpenSSL, then re-run:
  .\run-windows.ps1

Or generate manually from ${certsDir}:
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 `
    -keyout loopback-key.pem -out loopback-cert.pem -config loopback.cnf
"@
      exit 1
    }

    if (-not (Test-Path -LiteralPath $certsDir)) {
      New-Item -ItemType Directory -Path $certsDir | Out-Null
    }

    Write-Host "Generating self-signed OAuth loopback certs with openssl..."
    Write-Host "  $openssl"
    & $openssl req -x509 -nodes -newkey rsa:2048 -days 825 `
      -keyout $keyPem `
      -out $certPem `
      -config $cnf
    if ($LASTEXITCODE -ne 0) {
      Write-Error "openssl failed to generate loopback certs (exit $LASTEXITCODE)."
      exit 1
    }
    if (-not ((Test-Path -LiteralPath $certPem) -and (Test-Path -LiteralPath $keyPem))) {
      Write-Error "openssl reported success but PEM files are still missing under certs/."
      exit 1
    }
    Write-Host "Wrote:"
    Write-Host "  $certPem"
    Write-Host "  $keyPem"
  }

  Ensure-LoopbackCertTrusted -CertPem $certPem
}

function Ensure-LoopbackCertTrusted([string]$CertPem) {
  try {
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new((Resolve-Path -LiteralPath $CertPem))
  } catch {
    Write-Warning "Could not load loopback cert for trust install: $_"
    return
  }

  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
    [System.Security.Cryptography.X509Certificates.StoreName]::Root,
    [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
  )
  try {
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    if ($existing) {
      Write-Host "Loopback cert already trusted (CurrentUser\Root $($cert.Thumbprint))"
      return
    }
    Write-Host "Installing loopback cert into CurrentUser\Root so Edge/Chrome accept https://127.0.0.1:8765 …"
    Write-Host "  Thumbprint: $($cert.Thumbprint)"
    Write-Host "  If Windows shows a security prompt, choose Yes (local OAuth only)."
    $store.Add($cert)
    Write-Host "Loopback cert trusted."
  } catch {
    Write-Warning @"
Could not auto-trust loopback cert: $_
Browser may show ERR_CONNECTION_CLOSED / certificate errors for https://127.0.0.1:8765.
Manual fix (elevated not required for CurrentUser):
  Import-Certificate -FilePath '$CertPem' -CertStoreLocation Cert:\CurrentUser\Root
"@
  } finally {
    $store.Close()
  }
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

if ($envMap.ContainsKey("BUNGIE_CLIENT_SECRET") -and $envMap["BUNGIE_CLIENT_SECRET"]) {
  Write-Host "Warning: BUNGIE_CLIENT_SECRET is present in $EnvFile but is never passed to Flutter."
  Write-Host "  Windows host must use a Public + PKCE Bungie app (no secret)."
}

if ($RedirectUri -match "3000") {
  Write-Error "Redirect URI must not be the Next.js callback (port 3000). Use the Public app loopback (8765)."
  exit 1
}

if ($RedirectUri -match "/api/auth/callback") {
  Write-Error "Redirect URI looks like the Next.js Confidential callback. Windows host needs Public + PKCE loopback."
  exit 1
}

$prodHttps = "https://127.0.0.1:8765/callback"
$legacyHttp = "http://127.0.0.1:8765/callback"
if ($RedirectUri -ne $prodHttps -and $RedirectUri -ne $legacyHttp) {
  Write-Host "Using non-default redirect: $RedirectUri (must match Bungie Public app exactly)"
}

# HTTPS loopback needs local PEMs; HTTP loopback (older Public registration) does not.
if ($RedirectUri.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
  Ensure-LoopbackCerts
} else {
  Write-Host "HTTP loopback redirect — skipping TLS cert generation."
}

Write-Host "Launching windows_host"
Write-Host "  CLIENT_ID set: $([bool]$ClientId) (len $($ClientId.Length)) value=$ClientId"
Write-Host "  API_KEY set:   $([bool]$ApiKey) (len $($ApiKey.Length))"
Write-Host "  REDIRECT:      $RedirectUri"
Write-Host "  FLUTTER_DRIVER: $EnableFlutterDriver"
Write-Host "  ENV_FILE:      $EnvFile"

$defines = @(
  "--dart-define=BUNGIE_API_KEY=$ApiKey",
  "--dart-define=BUNGIE_CLIENT_ID=$ClientId",
  "--dart-define=BUNGIE_REDIRECT_URI=$RedirectUri"
)
if ($EnableFlutterDriver) {
  $defines += "--dart-define=ENABLE_FLUTTER_DRIVER=true"
}

Set-Location $PSScriptRoot
flutter pub get
flutter run -d windows @defines
