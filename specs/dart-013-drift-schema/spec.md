# Feature Specification: DART-013 Drift Schema

**Feature Branch**: `dart-013-drift-schema`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Drift schema mirroring core tables (users, builds, variants, sets, synergies, inventory). Schema creates clean DB; PRAGMA/index notes for critical uniques."

**Program ID**: DART-013  
**Phase**: P1  
**Depends**: DART-012 (StorageRoot done)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- New workspace package (e.g. `packages/db`, pub name `destiny2_db`) with **Drift** table definitions mirroring product `src/lib/db/schema.ts` **current** column set for:
  - **users**
  - **inventory** (`inventory_items`, `inventory_sync_meta`)
  - **sets** (`sets`, `set_tags`, `set_items`)
  - **synergies** (`synergies`, `synergy_links`)
  - **builds** (`builds`, `build_tags`, `build_variants`, `build_synergy_types`)
  - **variant_set_attachments** (RESTRICT on set delete)
- Open/create path: in-memory for tests; file path helper for later hosts (uses path string only — StorageRoot path composition stays in `destiny2_storage`)
- **Schema creates clean DB** (empty → all tables present with foreign keys ON)
- **PRAGMA/index notes** (and tests) for **critical uniques** and supporting indexes that product relies on
- `schemaVersion = 1` baseline; no multi-step migration history (that is DART-014)

**Out of scope (later slices):**

- Historical ensure*/ALTER migration path and version table (DART-014)
- Repository CRUD (DART-015 / DART-016)
- Flutter Windows open-DB host (DART-019)
- Manifest entity stores (DART-017+)
- OAuth / Bungie sync writers (P2)
- WASM/OPFS (DART-043)
- Legacy import from Next `.cache/app.db` (DART-048)
- Node sidecar or CLIENT_SECRET in clients (forbidden program-wide)
- Soft guidance evaluators (domain only; soft never auto-applies)

### Assumptions

- **A1**: Target column set is the **current** product schema after all `ensure*` upgrades in `src/lib/db/client.ts` (not intermediate historical shapes). DART-014 will encode empty→current as versioned steps if needed for import.
- **A2**: `loadouts` table is included for product schema parity (present in `schema.ts`) even though compose spine primarily uses builds/sets/synergies.
- **A3**: Drift native SQLite via `package:sqlite3` is sufficient for unit tests on Windows/CI; no Flutter engine required for this package.
- **A4**: Unique index **names** may use Drift defaults when product names differ slightly; tests assert **column sets** and uniqueness behavior, and docs record product index name mapping.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean empty DB from schema (Priority: P1)

As a multiplatform data engineer, I can open an in-memory or temp-file Drift database so that all core tables exist and foreign keys are enforced, without running the Next.js/better-sqlite3 stack.

**Why this priority**: Roadmap exit — “Schema creates clean DB.”

**Independent Test**: `dart test packages/db` opens memory DB, lists tables via `sqlite_master` / Drift, asserts expected table names present.

**Acceptance Scenarios**:

1. **Given** a new `AppDatabase` on `:memory:` (or equivalent), **When** the connection is opened with schema create, **Then** tables include at least: `users`, `inventory_items`, `inventory_sync_meta`, `sets`, `set_items`, `set_tags`, `synergies`, `synergy_links`, `builds`, `build_tags`, `build_variants`, `build_synergy_types`, `variant_set_attachments`, `loadouts`.
2. **Given** foreign keys pragma ON, **When** I insert a set_item with a non-existent `set_id`, **Then** the insert fails (FK enforcement).
3. **Given** pure packages (`destiny2_domain`, `destiny2_sandbox_data`), **When** I inspect their pubspecs, **Then** they do not depend on `drift` / `sqlite3`.

---

### User Story 2 - Critical uniques and indexes (Priority: P1)

As a data engineer, I can rely on the same uniqueness and lookup indexes product SQLite uses for inventory, sets, tags, and build synergy types so later repos and import do not invent divergent constraints.

**Why this priority**: Roadmap exit — “PRAGMA/index notes for critical uniques.”

**Independent Test**: PRAGMA `index_list` / uniqueness violation tests + documented notes in package or `specs/dart-013-drift-schema/`.

**Acceptance Scenarios**:

1. **Given** a user and two inventory rows with the same `(user_id, instance_id)`, **When** the second is inserted, **Then** SQLite rejects the unique violation.
2. **Given** two sets for the same user with the same `(type, name)`, **When** the second is inserted, **Then** unique violation occurs (`sets` user+type+name).
3. **Given** documentation for this slice, **When** I read index notes, **Then** I see critical uniques listed: at least `users.bungie_membership_id`, `inventory_items(user_id, instance_id)`, `sets(user_id, type, name)`, `set_tags(set_id, tag_id)`, `build_tags(build_id, tag_id)`, `build_synergy_types(build_id, type, sub_type)`, plus inventory lookup indexes (user+hash, user+bucket, user+location) and `variant_set_attachments` set-id index / RESTRICT semantics noted.

---

### User Story 3 - Host path open helper (Priority: P2)

As a future Flutter Windows host author, I can construct `AppDatabase` from a file path string (e.g. `StorageRoot.appDbPath`) so DART-019 does not reimplement open logic.

**Why this priority**: Unblocks host skeleton without implementing the shell here.

**Independent Test**: Open temp-file DB, create schema, close, reopen; assert tables still present.

**Acceptance Scenarios**:

1. **Given** a temp file path, **When** I open `AppDatabase` on that path and close it, **Then** reopening succeeds and tables remain.
2. **Given** the package API, **When** I construct the DB, **Then** I do not need to pass Bungie secrets or network config.

---

### Edge Cases

- Empty database file: schema create succeeds (version 1).
- Concurrent multi-process writers: out of scope; single-writer product rule documented only.
- Soft guidance never auto-applies; schema has no soft-evaluator side effects.
- `variant_set_attachments.set_id` ON DELETE RESTRICT: deleting a set that is attached fails (tested if practical in this slice).
- Nullable columns match product (e.g. exotic hashes, `instance_id` on set_items, inventory `gear_tier` / `socket_plugs` / `stat_values`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST add workspace package `packages/db` (`destiny2_db`) with Drift table definitions for core tables listed in scope.
- **FR-002**: Opening a new DB MUST create all core tables without manual SQL outside Drift schema generation / create-all.
- **FR-003**: Foreign keys MUST be enabled on open (`PRAGMA foreign_keys = ON`).
- **FR-004**: Critical unique constraints MUST match product intent (see US2).
- **FR-005**: Supporting indexes for inventory (user+hash, user+bucket, user+location) and set attachments / set items SHOULD be present (product parity).
- **FR-006**: Package MUST expose in-memory factory for tests and file-path factory for hosts.
- **FR-007**: Package MUST document PRAGMA/index notes for critical uniques (spec research, data-model, or package comment/README section).
- **FR-008**: Pure packages MUST remain free of Drift/sqlite3 runtime deps (graph guard still green).
- **FR-009**: No repository CRUD APIs beyond minimal smoke inserts needed for constraint tests (full repos = DART-015/016).
- **FR-010**: No CLIENT_SECRET, no Node sidecar, no soft auto-apply behavior.

### Key Entities *(schema-level)*

- **User** — Bungie membership identity row
- **InventoryItem** / **InventorySyncMeta** — owned instances + sync metadata
- **Set** / **SetItem** / **SetTag** — library sets
- **Synergy** / **SynergyLink** — library synergies + evidence links
- **Build** / **BuildVariant** / **BuildTag** / **BuildSynergyType** — builds and variants
- **VariantSetAttachment** — variant↔set attach with RESTRICT delete on set
- **Loadout** — legacy/generator loadout rows (schema parity)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/db` passes and proves clean create + critical uniques.
- **SC-002**: Documented index/unique notes exist for the critical constraints listed in US2.
- **SC-003**: Workspace resolves `destiny2_db`; analyze includes the package; pure graph guard still passes.
- **SC-004**: Slice scope not expanded into migrations (DART-014) or repos (DART-015+).
