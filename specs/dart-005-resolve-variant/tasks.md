# Tasks: DART-005 Resolve Variant

**Input**: Design documents from `/specs/dart-005-resolve-variant/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Confirm branch `dart-005-resolve-variant` off `feature/multiplatform-dart`; feature_directory set
- [x] T002 [P] Write spec kit docs under `specs/dart-005-resolve-variant/`

---

## Phase 2: Foundational exports

- [x] T003 Implement pure resolve module `packages/domain/lib/src/evaluators/resolve_variant.dart`
- [x] T004 Export resolve APIs from `packages/domain/lib/destiny2_domain.dart`
- [x] T005 Update package description to mention resolve (DART-005)

**Checkpoint**: Package analyzes with new exports

---

## Phase 3: User Story 1 — Conflicts & equipment map (P1) 🎯 MVP

**Goal**: `detectSlotConflicts`, `buildEquipmentMap`, `assertNoSlotConflicts` golden parity

- [x] T006 [US1] Write conflict/map tests in `packages/domain/test/resolve_variant_test.dart`
- [x] T007 [US1] Implement/verify first-writer map + SLOT_CONFLICT assert

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Exotic inject & pair armor (P1)

**Goal**: Exotic claims, effective weapon, pair match, intent mode

- [x] T008 [US2] Extend golden tests for exotic inject, effectiveExoticWeapon, pair match, intent skip
- [x] T009 [US2] Implement helpers to parity with `resolveVariant.test.ts`

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Completeness default vs non-default (P1)

**Goal**: Empty + full combat loadout + branch helper

- [x] T010 [US3] Extend tests for VARIANT_EMPTY, DEFAULT_VARIANT_INCOMPLETE missing list, full pass, non-default partial allowed
- [x] T011 [US3] Implement asserts + `assertVariantCompleteness` + pure `resolveVariantClaims`

**Checkpoint**: Full resolve_variant_test green

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

Port the pure TS surface into one module, grow golden tests per user story until vitest parity + completeness branch coverage is complete.
