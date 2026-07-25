# Feature Specification: DART-014 Drift Migrations

**Feature Branch**: `dart-014-drift-migrations`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Migration strategy mirroring historical ensure* / column upgrades needed for import later. Empty→current migrate green; documented version table."

**Program ID**: DART-014  
**Phase**: P1  
**Depends**: DART-013 (Drift schema core tables done)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- **Migration strategy** for `destiny2_db` that mirrors product historical **`ensure*`** / column upgrades from `src/lib/db/client.ts` (idempotent ADD COLUMN / table create / one-shot rebuilds needed for later legacy import).
- **Documented version table** mapping Drift `schemaVersion` (and logical ensure-step IDs) to product milestones / ensure* functions.
- **Empty → current** path green: opening a new DB (`onCreate` + open hooks) yields the same current column set as DART-013 create-all.
- **Idempotent ensure upgrades** runnable on DBs that already have base tables but lack later columns (simulates partial/legacy shapes import will see).
- Tests under `packages/db` proving empty→current and at least one partial→current ensure path.
- Wire `MigrationStrategy` (`onCreate` / `onUpgrade` / `beforeOpen`) so future version bumps and DART-048 import can plug in without reinventing ensure SQL.

**Out of scope (later slices):**

- Repository CRUD (DART-015 / DART-016)
- Full legacy import UX from Next `.cache/app.db` (DART-048) — this slice only prepares the upgrade primitives
- Flutter Windows host (DART-019)
- Manifest / entities (DART-017+)
- WASM/OPFS (DART-043)
- New product columns beyond current DART-013 / product schema
- Node sidecar or CLIENT_SECRET (forbidden)
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: Drift **schemaVersion remains 1** for this slice (schema shape unchanged from DART-013). Migrations work is **strategy + ensure* port + documentation**, not a version bump. Future column changes bump `schemaVersion` and append `onUpgrade` steps.
- **A2**: Product Next.js DBs do not rely on SQLite `user_version` for ensure*; they run idempotent PRAGMA table_info checks. Dart encodes the same idempotent ensures and records them in a **documented version / step table** for operators and DART-048.
- **A3**: Full multi-step historical DB fixtures for every intermediate product release are not required; representative partial schemas (missing one or more ensure columns) are sufficient.
- **A4**: `build_synergies` → `build_synergy_types` data move and `builds` exotic_armor NOT NULL rebuild are included as ensure steps (mirroring product) even if greenfield never creates the old shapes.
- **A5**: Soft guidance never auto-applies; migrations touch schema only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Empty → current migrate green (Priority: P1)

As a multiplatform data engineer, I can open a brand-new in-memory or temp-file Drift DB and land on the **current** schema (all core tables and late-added columns) so greenfield hosts need no manual migration.

**Why this priority**: Roadmap exit — “Empty→current migrate green.”

**Independent Test**: `dart test packages/db` opens empty DB, asserts core tables + representative ensure columns (`stat_values`, `gear_tier`, `socket_plugs`, `instance_id` on set_items, `sub_type` on synergies, artifact columns, soft_stat_targets, optimizer columns, build_synergy_types).

**Acceptance Scenarios**:

1. **Given** a new `AppDatabase.memory()`, **When** the connection opens, **Then** all expected core tables exist and late columns from product ensure* are present (via create-all at current version).
2. **Given** empty→current open, **When** I read `schemaVersion` / documented current version, **Then** it is **1** (current) and foreign_keys is ON.
3. **Given** DART-013 schema tests, **When** migration code is added, **Then** existing clean-create and unique tests remain green.

---

### User Story 2 - Documented version table (Priority: P1)

As a maintainer preparing DART-048 import, I can read a single **version table** that lists Drift schemaVersion, logical ensure-step IDs, product `ensure*` source, and SQL intent so import and future bumps do not invent divergent history.

**Why this priority**: Roadmap exit — “documented version table.”

**Independent Test**: Constants or markdown table in package + spec; unit test asserts step IDs / count match documented ensure list.

**Acceptance Scenarios**:

1. **Given** package docs (`migration_version_table` or equivalent + this spec), **When** I list steps, **Then** I see entries for at least: synergy `sub_type`, inventory `stat_values` / `gear_tier` / `socket_plugs`, set_items `instance_id`, builds identity nullability / weapon / super, variant artifact columns, builds `soft_stat_targets`, sets optimizer columns, `build_synergy_types` (+ optional legacy `build_synergies` migrate).
2. **Given** the version table, **When** I read current Drift version, **Then** it is documented as **1 = post-all-ensure current create-all**.
3. **Given** pure packages, **When** I inspect deps, **Then** they still do not depend on Drift.

---

### User Story 3 - Partial / legacy-shaped DB ensure upgrades (Priority: P1)

As an import tool author (later DART-048), I can run **idempotent ensure upgrades** against a SQLite file that has base tables but is missing late columns, so the DB reaches the current column set without dropping user data.

**Why this priority**: Goal — “mirroring historical ensure* … needed for import later.”

**Independent Test**: Create minimal tables via raw SQL missing ensure columns → open through upgrade path or call `applyEnsureUpgrades` → PRAGMA table_info shows columns; re-run is no-op.

**Acceptance Scenarios**:

1. **Given** an in-memory DB with a minimal `inventory_items` (no `stat_values` / `gear_tier` / `socket_plugs`), **When** ensure upgrades run, **Then** those columns exist and are nullable.
2. **Given** a DB already at current shape, **When** ensure upgrades run again, **Then** no error (idempotent).
3. **Given** ensure upgrades, **When** applied, **Then** they do not require CLIENT_SECRET or network.

---

### Edge Cases

- Table missing entirely: ensure that targets a missing table should no-op or only create when product would (e.g. `build_synergy_types` CREATE IF NOT EXISTS style).
- `builds.exotic_armor_hash` historically NOT NULL: rebuild path only when PRAGMA shows notnull=1.
- Concurrent writers: out of scope; single-writer product rule unchanged.
- Soft never auto-applies; migrations do not evaluate soft guidance.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST document a **version table** (code constants + spec/data-model) mapping Drift schemaVersion 1 and logical ensure-step IDs to product `ensure*` sources.
- **FR-002**: Opening an empty DB MUST migrate/create to **current** schema; tests MUST pass (empty→current green).
- **FR-003**: Package MUST implement idempotent ensure upgrades mirroring product `ensure*` column/table upgrades needed for later import.
- **FR-004**: `AppDatabase.migration` MUST use a clear `MigrationStrategy` (`onCreate` create-all; `onUpgrade` ready for future bumps; `beforeOpen` FK ON + ensure upgrades when appropriate).
- **FR-005**: Re-running ensure upgrades on a current DB MUST be safe (idempotent).
- **FR-006**: Pure packages MUST remain free of Drift/sqlite3.
- **FR-007**: No Node sidecar; no CLIENT_SECRET in clients.
- **FR-008**: Soft guidance never auto-applies via migrations.
- **FR-009**: This slice MUST NOT implement repository CRUD or full legacy import UI.

### Key Entities

- **MigrationVersionTable**: catalog of schemaVersion + ensure step IDs.
- **EnsureUpgradeStep**: named idempotent schema fix (ADD COLUMN / CREATE TABLE / rebuild).
- **AppDatabase**: Drift database applying strategy on open.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/db` passes including empty→current and partial ensure cases.
- **SC-002**: Version table documents Drift v1 current + all product ensure* steps listed in scope.
- **SC-003**: No pure-package Drift dependency; P0 graph guard still green if run.
- **SC-004**: Specs live under `specs/dart-014-drift-migrations/`; branch merges to `feature/multiplatform-dart` only.
