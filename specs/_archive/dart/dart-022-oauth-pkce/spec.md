# Feature Specification: DART-022 Public+PKCE OAuth Core

**Feature Branch**: `dart-022-oauth-pkce`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Public+PKCE authorize/token/refresh pure + platform redirect URI config. No client_secret fields; state/CSRF; token model."

**Program ID**: DART-022  
**Phase**: P2  
**Depends**: DART-021 (shared Bungie HTTP client)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Extend **`packages/bungie`** (`destiny2_bungie`) with **Public + PKCE (S256)** OAuth helpers
- **Authorize URL** builder: `client_id`, `response_type=code`, `state`, `redirect_uri`, `code_challenge`, `code_challenge_method=S256`
- **PKCE pair** generation (`code_verifier` + S256 `code_challenge`)
- **CSRF `state`** generation + constant-time validation helper
- **Token exchange** (`authorization_code` + `code_verifier`) and **refresh** (`refresh_token`) against Bungie token endpoint
- **Token model** (`BungieTokens`) with access/refresh, expiry timestamps, membership id
- **Platform redirect URI config** (host-selected URI matrix / resolver — no hard-coded production secrets)
- Injectable HTTP transport for unit tests (reuse DART-021 transport types)
- **No `client_secret` fields** anywhere in the public or private OAuth API surface

**Out of scope (later slices):**

- Windows loopback/deep-link browser open + secure token storage (DART-023)
- Jaspr browser OAuth shell (DART-045)
- Profile fetch / inventory sync (DART-024)
- Flutter/Jaspr UI for sign-in
- Confidential OAuth / Basic auth with client secret (legacy Next only)
- Node sidecar / BFF token exchange

### Assumptions

- **A1**: OAuth lives in existing `packages/bungie` (not a new package) — natural extension of DART-021 client surface for P2 auth.
- **A2**: Token endpoint is `https://www.bungie.net/platform/app/oauth/token/` (product parity). Response is **OAuth JSON** (not Platform envelope `ErrorCode`).
- **A3**: Authorize base is `https://www.bungie.net/en/oauth/authorize` (product parity).
- **A4**: Public client token requests send **`client_id` in the form body** and **never** send `client_secret` or Basic auth with a secret.
- **A5**: PKCE method is **S256 only** (not plain).
- **A6**: Access-token expiry applies a **60s margin** when mapping `expires_in` → `expiresAt` (product `EXPIRY_MARGIN_MS` parity).
- **A7**: Platform redirect config is a pure map/resolver of known platforms → registered `redirect_uri` strings supplied by the host; this slice does **not** open browsers or bind loopback ports.
- **A8**: Random `state` and `code_verifier` use `Random.secure()` (or injected entropy for tests).
- **A9**: Soft guidance never auto-applies; this package has no domain save path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - PKCE authorize URL + CSRF state (Priority: P1)

As a multiplatform host (Windows later), I can generate a cryptographically random OAuth `state` and PKCE pair, then build a Bungie authorize URL that includes `code_challenge` (S256), `state`, `client_id`, `redirect_uri`, and `response_type=code` so the user can complete browser consent without a client secret.

**Why this priority**: Core of Public+PKCE; roadmap exit “state/CSRF” and authorize path.

**Independent Test**: Unit tests generate PKCE, build URL, assert query params; validate state match/mismatch.

**Acceptance Scenarios**:

1. **Given** client id `cid` and redirect `http://127.0.0.1:8765/callback`, **When** a PKCE pair and state are generated and authorize URL is built, **Then** the URL is under Bungie authorize base and includes `client_id`, `response_type=code`, `state`, `redirect_uri`, `code_challenge`, and `code_challenge_method=S256`.
2. **Given** an expected state `abc` and returned state `abc`, **When** validated, **Then** validation succeeds; for `abc` vs `xyz`, validation fails.
3. **Given** a generated PKCE pair, **When** inspected, **Then** `code_verifier` is high-entropy URL-safe and `code_challenge` equals BASE64URL(SHA256(verifier)) without padding.

---

### User Story 2 - Token exchange and refresh without client_secret (Priority: P1)

As a multiplatform data layer, I can exchange an authorization `code` for tokens using `code_verifier` + `client_id`, and later refresh using `refresh_token` + `client_id`, with **no** `client_secret` parameter or Basic secret header.

**Why this priority**: Roadmap exit “No client_secret fields; token model”.

**Independent Test**: Mock transport records POST body/headers; map token JSON to `BungieTokens`; assert no secret fields on types/API.

**Acceptance Scenarios**:

1. **Given** a mock token response with access/refresh/expires/membership, **When** `exchangeCode` is called, **Then** body is `application/x-www-form-urlencoded` with `grant_type=authorization_code`, `code`, `client_id`, `code_verifier`, `redirect_uri`, and headers do **not** include Basic auth with a secret.
2. **Given** stored tokens, **When** `refresh` is called, **Then** body includes `grant_type=refresh_token`, `refresh_token`, `client_id` and no `client_secret`.
3. **Given** a successful raw token response, **When** mapped, **Then** `BungieTokens` has access/refresh tokens, `bungieMembershipId`, `expiresAt` ≈ now + expires_in − 60s, and `refreshExpiresAt` ≈ now + refresh_expires_in.
4. **Given** package sources and public OAuth API, **When** scanned, **Then** no `clientSecret` / `client_secret` / `CLIENT_SECRET` fields exist on OAuth types or method signatures.

---

### User Story 3 - Platform redirect URI config (Priority: P1)

As a host author, I can configure per-platform redirect URIs (Windows loopback, mobile schemes, web callback) and resolve the active `redirect_uri` for the current platform so DART-023/045 do not invent ad-hoc URI strings.

**Why this priority**: Roadmap goal “platform redirect URI config”; D-BUNGIE multi-redirect matrix.

**Independent Test**: Build a matrix; resolve Windows vs android vs web; missing platform throws clear config error.

**Acceptance Scenarios**:

1. **Given** a matrix with Windows `http://127.0.0.1:8765/callback` and web `https://app.example/auth/callback`, **When** resolving for Windows, **Then** the Windows URI is returned.
2. **Given** a matrix missing Android, **When** resolving Android, **Then** a clear configuration error is thrown (no silent fallback to another platform).
3. **Given** empty or blank redirect URI values when registering, **When** constructing/validating config, **Then** construction fails.

---

### Edge Cases

- Token HTTP non-2xx → typed OAuth/token error (do not leak tokens in message).
- Malformed token JSON → parse error, not partial tokens.
- State comparison is timing-safe enough for CSRF (constant-time compare of equal-length strings; length mismatch fails immediately).
- Special characters in `state` / redirect URI are URL-encoded in authorize query.
- Soft guidance never auto-applies.
- Pure domain packages remain free of this package’s network/crypto usage graph expansion as a pure dep (bungie is already non-pure).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose PKCE S256 pair generation (`code_verifier`, `code_challenge`).
- **FR-002**: Package MUST expose OAuth CSRF `state` generation and validation helpers.
- **FR-003**: Package MUST build Bungie authorize URLs including PKCE challenge params and redirect URI.
- **FR-004**: Package MUST exchange authorization codes and refresh tokens via form POST without any `client_secret`.
- **FR-005**: Package MUST expose a `BungieTokens` model (access, refresh, expiries, membership id) plus `needsRefresh` / `isSessionExpired` helpers.
- **FR-006**: Package MUST expose platform redirect URI configuration/resolution (host-supplied URIs per platform).
- **FR-007**: OAuth HTTP MUST use injectable transport; unit tests MUST pass with mocks only.
- **FR-008**: Public and private OAuth APIs MUST NOT define `clientSecret` / `client_secret` fields or parameters.
- **FR-009**: Access token mapping MUST apply a 60-second expiry margin.
- **FR-010**: Soft guidance never auto-applies.

### Key Entities

- **PkcePair**: `codeVerifier`, `codeChallenge`, method S256.
- **BungieOAuthClient**: Authorize URL + exchange + refresh using Public client id + PKCE.
- **BungieTokens**: Runtime token set (not persisted by this package).
- **OAuthRedirectPlatform / PlatformRedirectUriConfig**: Platform → redirect_uri matrix and resolver.
- **OAuthPendingAuth** (optional helper): Holds `state` + `codeVerifier` + `redirectUri` for hosts to store between authorize and callback (no secure storage here).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/bungie` passes (including new OAuth/PKCE tests) with mocked HTTP only.
- **SC-002**: Tests prove authorize URL includes PKCE S256 params and state.
- **SC-003**: Tests prove token exchange/refresh bodies omit `client_secret` and use `client_id` + PKCE where required.
- **SC-004**: Tests prove state validation and token model expiry helpers.
- **SC-005**: Tests prove platform redirect resolution and rejection of missing/blank URIs.
- **SC-006**: Grep/scan of OAuth sources shows no `client_secret` / `clientSecret` API surface.
- **SC-007**: Workspace resolves; pure graph guard still passes.

## Assumptions

See A1–A9 above. Defaults chosen to match Bungie Public app + product token endpoint while **replacing** confidential Basic auth with Public+PKCE per port decisions.
