# Research: DART-058 Prod Public OAuth Matrix

**Date**: 2026-07-25  
**Slice**: DART-058

## Decisions

### R1 — One Public app, multi-redirect matrix

**Decision**: Keep D-BUNGIE hybrid: single production **Public** Bungie application with multiple registered redirect URIs (Windows HTTPS loopback, Jaspr origin callback, mobile schemes).

**Rationale**: Port decisions already lock this; multi-app split only when store-review/ops pain warrants it.

**Alternatives rejected**: Per-shell Bungie apps on day one (ops overhead without requirement).

### R2 — Windows default HTTPS (not HTTP)

**Decision**: Published and host default redirect is `https://127.0.0.1:8765/callback`. Loopback TLS material already exists (`apps/windows_host/certs/`, `LoopbackCallbackServer.useTls`).

**Rationale**: README + run-windows.ps1 already document HTTPS; Bungie prefers HTTPS redirects; exit criteria explicitly say “Windows HTTPS loopback”. Legacy code default was HTTP and must be aligned.

**Alternatives rejected**: Keep HTTP default (diverges from docs and RC-AUTH HTTPS expectation).

### R3 — Web path fixed; origin operator-owned

**Decision**: Matrix documents path `/auth/callback` and helper `webRedirectUri(origin)`. Placeholder origin in docs only (`https://YOUR_JASPR_ORIGIN`); runtime uses browser origin or `BUNGIE_REDIRECT_URI` override (existing `WebOAuthConfig`).

**Rationale**: Production hostname is deployment-specific; code must not hard-code a fake prod domain as the only option.

### R4 — Mobile scheme publish without full host OAuth

**Decision**: Publish `d2buildcreator://oauth/callback` for Android and iOS in the matrix. Do not implement mobile `OAuthSession` in this slice (mobile surface matrix marks OAuth N/A; cutover-required shells are Windows + web).

**Rationale**: Exit criteria require mobile **schemes** in the matrix; full phone sign-in is product residual after portal registration.

### R5 — Secret scan as pure Dart tool

**Decision**: Add `tool/client_secret_scan.dart` with unit tests (pattern match on lib trees). Document that release binary scan is the same string patterns over built artifacts when operators ship.

**Rationale**: RC-AUTH asks for binary/source scan; CI-stable source scan is enforceable; binary scan is operator step at packaging time using the same forbidden strings.

### R6 — Live smoke evidence

**Decision**: CI “smoke” = matrix tests + secret scan + existing Windows/Jaspr mocked OAuth session tests. Operator live checklist in matrix doc for real Bungie login when credentials exist. RB-03 clears on published matrix + automated gates + architecture (Public+PKCE already shipped).

**Rationale**: Cannot require live Bungie credentials in automated agent/CI; PROC-style evidence is docs + gates + existing E2E mocks.

## References

- `docs/multiplatform-dart-port-decisions.md` — D-WEB-AUTH, D-BUNGIE  
- `packages/bungie/lib/src/oauth/redirect_uri_config.dart`  
- `apps/windows_host/lib/auth/loopback_callback_server.dart`  
- `apps/web_host/lib/auth/web_oauth_config.dart`  
- GAP-AUTH-01 / RB-03 / RC-AUTH  
