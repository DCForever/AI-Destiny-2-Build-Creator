# Tasks: DART-009 Static Sandbox Data

**Input**: Design documents from `/specs/dart-009-static-sandbox-data/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Golden unit tests required.

## Phase 1: Setup

- [x] T001 Confirm branch `dart-009-static-sandbox-data` off `feature/multiplatform-dart`; set `.specify/feature.json` feature_directory
- [x] T002 [P] Write Spec Kit docs under `specs/dart-009-static-sandbox-data/`

---

## Phase 2: Package scaffold

- [x] T003 Create `packages/sandbox_data/pubspec.yaml` (SDK-only runtime deps)
- [x] T004 Add `packages/sandbox_data` to root workspace `pubspec.yaml`
- [x] T005 Create barrel `packages/sandbox_data/lib/destiny2_sandbox_data.dart`

**Checkpoint**: `dart pub get` resolves sandbox_data

---

## Phase 3: User Story 1 — Core tables (P1) 🎯 MVP

**Goal**: Stat benefits, synergy verbs/elements, exotic ability requirements

- [x] T006 [US1] Implement `armor_stat_name.dart` + `stat_benefits.dart` with `computeBenefitsAt`
- [x] T007 [US1] Implement `synergy_elements.dart` + `synergy_verbs.dart`
- [x] T008 [US1] Implement `exotic_ability_requirements.dart`
- [x] T009 [US1] Export core APIs from barrel
- [x] T010 [US1] Write golden tests for benefits, verbs, exotic lookup in `test/sandbox_data_test.dart`

**Checkpoint**: US1 tests green

---

## Phase 4: User Story 2 — Supporting tables (P1)

**Goal**: Archetypes, champions, activity, timings, weapons, tags, subclasses

- [x] T011 [US2] Implement `armor_archetypes.dart`
- [x] T012 [US2] Implement `champion_counters.dart`
- [x] T013 [US2] Implement `activity_rules.dart` (artifact gate)
- [x] T014 [US2] Implement `ability_timings.dart`
- [x] T015 [US2] Implement `weapon_types.dart`, `concept_tags.dart`, `subclasses.dart`
- [x] T016 [US2] Export supporting APIs; extend golden tests

**Checkpoint**: Full sandbox_data_test green

---

## Phase 5: User Story 3 — Update process (P1)

- [x] T017 [US3] Write `docs/sandbox-data-update-process.md`
- [x] T018 [US3] Update `packages/README.md` layout for sandbox_data package

---

## Phase 6: Polish & finish

- [x] T019 Run `dart test packages/sandbox_data` and `dart analyze packages/sandbox_data`; fix issues
- [x] T020 Verify domain still green (`dart test packages/domain`)
- [x] T021 Mark tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Scaffold → US1 → US2 → US3 → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Port TS static tables into pure Dart modules; golden tests mirror vitest cases; document sandbox patch workflow.
