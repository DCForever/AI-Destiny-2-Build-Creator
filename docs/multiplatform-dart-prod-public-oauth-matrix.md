# Multiplatform Dart — Production Public OAuth Redirect Matrix (DART-058)

**Status:** published (ops registration contract)  
**Updated:** 2026-07-25  
**Program ID:** DART-058  
**Gap:** GAP-AUTH-01  
**Cutover:** RB-03 / RC-AUTH  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) (D-WEB-AUTH, D-BUNGIE)  
**Source of truth (code):** `packages/bungie/lib/src/oauth/prod_public_oauth_matrix.dart`

Dart shells use **Public + PKCE only**. Confidential Next credentials (`BUNGIE_CLIENT_SECRET`, `SESSION_SECRET`) stay **server-only** until cutover retires Next. **Never** embed those secrets in Flutter or Jaspr clients.

## Bungie application

| Field | Value |
| ----- | ----- |
| Recommended portal name | `Destiny2BuildCreator-Public` (`kProdPublicBungieAppName`) |
| OAuth client type | **Public** |
| PKCE | Required (S256) |
| Layout | **One** Public app with a **multi-redirect matrix** (D-BUNGIE). Split apps later only if ops/store-review requires it. |

Do **not** reuse the legacy Confidential Next redirect:

```text
https://127.0.0.1:3000/api/auth/callback   ← Next only
```

## Redirect matrix (register exactly)

| Platform | Shell | Redirect URI (exact) | Cutover-required live smoke | Notes |
| -------- | ----- | -------------------- | --------------------------- | ----- |
| Windows | Flutter desktop | `https://127.0.0.1:8765/callback` | **Yes** | HTTPS loopback; local self-signed certs under `apps/windows_host/certs/` |
| Web | Jaspr | `https://YOUR_JASPR_ORIGIN/auth/callback` | **Yes** | Path fixed: `/auth/callback`. Replace origin with production HTTPS host |
| Android | Flutter mobile | `d2buildcreator://oauth/callback` | **No** (scheme published; host OAuth deferred) | Custom scheme for portal registration |
| iOS | Flutter mobile | `d2buildcreator://oauth/callback` | **No** (scheme published; host OAuth deferred) | Same scheme string as Android |

### Constants (must match code)

| Constant | Value |
| -------- | ----- |
| `kProdWindowsRedirectUri` | `https://127.0.0.1:8765/callback` |
| `kProdWebOAuthCallbackPath` | `/auth/callback` |
| `kProdAndroidRedirectUri` / `kProdIosRedirectUri` | `d2buildcreator://oauth/callback` |

Helper: `prodWebRedirectUri(origin)` → `{origin}/auth/callback`.

Host defaults:

- Windows: `kDefaultWindowsRedirectUri` == `kProdWindowsRedirectUri` (HTTPS).
- Jaspr: `WebOAuthConfig.resolve` → `prodWebRedirectUri(origin)` when `BUNGIE_REDIRECT_URI` is empty.

## Operator registration steps

1. Create or open a **Public** Bungie application at <https://www.bungie.net/en/Application>.
2. Add each matrix redirect URI **exactly** (including `https` for Windows loopback).
3. For production web, add the real origin callback, e.g. `https://buildcreator.example/auth/callback`.
4. Copy **Client Id** (public) and API key into host config:
   - Windows: `--dart-define=BUNGIE_CLIENT_ID=…` / `.env.windows.local` (see `apps/windows_host/run-windows.ps1`)
   - Jaspr: `--dart-define=BUNGIE_CLIENT_ID=…` (and optional `BUNGIE_REDIRECT_URI` override)
5. **Never** configure `BUNGIE_CLIENT_SECRET` or `SESSION_SECRET` on Dart hosts.

## Automated evidence (CI / agent)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/bungie/test/prod_public_oauth_matrix_test.dart
dart run tool/client_secret_scan.dart
dart test tool/test/client_secret_scan_test.dart
# Existing mocked OAuth session preflight (cutover shells):
#   flutter test apps/windows_host/test/windows_oauth_session_test.dart
#   dart test apps/web_host/test/web_oauth_session_test.dart  (from apps/web_host)
```

| Gate | Pass condition |
| ---- | -------------- |
| Matrix unit tests | All four platforms; Windows HTTPS exact; web path `/auth/callback`; mobile schemes |
| Client secret scan | Zero `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` assignment or secret `fromEnvironment` in client `lib/` trees |
| Host OAuth session tests | Authorize/token path omits `client_secret`; mocked sign-in/out |

### Binary / release artifact scan

At packaging time, string-scan release binaries/assets for:

```text
BUNGIE_CLIENT_SECRET
SESSION_SECRET
```

Source scan (`tool/client_secret_scan.dart`) is the continuous gate; binary scan is the release checklist twin (same forbidden strings).

## Live sign-in smoke (operator)

Cutover-required shells: **Windows** and **Jaspr**. Mobile live smoke is **N/A** until a mobile OAuth session ships (schemes remain registered).

### Windows

1. Register `https://127.0.0.1:8765/callback` on the Public app.
2. `cd apps/windows_host` → `.\run-windows.ps1` (default redirect HTTPS).
3. Settings → confirm **Redirect URI** shows `https://127.0.0.1:8765/callback`.
4. Sign in → accept self-signed cert warning if prompted → complete Bungie authorize.
5. Confirm signed-in membership id → Sign out.
6. Confirm no Confidential secret was required.

### Jaspr

1. Register `https://YOUR_JASPR_ORIGIN/auth/callback`.
2. Serve web host with Public `BUNGIE_CLIENT_ID` and matching origin.
3. Settings → Sign in → browser returns to `/auth/callback` → session signed in.
4. Sign out. Confirm no `CLIENT_SECRET` / `SESSION_SECRET`.

### Smoke checklist markers

```
SMOKE-WINDOWS: operator / mocked-preflight PASS (DART-023 session tests + matrix HTTPS default)
SMOKE-JASPR: operator / mocked-preflight PASS (DART-045 session tests + /auth/callback matrix)
SMOKE-MOBILE: N/A (schemes published; session host deferred)
SECRET-SCAN: PASS (tool/client_secret_scan.dart)
```


## Session lifetime (Public clients)

Bungie **Public** OAuth clients **do not receive `refresh_token`** (official OAuth wiki). Windows/Jaspr therefore persist **access-only** sessions:

- Cold start restores while `access_token` is still valid (~1 hour minus safety margin).
- After access expiry the user must sign in again unless ops later moves to a confidential/BFF path that can hold a refresh token server-side.
- Token codec **must not** reject empty `refresh_token` (BUG-20260725-002).

## Non-goals

- Confidential cookie parity on pure clients
- Node BFF for token exchange
- Embedding refresh tokens in SQLite plaintext
- Multi-app Bungie split (day one)

## Related

- Windows host README OAuth section
- `apps/web_host` `/auth/callback` route (DART-045)
- Cutover checklist RC-AUTH / RB-03
