# Tasks: Bungie Equip

**Input**: `/specs/020-bungie-equip/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [ ] T001 Verify docs under `specs/020-bungie-equip/`
- [ ] T002 [P] Skim equipReady, syncInventory, characters route, resolveArtifactFashion, BuildsDebugPage

## Phase 2: Foundational

- [ ] T003 Add `BungieWriteClient` interface + mock in `src/lib/bungie/writeClient.ts`
- [ ] T004 Add `syncIfStale` (~60s) helper
- [ ] T005 Checkpoint: typecheck

## Phase 3: US1 Gate + character (P1)

- [ ] T006 [P] [US1] Failing tests: NOT_EQUIP_READY; INVALID_CHARACTER
- [ ] T007 [US1] Equip route precondition + class filter
- [ ] T008 [US1] Tests + gate

## Phase 4: US2 Sync/transfer/apply (P1)

- [ ] T009 [P] [US2] Failing tests: plan steps order transfer→equip→artifact→fashion
- [ ] T010 [US2] Implement `equipPlan.ts` + HTTP write client stubs/real
- [ ] T011 [US2] Orchestrator executes plan with injected client
- [ ] T012 [US2] Tests + gate

## Phase 5: US3 Partial status (P1)

- [ ] T013 [P] [US3] Failing tests: mid-fail keeps prior ok; status counts
- [ ] T014 [US3] Wire EquipStatus response shape
- [ ] T015 [US3] Tests + gate

## Phase 6: US4 Debug (P2)

- [ ] T016 [US4] BuildsDebugPage: class-filtered characters + Equip button
- [ ] T017 [US4] Tests/manual quickstart V4

## Phase 7: Polish

- [ ] T018 [P] Walk quickstart V1–V4
- [ ] T019 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
