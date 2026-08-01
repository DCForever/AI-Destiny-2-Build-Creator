# Feature Specification: DART-023 Flutter Windows OAuth

**Feature Branch**: `dart-023-flutter-windows-oauth`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Windows loopback/deep-link OAuth + secure storage. Sign-in/out E2E on Windows; tokens not in SQLite plaintext."

**Program ID**: DART-023  
**Phase**: P2  
**Depends**: DART-022 (Public+PKCE OAuth core), DART-019 (Flutter Windows host skeleton)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter Windows host **loopback OAuth callback** listener (`127.0.0.1` only) completing Public+PKCE flow from DART-022
- **Open system browser** to Bungie authorize URL (injectable launcher for tests)
- **Secure token persistence** for `BungieTokens` (access + refresh + expiries + membership id) — **not** SQLite plaintext, **not** SharedPreferences plaintext
- **Sign-in / sign-out** session controller wired into Windows host bootstrap
- **Settings UI** account card: signed-out → Sign in; signed-in → membership id + Sign out; busy/error states
- Unit/widget tests proving: full sign-in/out path with mocks (no live Bungie required in CI); tokens absent from SQLite after secure write
- Host-injected public `client_id` + Windows `redirect_uri` (+ optional API key already present) — **no CLIENT_SECRET**

**Out of scope (later slices):**

- Profile fetch / inventory sync (DART-024)
- Inventory sync Settings card (DART-025)
- Mobile custom-scheme OAuth (DART-040+)
- Jaspr browser OAuth (DART-045)
- Confidential OAuth / iron-session cookies
- Node sidecar / BFF token exchange
- Full live Bungie manual QA as CI gate (optional manual note only)

### Assumptions

- **A1**: Windows primary callback is **HTTP loopback** (`http://127.0.0.1:<port>/callback`). Custom deep-link scheme is not required for this slice; loopback satisfies “loopback/deep-link” for desktop.
- **A2**: Default redirect is `http://127.0.0.1:8765/callback` (fixed port so Bungie app registration is stable). Overridable via compile-time `BUNGIE_REDIRECT_URI` / constructor.
- **A3**: Public client id from compile-time `BUNGIE_CLIENT_ID` (or injected for tests). Empty client id → Sign in disabled with clear config message.
- **A4**: Secure storage backend is **`flutter_secure_storage`** on Windows (Credential Locker / platform secure store). Tests use in-memory `TokenStore`.
- **A5**: Pending PKCE (`state` + `code_verifier`) is held **in process memory** for the active sign-in only; not written to SQLite.
- **A6**: Sign-in/out E2E means host-level orchestration tests with mocked browser, loopback injection, and OAuth transport — green on Windows CI/dev without live Bungie credentials.
- **A7**: Soft guidance never auto-applies; this slice has no domain save path.
- **A8**: Users table may later store membership id (DART-024); this slice **must not** persist access/refresh tokens in Drift/SQLite.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure token storage (Priority: P1)

As the Windows host, I can save and load `BungieTokens` in platform secure storage and clear them on sign-out, with **no** access/refresh token written into the SQLite `app.db`.

**Why this priority**: Roadmap exit “tokens not in SQLite plaintext”; D-BUNGIE secure storage requirement.

**Independent Test**: Memory + (where available) secure store round-trip; after write, scan SQLite file/pages for token strings → none.

**Acceptance Scenarios**:

1. **Given** empty store, **When** tokens are written then read, **Then** equal membership id / tokens / expiries are returned.
2. **Given** stored tokens, **When** clear is called, **Then** read returns null.
3. **Given** tokens written only via secure `TokenStore` while Drift DB is open, **When** SQLite content is searched for the access and refresh token strings, **Then** neither string appears.

---

### User Story 2 - Loopback OAuth sign-in (Priority: P1)

As a Windows user, I can start sign-in from Settings, complete Bungie authorize in the system browser, and have the app capture the loopback callback, validate CSRF `state`, exchange the code with PKCE, and persist tokens securely.

**Why this priority**: Roadmap goal “Windows loopback OAuth”; depends on DART-022 client.

**Independent Test**: Inject fake browser launcher + loopback result + mock token transport; assert authorize URL params, state validation, exchange called, tokens stored.

**Acceptance Scenarios**:

1. **Given** configured client id + redirect, **When** sign-in starts, **Then** loopback server listens on `127.0.0.1`, browser opens authorize URL with PKCE S256 + state + redirect_uri, and no `client_secret` is used.
2. **Given** callback `code` + matching `state`, **When** exchange succeeds, **Then** tokens are stored securely and session is signed-in.
3. **Given** callback `state` mismatch, **When** completing sign-in, **Then** sign-in fails, tokens are not stored, and user sees an error.
4. **Given** user cancels / timeout / Bungie `error` query param, **When** sign-in ends, **Then** session remains signed-out with a non-leaking error message.

---

### User Story 3 - Sign-out + Settings account UI (Priority: P1)

As a Windows user, I can see account status on Settings and sign out, which clears secure tokens and returns the UI to signed-out.

**Why this priority**: Roadmap exit “Sign-in/out E2E on Windows”.

**Independent Test**: Widget tests with fake session/store: Sign in success → membership shown; Sign out → tokens cleared and Sign in available.

**Acceptance Scenarios**:

1. **Given** signed-out and valid client id, **When** Settings renders, **Then** an account card shows **Sign in** (and no access/refresh token text).
2. **Given** signed-in with membership id `M123`, **When** Settings renders, **Then** membership id is shown and **Sign out** is available.
3. **Given** signed-in, **When** user taps Sign out, **Then** secure store is cleared and UI returns to signed-out.
4. **Given** missing client id, **When** Settings renders, **Then** Sign in is disabled with a configuration hint (no crash).

---

### Edge Cases

- Port already in use on loopback → clear bind error; do not hang forever.
- Double-click Sign in while busy → second start ignored or queued safely (no double token write races).
- Token JSON corrupt in secure store → treat as signed-out; allow re-auth.
- Soft guidance never auto-applies.
- No CLIENT_SECRET / `client_secret` in host sources or binaries API surface.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Host MUST expose a `TokenStore` that can save/load/clear `BungieTokens` without using SQLite plaintext for secrets.
- **FR-002**: Production Windows path MUST use platform secure storage (`flutter_secure_storage` or equivalent OS-backed store).
- **FR-003**: Host MUST run a **loopback-only** HTTP callback listener for the registered Windows `redirect_uri` during sign-in.
- **FR-004**: Host MUST open the system browser to a DART-022-built authorize URL (Public+PKCE S256 + CSRF state).
- **FR-005**: On callback, host MUST validate `state`, exchange `code` via `BungieOAuthClient.exchangeCode`, and persist tokens via `TokenStore`.
- **FR-006**: Host MUST support sign-out that clears secure tokens and updates UI.
- **FR-007**: Settings MUST show account status (signed-out / signing-in / signed-in / error) without displaying raw tokens.
- **FR-008**: Public client id and redirect URI MUST be host-injected (compile defines or constructors); **no** client secret fields.
- **FR-009**: Automated tests MUST prove sign-in/out orchestration without live Bungie and prove token strings are absent from SQLite after secure write.
- **FR-010**: Soft guidance never auto-applies.

### Key Entities

- **TokenStore**: Secure persistence port for `BungieTokens`.
- **LoopbackCallbackServer**: Binds `127.0.0.1`, captures OAuth redirect query.
- **BrowserLauncher**: Opens authorize URL (real: `url_launcher`; tests: fake).
- **WindowsOAuthSession**: Sign-in/out orchestration + session state for UI.
- **OAuth account card (Settings)**: Sign-in / sign-out chrome.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `flutter test` for `apps/windows_host` passes including new OAuth/session tests.
- **SC-002**: Tests prove tokens round-trip via `TokenStore` and are cleared on sign-out.
- **SC-003**: Tests prove access/refresh token strings do not appear in SQLite after secure write.
- **SC-004**: Tests prove loopback sign-in orchestration (mock browser + mock token exchange) ends signed-in.
- **SC-005**: Tests prove state mismatch / error callback leaves session signed-out.
- **SC-006**: Settings widget tests cover Sign in / Sign out UI states.
- **SC-007**: Grep/scan of host auth sources shows no `client_secret` / `CLIENT_SECRET` API fields.
- **SC-008**: `dart analyze` / Flutter analyze clean on touched packages; pure graph guard still passes.

## Assumptions

See A1–A8 above.
