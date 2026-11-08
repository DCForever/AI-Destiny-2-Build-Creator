# Feature Specification: DART-045 Jaspr Browser Public+PKCE OAuth

**Feature Branch**: `dart-045-jaspr-oauth-pkce`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Browser Public+PKCE + token storage strategy. No confidential secret; sign-in works on HTTPS loopback/prod origin."

**Program ID**: DART-045  
**Phase**: P5  
**Depends**: DART-022 (Public+PKCE OAuth core), DART-042 (Jaspr app skeleton)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (D-WEB-AUTH, D-BUNGIE)

## Scope boundary

**In scope:**

- Jaspr **web host** browser OAuth using **Public + PKCE (S256)** from `packages/bungie` (DART-022)
- **Same-origin redirect callback** route (e.g. `/auth/callback`) registered as Bungie `redirect_uri`
- **Token storage strategy** for browser: origin-isolated storage for access/refresh tokens — **never** SQLite plaintext, **never** `CLIENT_SECRET` / confidential flow
- **Pending PKCE handoff** (`state` + `code_verifier`) across authorize redirect (session-scoped, not SQLite)
- **Sign-in / sign-out** session controller wired into web host bootstrap
- **Settings UI** account card: signed-out → Sign in; signed-in → membership id + Sign out; busy/error/not-configured states
- Unit/component tests with mocked navigation + token transport (no live Bungie required in CI)
- Host-injected public `client_id` + web `redirect_uri` (HTTPS loopback or production origin) — **no confidential secret**

**Out of scope (later slices):**

- Profile fetch / inventory sync UI on web (later compose/sync slices)
- Compose spine UI (DART-046)
- Equip / DIM on web (DART-047)
- Confidential OAuth / iron-session cookies / BFF (legacy Next only; never Jaspr)
- Node sidecar / client_secret token exchange
- Flutter Windows/mobile OAuth changes (already DART-023+)
- Live Bungie manual QA as CI gate

### Assumptions

- **A1**: Callback path is **`/auth/callback`** on the same origin as the SPA (`{origin}/auth/callback`). Matches D-BUNGIE multi-redirect matrix for platform `web`.
- **A2**: Public `client_id` from compile-time `BUNGIE_CLIENT_ID` (or injected for tests). Empty client id → Sign in disabled with config hint.
- **A3**: Default redirect URI is derived from browser `window.location.origin + '/auth/callback'` when not overridden via `BUNGIE_REDIRECT_URI` / constructor. Supports HTTPS production origins and HTTPS (or registered) loopback origins used in local/prod-like hosting.
- **A4**: Browser has no OS keychain equivalent to Windows Credential Locker. **Token storage strategy**: origin-scoped web storage (`localStorage` production default; `MemoryTokenStore` for tests). Tokens **must not** be written into Drift/SQLite. Document HTTPS + origin isolation expectations.
- **A5**: Pending PKCE (`state` + `code_verifier`) is held in **sessionStorage** (or memory for tests) for the active sign-in only — survives same-tab redirect, cleared after exchange/failure.
- **A6**: Sign-in starts by navigating the current tab to Bungie authorize URL; callback lands on `/auth/callback`, completes exchange, then routes back to Settings.
- **A7**: Soft guidance never auto-applies; this slice has no domain save path.
- **A8**: No `BUNGIE_CLIENT_SECRET`, `client_secret`, or `SESSION_SECRET` in web host sources, pubspec, dart-defines used by this slice, or token request bodies.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browser token storage strategy (Priority: P1)

As the Jaspr web host, I can save, load, and clear `BungieTokens` using an origin-scoped token store that never writes access/refresh tokens into SQLite, and I never accept a confidential client secret.

**Why this priority**: Roadmap exit “No confidential secret” + D-WEB-AUTH / D-BUNGIE secure storage intent for pure clients.

**Independent Test**: Memory + browser-storage-backed store round-trip unit tests; scan of OAuth/web_host sources for `client_secret` / `CLIENT_SECRET` → none; tokens not written via Drift.

**Acceptance Scenarios**:

1. **Given** empty store, **When** tokens are written then read, **Then** membership id / tokens / expiries round-trip.
2. **Given** stored tokens, **When** clear is called, **Then** read returns null.
3. **Given** web host OAuth modules, **When** scanned for confidential secret identifiers, **Then** no `client_secret` / `CLIENT_SECRET` / `SESSION_SECRET` fields or dart-define usage appear.
4. **Given** token write path, **When** tokens are persisted, **Then** the store implementation is not SQLite/Drift.

---

### User Story 2 - Public+PKCE browser sign-in (Priority: P1)

As a web user on an HTTPS (or registered) origin, I can start sign-in from Settings, complete Bungie authorize in the browser, return to `/auth/callback`, pass CSRF `state` validation, exchange the code with PKCE (no client secret), and land signed-in with tokens stored per US1.

**Why this priority**: Roadmap exit “sign-in works on HTTPS loopback/prod origin”.

**Independent Test**: Inject fake navigation + mock token transport + pre-seeded pending PKCE; complete callback handler; assert authorize URL params, state validation, exchange body omits secret, tokens stored.

**Acceptance Scenarios**:

1. **Given** configured public client id + redirect URI, **When** sign-in starts, **Then** pending PKCE is stored, browser navigates to Bungie authorize URL with `client_id`, `response_type=code`, `state`, `redirect_uri`, `code_challenge`, `code_challenge_method=S256`, and **no** `client_secret`.
2. **Given** callback query `code` + matching `state` and stored verifier, **When** callback completes, **Then** tokens are stored and session is signed-in; pending PKCE is cleared.
3. **Given** callback `state` mismatch, **When** completing sign-in, **Then** sign-in fails, tokens are not stored, session is error/signed-out, pending cleared.
4. **Given** Bungie `error` query or missing code, **When** callback runs, **Then** session is not signed-in and error is non-leaking (no raw tokens in message).

---

### User Story 3 - Sign-out + Settings account UI (Priority: P1)

As a web user, I can see account status on Settings and sign out, which clears stored tokens and returns the UI to signed-out.

**Why this priority**: Completes sign-in/out UX for DART-045 exit criteria.

**Independent Test**: Component tests with fake session/store: membership shown when signed-in; Sign out clears; Sign in disabled when not configured.

**Acceptance Scenarios**:

1. **Given** signed-out and valid client id, **When** Settings renders, **Then** account card shows **Sign in** (no access/refresh token text).
2. **Given** signed-in with membership id `M123`, **When** Settings renders, **Then** membership id is shown and **Sign out** is available.
3. **Given** signed-in, **When** user activates Sign out, **Then** token store is cleared and UI returns to signed-out.
4. **Given** missing client id, **When** Settings renders, **Then** Sign in is disabled with a configuration hint (no crash).

---

### Edge Cases

- Double-click Sign in while busy → second start ignored (no double navigate races).
- Token JSON corrupt in web storage → treat as signed-out; allow re-auth.
- Callback visited with no pending PKCE → error, signed-out.
- Soft guidance never auto-applies.
- No confidential secrets in host sources or binaries API surface.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Web host MUST expose a `TokenStore` (or web equivalent interface) that save/load/clears `BungieTokens` without SQLite plaintext for secrets.
- **FR-002**: Production browser path MUST use origin-scoped web storage strategy (documented); tests use in-memory store.
- **FR-003**: Host MUST use DART-022 `BungieOAuthClient` Public+PKCE only — no `client_secret` in types, bodies, or config.
- **FR-004**: Sign-in MUST generate PKCE S256 + CSRF state, persist pending auth for the redirect, and navigate to authorize URL.
- **FR-005**: Callback route MUST validate `state`, exchange `code` via `exchangeCode`, persist tokens, clear pending, and redirect to Settings.
- **FR-006**: Host MUST support sign-out that clears token store and updates UI.
- **FR-007**: Settings MUST show account status (signed-out / signing-in / signed-in / error / not configured) without displaying raw tokens.
- **FR-008**: Redirect URI MUST be origin + `/auth/callback` (or injected override) suitable for HTTPS loopback/prod registration.
- **FR-009**: Soft guidance never auto-applies.
- **FR-010**: CI tests MUST pass with mocks only (no live Bungie).

### Key Entities

- **WebTokenStore / MemoryTokenStore**: Persist `BungieTokens` outside SQLite.
- **WebPendingAuthStore**: session-scoped `OAuthPendingAuth` across redirect.
- **WebOAuthSession**: Sign-in/out/restore/callback orchestration for Jaspr.
- **OAuthAccountCard** (web): Settings account panel.
- **AuthCallbackPage**: Handles `/auth/callback` query params.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test` in `apps/web_host` passes (including new OAuth tests) with mocked HTTP/navigation only.
- **SC-002**: Tests prove authorize URL includes PKCE S256 + state and omits client_secret.
- **SC-003**: Tests prove token store round-trip and clear; tokens not written via Drift.
- **SC-004**: Tests prove callback success, state mismatch failure, and sign-out.
- **SC-005**: Grep/scan of web_host OAuth sources shows no `client_secret` / `CLIENT_SECRET` / `SESSION_SECRET`.
- **SC-006**: Settings UI shows Sign in / Sign out / membership without raw token display.
- **SC-007**: Workspace resolves; pure graph guard still passes if run.

## Assumptions

See A1–A8 above. Defaults match D-WEB-AUTH (Public+PKCE only; no confidential cookie parity via BFF) and D-BUNGIE hybrid (Dart shells Public).
