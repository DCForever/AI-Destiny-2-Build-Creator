# Tasks: DART-006 Equip Ready

**Input**: Design documents from `/specs/dart-006-equip-ready/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-006-equip-ready` off `feature/multiplatform-dart`; set feature_directory
- [x] T002 [P] Write spec kit docs under `specs/dart-006-equip-ready/`

---

## Phase 2: Foundational exports

- [x] T003 Implement pure equip-ready module `packages/domain/lib/src/evaluators/equip_ready.dart`
- [x] T004 Export equip-ready APIs from `packages/domain/lib/destiny2_domain.dart`
- [x] T005 Update package description to mention equip-ready (DART-006)

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Wishlist never equip-ready (P1) 🎯 MVP

**Goal**: Wishlist claims → not ready; assert throws NOT_EQUIP_READY; empty equipment not ready

- [x] T006 [US1] Write wishlist / empty / assert tests in `packages/domain/test/equip_ready_test.dart`
- [x] T007 [US1] Implement/verify `computeEquipReady` + `assertEquipReady` wishlist path

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Owned pins equip-ready (P1)

**Goal**: Matching pins ready; empty gaps ignored; inventory index builder

- [x] T008 [US2] Extend golden tests for full pin ready + single-slot ready with empty gaps
- [x] T009 [US2] Implement/verify `buildInventoryPinIndex` + pinned path

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Stale pins / post-sync (P1)

**Goal**: instance_missing, hash_mismatch, post-sync ready→stale and happy path

- [x] T010 [US3] Extend tests for stale reasons + post-sync scenarios
- [x] T011 [US3] Implement/verify stale status rules to parity with TS

**Checkpoint**: Full equip_ready_test green

---

## Phase 6: Polish & finish

- [x] T012 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T013 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T014 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- Single evaluator file + single test file
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port the pure TS surface into one module, grow golden tests per user story until vitest parity + hash_mismatch coverage is complete.
