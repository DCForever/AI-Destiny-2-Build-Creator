# Tasks: Soft Stat Targets

**Input**: `/specs/019-soft-stat-targets/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [ ] T001 Verify docs under `specs/019-soft-stat-targets/`
- [ ] T002 [P] Skim `statBenefits.ts`, `coverage.ts`, `buildRepository`, inventory `stat_values`, BuildsDebugPage

## Phase 2: Foundational

- [ ] T003 Add `soft_stat_targets` column + migration on `builds`
- [ ] T004 Add parse/validate helpers in `src/lib/builds/softStatTargets.ts` (ArmorStatName, 1–200)
- [ ] T005 Checkpoint: typecheck

## Phase 3: US1 Targets (P1)

- [ ] T006 [P] [US1] Failing tests set/clear/reject invalid targets
- [ ] T007 [US1] Wire build schemas + repository + updateUserBuild (not identity)
- [ ] T008 [US1] BuildsDebugPage: six target inputs + Save targets
- [ ] T009 [US1] Tests + gate

## Phase 4: US2 Warnings (P1)

- [ ] T010 [P] [US2] Failing tests: below-target → softStats; meet target → no row
- [ ] T011 [US2] Implement `statEstimate.ts` (best-effort; incomplete flag)
- [ ] T012 [US2] Extend `coverage.ts` / `coverageService` with targets, estimate, softStats
- [ ] T013 [US2] Update 017 “no softStats” test; Fetch Coverage shows new fields
- [ ] T014 [US2] Tests + gate

## Phase 5: US3 Nudges (P2)

- [ ] T015 [P] [US3] Failing tests nudge list + accept merge without lowering
- [ ] T016 [US3] `statNudges.ts` + GET suggest-stat-targets + accept on PATCH
- [ ] T017 [US3] Debug: Suggest / Accept nudges
- [ ] T018 [US3] Tests + gate

## Phase 6: US4 Soft coexistence (P2)

- [ ] T019 [P] [US4] Regression: softStats + element mismatch soft; save not blocked; targets ≠ identity
- [ ] T020 [US4] Tests + gate

## Phase 7: Polish

- [ ] T021 [P] Walk quickstart V1–V4
- [ ] T022 Final `npm run gate`; finish-spec; **update Domain Slice Loop canvas**
