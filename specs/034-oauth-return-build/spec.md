# Feature Specification: Default OAuth return path to /build

**Feature Branch**: `034-oauth-return-build`

**Created**: 2026-07-23

**Status**: Draft

**Input**: When login starts without a safe `returnUrl`, OAuth callback falls back to `/analyze`. Product home is `/build`. Change defaults to `/build`, keep open-redirect protection, prefer shared `DEFAULT_POST_LOGIN_PATH`, add unit tests for sanitize.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Default post-login lands on Build (Priority: P1)

A guardian signs in without an explicit return URL (or with a missing/empty `returnUrl`). After Bungie OAuth completes, they land on the Build surface (`/build`), the product primary journey, not Analyze.

**Why this priority**: Primary product home is `/build`; defaulting to a secondary surface confuses the post-login journey.

**Independent Test**: Start `/api/auth/login` with no `returnUrl` (or null); inspect sanitized session value and callback fallback; both resolve to `/build`.

**Acceptance Scenarios**:

1. **Given** a configured OAuth login request with no `returnUrl` query param, **When** login sanitizes the return path, **Then** the stored return path is `/build`.
2. **Given** a session with no `oauthReturnUrl` after a successful token exchange, **When** the callback redirects, **Then** the redirect target is `/build`.

---

### User Story 2 - Explicit safe return URLs still honored (Priority: P1)

A guardian signs in from Settings, Analyze, or another in-app surface that passes `returnUrl=/settings` or `returnUrl=/analyze`. After OAuth they return to that path.

**Why this priority**: Existing deep-link return behavior must not break.

**Independent Test**: Call sanitize with `/settings` and `/analyze`; both pass through unchanged (pathname + search).

**Acceptance Scenarios**:

1. **Given** `returnUrl=/settings`, **When** sanitize runs, **Then** result is `/settings`.
2. **Given** `returnUrl=/analyze`, **When** sanitize runs, **Then** result is `/analyze`.
3. **Given** `returnUrl=/build?tab=library`, **When** sanitize runs, **Then** pathname and search are preserved.

---

### User Story 3 - Open redirects blocked (Priority: P1)

Attacker-controlled or malformed return URLs never redirect off-origin. Unsafe inputs fall back to `/build`.

**Why this priority**: Security invariant; open redirects are unacceptable.

**Independent Test**: Unit tests for `//evil.com`, absolute external URLs, non-path inputs → `/build`.

**Acceptance Scenarios**:

1. **Given** `returnUrl=//evil.com`, **When** sanitize runs, **Then** result is `/build`.
2. **Given** `returnUrl=https://evil.com`, **When** sanitize runs, **Then** result is `/build`.
3. **Given** `returnUrl` is null or empty, **When** sanitize runs, **Then** result is `/build`.
4. **Given** a return URL whose resolved origin differs from the request origin, **When** sanitize runs, **Then** result is `/build`.

---

### Edge Cases

- Protocol-relative URLs (`//host`) are rejected.
- Absolute external URLs are rejected.
- Paths that do not start with `/` are rejected.
- Query strings on same-origin relative paths are preserved.
- Debug layout login entry may keep its own explicit return; only shared auth login/callback defaults change.
- Missing session `oauthReturnUrl` on callback uses the same default as sanitize.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST default the post-login return path to `/build` whenever `returnUrl` is missing, empty, or fails sanitization.
- **FR-002**: System MUST accept explicit same-origin relative `returnUrl` values (including `/analyze`) and restore them after OAuth.
- **FR-003**: System MUST reject open-redirect candidates: protocol-relative paths, absolute external URLs, non-path inputs, and cross-origin resolved URLs — falling back to `/build`.
- **FR-004**: Login sanitize and callback missing-session fallback MUST share one constant (e.g. `DEFAULT_POST_LOGIN_PATH = "/build"`) so defaults cannot drift.
- **FR-005**: Sanitize helper MUST be unit-testable (exported from a shared module under `src/lib/auth/` or equivalent).
- **FR-006**: Auth login and callback routes MUST use the shared sanitize/default helpers; debug layout login redirect may remain unchanged unless it duplicated the hard-coded `/analyze` default without an explicit return.

### Key Entities

- **Return path**: Same-origin relative path (+ optional query) stored as `session.oauthReturnUrl` during login and consumed on callback.
- **DEFAULT_POST_LOGIN_PATH**: Single source of truth for safe fallback (`/build`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `rg` over `src/app/api/auth` finds no default fallback string `"/analyze"` (explicit allowlist tests may still mention analyze as a valid returnUrl).
- **SC-002**: Unit tests cover null → `/build`, `/settings` → `/settings`, `//evil.com` → `/build`, `https://evil.com` → `/build`.
- **SC-003**: `npm run typecheck`, `npm run lint`, and `npm run test` pass.

## Assumptions

- Product primary home remains `/build` (`/` redirects to `/build`).
- Session cookie shape and Bungie OAuth redirect_uri registration are unchanged.
- Analyze feature remains available; only the *default* return path changes.
- No domain DBR/DAC product rule change required beyond operator-facing auth UX default (tooling/bugfix).
- Existing clients that pass `returnUrl` continue to work without client changes.
