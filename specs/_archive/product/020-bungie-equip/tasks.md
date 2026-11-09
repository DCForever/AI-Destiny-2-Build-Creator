# Tasks: Bungie Equip

**Input**: `/specs/020-bungie-equip/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [x] T001 Verify docs under `specs/020-bungie-equip/`
- [x] T002 [P] Skim equipReady, syncInventory, characters route, resolveArtifactFashion, BuildsDebugPage

## Phase 2: Foundational

- [x] T003 Add `BungieWriteClient` interface + mock in `src/lib/bungie/writeClient.ts`
- [x] T004 Add `syncIfStale` (~60s) helper
- [x] T005 Checkpoint: typecheck

## Phase 3: US1 Gate + character (P1)

- [x] T006 [P] [US1] Failing tests: NOT_EQUIP_READY; INVALID_CHARACTER
- [x] T007 [US1] Equip route precondition + class filter
- [x] T008 [US1] Tests + gate

## Phase 4: US2 Sync/transfer/apply (P1)

- [x] T009 [P] [US2] Failing tests: plan steps order transfer→equip→artifact→fashion
- [x] T010 [US2] Implement `equipPlan.ts` + HTTP write client stubs/real
- [x] T011 [US2] Orchestrator executes plan with injected client
- [x] T012 [US2] Tests + gate

## Phase 5: US3 Partial status (P1)

- [x] T013 [P] [US3] Failing tests: mid-fail keeps prior ok; status counts
- [x] T014 [US3] Wire EquipStatus response shape
- [x] T015 [US3] Tests + gate

## Phase 6: US4 Debug (P2)

- [x] T016 [US4] BuildsDebugPage: class-filtered characters + Equip button
- [x] T017 [US4] Tests/manual quickstart V4

## Phase 7: Polish

- [x] T018 [P] Walk quickstart V1–V4
- [x] T019 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
