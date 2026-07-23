# Feature Specification: Production SQLite Singleton

**Feature Branch**: `032-prod-sqlite-singleton`  
**Created**: 2026-07-23  
**Status**: Draft  
**Input**: Improve prompt `specs/data-layer/improve/001-prod-sqlite-singleton.md`

## Summary

The local app database must use **one** native SQLite connection per Node process in every environment (development, production/`next start`, and test runners when they intentionally use the app path). Today only development caches the handle; production opens a new connection on every `getDb()` call, risking file-descriptor growth, `SQLITE_BUSY`, and inconsistent writers against the single local DB file. Test helpers that create isolated in-memory databases must remain independent of that process singleton.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Production process reuses one DB handle (Priority: P1)

As a developer/operator running the app with production `NODE_ENV` (`next start` or equivalent), I need every request/path that obtains the app database to share a single native SQLite connection so the process does not leak handles or fight itself for the same file.

**Why this priority**: This is the production bug; without it, long-running servers accumulate connections and risk busy/lock errors on the product’s single local DB.

**Independent Test**: With `NODE_ENV` set to a non-development value, two sequential app-database acquisitions share the same underlying native handle (or open-once is proven). Existing typecheck/lint/test gates still pass.

**Acceptance Scenarios**:

1. **Given** the Node process has not yet opened the app DB, **When** the app database is obtained twice in sequence under non-development `NODE_ENV`, **Then** both acquisitions use the same native SQLite handle.
2. **Given** the process singleton is already open, **When** further app-database acquisitions occur, **Then** no additional file-backed app DB open is performed for that process.

---

### User Story 2 - Test isolation stays intact (Priority: P1)

As a developer running unit/integration tests, I need `createTestDb` / `createTestSqlite` (or equivalents) to keep using isolated `:memory:` databases that do not share or corrupt the process file singleton.

**Why this priority**: A singleton fix that couples tests to the on-disk app DB would break the suite and risk destroying developer data.

**Independent Test**: Existing schema/repository tests that use test helpers still pass; a focused check confirms test helpers do not return the process app-file singleton.

**Acceptance Scenarios**:

1. **Given** the process app singleton may or may not already exist, **When** a test helper creates a test database, **Then** that database is an isolated in-memory instance, not the app file singleton.
2. **Given** migrations run for test helpers, **When** the process migration flag / singleton state is involved, **Then** test setup still applies schema correctly without permanently breaking the app singleton path.

---

### User Story 3 - Operators understand process model limits (Priority: P2)

As a maintainer, I need a short, durable code comment stating that multi-worker / Edge deployments against one SQLite file remain unsupported, aligned with the product’s local-first single-process model.

**Why this priority**: Prevents “fix” attempts that scale workers against one file without understanding the constraint.

**Independent Test**: Source review shows the comment near the singleton open/cache path.

**Acceptance Scenarios**:

1. **Given** a reader inspects the DB client module, **When** they look at the singleton acquisition path, **Then** they see an explicit note that multi-worker/Edge against one file is unsupported.

---

### Edge Cases

- Hot reload in development must not open unbounded handles (retain global cache pattern).
- `runMigrations` must still run effectively once per process against the singleton (no schema content change required).
- Changing `NODE_ENV` mid-process in tests for singleton proof must restore prior env and not leave the suite poisoned.
- Future need to reset the singleton in integration tests should prefer a test-only reset helper rather than parallel file handles (out of scope unless required for the acceptance test).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App database acquisition MUST cache and reuse one native SQLite connection for the Node process across **all** `NODE_ENV` values used by the Next server (not only `"development"`).
- **FR-002**: Opening the app database MUST continue to apply WAL journal mode and foreign keys, and MUST continue to use the existing app DB path under `.cache/`.
- **FR-003**: Schema migrations MUST still run once per process against that singleton (existing once-per-process guard may remain or be tied to the singleton).
- **FR-004**: Test database helpers MUST continue to create **isolated** `:memory:` databases and MUST NOT share the production/dev file singleton.
- **FR-005**: Schema SQL content and domain repository public APIs MUST remain unchanged except as required to support the singleton.
- **FR-006**: The singleton acquisition path MUST document that multi-worker / Edge against one file remains unsupported (local-first single-process constraint).
- **FR-007**: Automated verification MUST include a unit or smoke test proving two sequential app-database acquisitions under a non-development `NODE_ENV` simulation share the same underlying sqlite handle (or that the app path open runs once per process).

### Key Entities

- **Process SQLite singleton**: The single native connection bound to the on-disk app database for the lifetime of the Node process.
- **Test in-memory database**: Ephemeral SQLite instance used only by tests; never the process file singleton.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Under a non-development environment simulation, two sequential app DB acquisitions share one native handle (automated test green).
- **SC-002**: `npm run typecheck`, `npm run lint`, and `npm run test` exit 0.
- **SC-003**: Static review confirms there is no unconditional production-only open that bypasses caching (`return openDatabase` without cache).
- **SC-004**: Existing tests that rely on isolated test DBs remain green without pointing at the on-disk app DB.

## Assumptions

- Single Node process local-first model remains the product constraint; multi-instance SQLite is out of scope.
- Exporting `resetAppSqliteForTests()` is optional for this slice if the acceptance test can prove reuse without a permanent public reset API; prefer minimal surface area.
- No domain business-rule doc updates are required (tooling/reliability fix, no product semantics change).
- Drizzle wrapper instances may be created per `getDb()` call; the requirement is native handle reuse, not necessarily drizzle object identity.

## Out of Scope

- Moving migrations to drizzle-kit
- Multi-tenant or remote Postgres
- Changing WAL/journal settings beyond keeping current pragmas
- Refactoring repositories
