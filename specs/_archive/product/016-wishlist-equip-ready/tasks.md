# Tasks: Wishlist Desired Rolls & Equip-Ready Pins

**Input**: Design documents from `/specs/016-wishlist-equip-ready/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Test-first; green `npm run gate` at each story checkpoint.

## Phase 1: Setup

- [x] T001 Verify docs under `specs/016-wishlist-equip-ready/` and note touchpoints from `plan.md`
- [x] T002 [P] Skim `resolveVariant.ts`, `attachmentService.ts`, set item schemas, inventory list helpers for pin extension points

## Phase 2: Foundational

- [x] T003 Extend `SnapshotConfig` + `buildSnapshotConfigs` to include optional `instanceId` in `src/lib/builds/attachmentService.ts` / variant repository types
- [x] T004 Propagate `instanceId` on `ExpandedSetItem` / `SlotClaim` / live `itemsToSlotClaims` in `src/lib/builds/resolveVariant.ts`
- [x] T005 [P] Add `NOT_EQUIP_READY` to `src/lib/api/errors.ts`
- [x] T006 Checkpoint: typecheck compiles with pin fields present (no readiness behavior yet)

## Phase 3: US1 Wishlist desired rolls (P1)

### Tests

- [x] T007 [P] [US1] Failing tests: set item / attachment save without instanceId retains desired roll in `src/lib/sets/` or `src/lib/builds/` tests
- [x] T008 [P] [US1] Failing tests: resolved claim without instanceId is wishlist-shaped in resolve/equipReady tests

### Implementation

- [x] T009 [US1] Ensure wishlist path (null instanceId) remains valid through attach/resolve in builds/sets services
- [x] T010 [US1] Document/verify Sets debug already supports catalog-only attach; note gaps only
- [x] T011 [US1] US1 tests green + `npm run gate`

## Phase 4: US2 Pin status & equip-ready (P1)

### Tests

- [x] T012 [P] [US2] Failing unit tests for `computeEquipReady` wishlist/pinned/stale matrix in `src/lib/builds/equipReady.test.ts`
- [x] T013 [P] [US2] Failing tests: non-default empty slots ignored for readiness

### Implementation

- [x] T014 [US2] Implement `computeEquipReady` in `src/lib/builds/equipReady.ts`
- [x] T015 [US2] Wire inventory lookup + equipReady/pinStatuses into `getResolvedVariant` / resolved route
- [x] T016 [US2] Show equipReady + pinStatuses on `BuildsDebugPage.tsx` after Fetch Resolved
- [x] T017 [US2] US2 tests green + `npm run gate`

## Phase 5: US3 Equip/DIM gates (P1)

### Tests

- [x] T018 [P] [US3] Failing tests for `assertEquipReady` / gate helper not-ready vs ready

### Implementation

- [x] T019 [US3] Implement shared gate helper throwing/returning `NOT_EQUIP_READY`
- [x] T020 [US3] Add `equip-gate` and `dim-export-gate` routes under `src/app/api/user/builds/[id]/variants/[variantId]/`
- [x] T021 [US3] Add Check equip gate / Check DIM gate buttons on `BuildsDebugPage.tsx`
- [x] T022 [US3] US3 tests green + `npm run gate`

## Phase 6: US4 Stale pins (P2)

### Tests

- [x] T023 [P] [US4] Failing tests: missing inventory instance â†’ stale; re-pin clears

### Implementation

- [x] T024 [US4] Ensure evaluate-on-read stale logic covers missing + hash mismatch in `equipReady.ts`
- [x] T025 [US4] Confirm re-pin via existing set-item upsert clears stale on next resolve
- [x] T026 [US4] US4 tests green + `npm run gate`

## Phase 7: Polish

- [x] T027 [P] Walk `quickstart.md` V1–V4; note gaps
- [x] T028 [P] Index `NOT_EQUIP_READY` in `specs/business-rules.md` if needed
- [x] T029 Final `npm run gate`; mark roadmap slice 2 done after finish-spec

## Notes

- Pin write path reuses Sets debug InstanceCarousel
- Composition (015) remains independent of equip-ready
- Commit only when story tests + gate are green
