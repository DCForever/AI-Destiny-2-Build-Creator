# Feature Specification: DART-048 Legacy DB Import

**Feature Branch**: `dart-048-legacy-db-import`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Import tool/UX from Next `.cache/app.db` → platform StorageRoot. One documented migration path; dry-run + apply."

**Program ID**: DART-048  
**Phase**: P5  
**Depends**: DART-014 (Drift ensure* migrations), DART-043 (OPFS / platform StorageRoot context)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (D-IO pure Dart; app-support StorageRoot not repo `.cache`)

## Scope boundary

**In scope:**

- **One documented migration path** from legacy Next.js SQLite (`.cache/app.db`) into multiplatform **StorageRoot** `app.db`
- Pure Dart **dry-run** that opens a source SQLite file read-only, validates it looks like product `app.db`, reports table row counts and apply readiness
- Pure Dart **apply** that backups any existing target, copies source → `StorageRoot.appDbPath`, opens target so DART-014 ensure* upgrades heal schema, then closes
- Windows Settings **UX** card: source path, Dry-run, Apply (with confirm), report display
- Repo docs under `docs/multiplatform-dart-legacy-db-import.md` + optional CLI under `tool/`
- Unit tests for dry-run + apply on temp fixture DBs

**Out of scope (later / deferred):**

- Merge/diff import that preserves newer target rows (this slice is **replace** of `app.db`)
- Full entity-cache / raw-manifest tree migration UX (optional note only; users re-refresh manifest on Windows)
- Live Bungie token / secure-store migration (tokens never lived in `app.db` for Dart shells; Next session cookies not imported)
- Jaspr web OPFS file-picker import UI (desktop/Windows is primary; pure API is IO-native)
- Node sidecar / product Next route changes / CLIENT_SECRET

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dry-run validates legacy app.db (Priority: P1)

As a user migrating from the Next local app, I point at my `.cache/app.db` and run **Dry-run**. I see whether the file is a valid product DB, row counts for core tables, destination path under StorageRoot, and whether Apply is allowed.

**Why this priority**: Exit criteria — dry-run must exist and be trustworthy before any write.

**Independent Test**: Build a minimal fixture SQLite with `users` + `builds`; dry-run returns `canApply: true` and counts; corrupt/missing file returns blocking errors.

**Acceptance Scenarios**:

1. **Given** a valid product-shaped SQLite at a source path, **When** dry-run runs against a StorageRoot target path, **Then** the plan lists present core tables, non-negative row counts, target path, and `canApply` is true when required tables exist.
2. **Given** a missing or non-SQLite file, **When** dry-run runs, **Then** `canApply` is false and errors explain the failure.
3. **Given** a SQLite file missing all library tables, **When** dry-run runs, **Then** `canApply` is false (not treated as a product DB).

---

### User Story 2 - Apply imports into StorageRoot (Priority: P1)

As a user who accepted a successful dry-run, I run **Apply**. The tool backs up any existing target `app.db`, copies the source into StorageRoot, and heals schema via ensure* so the multiplatform host can open it.

**Why this priority**: Exit criteria — apply must materialize the migration path.

**Independent Test**: Dry-run then apply on temp dirs; target file exists; opens with `AppDatabase.file`; core tables readable; backup created when target pre-existed.

**Acceptance Scenarios**:

1. **Given** a successful dry-run plan and empty target directory, **When** apply runs, **Then** target `app.db` exists and opens with core tables present.
2. **Given** an existing target `app.db`, **When** apply runs, **Then** a timestamped backup is written beside the target and the target is replaced by the source content (post ensure*).
3. **Given** dry-run would fail (`canApply` false), **When** apply is invoked, **Then** no target write occurs and an error is raised.

---

### User Story 3 - Windows Settings import card (Priority: P2)

As a Windows host user, I use Settings → **Legacy DB import** to paste/type the path to Next `.cache/app.db`, dry-run, and apply with an explicit confirm that existing platform data will be replaced and a restart is recommended.

**Why this priority**: UX on the primary desktop shell; pure tool still usable without UI.

**Independent Test**: Widget test: card renders; dry-run with injectable importer shows summary; apply disabled until successful dry-run; confirm path required for apply.

**Acceptance Scenarios**:

1. **Given** Settings open, **When** the import card renders, **Then** source field, Dry-run, and Apply controls are visible; Apply is disabled until a successful dry-run for the current source path.
2. **Given** a successful dry-run, **When** Apply is pressed, **Then** a confirm step is required before the importer apply runs.
3. **Given** apply succeeds, **When** the card updates, **Then** status indicates success and that the app should be restarted to bind the new DB connection.

---

### Edge Cases

- Source equals target path → dry-run may allow report but apply is no-op or blocked with warning (do not backup-overwrite self).
- Target open by host → apply may fail with file lock; message tells user to close other writers / restart after staged failure.
- Partial legacy schema (missing late columns) → apply still succeeds because ensure* heals on open.
- Soft guidance / hard DBR rules are unchanged by import (data only).
- No CLIENT_SECRET involved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a pure-Dart dry-run API that accepts a source file path and a target `app.db` path (StorageRoot).
- **FR-002**: Dry-run MUST open the source read-only, detect SQLite/product shape via core table presence, and return row counts for known core tables.
- **FR-003**: Dry-run MUST set `canApply` false when source is missing, unreadable, not SQLite, or lacks minimum product tables (`users` plus at least one of `builds` / `sets` / `synergies` / `inventory_items`).
- **FR-004**: System MUST provide an apply API that refuses when dry-run would fail; on success MUST write target under StorageRoot layout.
- **FR-005**: Apply MUST backup an existing target file to a sibling `app.db.bak-<timestamp>` before replace.
- **FR-006**: Apply MUST open the written target with the multiplatform opener path so DART-014 ensure* upgrades run at least once, then close.
- **FR-007**: Windows Settings MUST expose source path + Dry-run + Apply (confirm) UX wired to the pure API.
- **FR-008**: Docs MUST describe the single migration path (Next `.cache/app.db` → StorageRoot `app.db`) including dry-run, apply, backup, and restart guidance.
- **FR-009**: Tests MUST cover dry-run success/failure and apply with backup on temp files (no live Bungie; pure Dart I/O only).

### Key Entities

- **LegacyDbImportPlan**: dry-run result (paths, counts, warnings, errors, canApply).
- **LegacyDbImportResult**: apply result (target path, backup path, post-open table counts).
- **LegacyDbImporter**: pure I/O service (native/VM).
- **StorageRoot.appDbPath**: canonical destination (not repo `.cache`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Documented migration path exists in-repo and matches the implemented API.
- **SC-002**: Dry-run + apply green on automated tests with fixture DBs.
- **SC-003**: Windows Settings card can dry-run and apply via injectable importer in widget tests.
- **SC-004**: Soft guidance never auto-applies (import does not touch soft evaluators); hard DBR unchanged.

## Assumptions

- Schema parity: Drift tables mirror product `src/lib/db`; file copy + ensure* is sufficient (no row-level transform).
- Primary host for import UX is **Flutter Windows**; web OPFS picker is deferred.
- Import mode is **full replace** of `app.db`, not merge.
- Entity/manifest caches are **not** required for this slice; user can re-refresh manifest on Windows after import.
- OAuth tokens are not in `app.db`; user re-signs in on multiplatform shells (Public+PKCE).
