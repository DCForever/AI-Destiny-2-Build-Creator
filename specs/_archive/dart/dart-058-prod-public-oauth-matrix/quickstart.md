# Quickstart: DART-058 Prod Public OAuth Matrix

## Register Bungie Public app redirects

1. Open <https://www.bungie.net/en/Application> → Public application (or create one).
2. Add **exactly** the redirects from [docs/multiplatform-dart-prod-public-oauth-matrix.md](../../docs/multiplatform-dart-prod-public-oauth-matrix.md):
   - `https://127.0.0.1:8765/callback` (Windows)
   - `https://YOUR_JASPR_ORIGIN/auth/callback` (web)
   - `d2buildcreator://oauth/callback` (Android + iOS)
3. Never register Confidential Next redirect for Dart hosts (`https://127.0.0.1:3000/api/auth/callback`).
4. Never put `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr.

## Run automated gates

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/bungie/test/prod_public_oauth_matrix_test.dart
dart test tool/test/client_secret_scan_test.dart
dart run tool/client_secret_scan.dart
dart test tool/test/cutover_parity_checklist_validate_test.dart
```

## Operator live smoke (Windows)

```powershell
cd apps\windows_host
.\run-windows.ps1   # uses https://127.0.0.1:8765/callback by default
# Settings → confirm Redirect URI → Sign in → complete Bungie → Sign out
```

## Operator live smoke (Jaspr)

```powershell
cd apps\web_host
# serve with Public BUNGIE_CLIENT_ID + origin that matches portal redirect
# Settings → Sign in → /auth/callback completes → Sign out
```

## Secret scan only

```powershell
dart run tool/client_secret_scan.dart
# exit 0 = no BUNGIE_CLIENT_SECRET / SESSION_SECRET assignment in client lib trees
```
