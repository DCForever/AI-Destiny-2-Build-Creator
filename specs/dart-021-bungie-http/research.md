# Research: DART-021 Shared Bungie HTTP Client

**Date**: 2026-07-24  
**Branch**: `dart-021-bungie-http`

## Decisions

### R1 — New package `destiny2_bungie`

**Decision**: `packages/bungie` with pub name `destiny2_bungie`.  
**Rationale**: Roadmap P2 foundation for OAuth (DART-022), profile sync (DART-024), equip (DART-037). Manifest already has a minimal GET helper for raw tables; a shared Platform client belongs outside pure domain and outside entity-store packaging.  
**Alternatives rejected**: Extending only `destiny2_manifest` (wrong dependency direction for OAuth); putting HTTP in `destiny2_domain` (violates purity).

### R2 — Injectable transport, default `dart:io` HttpClient

**Decision**: `typedef BungieHttpTransport = Future<BungieHttpResponse> Function(BungieHttpRequest request);` with a default factory using `HttpClient`.  
**Rationale**: Matches DART-018 manifest pattern; no new third-party HTTP package; unit tests inject mocks.  
**Alternatives rejected**: Hard dependency on `package:http` (extra surface); only mockable via global `HttpOverrides` (harder tests).

### R3 — Envelope success = ErrorCode == 1

**Decision**: Mirror product `assertBungieEnvelope` in `profile.ts` / `writeClient.ts`.  
**Rationale**: Product parity; Bungie Platform convention.

### R4 — Rate-limit hooks are observational + metadata

**Decision**:  
- `typedef RateLimitHook = void Function(RateLimitSignal signal);` on the client.  
- Platform failures with `ThrottleSeconds > 0` and HTTP 429 invoke the hook.  
- Exceptions carry optional `throttleSeconds`.  
- Optional static helper `suggestedDelay(RateLimitSignal)` returns `Duration` for cooperative wait — **does not auto-retry**.  
**Rationale**: Roadmap says “hooks”; DBR-EQP-007 / product equip research treat rate limits as caller policy (~1/min inventory, WAIT surface). Auto-retry would hide errors from orchestrators.  
**Alternatives rejected**: Silent auto-retry loop (opaque to equip/sync); ignoring ThrottleSeconds (callers re-parse JSON).

### R5 — No secrets in package

**Decision**: Constructor requires host-injected `apiKey` `String`. No env file reads inside package for secrets. No `clientSecret` parameter. Tokens only as runtime request args.  
**Rationale**: D-WEB-AUTH / D-IO; roadmap exit “no secrets in package”.

### R6 — Known throttle ErrorCode

**Decision**: Treat HTTP 429 always as rate-limit. Also treat platform `ThrottleSeconds > 0` as rate-limit regardless of ErrorCode. Optionally recognize Bungie `ErrorCode` **1672** (`DestinyThrottledByGameServer` / throttle family used in community docs) when present without relying solely on it.  
**Rationale**: Defensive; product TS does not currently parse ThrottleSeconds — we improve for multiplatform.

## Product reference

- `src/lib/bungie/profile.ts` — `X-API-Key`, Bearer, `assertBungieEnvelope`
- `src/lib/bungie/writeClient.ts` — POST + same envelope assert
- `packages/manifest/lib/src/http_client.dart` — injectable GET pattern
- `docs/multiplatform-dart-port-decisions.md` — Public+PKCE; no CLIENT_SECRET

## Non-decisions (later)

- OAuth token exchange endpoints (DART-022 may use this client or a thin OAuth-specific caller)
- Profile/inventory parsing (DART-024)
- Equip step execution (DART-037)
- Migrating manifest download onto this client (optional follow-on)
