---
status: DONE
priority: P1
effort: S
risk: MED
category: bug
depends: []
planned_at: 799a9d6
issue: ""
---

# Cache one SQLite handle for the whole Node process

## Objective

Under `next start` (production `NODE_ENV`), every `getDb()` call opens a **new** better-sqlite3 connection and never closes it. Development already caches on `global.__d2bcSqlite`. Multiple handles against `.cache/app.db` risk file-descriptor growth, `SQLITE_BUSY`, and inconsistent writers on the product’s single local DB. After this lands, all environments reuse one native connection per process (with an explicit test reset path), matching the documented single-process local-first model.

## Current context

- `src/lib/db/client.ts` — SQLite open, migrations, `getDb` / test helpers.
- Product constraint (README / PRODUCT.md): local-first single-process SQLite at `.cache/app.db`; not multi-worker serverless.
- Exemplar of intentional transaction use: `src/lib/db/repositories/inventoryRepository.ts:14` (`db.transaction(...)`).
- Verification commands: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`, `npm run gate`.

Current production branch opens a new DB every call:

```ts
// src/lib/db/client.ts:25-33
function getSqlite(): Database.Database {
  if (process.env.NODE_ENV === "development") {
    if (!global.__d2bcSqlite) {
      global.__d2bcSqlite = openDatabase();
    }
    return global.__d2bcSqlite;
  }
  return openDatabase();
}
```

```ts
// src/lib/db/client.ts:363-367
export function getDb(): AppDatabase {
  const sqlite = getSqlite();
  runMigrations(sqlite);
  return drizzle(sqlite, { schema });
}
```

Test helpers already reset migration state carefully (`createTestDb` / `createTestSqlite` at lines 369–388) and must keep working with isolated in-memory DBs.

## Detailed instructions

### Requirements

- R1: `getSqlite()` (or equivalent) caches the native better-sqlite3 Database on `globalThis` (or the existing `global.__d2bcSqlite`) in **all** `NODE_ENV` values used by the Next server, not only `"development"`.
- R2: Opening still applies WAL + foreign_keys; path remains `appDbPath()` under `.cache/`.
- R3: `runMigrations` still runs once per process against that singleton (existing `migrated` flag may stay or be tied to the singleton).
- R4: `createTestDb` and `createTestSqlite` continue to use **isolated** `:memory:` databases and must not share the production/dev file singleton.
- R5: No change to schema SQL content or domain repositories’ public APIs beyond what is required for the singleton.
- R6: Document in a short code comment that multi-worker / Edge against one file remains unsupported (align with PRODUCT local-first constraint).

### Acceptance criteria

- [ ] `npm run typecheck` exits 0
- [ ] `npm run test` exits 0 (including any new/adjusted `client` / schema tests)
- [ ] A unit or smoke test proves two sequential `getDb()` calls in a non-development NODE_ENV simulation share the same underlying sqlite handle (or that `openDatabase` is invoked once per process for the app path)
- [ ] `rg -n "return openDatabase" src/lib/db/client.ts` does not show an unconditional production-only open without caching
- [ ] `npm run lint` exits 0

### Scope boundaries

**In scope**

- `src/lib/db/client.ts`
- Related tests under `src/lib/db/` if present or newly added

**Out of scope**

- Moving migrations to drizzle-kit
- Multi-tenant or remote Postgres
- Changing WAL/journal settings beyond keeping current pragmas
- Refactoring repositories

### Risks and notes

- Next.js may hot-reload in dev: keep the existing `global` pattern so HMR does not open unbounded handles.
- Reviewers should confirm tests never point `createTestDb` at the on-disk app DB.
- If a future need arises to reset the singleton in integration tests, export a test-only `resetAppSqliteForTests()` rather than opening parallel handles.