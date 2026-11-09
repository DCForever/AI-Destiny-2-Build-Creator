# Research: DART-022 Public+PKCE OAuth Core

**Date**: 2026-07-24  
**Branch**: `dart-022-oauth-pkce`

## Decisions

### R1 — Extend `packages/bungie` (no new package)

**Decision**: Add OAuth/PKCE modules under `packages/bungie/lib/src/oauth/`.  
**Rationale**: DART-021 already owns shared Bungie network types (`BungieHttpTransport`). A second package would only re-export transport and fragment P2 auth.  
**Alternatives rejected**: New `packages/bungie_oauth` (extra workspace churn); pure domain package (network + crypto I/O boundary).

### R2 — Public client token body (no Basic secret)

**Decision**: Token POST uses `application/x-www-form-urlencoded` with `client_id` in body; **never** `client_secret` or `Authorization: Basic`.  
**Rationale**: D-WEB-AUTH Public+PKCE; roadmap exit “No client_secret fields”. Product Next confidential client uses Basic — **do not port that path**.  
**Alternatives rejected**: Dual confidential/public API (scope creep; secret fields would exist).

### R3 — PKCE S256 only

**Decision**: `code_challenge_method=S256`; generate verifier with `Random.secure()` (43–128 chars, unreserved). Challenge = BASE64URL(SHA256(ascii(verifier))) without padding.  
**Rationale**: RFC 7636; Bungie supports S256; plain method is weaker and unused.  
**Dependency**: `package:crypto` for SHA-256 (standard Dart crypto package).

### R4 — Token endpoint is OAuth JSON, not Platform envelope

**Decision**: Parse token responses as OAuth fields (`access_token`, `expires_in`, …), not `ErrorCode` envelopes. Reuse transport types only.  
**Rationale**: Product `oauth.ts` already treats token endpoint as raw OAuth JSON.

### R5 — Platform redirect URI matrix

**Decision**: Enum-like platforms (`windows`, `android`, `ios`, `web`) + host-provided URI map + `resolve(platform)`. Empty URIs rejected.  
**Rationale**: Port decisions multi-redirect matrix; DART-023/045 supply concrete loopback/scheme/origin values.  
**Alternatives rejected**: Single global constant redirect (breaks multi-platform); reading env files inside package (host concern).

### R6 — CSRF state helpers only (no session store)

**Decision**: Generate/validate `state`; optional `OAuthPendingAuth` DTO for hosts. Persistence/secure storage is DART-023.  
**Rationale**: Slice exit is pure authorize/token/refresh + config, not Windows E2E.

### R7 — Expiry helpers parity

**Decision**: `needsRefresh` / `isSessionExpired` mirror product; access mapping subtracts 60s margin.  
**Rationale**: Prevent edge-of-expiry Platform 401s.

## Product / architecture references

- `src/lib/bungie/oauth.ts` — endpoints, token map, refresh (confidential — adapt to Public)
- `src/lib/bungie/types.ts` — `BungieTokens` shape
- `docs/multiplatform-dart-port-decisions.md` — D-WEB-AUTH, D-BUNGIE Public+PKCE
- `packages/bungie` — DART-021 transport + errors

## Non-decisions (later)

- Loopback HTTP listener / deep link (DART-023)
- Secure storage of refresh tokens (DART-023)
- Browser origin cookie-less storage strategy (DART-045)
- Profile membership selection after tokens (DART-024)
