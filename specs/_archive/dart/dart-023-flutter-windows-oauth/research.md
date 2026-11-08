# Research: DART-023 Flutter Windows OAuth

**Date**: 2026-07-24  
**Branch**: `dart-023-flutter-windows-oauth`

## Decisions

### R1 — Loopback HTTP over custom scheme for Windows

**Decision**: Complete OAuth via `HttpServer.bind('127.0.0.1', port)` and a fixed registered redirect (default `http://127.0.0.1:8765/callback`).  
**Rationale**: Bungie requires pre-registered `redirect_uri`; fixed loopback is the standard desktop public-client pattern; no Windows protocol registration needed for MVP.  
**Alternatives rejected**: Custom `destiny2buildcreator://` scheme only (extra Windows packaging); ephemeral random ports (cannot register every port with Bungie).

### R2 — Secure storage package

**Decision**: Use `flutter_secure_storage` for production `SecureTokenStore`; `MemoryTokenStore` for unit/widget tests.  
**Rationale**: OS-backed credentials on Windows; common Flutter desktop pattern; injectability satisfies SC-003 without platform plugins in pure unit tests.  
**Alternatives rejected**: Encrypt tokens into SQLite (still at-rest key management complexity; port decisions say not SQLite for refresh tokens); plain SharedPreferences (plaintext — forbidden).

### R3 — Session orchestration in host app (not packages/bungie)

**Decision**: `WindowsOAuthSession`, loopback server, and token store live under `apps/windows_host/lib/auth/`. Reuse `BungieOAuthClient` + PKCE helpers from `destiny2_bungie`.  
**Rationale**: DART-022 intentionally left browser/loopback/storage to the host; keeps `packages/bungie` free of Flutter plugins.  
**Alternatives rejected**: Moving secure storage into `packages/bungie` (would force Flutter dep on shared HTTP package).

### R4 — Injectable browser + callback for E2E tests

**Decision**: Abstract `BrowserLauncher` and allow injecting a pre-completed loopback result / fake server so CI proves sign-in/out without live Bungie or a real browser.  
**Rationale**: Exit “Sign-in/out E2E on Windows” as host-level end-to-end path with mocks; live Bungie is manual/dev only.  
**Alternatives rejected**: Live-only E2E as CI gate (needs secrets + flaky browser automation).

### R5 — Token serialization

**Decision**: JSON map: `access_token`, `refresh_token`, `expires_at` (ISO-8601 UTC), `refresh_expires_at`, `membership_id`. Single secure-storage key.  
**Rationale**: Stable, inspectable, no freezed dep required in host; maps cleanly to `BungieTokens`.

### R6 — No SQLite token columns

**Decision**: Do not add Drift columns or prefs tables for tokens. Membership id display comes from loaded `BungieTokens` only in this slice.  
**Rationale**: D-BUNGIE / roadmap: tokens not in SQLite plaintext; user/profile sync is DART-024.

## Product / architecture references

- `packages/bungie` — `BungieOAuthClient`, `BungieTokens`, PKCE, state, `PlatformRedirectUriConfig`
- `docs/multiplatform-dart-port-decisions.md` — D-WEB-AUTH, D-BUNGIE Public+PKCE, secure storage
- `apps/windows_host` — Settings + HostBootstrap (DART-019/020)
- Product Next OAuth is confidential — **do not port client secret path**

## Non-decisions (later)

- Inventory/profile after auth (DART-024)
- Auto-refresh background scheduler (may hang off session when first Platform call needs it)
- Mobile schemes / Jaspr storage
