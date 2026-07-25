# Feature Specification: DART-043 Jaspr OPFS SQLite

**Feature Branch**: `dart-043-jaspr-opfs-sqlite`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Drift WASM + OPFS + single-tab writer lock UX. Second tab read-only or blocked; documented limits."

**Program ID**: DART-043  
**Phase**: P5  
**Depends**: DART-042 (Jaspr skeleton), DART-014 (Drift migrations)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) — **D-WEB-DB (1a)**

## Scope boundary

**In scope:**

- Open the shared Drift `AppDatabase` schema on **Jaspr web** via **sqlite3 WASM + OPFS** (Drift `WasmDatabase.open`), falling back per browser support (IndexedDB / in-memory) with status surfaced to UX
- **Single-tab writer** policy at the app layer: first tab acquires exclusive writer role; additional tabs are **blocked** (or read-only if later enabled) with clear Settings UX
- Wire Settings page to show local DB status: role (writer / blocked), chosen storage implementation, missing features when relevant
- Make `destiny2_db` importable from web (conditional native open; no unconditional `dart:io` / `drift/native` in shared DB definition)
- Ship/download **`sqlite3.wasm`** + **`drift_worker.js`** into `apps/web_host/web/` (or documented fetch script)
- Document OPFS / multi-tab / COOP-COEP / private-mode **limits**
- Automated tests for writer-lock state machine and Settings DB status copy (no live multi-browser E2E required)

**Out of scope (later slices):**

- Prebuilt entity bundles / catalog on web (DART-044)
- Browser Public+PKCE OAuth (DART-045)
- Compose spine UI (DART-046)
- Equip / DIM on web (DART-047)
- Legacy `app.db` import (DART-048)
- Multi-worker Edge / multi-writer cloud SQLite (explicit non-goal)
- Node sidecar, `CLIENT_SECRET` in clients
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: **Second-tab policy default = blocked** (no write session; no second writer connection). UX must state that another tab holds the writer. Read-only multi-tab DB open is deferred unless storage implementation is proven safe in-slice; exit criteria allows either read-only **or** blocked.
- **A2**: Writer election uses an injectable **tab lock backend** (memory for tests; browser storage/locks on web) so VM unit tests do not need OPFS.
- **A3**: Real `WasmDatabase.open` runs only in the browser client path; unit tests inject a fake opener that records open/skip.
- **A4**: Database name is a stable identifier (e.g. `destiny2_app_db`); not repo `.cache`.
- **A5**: COOP/COEP headers are **documented as recommended** for best OPFS path (`opfsLocks`); not mandatory for slice exit — Drift may fall back.
- **A6**: `apps/web_host` remains outside root pub workspace (Jaspr/Flutter meta pin); path-depends on `destiny2_db` + `destiny2_ui_tokens`.
- **A7**: Soft guidance never auto-applies; no OAuth in this slice.
- **A8**: Pure Dart I/O only; no Next.js runtime dependency; no `CLIENT_SECRET`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Web host opens Drift via WASM/OPFS (Priority: P1)

As a user on a modern browser, the Jaspr web host opens the same Drift schema as desktop (migrations/ensure* on open) using sqlite WASM with OPFS when available.

**Why this priority**: Roadmap exit — “Drift WASM + OPFS”; D-WEB-DB 1a.

**Independent Test**: Bootstrap (with fake or real opener) reports success for writer role; unit test proves `AppDatabase` can be constructed from an injected executor; docs list asset prerequisites.

**Acceptance Scenarios**:

1. **Given** the writer tab, **When** bootstrap completes successfully, **Then** Settings shows a non-error DB status including a storage implementation label (e.g. OPFS / IndexedDB / in-memory).
2. **Given** `destiny2_db`, **When** compiled for web entry imports, **Then** shared schema code does not unconditionally import `dart:io` / `package:drift/native.dart`.
3. **Given** `apps/web_host/web/`, **When** assets are prepared, **Then** `sqlite3.wasm` and `drift_worker.js` are present or fetchable via documented script.

---

### User Story 2 - Second tab blocked or read-only (Priority: P1)

As a user who opens a second browser tab, I am not given a second writer connection. The second tab is blocked (default) with clear UX, preserving single-writer local-first semantics.

**Why this priority**: Roadmap exit — “Second tab read-only or blocked”; D-WEB-DB single-tab writer.

**Independent Test**: Coordinator unit tests: first session → writer; second concurrent session → blocked; release writer → next acquire succeeds.

**Acceptance Scenarios**:

1. **Given** tab A holds the writer lock, **When** tab B tries to acquire, **Then** tab B role is `blocked` (not writer).
2. **Given** tab B is blocked, **When** Settings renders, **Then** visible copy explains another tab holds the database writer and that writes are unavailable here.
3. **Given** tab A releases the lock (close/unload), **When** tab B retries or re-acquires, **Then** tab B can become writer.

---

### User Story 3 - Documented OPFS / multi-tab limits (Priority: P1)

As a developer or power user, documented limits explain OPFS, fallbacks, COOP/COEP, private browsing, and the single-writer policy.

**Why this priority**: Roadmap exit — “documented limits.”

**Independent Test**: Docs exist under `docs/` and/or `apps/web_host/README.md` + feature quickstart; checklist item verifies key sections.

**Acceptance Scenarios**:

1. **Given** docs, **When** read, **Then** they state single-tab writer policy and second-tab blocked behavior.
2. **Given** docs, **When** read, **Then** they note Drift storage strategies (OPFS preferred, IndexedDB/in-memory fallbacks) and optional COOP/COEP headers.
3. **Given** docs, **When** read, **Then** they note private-mode / Safari / Android Chrome multi-tab caveats at a high level.

---

### Edge Cases

- Private browsing: may fall back to IndexedDB or in-memory — status must not crash the shell.
- Lock backend unavailable: treat as degraded; prefer failing closed (no dual writers) over silent multi-writer.
- Stale writer heartbeat after crash: lock must expire so a new tab can become writer.
- Soft guidance never auto-applies.
- OAuth / entity bundles still absent.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Writer tab MUST open Drift via WASM path (`WasmDatabase.open` or equivalent) using shared `AppDatabase` schema/migrations.
- **FR-002**: System MUST enforce single-tab writer at app layer (exclusive lock); second concurrent tab MUST NOT obtain writer role.
- **FR-003**: Second tab MUST present blocked (or read-only) UX on Settings with clear explanation.
- **FR-004**: Settings MUST surface DB session role and chosen storage / error summary when open is attempted.
- **FR-005**: `destiny2_db` MUST support web compilation of schema (conditional native openers).
- **FR-006**: Host MUST NOT embed `CLIENT_SECRET` or depend on Next.js / Node sidecar for DB.
- **FR-007**: Limits MUST be documented (OPFS, multi-tab, headers, fallbacks).
- **FR-008**: Automated tests MUST cover tab-writer coordinator (writer vs blocked) and Settings status copy for blocked/writer states.
- **FR-009**: Soft guidance never auto-applies.

### Key Entities

- **WebDbRole**: `writer` | `blocked` (slice default; read-only reserved for future).
- **WebDbSessionStatus**: role, storageImplementation label, missingFeatures, error message, ready flag.
- **TabWriterLock / Coordinator**: exclusive cross-tab (or simulated) writer election.
- **WebDatabaseBootstrap**: acquire role → open DB only for writer → emit status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Coordinator unit tests pass: second concurrent acquire is not writer.
- **SC-002**: Settings component tests show blocked and writer status copy.
- **SC-003**: `dart test` in `apps/web_host` (and `packages/db` if touched) is green on VM.
- **SC-004**: Documented limits present; wasm worker assets scripted or shipped under `web/`.
- **SC-005**: No CLIENT_SECRET; no Next runtime dependency for DB.

## Assumptions

See A1–A8 above. Defaults chosen to match D-WEB-DB without NEEDS CLARIFICATION.
