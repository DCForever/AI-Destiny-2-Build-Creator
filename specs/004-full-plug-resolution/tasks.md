---
description: "Task list for Full Inventory Plug Resolution feature"
---

# Tasks: Full Inventory Plug Resolution

**Input**: Design documents from `/specs/004-full-plug-resolution/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Hybrid plug map in Foundational phase (blocks all stories). US1/US2 share the same code path; story phases focus on weapon vs armor validation. US3/US4 are search + debug verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US4)

## Path Conventions

- Domain: `src/lib/inventory/instances/`
- Catalog helper: `src/lib/catalog/inventoryHashProjections.ts`
- API: `src/app/api/user/inventory/instances/route.ts`, `[instanceId]/route.ts`
- Docs: `DEBUG.md`, `specs/004-full-plug-resolution/quickstart.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test fixtures and helpers for plug resolution coverage (SC-001)

- [ ] T001 [P] Add Ringing Nail and armor plug hash fixtures in `src/lib/inventory/instances/__fixtures__/plugFixtures.ts` (quickstart.md hash table)
- [ ] T002 [P] Add `collectEquipmentPlugHashes` helper stub and failing tests in `src/lib/inventory/instances/collectPlugHashes.test.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Hybrid plug name map — entity stores + manifest batch fallback (research R2, R3)

**⚠️ CRITICAL**: No user story validation until this phase completes

- [ ] T003 [P] Add failing hybrid `buildPlugNameMap` tests (entity layer + manifest merge; unresolved fallback) in `src/lib/inventory/instances/resolvePlugs.test.ts`
- [ ] T004 [P] Add failing `buildPlugMapForInventory` tests in `src/lib/inventory/instances/loadInstanceContext.test.ts`
- [ ] T005 Implement `collectEquipmentPlugHashes` in `src/lib/inventory/instances/collectPlugHashes.ts` (equipment buckets only; union unique hashes)
- [ ] T006 Add shared `resolvePlugNamesFromManifest` (reuse `getRaw`/`isUsable`/`projectBase` pattern) in `src/lib/inventory/instances/plugNamesFromManifest.ts`; DRY with `src/lib/catalog/inventoryHashProjections.ts` if practical
- [ ] T007 Expand `buildPlugNameMap` and add `mergeManifestPlugNames` in `src/lib/inventory/instances/resolvePlugs.ts` (FR-003, FR-006)
- [ ] T008 Refactor `loadInstanceListContext` → export `buildPlugMapForInventory(entityCache, manifest, plugHashes)` in `src/lib/inventory/instances/loadInstanceContext.ts` (research R3)

**Checkpoint**: Hybrid map builds from fixture hashes; unresolved plugs still degrade to hash string

---

## Phase 3: User Story 1 — Readable Weapon Plug Names (Priority: P1) 🎯 MVP

**Goal**: Weapon instance list/detail resolve intrinsics, mods, masterwork, cosmetics, and roll perks (FR-001, SC-001 weapon fixture)

**Independent Test**: `GET /api/user/inventory/instances?itemHash=4206550094` — Ringing Nail plugs include named Precision Frame, Synergy, Default Shader (quickstart Scenarios 1–2)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before route wiring

- [ ] T009 [P] [US1] Add failing weapon plug resolution tests (Ringing Nail fixture hashes → `resolved: true`) in `src/lib/inventory/instances/listUserInstances.test.ts`

### Implementation for User Story 1

- [ ] T010 [US1] Wire list route: collect plug hashes from DB, call `buildPlugMapForInventory`, pass map to `listUserInstances` in `src/app/api/user/inventory/instances/route.ts`
- [ ] T011 [US1] Wire detail route: collect plug hashes for single row (or item's hashes), hybrid map in `src/app/api/user/inventory/instances/[instanceId]/route.ts`
- [ ] T012 [US1] Run `npm run gate` and validate quickstart Scenarios 1–2 (list vs detail consistency)

**Checkpoint**: User Story 1 complete — weapon plugs named at ≥99% on fixture

---

## Phase 4: User Story 2 — Readable Armor Plug Names (Priority: P1)

**Goal**: Armor instances resolve mods, masterwork, ornaments, shaders with same rules as weapons (FR-002)

**Independent Test**: `GET /api/user/inventory/instances?kind=armor&itemHash={hash}` — mod and masterwork plugs named (quickstart Scenario 4)

### Tests for User Story 2 ⚠️

- [ ] T013 [P] [US2] Add failing armor plug resolution tests (mod + masterwork fixture hashes) in `src/lib/inventory/instances/projectInstance.test.ts`

### Implementation for User Story 2

- [ ] T014 [US2] Extend `plugFixtures.ts` with armor socket hashes; assert armor `kind` in `listUserInstances.test.ts` uses hybrid map (same routes as US1 — no duplicate wiring)
- [ ] T015 [US2] Run `npm run gate` and validate quickstart Scenario 4

**Checkpoint**: P1 stories complete — weapons and armor plug names

---

## Phase 5: User Story 3 — Perk Text Search (Priority: P2)

**Goal**: `q` matches newly resolved non-roll plug names (FR-007, SC-003)

**Independent Test**: `GET /api/user/inventory/instances?q=Synergy` returns Ringing Nail copies (quickstart Scenario 3)

### Tests for User Story 3 ⚠️

- [ ] T016 [P] [US3] Add failing `q=Synergy` and `q=Precision` filter tests in `src/lib/inventory/instances/filterInstances.test.ts`

### Implementation for User Story 3

- [ ] T017 [US3] Confirm `filterInstances` matches on projected `displayName`/`name` only — fix only if tests fail in `src/lib/inventory/instances/filterInstances.ts`
- [ ] T018 [US3] Run `npm run gate` and validate quickstart Scenario 3

**Checkpoint**: Search finds enhanced mods and intrinsics by name

---

## Phase 6: User Story 4 — Debug Verification (Priority: P2)

**Goal**: Debug catalog instance panel reflects expanded resolution; operator docs updated (SC-001, SC-002)

**Independent Test**: `/debug/catalog` owned row → instance cards show named non-roll plugs (quickstart Scenario 5)

### Implementation for User Story 4

- [ ] T019 [US4] Update owned-instance plug resolution notes in `DEBUG.md` (link quickstart fixtures; no API shape change)
- [ ] T020 [US4] Run `npm run gate` and validate quickstart Scenarios 5–6 (debug + manifest-missing degrade)

**Checkpoint**: Debug + docs aligned with 004 behavior

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Contract alignment and final validation

- [ ] T021 [P] Cross-check `specs/004-full-plug-resolution/contracts/plug-resolution-contract.md` examples against implemented fixture names; adjust contract or fixtures if drift
- [ ] T022 Run full `specs/004-full-plug-resolution/quickstart.md` Scenario 7 (`npm run gate`) and mark feature ready for `/speckit-implement` completion

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user stories**
- **Phase 3 (US1)**: Depends on Phase 2 — MVP
- **Phase 4 (US2)**: Depends on Phase 2; parallel with US1 after T010–T011 if routes already wired
- **Phase 5 (US3)**: Depends on Phase 3 (needs expanded map in list flow)
- **Phase 6 (US4)**: Depends on Phase 3 (debug shows API output)
- **Phase 7 (Polish)**: After US1–US4 checkpoints

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| US1 (P1) | Foundational | Route wiring + weapon tests |
| US2 (P1) | Foundational | Same map; armor-specific tests only |
| US3 (P2) | US1 | Search uses same plug map from list route |
| US4 (P2) | US1 | Debug displays API data; docs update |

### Parallel Opportunities

- **Phase 1**: T001 ∥ T002
- **Phase 2**: T003 ∥ T004; after T005–T007 sequential core, finish T004 tests
- **Phase 3**: T009 ∥ (T010 prep review); T010 then T011 sequential (same feature, different routes)
- **Phase 4**: T013 ∥ T014 after US1 checkpoint
- **Phase 5**: T016 independent once hybrid map exists in test harness
- **Phase 7**: T021 ∥ prep for T022

---

## Parallel Example: Foundational Phase

```bash
# Tests first (parallel):
T003: resolvePlugs.test.ts — hybrid map failures
T004: loadInstanceContext.test.ts — orchestration failures

# Then implementation chain:
T005 → T006 → T007 → T008 (gate)
```

---

## Parallel Example: User Story 1

```bash
# After Foundational checkpoint:
T009: listUserInstances.test.ts — weapon fixture (parallel with reading route code)
T010: instances/route.ts
T011: instances/[instanceId]/route.ts
T012: gate + quickstart 1–2
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1–2 (fixtures + hybrid map)
2. Complete Phase 3 (US1 route wiring + weapon validation)
3. **STOP and VALIDATE** quickstart Scenarios 1–2
4. Proceed to US2–US4 incrementally

### Incremental Delivery

1. Foundational → hybrid map works in unit tests
2. US1 → weapons named → demo/debug
3. US2 → armor named
4. US3 → search by mod/intrinsic name
5. US4 → DEBUG.md + manual debug pass

### Suggested MVP Scope

**Phases 1–3 only** (T001–T012) delivers core value: weapon instance detail with full plug names.

---

## Notes

- Do **not** change `ResolvedPlug` JSON shape or sync pipeline (FR-008, FR-009; research R5)
- Manifest fallback uses current cached version; missing manifest → more hash fallbacks, not errors
- `loadoutText.ts` hash index alignment is optional — not in task scope unless time permits after T022

---

## Task Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| 1 Setup | T001–T002 | — |
| 2 Foundational | T003–T008 | — |
| 3 US1 Weapon | T009–T012 | US1 |
| 4 US2 Armor | T013–T015 | US2 |
| 5 US3 Search | T016–T018 | US3 |
| 6 US4 Debug | T019–T020 | US4 |
| 7 Polish | T021–T022 | — |
| **Total** | **22 tasks** | |
