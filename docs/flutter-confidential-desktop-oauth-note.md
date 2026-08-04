# Note — Potential Confidential desktop OAuth for Flutter

**Status:** design note (not implemented)  
**Updated:** 2026-08-04  
**Audience:** agents + operators considering DIM-like multi-day login on Windows  
**Current default:** Public + PKCE — [multiplatform-dart-prod-public-oauth-matrix.md](./multiplatform-dart-prod-public-oauth-matrix.md), `D-WEB-AUTH` / `D-BUNGIE` in [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Host README:** `flutter/apps/windows_host/README.md`

## Why this note exists

Bungie **Public** clients **do not receive `refresh_token`** (portal OAuth docs). Access lasts ~1 hour. After expiry the Windows host must re-run browser OAuth for **live** API/Sync. Local inventory still powers Catalog Owned (see `findLastSyncedBungieUser` / `OwnedCatalogBridge`).

**DIM** and **Next.js** stay signed in for weeks because they use a **Confidential** Bungie app: token exchange returns `refresh_token` + `refresh_expires_in` (~90 days). Silent refresh on cold start = no hourly login.

This note records **implications** and a **Flutter-shaped path** if product decides Confidential desktop is worth the security tradeoff.

## Current vs potential

| | Today (Public, Windows Flutter) | Potential (Confidential desktop) |
| --- | --- | --- |
| Bungie app type | Public | Confidential (new or shared with Next) |
| Token exchange | `client_id` + PKCE; **no** secret | Basic auth or `client_secret` body |
| Refresh token | **None** | Expected (~90d) |
| Live session UX | Re-sign-in ~hourly for Sync/API | Silent refresh like DIM / Next |
| Secret storage | N/A | **Must not** ship in binary/repo |
| Cutover gates | `client_secret_scan` forbids secret in client trees | Scan rules / architecture exception needed |
| Redirect | `https://127.0.0.1:8765/callback` | Same loopback **or** dedicated Confidential redirect |

## Implications (security & product)

### 1. Secret exposure risk

A true Confidential client assumes the secret is **not** extractable by end users. A Flutter **desktop binary** is reverse-engineerable:

- Embedding `BUNGIE_CLIENT_SECRET` in the shipped `.exe` / assets is **weak Confidential** (security theater vs Public).
- Anyone who extracts the secret can mint tokens for **your** Bungie app (quota abuse, user data under your client id, app disablement risk).

**Acceptable only if:**

- **Operator / power-user / dev machine** (gitignored env, never CI-published builds), **or**
- Secret lives on a **local helper / BFF** you control (not in the Flutter app package), **or**
- Product explicitly accepts “personal desktop tool” threat model (not a store multi-user product).

**Not acceptable for:** public store builds, CI artifacts, open-source release binaries, shared machines.

### 2. Conflict with current architecture decisions

| Decision | Tension |
| --- | --- |
| `D-WEB-AUTH` / `D-BUNGIE` | Public+PKCE only; no secret in Flutter/Jaspr |
| DART-058 / RC-AUTH | Matrix + `tool/client_secret_scan.dart` must stay green for Public path |
| Next cutover | Confidential stays Next-server-only until cutover |

Confidential desktop is a **product decision + ADR update**, not a silent code flip. Update port-decisions (or supersede) before merging production Confidential into the default Windows host.

### 3. Operational

- **Second Bungie app** recommended (do not overload Next Confidential redirect `:3000/api/auth/callback` with desktop loopback unless ops deliberately multi-registers).
- Redirect must match portal **exactly** (HTTPS loopback still fine).
- API key must be the key **linked to that client id** (Bungie ties keys to the app).
- Signing out / revoke: refresh invalidation same as Next.
- Compromised secret → rotate portal keys, force re-auth all users of that app.

### 4. UX

| Surface | Public today | With Confidential refresh |
| --- | --- | --- |
| Catalog Owned | Local DB after access expiry | Same + live session stays warm |
| Settings Sync | Needs live access | Silent refresh then Sync |
| Cold start | Often signed out after ~1h | `restore()` → refresh grant → signed in |
| First install | Browser OAuth | Same (first time only more often) |

Local-owned fallback **remains valuable** even with Confidential (offline, corrupt refresh, network down).

### 5. Multiplatform

| Shell | Confidential? |
| --- | --- |
| Windows host | Only candidate for optional Confidential (desktop threat model + loopback) |
| Jaspr web | **Do not** put secret in browser; would need BFF (explicitly rejected for pure clients in `D-WEB-AUTH`) |
| Mobile | Same as Public default; store review + secret extraction worse than desktop |

Prefer **optional Windows-only** Confidential, keep Public default for other shells.

## How we might implement it (Flutter)

### Option A — Operator-only secret on machine (smallest)

**When:** personal/dev Windows host only; never store/CI.

1. **Bungie portal:** Confidential app; redirect `https://127.0.0.1:8765/callback` (or dedicated path).
2. **Config:** gitignored `.env.windows.local`:
   ```text
   BUNGIE_CLIENT_ID=…
   BUNGIE_CLIENT_SECRET=…   # machine-only
   BUNGIE_API_KEY=…
   BUNGIE_REDIRECT_URI=https://127.0.0.1:8765/callback
   ```
3. **`run-windows.ps1`:** pass secret only via `--dart-define` when present; **never** log it.
4. **`BungieOAuthClient`:**
   - Detect confidential mode when secret non-empty.
   - Token POST: include `client_secret` **or** `Authorization: Basic base64(id:secret)` (match Next `web/NextJS/src/lib/bungie/oauth.ts`).
   - PKCE: keep for defense-in-depth if portal allows; Next confidential code exchange historically uses Basic without PKCE — confirm portal rules for that app.
5. **`mapTokenResponse`:** already accepts refresh; assert/warn if confidential exchange returns empty refresh.
6. **`WindowsOAuthSession.restore`:** existing refresh path already works when `refreshToken` non-empty.
7. **Gates:**
   - `client_secret_scan`: allow only env/`fromEnvironment` patterns that **do not** hardcode values; forbid secret literals in `lib/`.
   - Default CI builds **omit** secret → remain Public behavior.
8. **Docs / ADR:** “Optional Confidential Windows operator mode.”

**Pros:** Smallest code change; real refresh tokens.  
**Cons:** Secret on disk of every operator; not shippable to strangers.

### Option B — Local loopback token helper (medium)

**When:** want Confidential without secret inside Flutter package.

1. Tiny local process (Dart CLI / PowerShell / existing Next on localhost) holds secret.
2. Flutter opens browser OAuth → code → posts **code only** to `https://127.0.0.1:9xxx/token` on the helper.
3. Helper exchanges with Bungie (secret) → returns tokens to Flutter over loopback.
4. Flutter still stores tokens in DualTokenStore; refresh either:
   - Flutter holds refresh and calls Bungie refresh **without** secret if Bungie allows refresh with refresh_token alone for confidential (check current API — Bungie confidential refresh typically needs client auth), **or**
   - Helper also implements refresh.

**Pros:** Secret never in Flutter binary.  
**Cons:** Second process; install complexity; closer to a BFF (`D-WEB-AUTH` caution).

### Option C — Shared Next / remote BFF (largest)

**When:** multi-device product wants one identity.

1. Flutter redirects to product web OAuth (Next Confidential).
2. Session via backend; desktop uses API with short-lived tokens from backend.
3. Aligns with server-held secrets; biggest product/infra change.

**Pros:** Real Confidential security model.  
**Cons:** Requires backend always on; not “offline desktop first.”

### Recommended order if we pursue this

1. **Product yes/no** on threat model (operator-only vs store).
2. **ADR** superseding or carving exception to “no secret in Flutter” for **Windows operator mode only**.
3. **Option A** prototype behind env flag (`BUNGIE_OAUTH_MODE=public|confidential`).
4. Keep Public matrix as default; confidential untested in CI without secret fixtures.
5. Keep local inventory fallback forever.
6. Do **not** enable Confidential for Jaspr/mobile without a proper BFF story.

## Code touch map (Option A sketch)

| Area | Change |
| --- | --- |
| `packages/bungie` `BungieOAuthClient` | Optional secret; Basic/form confidential exchange + refresh |
| `apps/windows_host` `local_env.dart` / `run-windows.ps1` | Load secret when set; never print |
| `WindowsOAuthSession` | Log “confidential refresh enabled” without secret length leakage |
| Token tests | Fixture with refresh required when confidential |
| `tool/client_secret_scan.dart` | Document allowed env-only patterns |
| Product-map / Settings UI | Optional “Session: Public (~1h) / Confidential (refresh)” diagnostic |

Reference implementation already in repo: `web/NextJS/src/lib/bungie/oauth.ts` (Basic auth + required `refresh_token` in response).

## Non-goals of this note

- Changing the default production matrix to Confidential without an ADR.
- Embedding Next’s `BUNGIE_CLIENT_SECRET` in Flutter CI or release builds.
- Claiming Public mapping can invent refresh tokens (it cannot).

## Related

- Live Public matrix: [multiplatform-dart-prod-public-oauth-matrix.md](./multiplatform-dart-prod-public-oauth-matrix.md)
- Port decisions: [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) (`D-WEB-AUTH`, `D-BUNGIE`)
- Windows host runbook: `flutter/apps/windows_host/README.md`
- Local owned after Public expiry: `findLastSyncedBungieUser` in `packages/db`, `OwnedCatalogBridge`
