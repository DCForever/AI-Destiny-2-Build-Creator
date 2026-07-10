# Tasks: Soft Guidance & Coverage Indicators

**Input**: `/specs/017-soft-guidance/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [x] T001 Verify docs under `specs/017-soft-guidance/`
- [x] T002 [P] Skim `resolveVariant.ts`, synergy link schemas, `suggestSets.ts`, set-bonus helpers

## Phase 2: Foundational

- [x] T003 Add `src/lib/builds/coverage.ts` types + `matchEvidenceLink` stubs
- [x] T004 Checkpoint: typecheck compiles

## Phase 3: US1 Synergy tiers (P1)

- [x] T005 [P] [US1] Failing tests all/some/none → supported/weak/missing in `coverage.test.ts`
- [x] T006 [US1] Implement synergy tier evaluation in `coverage.ts`
- [x] T007 [US1] Wire `GET .../coverage` route returning synergy tiers
- [x] T008 [US1] Fetch Coverage on `BuildsDebugPage.tsx`
- [x] T009 [US1] Tests + gate

## Phase 4: US2 Breakdown (P1)

- [x] T010 [P] [US2] Failing tests for set-bonus soft rows + element mismatch rows
- [x] T011 [US2] Implement set-bonus + element soft rows + hints in `coverage.ts`
- [x] T012 [US2] Ensure response has no softStats; debug shows breakdown
- [x] T013 [US2] Tests + gate

## Phase 5: US3 Suggest gap bias (P2)

- [x] T014 [P] [US3] Failing tests gap-closing sets rank above non-closing peers
- [x] T015 [US3] Add gap bonus in `suggestSets.ts` (exclude fashion)
- [x] T016 [US3] Tests + gate

## Phase 6: US4 Soft save (P1)

- [x] T017 [P] [US4] Regression: weak coverage does not block non-default save; hard exotic still fails
- [x] T018 [US4] Confirm coverage not called from save/validate paths
- [x] T019 [US4] Tests + gate

## Phase 7: Polish

- [x] T020 [P] Walk quickstart V1–V4
- [x] T021 Final `npm run gate`; finish-spec merge to `feature/overhall`
