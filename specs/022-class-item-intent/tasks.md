# Tasks: Class-Item Intent Lock

**Input**: `/specs/022-class-item-intent/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [ ] T001 Verify docs under `specs/022-class-item-intent/`
- [ ] T002 [P] Skim buildService identity, resolveVariant, exotic-armor records, coverageService, BuildsDebugPage

## Phase 2: Foundational

- [ ] T003 Add `exoticArmorIntent.ts` (detect mode + identity change rules)
- [ ] T004 Centralize exotic slot lookup (shared helper)
- [ ] T005 Checkpoint: typecheck

## Phase 3: US1 Detect (P1)

- [ ] T006 [P] [US1] Failing tests: ClassItem vs classic mode
- [ ] T007 [US1] Wire detection from catalog slot
- [ ] T008 [US1] Tests + gate

## Phase 4: US2 Identity skip (P1)

- [ ] T009 [P] [US2] Failing tests: class-item hash swap no confirm; classic still confirms; mode flip confirms
- [ ] T010 [US2] Gate `identityFieldsChanged` / updateUserBuild
- [ ] T011 [US2] Relax pair armor match in intent mode
- [ ] T012 [US2] Tests + gate

## Phase 5: US3 Perk config + resolve (P1)

- [ ] T013 [P] [US3] Failing tests: class_item selectedPerks on resolved claim
- [ ] T014 [US3] Intent resolve prefers variant class_item + perks; fix coverage slot lookup
- [ ] T015 [US3] Tests + gate

## Phase 6: US4 Debug (P2)

- [ ] T016 [US4] BuildsDebugPage: edit exotic armor + show mode + identity actions
- [ ] T017 [US4] Manual quickstart V4

## Phase 7: Polish

- [ ] T018 [P] Walk quickstart V1–V4
- [ ] T019 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
