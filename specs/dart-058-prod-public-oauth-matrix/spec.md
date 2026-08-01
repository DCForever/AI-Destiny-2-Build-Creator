# Feature Specification: DART-058 Prod Public OAuth Matrix

**Feature Branch**: `dart-058-prod-public-oauth-matrix`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Prod Public redirects for all shells; no secrets in clients. GAP-AUTH-01; RB-03 / RC-AUTH."

**Program ID**: DART-058  
**Phase**: P8  
**Depends**: DART-023 (Windows OAuth), DART-045 (Jaspr OAuth), DART-022 (Public+PKCE core)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (D-WEB-AUTH, D-BUNGIE hybrid Public+PKCE; no CLIENT_SECRET)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-AUTH-01**  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RB-03** / **RC-AUTH**

## Scope boundary

**In scope:**

- Published **Bungie Public app redirect matrix** (canonical doc + pure Dart source of truth) covering:
  - **Windows** HTTPS loopback `https://127.0.0.1:8765/callback`
  - **Jaspr** production origin callback `{origin}/auth/callback` (path fixed `/auth/callback`)
  - **Mobile** Android + iOS custom schemes (registered strings for Bungie portal)
- Align Windows host default redirect to **HTTPS** loopback (matches README / run script / loopback TLS)
- Host surfaces (Settings account cards / config) show the active matrix redirect for operator registration
- **Secret scan** gate: source (and documented binary guidance) shows zero `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` assignment or `fromEnvironment` in Flutter/Jaspr client packages and hosts
- **Live sign-in smoke procedure** for cutover-required shells (Windows + Jaspr) with automated preflight (authorize URL + redirect matrix + no-secret) and operator live smoke checklist
- Close **GAP-AUTH-01**; clear **RB-03**; set **RC-AUTH** to **PASS** with evidence pointers
- Soft never auto-applies; no Node sidecar; Confidential Next secrets stay server-only

**Out of scope (do not implement in this slice):**

- Full mobile OAuth session host (sign-in UI on phone) — matrix schemes are published for portal registration; mobile product OAuth remains deferred beyond scheme publish
- Entity bundle CDN / dual-run ops / PRODUCTION_CUTOVER GO (DART-059–061)
- Confidential cookie parity / embedding secrets in clients (forbidden)
- Changing Bungie Confidential Next redirect (`:3000/api/auth/callback`)
- Multi-app Bungie split (still one Public app + multi-redirect matrix per D-BUNGIE)

## Assumptions

- **A1**: Cutover-required OAuth shells are **Windows Flutter** and **Jaspr web**. Mobile schemes are published for portal + future host work; mobile live sign-in smoke is **N/A** until a mobile OAuth session ships (does not block RC-AUTH).
- **A2**: Production Public app uses **one** Bungie Public application with multiple redirect URIs (D-BUNGIE). Exact portal app display name is operator-owned; matrix documents the **redirect strings** and recommended app label `Destiny2BuildCreator-Public`.
- **A3**: Jaspr production origin is operator-configured (e.g. `https://buildcreator.example`). Matrix documents path `/auth/callback` and a **placeholder origin** plus override via `BUNGIE_REDIRECT_URI` / runtime origin.
- **A4**: Windows production default is **HTTPS** loopback with packaged self-signed certs (`certs/loopback-*.pem`). First browser visit may warn; documented.
- **A5**: Mobile schemes: `d2buildcreator://oauth/callback` for both Android and iOS (single scheme string simplifies portal registration). Package id / associated domains can refine later without changing the published OAuth redirect string if the scheme stays.
- **A6**: "Live sign-in smoke" for CI means: automated matrix + PKCE authorize/token contract tests (no secret) + documented operator checklist. Operator marks live PASS on Windows + Jaspr when credentials available; automated evidence is required to clear RB-03 in-repo.
- **A7**: Soft guidance never auto-applies; this slice has no domain save path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Published redirect matrix (Priority: P1)

As an operator registering the Bungie Public app for production, I have a single published matrix of exact `redirect_uri` values for Windows HTTPS loopback, Jaspr `/auth/callback`, and mobile schemes — matching pure Dart constants used by hosts.

**Why this priority**: GAP-AUTH-01 / RB-03 core deliverable.

**Independent Test**: Unit tests assert matrix URIs; doc contains the same strings; Windows default resolves to HTTPS loopback.

**Acceptance Scenarios**:

1. **Given** the prod Public matrix source, **When** platforms are listed, **Then** windows, web, android, and ios each have a non-empty redirect URI.
2. **Given** Windows entry, **When** resolved, **Then** it is exactly `https://127.0.0.1:8765/callback` (HTTPS).
3. **Given** web entry, **When** built with origin `https://app.example`, **Then** redirect is `https://app.example/auth/callback`.
4. **Given** the ops doc, **When** compared to Dart constants, **Then** strings match (or doc embeds the matrix table from the same source of truth).

---

### User Story 2 - No confidential secrets in clients (Priority: P1)

As a cutover reviewer, I can run a scan of Dart client packages/hosts proving zero `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` / `client_secret` field assignment or secret `fromEnvironment` in client artifacts.

**Why this priority**: RC-AUTH + RC-SECRETS hard non-regression.

**Independent Test**: `dart run tool/client_secret_scan.dart` (or package test) exit 0; unit tests for forbidden patterns.

**Acceptance Scenarios**:

1. **Given** packages `bungie`, `app`, `domain`, `db`, `manifest`, `storage` and hosts `windows_host`, `web_host`, `mobile_host` lib trees, **When** secret scan runs, **Then** no forbidden secret assignment / env keys are found.
2. **Given** OAuth authorize/token builders, **When** exercised, **Then** request bodies/URLs never include `client_secret`.

---

### User Story 3 - Sign-in smoke on cutover shells (Priority: P1)

As a cutover operator, I can follow a written smoke path on Windows and Jaspr: config shows matrix redirect → Sign in → Public+PKCE completes (or mock preflight in CI) with no CLIENT_SECRET.

**Why this priority**: Exit criteria require live sign-in smoke on each cutover-required shell.

**Independent Test**: Host OAuth session tests (existing mocked E2E) + matrix preflight tests + smoke doc markers.

**Acceptance Scenarios**:

1. **Given** Windows host with Public client id + HTTPS loopback redirect, **When** mocked sign-in runs, **Then** authorize URL includes matrix redirect and omits client_secret; tokens store outside SQLite.
2. **Given** Jaspr host with origin callback, **When** mocked sign-in / callback path runs, **Then** redirect is `{origin}/auth/callback` and no secret is used.
3. **Given** smoke checklist doc, **When** validated, **Then** it lists Windows + Jaspr steps and points at matrix + secret scan evidence.

---

### Edge Cases

- Empty client id → Sign in disabled; matrix redirect still displayed for registration
- Override `BUNGIE_REDIRECT_URI` wins over default matrix entry for that process
- HTTP loopback override still bindable for emergency debug but is **not** the published prod matrix default
- Mobile schemes registered but host has no OAuth session yet → Settings notes deferred sign-in; does not claim mobile live smoke PASS
- Next Confidential redirect must never appear as a Dart host default

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST publish a prod Public OAuth redirect matrix covering Windows, web, Android, and iOS with exact URI strings.
- **FR-002**: Windows default redirect MUST be `https://127.0.0.1:8765/callback`.
- **FR-003**: Web callback path MUST remain `/auth/callback` under the production HTTPS origin.
- **FR-004**: Mobile matrix entries MUST document custom-scheme redirects for Android and iOS suitable for Bungie portal registration.
- **FR-005**: Client packages and Flutter/Jaspr hosts MUST NOT accept, assign, or `fromEnvironment` load `BUNGIE_CLIENT_SECRET` or `SESSION_SECRET`.
- **FR-006**: OAuth token exchange MUST remain Public+PKCE only (no `client_secret` in form body).
- **FR-007**: Docs MUST include operator registration steps + live smoke checklist for Windows and Jaspr.
- **FR-008**: Cutover checklist MUST clear RB-03 and set RC-AUTH PASS with evidence when exit criteria are met.
- **FR-009**: Soft guidance MUST never auto-apply (non-regression; no soft write path in this slice).

### Key Entities

- **ProdPublicOAuthMatrix**: Platform → redirect_uri (+ notes: scheme, cutover-required, smoke applicability)
- **OAuthRedirectPlatform**: windows | android | ios | web (existing)
- **SecretScanFinding**: file path + matched pattern (empty = PASS)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Matrix unit tests pass for all four platforms; Windows URI is HTTPS loopback exact match.
- **SC-002**: Client secret scan tool/tests exit green on package+host lib trees.
- **SC-003**: Windows + Jaspr OAuth session tests remain green (mocked smoke preflight).
- **SC-004**: GAP-AUTH-01 closed; RB-03 cleared; RC-AUTH **PASS** in cutover checklist with dated evidence.
- **SC-005**: Roadmap DART-058 status **done**; Current pointer advances to DART-059.

## Assumptions (defaults for NEEDS CLARIFICATION)

See Assumptions A1–A7 above. No open NEEDS CLARIFICATION retained.
