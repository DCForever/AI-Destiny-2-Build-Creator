# Research: Production SQLite Singleton

## Decision 1: Always cache on `global.__d2bcSqlite`

**Decision**: Remove the `NODE_ENV === "development"` guard. Always lazy-init and return `global.__d2bcSqlite`.

**Rationale**: Development already uses this pattern for HMR safety. Production (`next start`) has the same single-process model and currently leaks a handle per `getDb()`. One code path reduces branch risk.

**Alternatives considered**:
- Module-level `let sqlite` only — fails under Next HMR (module re-eval opens another handle while old global lives).
- Separate production vs dev globals — unnecessary duplication.
- Connection pool — overkill for single-writer local SQLite; product forbids multi-worker file sharing.

## Decision 2: Prove reuse via exported test-only peek / handle identity

**Decision**: Export a minimal `getSqliteForTests()` (or assert via `global.__d2bcSqlite` after two `getDb()` calls) so the test can compare native handle identity under `NODE_ENV=production`. Prefer comparing `global.__d2bcSqlite` reference stability and/or exporting `getUnderlyingSqlite(db)` only if needed.

**Rationale**: Drizzle wrappers are new objects each `getDb()`; requirement is native handle reuse. Using the existing global is enough if tests set/clear it carefully. Export `resetAppSqliteForTests()` only if cleanup requires closing the handle after pointing tests at a temp path.

**Alternatives considered**:
- Mock `Database` constructor call count — brittle with ESM/CJS interop of better-sqlite3.
- Only static `rg` check — insufficient per acceptance criteria FR-007.

## Decision 3: Avoid opening real `.cache/app.db` in the singleton unit test when possible

**Decision**: For the reuse test, either (a) temporarily point app path via env if supported, or (b) pre-seed `global.__d2bcSqlite` with an in-memory Database and verify `getDb()` twice does not replace it / returns drizzle over the same handle. Prefer (b) if `getSqlite` only opens when global is empty — then production NODE_ENV path still exercises cache hit without touching disk. Also add a path that calls real open once if needed, using a temp directory override if `appDbPath` is env-driven.

**Rationale**: Tests must not corrupt developer app DB. Inspect `appDbPath()` for override hooks; if none, cache-hit test with pre-seeded global + isolation test for createTestDb is sufficient combined with code review that open only happens inside uncached branch.

**Alternatives considered**: Open real app path and close after — risky on shared workstations.

## Decision 4: No domain doc updates

**Decision**: Skip `specs/domain-*.md` / `business-rules.md` edits.

**Rationale**: Reliability/tooling fix; no user-visible product rule change.
