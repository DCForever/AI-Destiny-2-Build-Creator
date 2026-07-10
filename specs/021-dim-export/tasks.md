# Tasks: DIM Export

**Input**: `/specs/021-dim-export/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [ ] T001 Verify docs under `specs/021-dim-export/`
- [ ] T002 [P] Skim dimLoadout, dimSync, dim-export-gate, getResolvedVariant, BuildsDebugPage

## Phase 2: Foundational

- [ ] T003 Add `collectVariantMods` helper
- [ ] T004 Add `buildVariantDimLoadout` (+ types reuse)
- [ ] T005 Checkpoint: typecheck

## Phase 3: US1 Gate (P1)

- [ ] T006 [P] [US1] Failing tests: NOT_EQUIP_READY on export
- [ ] T007 [US1] `POST …/dim-export` route with assertEquipReady
- [ ] T008 [US1] Tests + gate

## Phase 4: US2 Payload (P1)

- [ ] T009 [P] [US2] Failing tests: equipped ids, mods, fashion omit, artifact notes
- [ ] T010 [US2] Implement builder mapping + soft-stat constraints
- [ ] T011 [US2] Tests + gate

## Phase 5: US3 Share (P1)

- [ ] T012 [P] [US3] Failing tests: shareUrl mock; 503 without key; jsonOnly 200
- [ ] T013 [US3] Wire DimSyncClient share in route
- [ ] T014 [US3] Tests + gate

## Phase 6: US4 Debug (P2)

- [ ] T015 [US4] BuildsDebugPage: Export to DIM (+ optional jsonOnly)
- [ ] T016 [US4] Manual quickstart V4

## Phase 7: Polish

- [ ] T017 [P] Walk quickstart V1–V4
- [ ] T018 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
