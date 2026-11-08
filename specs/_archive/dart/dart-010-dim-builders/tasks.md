# Tasks: DART-010 DIM Builders

**Input**: Design documents from `/specs/dart-010-dim-builders/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required.

## Phase 1: Setup

- [x] T001 Confirm branch `dart-010-dim-builders` off `feature/multiplatform-dart`; set `.specify/feature.json` feature_directory
- [x] T002 [P] Write Spec Kit docs under `specs/dart-010-dim-builders/`

---

## Phase 2: Models & constants

- [x] T003 Implement `packages/domain/lib/src/models/dim_loadout.dart` (Dim* types, class/stat constants, toJson helpers, thin fashion/artifact/subclass DTOs)
- [x] T004 Export dim models from `packages/domain/lib/destiny2_domain.dart`
- [x] T005 Update package description to mention DIM builders (DART-010)

**Checkpoint**: Package analyzes with new model exports

---

## Phase 3: User Story 1 — Variant builder golden (P1) 🎯 MVP

**Goal**: `buildVariantDimLoadout` matches TS fixture for equipped pins + mods; fashion/notes/soft stats covered

- [x] T006 [US1] Implement `packages/domain/lib/src/evaluators/dim_builders.dart` (`buildVariantDimLoadout`)
- [x] T007 [US1] Export builders from barrel
- [x] T008 [US1] Write golden tests in `packages/domain/test/dim_builders_test.dart` for primary TS fixture + fashion + notes + soft stats + fixed-id json body

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — equipReady gate (P1)

**Goal**: jsonOnly helper asserts equip-ready then returns `{ loadout }`

- [x] T009 [US2] Implement `buildJsonOnlyDimExport` using `assertEquipReady`
- [x] T010 [US2] Tests: ready → payload; wishlist → `NOT_EQUIP_READY`

**Checkpoint**: US2 tests green

---

## Phase 5: User Story 3 — sockets / exotic / constants (P2)

- [x] T011 [US3] Tests for classType map, socketOverrides from selectedPerks, exoticArmorHash from build_exotic_armor, autoStatMods flags
- [x] T012 [US3] Implement any remaining parameter parity gaps

**Checkpoint**: Full dim_builders_test green

---

## Phase 6: Polish & finish

- [x] T013 Run `dart test packages/domain` and `dart analyze packages/domain`; fix issues
- [x] T014 Verify domain pubspec still has zero IO/UI runtime deps
- [x] T015 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Models → US1 → US2 → US3 → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port TS `buildVariantDimLoadout` + Dim types into pure Dart; gate with existing equip-ready assert; one golden fixture proves jsonOnly body parity.
