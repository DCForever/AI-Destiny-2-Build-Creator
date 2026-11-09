# Tasks: DART-008 Optimizer Core

**Input**: Design documents from `/specs/dart-008-optimizer-core/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-008-optimizer-core` off `feature/multiplatform-dart`; set feature_directory
- [x] T002 [P] Write spec kit docs under `specs/dart-008-optimizer-core/`

---

## Phase 2: Foundational types & exports

- [x] T003 Implement pure optimizer models in `packages/domain/lib/src/models/optimizer.dart`
- [x] T004 Implement kit constraints in `packages/domain/lib/src/evaluators/optimizer_constraints.dart`
- [x] T005 Implement score helpers in `packages/domain/lib/src/evaluators/optimizer_score.dart`
- [x] T006 Implement prune in `packages/domain/lib/src/evaluators/optimizer_prune.dart`
- [x] T007 Implement enumerate in `packages/domain/lib/src/evaluators/optimizer_enumerate.dart`
- [x] T008 Export optimizer APIs from `packages/domain/lib/destiny2_domain.dart`
- [x] T009 Update package description to mention optimizer-core (DART-008)

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Enumerate + truncation (P1) 🎯 MVP

**Goal**: groupBySlot, enumerateKits, hard constraints, maxCombinations truncation

- [x] T010 [US1] Write enumerate + constraints golden tests in `packages/domain/test/optimizer_core_test.dart`
- [x] T011 [US1] Implement/verify enumerate + isKitValid parity with TS

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Prune (P1)

**Goal**: top-K, locked exotic retain, set-bonus family retain

- [x] T012 [US2] Add prune fixtures to `optimizer_core_test.dart`
- [x] T013 [US2] Implement/verify prunePiecesForSlot / prunePiecesBySlot

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Score (P1)

**Goal**: estimate, priorities, compare, soft thresholds, incomplete

- [x] T014 [US3] Add score fixtures to `optimizer_core_test.dart`
- [x] T015 [US3] Implement/verify score helpers parity

**Checkpoint**: Full optimizer_core_test green

---

## Phase 6: Polish & finish

- [x] T016 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T017 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T018 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port pure TS surfaces into domain modules; grow golden tests per user story until vitest parity + truncation is complete.
