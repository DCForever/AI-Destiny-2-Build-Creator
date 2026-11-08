# Tasks: Class-Item Intent Lock

**Input**: `/specs/022-class-item-intent/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [x] T001 Verify docs under `specs/022-class-item-intent/`
- [x] T002 [P] Skim buildService identity, resolveVariant, exotic-armor records, coverageService, BuildsDebugPage

## Phase 2: Foundational

- [x] T003 Add `exoticArmorIntent.ts` (detect mode + identity change rules)
- [x] T004 Centralize exotic slot lookup (shared helper)
- [x] T005 Checkpoint: typecheck

## Phase 3: US1 Detect (P1)

- [x] T006 [P] [US1] Failing tests: ClassItem vs classic mode
- [x] T007 [US1] Wire detection from catalog slot
- [x] T008 [US1] Tests + gate

## Phase 4: US2 Identity skip (P1)

- [x] T009 [P] [US2] Failing tests: class-item hash swap no confirm; classic still confirms; mode flip confirms
- [x] T010 [US2] Gate `identityFieldsChanged` / updateUserBuild
- [x] T011 [US2] Relax pair armor match in intent mode
- [x] T012 [US2] Tests + gate

## Phase 5: US3 Perk config + resolve (P1)

- [x] T013 [P] [US3] Failing tests: class_item selectedPerks on resolved claim
- [x] T014 [US3] Intent resolve prefers variant class_item + perks; fix coverage slot lookup
- [x] T015 [US3] Tests + gate

## Phase 6: US4 Debug (P2)

- [x] T016 [US4] BuildsDebugPage: edit exotic armor + show mode + identity actions
- [x] T017 [US4] Manual quickstart V4

## Phase 7: Polish

- [x] T018 [P] Walk quickstart V1–V4
- [x] T019 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
