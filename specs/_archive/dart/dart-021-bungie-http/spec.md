# Feature Specification: DART-021 Shared Bungie HTTP Client

**Feature Branch**: `dart-021-bungie-http`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Shared Bungie HTTP client (API key header, errors, rate-limit hooks). Unit tests with mocked HTTP; no secrets in package."

**Program ID**: DART-021  
**Phase**: P2  
**Depends**: DART-011 (domain parity gate; pure packages remain pure)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- New workspace package **`packages/bungie`** (`destiny2_bungie`) — shared **Bungie Platform HTTP client**
- Always send public **`X-API-Key`** header (host-injected; never a secret)
- Optional **`Authorization: Bearer <accessToken>`** for authenticated Platform calls (token supplied per request or constructor; not stored as a secret constant)
- Parse Bungie **envelope** (`ErrorCode`, `Message`, `ThrottleSeconds`, `Response`)
- Typed **errors**: HTTP non-2xx, non-success `ErrorCode`, JSON parse failures
- **Rate-limit hooks**: observe throttle signals (`ThrottleSeconds > 0`, HTTP 429, known throttle `ErrorCode`) so later OAuth/sync/equip slices can wait or surface WAIT without re-implementing envelope parsing
- Injectable HTTP transport for **unit tests with mocked HTTP** (no live Bungie in CI)
- **No secrets in package**: no `CLIENT_SECRET`, no hard-coded API keys, no token persistence

**Out of scope (later slices):**

- OAuth PKCE authorize/token/refresh (DART-022)
- Windows OAuth UI / secure storage (DART-023)
- Profile fetch + inventory sync algorithm (DART-024)
- Equip write orchestration (DART-037)
- Manifest download pipeline (stays in `destiny2_manifest`; may adopt this client later, not required here)
- Flutter/Jaspr UI
- Node sidecar

### Assumptions

- **A1**: Package name `destiny2_bungie` at `packages/bungie`. Not pure-domain (uses network); **not** on the P0 pure graph-guard list.
- **A2**: Base URL default `https://www.bungie.net/Platform` (overridable for tests).
- **A3**: Success envelope is `ErrorCode == 1` (Bungie Success), matching product `assertBungieEnvelope`.
- **A4**: **Rate-limit hooks** = callbacks + structured throttle info on errors/responses; optional cooperative delay helper. Full retry/backoff policy is **not** mandatory auto-behavior (callers decide); client **must** surface throttle metadata.
- **A5**: HTTP transport is injectable (`BungieHttpTransport` typedef / interface). Default transport uses `dart:io` `HttpClient` (same pattern as manifest) — **no** required `package:http` dependency.
- **A6**: API key is required non-empty at construction; empty/null rejected. Key is never logged by the package.
- **A7**: No `CLIENT_SECRET` type, field, or parameter exists in the public API.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Platform GET/POST with API key (Priority: P1)

As a multiplatform data layer, I can perform Bungie Platform GET and POST requests that always include the host-provided public API key header, and optionally a Bearer token, and receive the unwrapped `Response` payload on success.

**Why this priority**: Core shared client for all P2+ Bungie traffic; roadmap goal “API key header”.

**Independent Test**: Mock transport records headers/method/body; success envelope returns Response map.

**Acceptance Scenarios**:

1. **Given** a client with API key `k` and mock transport returning `{ErrorCode:1, Response:{ok:true}}`, **When** `get('/User/GetMembershipsForCurrentUser/')` with access token, **Then** request URL is under Platform base, headers include `X-API-Key: k` and `Authorization: Bearer …`, and result is `{ok:true}`.
2. **Given** a client, **When** `post(path, body: map)` without token, **Then** headers include `X-API-Key` and `Content-Type: application/json`, no Authorization, body is JSON-encoded.
3. **Given** empty API key, **When** constructing client, **Then** construction fails with a clear error (no network call).

---

### User Story 2 - Typed Bungie / HTTP errors (Priority: P1)

As a caller (sync, equip, OAuth later), I receive typed errors for HTTP failures and non-success Bungie envelopes so I can branch on platform vs transport problems.

**Why this priority**: Roadmap goal “errors”; product profile/write clients throw on `ErrorCode !== 1`.

**Independent Test**: Mock transport returns 500 / ErrorCode≠1 / invalid JSON; assert exception types and fields.

**Acceptance Scenarios**:

1. **Given** HTTP status 503, **When** request completes, **Then** `BungieHttpException` (or subclass) exposes status code and is not a platform envelope error.
2. **Given** HTTP 200 with `{ErrorCode:99, Message:"Access Denied", ThrottleSeconds:0}`, **When** request completes, **Then** `BungiePlatformException` with `errorCode:99`, `message` containing Access Denied.
3. **Given** non-JSON body on 200, **When** request completes, **Then** parse-oriented error is thrown (not silent null Response).

---

### User Story 3 - Rate-limit hooks (Priority: P1)

As a later sync/equip orchestrator, I can register a rate-limit observer and/or read throttle metadata when Bungie signals throttling so I can wait or surface WAIT without re-parsing envelopes.

**Why this priority**: Roadmap exit “rate-limit hooks”.

**Independent Test**: Mock 429 and/or envelope with `ThrottleSeconds > 0` / throttle ErrorCode; assert hook invoked with structured info; optional delay helper uses seconds from signal.

**Acceptance Scenarios**:

1. **Given** an `onRateLimit` hook and response envelope `ErrorCode≠1` with `ThrottleSeconds: 5`, **When** request fails, **Then** hook is invoked with `throttleSeconds: 5` (and request path) before/as error is thrown.
2. **Given** HTTP 429 with optional `Retry-After` header, **When** request fails, **Then** hook receives throttle signal and HTTP exception includes throttle metadata when available.
3. **Given** success envelope with `ThrottleSeconds: 0`, **When** request succeeds, **Then** hook is **not** required to fire (no false throttle noise).

---

### Edge Cases

- Path already absolute URL vs path-relative under Platform base — client joins relative paths; absolute URLs allowed for tests.
- Concurrent requests: no global mutex in this slice (hooks are observational; hosts may serialize later).
- Soft guidance never auto-applies; this package has no domain save path.
- Secrets: scanning package sources must not reveal CLIENT_SECRET or hard-coded production keys.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Workspace MUST include package `packages/bungie` (`destiny2_bungie`) registered in root workspace.
- **FR-002**: Client MUST send `X-API-Key` on every Platform request from host-injected API key.
- **FR-003**: Client MUST support optional Bearer access token per request (and/or default on client).
- **FR-004**: Client MUST expose GET and POST helpers that unwrap successful Bungie envelopes (`ErrorCode == 1` → `Response`).
- **FR-005**: Client MUST throw typed errors for HTTP non-success and platform non-success envelopes.
- **FR-006**: Client MUST expose rate-limit hooks / throttle metadata for throttle signals (`ThrottleSeconds`, 429, related platform codes when present).
- **FR-007**: HTTP transport MUST be injectable; unit tests MUST pass with mocks only (no live network).
- **FR-008**: Package MUST NOT contain `CLIENT_SECRET`, session secrets, or hard-coded real API keys.
- **FR-009**: Pure domain packages MUST remain free of this package’s network deps (bungie is not pure).
- **FR-010**: Soft guidance never auto-applies.

### Key Entities

- **BungieHttpClient**: Configurable Platform client (base URL, API key, transport, hooks).
- **BungieEnvelope**: Parsed platform JSON wrapper fields.
- **BungieHttpException / BungiePlatformException**: Typed failure surfaces.
- **RateLimitSignal**: Structured throttle observation for hooks.
- **BungieHttpTransport**: Injectable request function for tests/hosts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/bungie` passes with mocked HTTP only.
- **SC-002**: Tests prove `X-API-Key` is set and Bearer is optional.
- **SC-003**: Tests prove ErrorCode≠1 and HTTP errors map to typed exceptions.
- **SC-004**: Tests prove rate-limit hook fires on throttle signal.
- **SC-005**: Package sources contain no `CLIENT_SECRET` / no embedded production secrets.
- **SC-006**: Workspace resolves (`dart pub get`); pure graph guard still passes.

## Assumptions

See A1–A7 above. Defaults chosen where product TS duplicated per-client fetch helpers without a shared package.
