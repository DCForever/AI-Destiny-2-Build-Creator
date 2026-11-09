# Tasks: DART-004 Soft Coverage

**Input**: Design documents from `/specs/dart-004-soft-coverage/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-004-soft-coverage` off `feature/multiplatform-dart`; feature_directory set
- [x] T002 [P] Add pure `SetBonusRecord` model in `packages/domain/lib/src/models/set_bonus.dart`

---

## Phase 2: Foundational evaluators + exports

- [x] T003 Implement `packages/domain/lib/src/evaluators/soft_stat_targets.dart` (normalize, merge, STAT_MAX, exception)
- [x] T004 Implement `packages/domain/lib/src/evaluators/stat_estimate.dart` (estimateLoadoutStats, softStatWarnings)
- [x] T005 Implement `packages/domain/lib/src/evaluators/soft_coverage.dart` (tierForMatches, matchEvidenceLink, evaluateCoverage, CoverageEvalInput)
- [x] T006 Implement `packages/domain/lib/src/evaluators/stat_nudges.dart` (suggestStatNudges, targetsFromAcceptedNudges, StatNudge)
- [x] T007 Export new APIs from `packages/domain/lib/destiny2_domain.dart`; update package description

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Soft coverage (P1) 🎯 MVP

**Goal**: Synergy tiers, set-bonus soft rows, element soft mismatches

- [x] T008 [US1] Write golden tests for tierForMatches, matchEvidenceLink, evaluateCoverage in `packages/domain/test/soft_coverage_test.dart`
- [x] T009 [US1] Cover partial set-bonus + element mismatch + empty softStats when no targets

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Soft stats (P1)

**Goal**: estimate + warnings + normalize/merge targets

- [x] T010 [US2] Extend tests for estimateLoadoutStats incomplete, softStatWarnings below-target only, normalize/merge, coverage softStats attachment

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Hard/soft separation (P1)

**Goal**: Soft never hard-blocks; nudges not auto-applied

- [x] T011 [US3] Tests asserting CoverageResult has no hard-block semantics; soft conditions never emit DomainFailureCodes.pureHardGateCodes; soft APIs pure; stat nudges require accept merge
- [x] T012 [US3] Side-by-side: weak coverage does not produce ConstraintEvaluation hard blocks

**Checkpoint**: Full soft_coverage_test green

---

## Phase 6: Polish & finish

- [x] T013 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T014 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T015 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port pure TS helpers into small evaluator files; one soft_coverage_test.dart grows per user story until parity + separation exit criteria pass.
