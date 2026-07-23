# Implementation Plan: Production SQLite Singleton

**Branch**: `032-prod-sqlite-singleton` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/032-prod-sqlite-singleton/spec.md`

## Summary

Cache one better-sqlite3 handle on `global.__d2bcSqlite` for **all** `NODE_ENV` values in `src/lib/db/client.ts`. Keep `createTestDb` / `createTestSqlite` on isolated `:memory:` DBs. Add a unit test that production-path acquisition reuses the handle. No schema or repository API changes.

## Technical Context

**Language/Version**: TypeScript (strict), Node.js (Next.js app server)
**Primary Dependencies**: better-sqlite3, drizzle-orm/better-sqlite3, Next.js 16
**Storage**: Single local SQLite file via `appDbPath()` under `.cache/`; WAL + foreign_keys
**Testing**: Project test runner via `npm run test` (colocated unit tests under `src/`)
**Target Platform**: Local-first single Node process (not multi-worker / Edge)
**Project Type**: Web application (Next.js)
**Performance Goals**: Eliminate per-`getDb()` native open in production; no schema change
**Constraints**: HMR-safe global cache; tests must not bind to on-disk app DB; no domain BR/DAC changes
**Scale/Scope**: One module + one focused test file under `src/lib/db/`

## Constitution Check

- Local-first single-process SQLite remains the model; plan does not introduce multi-tenant DB.
- No product semantics change → domain docs unchanged.
- Prefer minimal diff: collapse env branch, keep open pragmas and migrations as-is.
- Gates: typecheck, lint, test must pass.

## Project Structure

### Documentation (this feature)

```text
specs/032-prod-sqlite-singleton/
├── plan.md
├── research.md
├── quickstart.md
├── contracts/
│   └── sqlite-singleton.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
src/lib/db/
├── client.ts          # getSqlite singleton for all NODE_ENV
├── client.test.ts     # NEW: production-path reuse + test isolation
├── schema.ts
└── schema.test.ts     # unchanged; still uses createTestSqlite
```

**Structure Decision**: Touch only `src/lib/db/client.ts` and add `src/lib/db/client.test.ts`.

## Complexity Tracking

No constitution violations. Complexity is intentionally low (S effort).

## Phase 0 / Phase 1

See [research.md](./research.md), [contracts/sqlite-singleton.md](./contracts/sqlite-singleton.md), [quickstart.md](./quickstart.md). No data-model.md (no schema entities change).
