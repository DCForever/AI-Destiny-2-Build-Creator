# Tasks: DART-011 Domain Parity Gate

**Input**: Design documents from `/specs/dart-011-domain-parity-gate/`

**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Graph guard unit tests required; aggregate suite must stay green.

## Phase 1: Setup

- [x] T001 Confirm branch `dart-011-domain-parity-gate` off `feature/multiplatform-dart`; set `.specify/feature.json` feature_directory
- [x] T002 [P] Write Spec Kit docs under `specs/dart-011-domain-parity-gate/`

---

## Phase 2: User Story 2 — Graph guard (P1)

**Goal**: Fail pure packages that declare forbidden IO/UI runtime deps

- [x] T003 [US2] Implement pure package list + forbidden deps in `tool/pure_packages.dart`
- [x] T004 [US2] Implement scanner/CLI library in `tool/pure_package_graph_guard.dart`
- [x] T005 [US2] Unit tests in `tool/test/pure_package_graph_guard_test.dart` (clean pass + forbidden fail)
- [x] T006 [US2] CLI entry runnable as `dart run tool/pure_package_graph_guard.dart`

**Checkpoint**: Guard passes on live packages; unit tests green

---

## Phase 3: User Story 1 — Aggregate pure suite (P1) 🎯 MVP

**Goal**: Single command runs full pure suite

- [x] T007 [US1] Implement `tool/run_all_pure_tests.dart` (dart test each pure package)
- [x] T008 [US1] Implement `tool/p0_parity_gate.dart` (guard then full suite; aggregate exit)
- [x] T009 [US1] Wire Melos scripts in root `pubspec.yaml`: `test`, `graph-guard`, `p0-gate` non-interactive root runs

**Checkpoint**: `dart run tool/p0_parity_gate.dart` exits 0

---

## Phase 4: User Story 3 — Docs (P2)

- [x] T010 [US3] Document P0 gate in `packages/README.md` and slice `quickstart.md`
- [x] T011 [US3] Note graph guard automation replaces “planned for DART-011” wording

**Checkpoint**: Docs name single command

---

## Phase 5: Polish & finish

- [x] T012 Run `dart run tool/p0_parity_gate.dart` and `dart test tool/test`; fix issues
- [x] T013 Mark all tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer to DART-012

---

## Dependencies & Execution Order

- Setup → US2 guard → US1 aggregate → US3 docs → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Land guard first (testable purity), then aggregate runner, then Melos aliases and docs. No domain evaluator changes.
