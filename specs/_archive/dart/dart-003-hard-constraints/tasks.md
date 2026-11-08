# Tasks: DART-003 Hard Constraints

**Input**: Design documents from `/specs/dart-003-hard-constraints/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-003-hard-constraints` off `feature/multiplatform-dart`; feature_directory set
- [x] T002 [P] Create `packages/domain/lib/src/evaluators/` directory

---

## Phase 2: Foundational exports

- [x] T003 Implement pure evaluators module `packages/domain/lib/src/evaluators/destiny_build_constraints.dart` (all functions + private helpers)
- [x] T004 Export evaluators from `packages/domain/lib/destiny2_domain.dart`
- [x] T005 [P] Add dartdoc for `capacityResolved` on evaluator + ensure `SubclassKitEvalInput` docs remain accurate

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Exotic limits & mod energy (P1) 🎯 MVP

**Goal**: `evaluateExoticLimits`, `evaluateModEnergy` golden parity

- [x] T006 [US1] Write golden tests for exotic limits + mod energy in `packages/domain/test/hard_constraints_test.dart`
- [x] T007 [US1] Verify messages/codes match TS fixtures (dedupe, invalid hashes, over/under capacity)

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Subclass kit & capacityResolved (P1)

**Goal**: Aspect/fragment hard blocks with capacityResolved skip semantics

- [x] T008 [US2] Extend golden tests for aspect over max, fragments over/at capacity, capacityResolved false
- [x] T009 [US2] Confirm documentation in research.md/quickstart.md matches implementation

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Ability match, synergy, merge (P2)

**Goal**: Exotic ability match + synergy requirement + merge helper

- [x] T010 [US3] Extend golden tests for ability mismatch, pinned super, no-op requirements, synergy empty/non-empty, merge
- [x] T011 [US3] Soft warning only with hard mismatch path covered

**Checkpoint**: Full hard_constraints_test green

---

## Phase 6: Polish & finish

- [x] T012 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T013 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T014 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- US1–US3 share one evaluator file and one test file
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Implement the full TS module in one evaluator file, then grow the golden test groups per user story until vitest parity is complete.
