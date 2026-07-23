# Tasks: Production SQLite Singleton

**Input**: Design documents from `/specs/032-prod-sqlite-singleton/`  
**Prerequisites**: plan.md, spec.md, research.md, contracts/, quickstart.md

## Phase 1: Setup

- [ ] T001 Confirm feature artifacts under `specs/032-prod-sqlite-singleton/` and `.specify/feature.json` point at this feature

## Phase 2: Foundational

- [ ] T002 Read `src/lib/db/client.ts` `getSqlite`/`openDatabase`/`createTestDb`/`createTestSqlite` and `src/lib/manifest/cachePaths.ts` `appDbPath` before editing

## Phase 3: User Story 1 — Production process reuses one DB handle (P1)

**Goal**: All `NODE_ENV` values cache one native handle on `global.__d2bcSqlite`.  
**Independent Test**: `src/lib/db/client.test.ts` under simulated production env.

- [ ] T003 [US1] Collapse `getSqlite()` to always lazy-init/cache `global.__d2bcSqlite` in `src/lib/db/client.ts`; keep WAL + foreign_keys in `openDatabase`
- [ ] T004 [US1] Add short comment on singleton path that multi-worker/Edge against one file is unsupported in `src/lib/db/client.ts`
- [ ] T005 [P] [US1] Add `src/lib/db/client.test.ts` proving two sequential `getDb()` calls under non-development `NODE_ENV` share the same native handle (use temp cwd or pre-seeded global; restore env/global; do not poison developer `.cache/app.db`)
- [ ] T006 [US1] Optionally export `resetAppSqliteForTests()` in `src/lib/db/client.ts` if needed for safe test cleanup

## Phase 4: User Story 2 — Test isolation (P1)

**Goal**: Test helpers stay on isolated `:memory:` DBs.  
**Independent Test**: assertions in `client.test.ts` + existing `schema.test.ts`.

- [ ] T007 [US2] Verify `createTestDb`/`createTestSqlite` in `src/lib/db/client.ts` never read/write the file singleton; add isolation assertion in `src/lib/db/client.test.ts`

## Phase 5: User Story 3 — Operator documentation (P2)

- [ ] T008 [US3] Confirm multi-worker/Edge unsupported comment present near acquisition in `src/lib/db/client.ts` (covered by T004)

## Phase 6: Polish & verification

- [ ] T009 Run `rg -n "return openDatabase" src/lib/db/client.ts` and confirm no unconditional production-only open
- [ ] T010 Run `npm run typecheck`, `npm run lint`, `npm run test`; fix failures introduced by this change
- [ ] T011 Mark improve prompt `specs/data-layer/improve/001-prod-sqlite-singleton.md` status DONE
- [ ] T012 Commit implementation with `[Spec Kit]` message and Oz co-author trailer

## Dependencies

- T001 → T002 → T003 → T004
- T005 after T003 (can draft test first red, then green)
- T006 with T005 as needed
- T007 after T003
- T008 with T004
- T009–T012 after stories complete

## Parallel opportunities

- T005 test file can be written in parallel with T004 comment once T003 API shape is known

## MVP

T003 + T005 + T007 + T010

## Implementation strategy

1. Change `getSqlite` to unconditional global cache.  
2. Add focused client tests (production reuse + memory isolation).  
3. Gate typecheck/lint/test.  
4. Mark improve DONE and commit.
