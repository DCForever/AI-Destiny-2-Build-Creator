# Tasks: DART-002 Models

**Input**: Design documents from `/specs/dart-002-models/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Model unit tests required (constitution Test-First for new behavior).

## Phase 1: Setup

- [x] T001 Create `packages/domain/lib/src/models/` directory and update barrel export plan
- [x] T002 [P] Align `packages/README.md` to mention models surface (still pure, zero IO)

---

## Phase 2: Foundational enums & failure codes

- [x] T003 [P] Implement equipment/set/claim/pin enums with wire names in `packages/domain/lib/src/models/equipment.dart` and `pin.dart` (kinds only if co-located)
- [x] T004 [P] Implement `DomainFailureCodes` in `packages/domain/lib/src/models/failure_codes.dart`
- [x] T005 [P] Implement armor stat / guardian class / coverage tier enums in soft_stats/coverage modules

**Checkpoint**: Enums and codes compile

---

## Phase 3: User Story 1 — Claims & pins (P1) 🎯 MVP

**Goal**: SlotClaim, ResolvedVariantEquipment, PinStatus, EquipReadyResult

- [x] T006 [US1] Implement `slot_claim.dart`, `resolved_variant.dart`, pin result types in `pin.dart`
- [x] T007 [US1] Write tests for claim/pin construction, equality, wire names in `packages/domain/test/models_test.dart`

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Failure codes & constraint envelopes (P1)

**Goal**: HardBlock, SoftWarning, ConstraintEvaluation + code parity

- [x] T008 [US2] Implement `constraints.dart`
- [x] T009 [US2] Assert core hard-gate code string parity in tests

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — Kits, coverage, library shapes (P2)

**Goal**: Kits, coverage tree, build/variant/set/synergy shapes

- [x] T010 [P] [US3] Implement `kit.dart`, `coverage.dart`, `soft_stats.dart`
- [x] T011 [P] [US3] Implement `synergy.dart`, `library.dart`
- [x] T012 [US3] Export all models from `packages/domain/lib/destiny2_domain.dart`
- [x] T013 [US3] Extend `models_test.dart` for kits, coverage, library shapes; keep soft types distinct from hard blocks

**Checkpoint**: US3 tests green

---

## Phase 6: Polish & finish

- [x] T014 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T015 Verify domain pubspec has no IO/UI runtime deps
- [x] T016 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- US2/US3 can partly parallel after foundational enums
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Ship US1 first (claims/pins), then codes, then remaining shapes; single package test file for parity assertions.
