# Tasks: DART-007 Finish Gaps

**Input**: Design documents from `/specs/dart-007-finish-gaps/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-007-finish-gaps` off `feature/multiplatform-dart`; set feature_directory
- [x] T002 [P] Write spec kit docs under `specs/dart-007-finish-gaps/`

---

## Phase 2: Foundational exports

- [x] T003 Implement pure finish gaps module `packages/domain/lib/src/evaluators/finish_gaps.dart`
- [x] T004 Implement pure next-slot module `packages/domain/lib/src/evaluators/finish_next_slot.dart`
- [x] T005 Export finish APIs from `packages/domain/lib/destiny2_domain.dart`
- [x] T006 Update package description to mention finish-gaps (DART-007)

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Gap evaluation parity (P1) 🎯 MVP

**Goal**: Ordered gaps, statuses, covering preference, mod soft, nextActionable skips

- [x] T007 [US1] Write finishGaps golden tests in `packages/domain/test/finish_gaps_test.dart`
- [x] T008 [US1] Implement/verify `evaluateFinishGaps` parity with TS

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Default vs non-default stability (P1)

**Goal**: Identical gap lists for default and non-default fixtures

- [x] T009 [US2] Add paired default/non-default fixtures asserting gap list equality
- [x] T010 [US2] Confirm `isDefaultVariant` is echo-only (no status math)

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Next-slot helpers (P1)

**Goal**: fill order, armor_optimize, snapshot category, create actions

- [x] T011 [US3] Extend tests for finishNextSlot helpers
- [x] T012 [US3] Implement/verify resolvePostMutationStep and helpers

**Checkpoint**: Full finish_gaps_test green

---

## Phase 6: Polish & finish

- [x] T013 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T014 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T015 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- Two evaluator files + one test file
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port pure TS surfaces into domain modules; grow golden tests per user story until vitest parity + default stability is complete.
