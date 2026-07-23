# Tasks: Equip Post-Sync Reassert

**Input**: Design documents from `/specs/036-equip-post-sync/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup

- [x] T001 Create `specs/036-equip-post-sync/` and set `.specify/feature.json`

---

## Phase 2: Foundational

- [x] T002 Spec, plan, research, data-model, contracts, quickstart, checklist committed

---

## Phase 3: User Story 1 - Post-sync readiness hard-fail (P1) 🎯 MVP

**Goal**: After sync, recompute readiness; 409 if not ready; no execute.

**Independent Test**: Missing post-sync instance → assert throws NOT_EQUIP_READY; route recomputes before plan.

### Tests

- [ ] T003 [P] [US1] Add test: post-sync style missing instance → computeEquipReady false + assertEquipReady NOT_EQUIP_READY in `src/lib/builds/equipReady.test.ts`
- [ ] T004 [P] [US1] Add test documenting multi-pin happy readiness still true when all instances present (if not already covered)

### Implementation

- [ ] T005 [US1] After `listInventoryItems` in `src/app/api/user/builds/[id]/variants/[variantId]/equip/route.ts`, call `computeEquipReady` + `buildInventoryPinIndex` + `assertEquipReady` before `planEquipSteps`

**Checkpoint**: Post-sync reassert on route

---

## Phase 4: User Story 2 - Planner hard-error on missing combat instance (P1)

**Goal**: No silent `continue` when combat claim has `instanceId` but inventory lacks row.

**Independent Test**: planEquipSteps throws; happy path plans all pinned combat slots.

### Tests

- [ ] T006 [P] [US2] Add test: missing inventory for claimed instanceId throws in `src/lib/builds/equipPlan.test.ts`
- [ ] T007 [P] [US2] Add test: happy path plans equip steps for multiple pinned combat slots in `src/lib/builds/equipPlan.test.ts`

### Implementation

- [ ] T008 [US2] Replace silent skip in `src/lib/builds/equipPlan.ts` with `ApiError` NOT_EQUIP_READY hard error

**Checkpoint**: Planner defense-in-depth

---

## Phase 5: Polish

- [ ] T009 Run `npm run test`, `npm run typecheck`, `npm run lint`; fix failures
- [ ] T010 Mark improve prompt acceptance notes if needed; final commit

---

## Dependencies & Execution Order

- Setup → Foundational docs → US1 tests → US1 route → US2 tests → US2 planner → gate
- US1 and US2 tests can be written in parallel before implementations

## Implementation Strategy

MVP = US1 route reassert. US2 planner throw is same PR defense-in-depth per improve R3.
