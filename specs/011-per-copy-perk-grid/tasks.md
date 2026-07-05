---
description: "Task list for Per-Copy Weapon Perk Grid"
---

# Tasks: Per-Copy Weapon Perk Grid

**Input**: Design documents from `/specs/011-per-copy-perk-grid/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are **in scope** (spec Verification + quickstart "Automated coverage" table) and the constitution requires Test-First. Per story, tests are written FIRST and confirmed FAILING before implementation; commits happen only at green checkpoints after the increment's tests + `npm run gate` pass.

**Organization**: Tasks are grouped by user story (priority order from spec.md) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US3 (maps to spec.md user stories); Setup/Foundational/Polish carry no story label
- Exact file paths are included in each task

## Path Conventions

Single Next.js project; source at repository root `src/`. Co-located `*.test.ts` beside each module (Constitution IV).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish a green baseline; confirm no new dependencies or tooling are needed.

- [ ] T001 Confirm branch `011-per-copy-perk-grid` is checked out and `npm run gate` passes on the current baseline (green starting point per Constitution III).
- [ ] T002 [P] Confirm required manifest entity stores (`weapons`, `exotic-weapons`, `weapon-perks`, `origin-traits`) build and debug prerequisites in `DEBUG.md` are met; verify no new npm dependencies are required by this feature.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Additive, nullable DB column for per-copy socket plug capture. Backward compatible; rows synced before this feature have `socket_plugs = NULL` until re-sync (FR-018).

**⚠️ CRITICAL**: No user story work should modify `src/lib/db/schema.ts` / `client.ts` until this phase is complete.

- [ ] T003 Extend the migration smoke test in `src/lib/db/schema.test.ts` to assert that `inventory_items.socket_plugs` exists after `runMigrations` (write FIRST; must FAIL before T004/T005).
- [ ] T004 [P] Add `inventoryItems.socketPlugs` (`text("socket_plugs")`) to the drizzle schema in `src/lib/db/schema.ts`.
- [ ] T005 [P] Add idempotent `ensureSocketPlugsColumn(db)` (PRAGMA `table_info` + `ALTER TABLE ADD COLUMN`, mirroring `ensureGearTierColumn`) and invoke it from `runMigrations` in `src/lib/db/client.ts`.
- [ ] T006 [P] Add `socketPlugs: StoredSocketPlug[] | null` to `UserInventoryItem` in `src/lib/db/types.ts` and JSON parse/serialize in `src/lib/db/repositories/inventoryRepository.ts` (read/write `socket_plugs` column).

**Checkpoint**: Migrations pass (T003 green); DB row shape carries `socketPlugs`. `npm run gate` clean → commit.

---

## Phase 3: User Story 1 - See a Copy's Real Perks Laid Out by Column (Priority: P1) 🎯 MVP

**Goal**: When the user selects one owned weapon copy, show a **DIM-style per-column perk grid** for **that copy** — each column lists perks the copy can slot (equipped + alternates), equipped marked and preselected. Replaces catalog `perk-options` (weapon-type pool) in Sets debug.

**Independent Test**: Select a weapon copy from the carousel → grid loads from `GET /api/user/inventory/instances/:instanceId/perk-grid` with labeled columns and equipped marked; a second copy of the same weapon with a different roll shows a different grid; crafted/multi-perk copy shows multiple options in at least one column.

### Tests for User Story 1 ⚠️ (write first, confirm failing)

- [ ] T007 [P] [US1] Tests for parsing Bungie component **310** reusable plugs + merging equipped socket rows into `StoredSocketPlug[]` (weapon only; non-weapon → null) in `src/lib/bungie/profile.test.ts`.
- [ ] T008 [P] [US1] Tests for `classifyWeaponSocket` (barrel/magazine/trait/intrinsic/origin/masterwork/catalyst labels; exclude shader/tracker/ornament sockets) in `src/lib/inventory/instances/classifyWeaponSocket.test.ts`.
- [ ] T009 [P] [US1] Tests for `resolveInstancePerkGrid` (complete grid with alternates; equipped flagged; enhanced `" (Enhanced)"` label; exotic catalyst column; two copies → different options; **no type-pool hashes**) in `src/lib/inventory/instances/resolveInstancePerkGrid.test.ts`.
- [ ] T010 [P] [US1] Tests for `GET /api/user/inventory/instances/[instanceId]/perk-grid` (200 shape; `401` unsigned; `404` missing; armor → error; pending → equipped-only + status) in `src/app/api/user/inventory/instances/[instanceId]/perk-grid/route.test.ts`.

### Implementation for User Story 1

- [ ] T011 [P] [US1] Add `StoredSocketPlug`, `SocketColumnKind`, `InstancePerkGrid`, `InstancePerkColumn`, and `InstancePerkOption` types in `src/lib/inventory/instances/types.ts`.
- [ ] T012 [P] [US1] Implement `classifyWeaponSocket(itemHash, socketIndex, manifestContext) → { columnKind, columnLabel, includeInGrid }` in `src/lib/inventory/instances/classifyWeaponSocket.ts` (depends on T008).
- [ ] T013 [US1] Extend `INVENTORY_COMPONENTS` with **310** (+ profile/character plug sets if required per `profile.test.ts`); add `parseReusablePlugsMap`, merge plug-set alternates, and build `socketPlugs[]` via `classifyWeaponSocket` in `src/lib/bungie/profile.ts` (depends on T006, T007, T012).
- [ ] T014 [US1] Persist `socketPlugs` on weapon/exotic weapon rows during `upsertInventoryBatch` in `src/lib/bungie/syncInventory.ts` (depends on T013).
- [ ] T015 [US1] Implement `resolveInstancePerkGrid({ item, socketPlugs, plugMap, manifestContext }) → InstancePerkGrid` with `captureStatus` in `src/lib/inventory/instances/resolveInstancePerkGrid.ts` (depends on T009, T011, T012).
- [ ] T016 [US1] Implement `GET /api/user/inventory/instances/[instanceId]/perk-grid/route.ts` (auth, load row, weapon-kind guard, call resolver, zod-safe response) per `contracts/instance-perk-grid-contract.md` (depends on T015).
- [ ] T017 [US1] Replace catalog `perk-options` fetch with perk-grid in `src/app/debug/sets/SetsDebugPage.tsx`: lazy load on weapon copy select, render labeled columns with equipped marker, refresh grid when carousel copy changes; **do not** call `GET /api/catalog/weapons/perk-options` (depends on T016).

**Checkpoint**: US1 independently testable — per-copy grid renders from real capture data. `npm run gate` clean → commit.

---

## Phase 4: User Story 2 - Pick Perks Per Column and Save Them to the Set (Priority: P1)

**Goal**: User chooses one perk per column (defaults to equipped); **Put item** persists `instanceId` + column-ordered `selectedPerks` via existing set-item write path.

**Independent Test**: Change one column away from equipped, click Put item → saved set item has correct `instanceId` and `selectedPerks` matching equipped defaults + override in **grid column order**; no changes → equipped perks recorded.

### Tests for User Story 2 ⚠️ (write first, confirm failing)

- [ ] T018 [P] [US2] Extend `src/lib/sets/setItemService.test.ts`: grid-derived `selectedPerks` (column display order) persist with `instanceId`; untouched columns keep equipped defaults; two copies → distinguishable saved references.
- [ ] T019 [P] [US2] Extend `src/lib/sets/schemas.test.ts` (if needed): `selectedPerks` array length/order accepted for multi-column weapon rolls.

### Implementation for User Story 2

- [ ] T020 [US2] Wire perk-grid selection state in `src/app/debug/sets/SetsDebugPage.tsx`: initialize each column to `equippedPlugHash`; map `selectedPerks` to column-order hash array on Put item; preserve replace confirmation and slot rules (depends on T017).
- [ ] T021 [US2] Verify `upsertSetItem` in `src/lib/sets/setItemService.ts` stores grid selection unchanged (extend only if gaps found by T018; otherwise confirm via green tests).

**Checkpoint**: P1 complete (US1 + US2) — compare copies, pick per-column roll, attach to set. `npm run gate` clean → commit.

---

## Phase 5: User Story 3 - Degrade Gracefully When Per-Copy Data Is Unavailable (Priority: P2)

**Goal**: When capture is missing or fails, show equipped-only grid with clear indicator; **auto re-sync once per copy per session** when `captureStatus: "pending"`; never show weapon-type pool.

**Independent Test**: Stale copy (`socket_plugs` null) → one automatic `POST /api/bungie/sync`, grid re-fetches; sync failure → equipped-only + indicator, no retry loop; transient errors → degraded state not error page.

### Tests for User Story 3 ⚠️ (write first, confirm failing)

- [ ] T022 [P] [US3] Extend `src/lib/inventory/instances/resolveInstancePerkGrid.test.ts`: `captureStatus: "pending"` and `"unavailable"` → equipped-only options per column; never inject catalog type-pool hashes.
- [ ] T023 [P] [US3] Tests for `perkGridRefresh` session dedupe (one sync attempt per `instanceId`; `inFlight` guard; no loop on repeated failure) in `src/lib/inventory/instances/perkGridRefresh.test.ts`.

### Implementation for User Story 3

- [ ] T024 [US3] Implement `perkGridRefresh.ts` (`syncAttemptedFor` set, `shouldAutoSync`, `markSyncAttempted`) in `src/lib/inventory/instances/perkGridRefresh.ts` (depends on T023).
- [ ] T025 [US3] Add auto re-sync UX in `src/app/debug/sets/SetsDebugPage.tsx`: on `captureStatus === "pending"` call `POST /api/bungie/sync` once per copy per session (via T024), show loading while pending, re-fetch grid; on `"unavailable"` show equipped-only + indicator; never fall back to catalog `perk-options` (depends on T017, T024).

**Checkpoint**: All user stories complete. `npm run gate` clean → commit.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T026 [P] Update `DEBUG.md` (perk-grid endpoint, auto re-sync on stale copies, Sets debug no longer uses catalog `perk-options` for attachment, edge-case table) and bump **Last reviewed** date, per the `debug-docs` rule.
- [ ] T027 Run `quickstart.md` Scenarios A–D + edge cases, then `npm run gate` for the full-feature green checkpoint.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup; **blocks** any story task that touches `src/lib/db/*` or reads `socketPlugs` from DB (T013–T016).
- **User Stories (Phase 3–5)**: depend on Foundational. Priority order US1 → US2 (P1) → US3 (P2). US2 depends on US1 grid UI; US3 extends US1 UI with re-sync/degradation.
- **Polish (Phase 6)**: depends on all targeted stories being complete.

### Key cross-task dependencies

- T003 (failing migration test) → T004, T005, T006.
- T007 → T013; T008 → T012; T009 → T015; T010 → T016.
- T011 ∥ T012 (after T008); T012 → T013 → T014; T015 → T016 → T017.
- T017 → T020 → T025 (sequential on `SetsDebugPage.tsx`).
- T018 → T020, T021; T023 → T024 → T025.

### Shared-file serialization (NOT parallel)

- `src/lib/bungie/profile.ts`: T013 only (after T012 exists).
- `src/app/debug/sets/SetsDebugPage.tsx`: T017 → T020 → T025 run sequentially.
- `src/lib/db/schema.ts` / `client.ts` / `schema.test.ts`: confined to Phase 2.

---

## Parallel Opportunities

- **Phase 1**: T002 ∥ T001.
- **Phase 2 (after T003)**: T004 ∥ T005 ∥ T006.
- **US1 tests**: T007 ∥ T008 ∥ T009 ∥ T010 (distinct files).
- **US1 impl (partial)**: T011 ∥ T012 after T008; T013 after T012.
- **US2 tests**: T018 ∥ T019.
- **US3 tests**: T022 ∥ T023 (T022 extends existing file — run after T009 lands or coordinate).

### Parallel Example: User Story 1 tests

```bash
Task: "Component 310 parse tests in src/lib/bungie/profile.test.ts"
Task: "classifyWeaponSocket tests in src/lib/inventory/instances/classifyWeaponSocket.test.ts"
Task: "resolveInstancePerkGrid tests in src/lib/inventory/instances/resolveInstancePerkGrid.test.ts"
Task: "perk-grid route tests in src/app/api/user/inventory/instances/[instanceId]/perk-grid/route.test.ts"
```

---

## Implementation Strategy

### MVP scope

- **Minimum**: Phase 1 + Phase 2 + **US1** (sync capture + per-copy grid API + Sets debug grid display) — proves real per-copy perks end-to-end after one inventory re-sync.
- **Shippable P1 increment**: US1 + **US2** — pick per-column roll and attach to set with `instanceId` + `selectedPerks`.

### Incremental delivery

1. Setup + Foundational → `socket_plugs` migration green → gate → commit.
2. US1 → per-copy grid (MVP) → gate → commit.
3. US2 → save column selections → **P1 complete** → gate → commit.
4. US3 → auto re-sync + degradation → gate → commit.
5. Polish (DEBUG.md + quickstart validation).

### Notes

- Verify each story's tests FAIL before implementing (Test-First, NON-NEGOTIABLE).
- Commit only at checkpoints where the increment's tests pass and `npm run gate` is clean (Green Checkpoints).
- Existing `GET /api/catalog/weapons/perk-options` remains but Sets debug must not use it after T017 (FR-015).
- `socket_plugs` backfill requires inventory re-sync; US3 auto-triggers one sync per stale copy per session (FR-018).
- Enhanced perks: separate options with `" (Enhanced)"` displayName suffix (FR-017).
- Exotics use the same grid resolver; catalyst column when socket present (FR-016).

---

## Task Summary

| Phase | Story | Task IDs | Count |
|-------|-------|----------|-------|
| Setup | — | T001–T002 | 2 |
| Foundational | — | T003–T006 | 4 |
| US1 Per-copy grid | US1 | T007–T017 | 11 |
| US2 Save selection | US2 | T018–T021 | 4 |
| US3 Degrade + re-sync | US3 | T022–T025 | 4 |
| Polish | — | T026–T027 | 2 |
| **Total** | | **T001–T027** | **27** |

**Format validation**: All 27 tasks use `- [ ]`, sequential Task IDs, story labels on US phases, and explicit file paths.
