# Tasks: Armor Set Optimizer

**Input**: Design documents from `/specs/026-armor-set-optimizer/`

**Prerequisites**: plan.md, spec.md (clarifications Session 2026-07-14), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Constitution requires test-first — write failing Vitest tests before implementation; commit only when `npm run gate` is green.

**Organization**: Phases by user story (US1 → US6). Design-doc sync is Phase 1 because plan/contracts predate constraint-persistence clarifications.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1 / US2 / US3 / US4 / US5 / US5b / US6
- Include exact file paths

## Phase 1: Setup (Design Sync + Scaffold)

**Purpose**: Align design artifacts with clarified spec; create optimizer module scaffold

- [ ] T001 Sync `specs/026-armor-set-optimizer/plan.md` Summary/Structure with clarifications (persisted constraints, in-place refresh, soft suggestions, create-from-build seeding)
- [ ] T002 [P] Sync `specs/026-armor-set-optimizer/data-model.md` — `ArmorSetOptimizerConstraints` on sets, `linkedModSetId`, improvement-suggestion entity; drop “create-only / no overwrite” language
- [ ] T003 [P] Sync `specs/026-armor-set-optimizer/research.md` R5–R8 for constraint persistence + suggest-then-confirm (supersede create-only materialize)
- [ ] T004 [P] Sync contracts: `contracts/create-sets-from-build-contract.md`, `contracts/armor-optimize-contract.md`, `contracts/materialize-combination-contract.md` + add `contracts/refresh-constrained-set-contract.md` and `contracts/improvement-suggestions-contract.md`
- [ ] T005 [P] Sync `specs/026-armor-set-optimizer/quickstart.md` for refresh, soft suggestions, constraint seed/clear
- [ ] T006 Create optimizer package scaffold dirs/files per plan: `src/lib/optimizer/` (`types.ts`, `constraints.ts`, `prune.ts`, `enumerate.ts`, `score.ts`, `autoStatMods.ts`, `estimate.ts`, `explainEmpty.ts`, `optimizeArmor.ts`)
- [ ] T007 [P] Add domain BR stubs for create-from-build / replace-by-type / set constraints in `specs/business-rules.md` (and DBR note if needed) per AGENTS.md co-update rule

---

## Phase 2: Foundational (Blocking)

**Purpose**: Shared persistence, naming, attach-replace, and Zod types used by all stories

**⚠️ CRITICAL**: No user story implementation until this phase completes

- [ ] T008 Add failing schema tests for `optimizer_constraints` (+ optional `linked_mod_set_id`) on `sets` in `src/lib/db/schema.test.ts`
- [ ] T009 Implement `sets.optimizer_constraints` TEXT JSON (nullable) and `sets.linked_mod_set_id` TEXT nullable FK in `src/lib/db/schema.ts` + migration/ensure path used by the app so T008 passes
- [ ] T010 [P] Add Zod types + normalize/clear helpers for optimizer constraints in `src/lib/optimizer/types.ts` and `src/lib/optimizer/constraintsSchema.ts` with tests in `src/lib/optimizer/constraintsSchema.test.ts`
- [ ] T011 [P] Add failing tests then implement unique set-name helper (numeric suffix) in `src/lib/sets/uniqueSetName.ts` + `src/lib/sets/uniqueSetName.test.ts`
- [ ] T012 [P] Add failing tests then implement replace-by-type attach helper in `src/lib/builds/replaceAttachmentByType.ts` + `src/lib/builds/replaceAttachmentByType.test.ts` (detach same-type live → attach new)
- [ ] T013 Extend set read/write mapping in `src/lib/sets/setService.ts` / `src/lib/sets/schemas.ts` to load/save `optimizerConstraints` and `linkedModSetId`
- [ ] T014 [P] Add seed-from-build helper (exotic + soft-stat priorities/thresholds; empty set-bonus goals) in `src/lib/optimizer/seedConstraintsFromBuild.ts` + `src/lib/optimizer/seedConstraintsFromBuild.test.ts`

**Checkpoint**: Schema + shared helpers green; stories can proceed

---

## Phase 3: User Story 1 — Create Sets from Build + Attach (P1) 🎯 MVP

**Goal**: Snapshot composed gear into Sets, seed Armor Set constraints from Build, attach-now with replace-by-type

**Independent Test**: Debug Builds → create-sets → new Armor Set has pieces + seeded constraints; attached live; prior same-type attachment detached

### Tests for User Story 1

- [ ] T015 [P] [US1] Failing service tests for create-from-build (categories, auto-name, seed constraints, attachNow true/false, replace-by-type) in `src/lib/builds/createSetsFromBuild.test.ts`
- [ ] T016 [P] [US1] Failing route contract tests for `POST /api/user/builds/[id]/create-sets` in `src/app/api/user/builds/[id]/create-sets/route.test.ts`

### Implementation for User Story 1

- [ ] T017 [US1] Implement `createSetsFromBuild` in `src/lib/builds/createSetsFromBuild.ts` so T015 passes (reuse `setService`, `setItemService`, T011–T014)
- [ ] T018 [US1] Implement `src/app/api/user/builds/[id]/create-sets/route.ts` so T016 passes
- [ ] T019 [US1] Add Create-sets-from-build form + JSON panel on `src/app/debug/builds/BuildsDebugPage.tsx`
- [ ] T020 [US1] Run `npm run gate`; commit US1 checkpoint

**Checkpoint**: MVP — create-from-build + attach works

---

## Phase 4: User Story 2 — Constrained Full-Kit Search (P1)

**Goal**: Owned-inventory search returns only complete five-slot kits meeting exotic + set-bonus goals; lexicographic ranking

**Independent Test**: Fixture inventory + dual-2pc + exotic + Melee-first priorities → 100% of results satisfy hard constraints; emptyReason when impossible

### Tests for User Story 2

- [ ] T021 [P] [US2] Failing unit tests for constraint checks / empty explanations in `src/lib/optimizer/constraints.test.ts` and `src/lib/optimizer/explainEmpty.test.ts`
- [ ] T022 [P] [US2] Failing unit tests for prune + enumerate + lexicographic score (complete kits only) in `src/lib/optimizer/prune.test.ts`, `src/lib/optimizer/enumerate.test.ts`, `src/lib/optimizer/score.test.ts`
- [ ] T023 [P] [US2] Failing orchestrator tests (build seed, hard filters, truncated top-N) in `src/lib/optimizer/optimizeArmor.test.ts`
- [ ] T024 [P] [US2] Failing route tests for `POST /api/user/armor/optimize` in `src/app/api/user/armor/optimize/route.test.ts`

### Implementation for User Story 2

- [ ] T025 [US2] Implement `constraints.ts`, `explainEmpty.ts`, `prune.ts`, `enumerate.ts`, `score.ts` so T021–T022 pass (`includeModEstimates` may be stubbed false)
- [ ] T026 [US2] Implement `optimizeArmor.ts` + inventory load adapter so T023 passes
- [ ] T027 [US2] Implement `src/app/api/user/armor/optimize/route.ts` so T024 passes
- [ ] T028 [US2] Add minimal Optimize form (buildId seed + constraints JSON) on `src/app/debug/builds/BuildsDebugPage.tsx`
- [ ] T029 [US2] Run `npm run gate`; commit US2 checkpoint

**Checkpoint**: Constrained search API works without mods / materialize

---

## Phase 5: User Story 3 — Browse Combination Results (P2)

**Goal**: Ranked result rows expose pieces, six-stat estimates, set-bonus summary; selection does not write Sets

**Independent Test**: Optimize response/UI shows five pieces + setBonusSummary + estimatedStats; selecting a row does not call materialize

### Tests for User Story 3

- [ ] T030 [P] [US3] Failing tests for combination DTO shaping / set-bonus summary helpers in `src/lib/optimizer/combinationDto.test.ts`

### Implementation for User Story 3

- [ ] T031 [US3] Implement combination DTO helpers in `src/lib/optimizer/combinationDto.ts` so T030 passes; wire into optimize response
- [ ] T032 [US3] Add results table (pieces, stats, set bonuses, score, truncated flag) on Builds debug optimize panel without auto-write
- [ ] T033 [US3] Run `npm run gate`; commit US3 checkpoint

**Checkpoint**: DIM-like browse of search results

---

## Phase 6: User Story 4 — Mod-Aware Estimates (P2)

**Goal**: Optional auto-stat-mod estimates within energy; auditable assumedMods; toggle off = base-only

**Independent Test**: Fixture where only mod-aware path meets Melee threshold ranks that kit higher; assumedMods listed; toggle clears them

### Tests for User Story 4

- [ ] T034 [P] [US4] Failing tests for greedy auto-stat-mod assigner + energy in `src/lib/optimizer/autoStatMods.test.ts`
- [ ] T035 [P] [US4] Failing tests for mod-inclusive estimate + ranking fixture (SC-004) in `src/lib/optimizer/estimate.test.ts` and extend `optimizeArmor.test.ts`

### Implementation for User Story 4

- [ ] T036 [US4] Implement `autoStatMods.ts` + `estimate.ts`; integrate into `optimizeArmor.ts` / score path so T034–T035 pass
- [ ] T037 [US4] Expose `includeModEstimates` + `assumedMods` on optimize API/UI; document candidate mod pool limits in code comments matching research R4
- [ ] T038 [US4] Run `npm run gate`; commit US4 checkpoint

**Checkpoint**: Mod-aware ranking works

---

## Phase 7: User Story 5 — Materialize Constrained Armor Set (P2)

**Goal**: First-time materialize creates Armor Set (+ optional Mod Set), persists constraints, optional attach-now

**Independent Test**: Materialize → Set has five pieces + stored constraints equal search; optional Mod Set linked; attach replace-by-type

### Tests for User Story 5

- [ ] T039 [P] [US5] Failing service tests for materialize (create new, persist constraints, linked mod set, attachNow, auto-name) in `src/lib/sets/materializeCombination.test.ts`
- [ ] T040 [P] [US5] Failing route tests for `POST /api/user/armor/optimize/materialize` in `src/app/api/user/armor/optimize/materialize/route.test.ts`

### Implementation for User Story 5

- [ ] T041 [US5] Implement `src/lib/sets/materializeCombination.ts` so T039 passes
- [ ] T042 [US5] Implement `src/app/api/user/armor/optimize/materialize/route.ts` so T040 passes
- [ ] T043 [US5] Wire Materialize confirm UI on Builds debug results table (names, createModSet, attachNow)
- [ ] T044 [US5] Add GET/PATCH constraints view/edit on set detail API path used by debug (`src/app/api/user/sets/[id]/route.ts` + schemas) for FR-010b/010d clear
- [ ] T045 [US5] Run `npm run gate`; commit US5 checkpoint

**Checkpoint**: Constrained Sets can be created from search

---

## Phase 8: User Story 5b — Refresh In Place + Soft Suggestions (P2)

**Goal**: Re-optimize from stored constraints; apply better kit in place; post-sync soft suggestions for attached Sets; on-open check for unattached

**Independent Test**: Refresh updates same Set id; sync suggestion → confirm updates / dismiss no-op; open unattached constrained Set soft-suggests

### Tests for User Story 5b

- [ ] T046 [P] [US5b] Failing tests for in-place apply (items replaced, constraints unchanged, optional mod set update) in `src/lib/sets/applyCombinationInPlace.test.ts`
- [ ] T047 [P] [US5b] Failing tests for improvement detection (lexicographic better-than-current) in `src/lib/optimizer/detectImprovement.test.ts`
- [ ] T048 [P] [US5b] Failing route tests for refresh/apply + suggestions endpoints per `contracts/refresh-constrained-set-contract.md` and `contracts/improvement-suggestions-contract.md`

### Implementation for User Story 5b

- [ ] T049 [US5b] Implement `applyCombinationInPlace` in `src/lib/sets/applyCombinationInPlace.ts` so T046 passes
- [ ] T050 [US5b] Implement `detectImprovement` + optimize-from-set wrapper in `src/lib/optimizer/detectImprovement.ts` / `optimizeFromSet.ts` so T047 passes
- [ ] T051 [US5b] Implement API routes (e.g. `POST /api/user/sets/[id]/optimize`, `POST /api/user/sets/[id]/apply-combination`, `GET /api/user/armor/improvement-suggestions`) so T048 passes
- [ ] T052 [US5b] Hook post-sync suggestion fetch after inventory sync success path (reuse existing sync completion in inventory sync module under `src/lib/inventory/` or debug sync UI) — suggest only, never auto-apply
- [ ] T053 [US5b] Debug UI: soft suggestion banner + confirm/dismiss on Builds; on-open check when loading a constrained Set in Sets debug
- [ ] T054 [US5b] Run `npm run gate`; commit US5b checkpoint

**Checkpoint**: Living constrained Sets refresh safely

---

## Phase 9: User Story 6 — Advanced Evaluation from Sets (P3)

**Goal**: Full optimize → materialize → constraints flow from Sets debug without Build context

**Independent Test**: Sets debug: manual class/exotic/goals → optimize → materialize → Set appears with constraints; on-open suggestion path works

### Tests for User Story 6

- [ ] T055 [P] [US6] Failing tests that optimize without `buildId` requires `classType` and persists constraints on materialize (extend `optimizeArmor.test.ts` / materialize tests)

### Implementation for User Story 6

- [ ] T056 [US6] Add Optimize + Materialize + constraints editor + on-open improvement check to `src/app/debug/sets/SetsDebugPage.tsx`
- [ ] T057 [US6] Ensure clear-constraints control opts Set out of suggestions (FR-010d) in Sets debug + API
- [ ] T058 [US6] Run `npm run gate`; commit US6 checkpoint

**Checkpoint**: Sets library entry point complete

---

## Phase 10: Polish & Cross-Cutting

**Purpose**: Docs, domain rules, quickstart validation, performance caps

- [ ] T059 [P] Finalize BR/DBR entries for optimizer constraints, replace-by-type, soft suggestions in `specs/business-rules.md` / `specs/domain-business-rules.md` if not fully done in T007
- [ ] T060 [P] Update `specs/026-armor-set-optimizer/quickstart.md` with end-to-end verified commands matching shipped routes
- [ ] T061 Add/confirm prune + enumeration caps + `truncated` behavior documented and covered in `src/lib/optimizer/optimizeArmor.test.ts` (SC-007)
- [ ] T062 Run full `npm run gate` and manual quickstart pass on debug Builds + Sets

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Start immediately — design sync + scaffold
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all stories**
- **Phase 3 (US1)**: After Phase 2 — **MVP**
- **Phase 4 (US2)**: After Phase 2 (can parallel US1 if staffed; typically after US1)
- **Phase 5 (US3)**: After US2 (needs optimize response)
- **Phase 6 (US4)**: After US2 (extends optimize)
- **Phase 7 (US5)**: After US2 (+ ideally US4 if materializing assumed mods)
- **Phase 8 (US5b)**: After US5 (needs persisted constraints + materialize)
- **Phase 9 (US6)**: After US5 (reuses APIs); US5b on-open UI can land with US6
- **Phase 10**: After desired stories

### User Story Dependencies

| Story | Depends on | Independently testable? |
|-------|------------|-------------------------|
| US1 | Phase 2 | Yes — create-from-build alone |
| US2 | Phase 2 | Yes — optimize API alone |
| US3 | US2 | Yes — browse-only UI/DTO |
| US4 | US2 | Yes — mod toggle on optimize |
| US5 | US2 (+ US4 optional) | Yes — materialize from fixture combo |
| US5b | US5 | Yes — refresh/suggest on fixture Set |
| US6 | US5 | Yes — Sets debug flow |

### Parallel Opportunities

- T002–T005 (doc sync), T006 scaffold, T007 BRs
- T010–T012, T014 after schema direction clear
- T015–T016; T021–T024; T034–T035; T039–T040; T046–T048
- US1 and US2 after Phase 2 if two implementers

### Parallel Example: User Story 2

```text
T021 constraints/explainEmpty tests
T022 prune/enumerate/score tests
T023 optimizeArmor orchestrator tests
T024 optimize route tests
# then implement T025 → T027
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1–2  
2. Phase 3 (US1)  
3. **STOP** — demo create-from-build + seeded constraints + attach  

### Incremental Delivery

1. US1 → library from Build  
2. US2 → constrained search  
3. US3 → readable results  
4. US4 → mod-aware scores  
5. US5 → persist constrained Sets  
6. US5b → living Sets + soft suggestions  
7. US6 → Sets entry point  
8. Polish  

---

## Notes

- Prefer co-located `*.test.ts` next to modules (project pattern)
- Do not vendor DIM LO; clean-room per research R1
- Soft suggestions never auto-apply
- Complete five-slot kits only in optimize results
- Commit only at green checkpoints after each story
