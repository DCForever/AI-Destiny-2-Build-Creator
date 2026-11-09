# Tasks: DART-028 App Use Cases Build

**Input**: Design documents from `/specs/dart-028-app-use-cases-build/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: In-memory Drift unit tests. No live Bungie. No CLIENT_SECRET. Soft never auto-applies.

## Phase 1: Setup

- [x] T001 Extend `packages/app/pubspec.yaml` with `destiny2_sandbox_data`; export plan modules from barrel
- [x] T002 [P] Extend `errors.dart` with hard-gate / soft-related use-case codes

---

## Phase 2: Foundational ports + gates

- [x] T003 Implement `hard_gate_ports.dart` (capacity, ability reqs, exotic composition, mod pieces, slots)
- [x] T004 Implement `hard_gates.dart` (identity + variant save assert order)
- [x] T005 Extend `mappers.dart` for subclass kit, build, variant, soft stat targets, designations

**Checkpoint**: Package resolves with `dart pub get`

---

## Phase 3: User Story 1 — Build identity hard gates (P1) 🎯 MVP

**Goal**: Create/update/list/get/delete build with NO_SYNERGY / kit / exotic ability blocks  
**Independent Test**: `build_use_cases_test.dart`

- [x] T006 [US1] Implement `build_use_cases.dart`
- [x] T007 [US1] Write `packages/app/test/build_use_cases_test.dart`
- [x] T008 [US1] Confirm build tests pass

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Variant equipment save (P1)

**Goal**: Expand attachments, validateVariantSave order, rollback on hard fail  
**Independent Test**: `variant_use_cases_test.dart`

- [x] T009 [US2] Implement `variant_use_cases.dart` (expand + validate + update)
- [x] T010 [US2] Write `packages/app/test/variant_use_cases_test.dart`
- [x] T011 [US2] Confirm variant tests pass

**Checkpoint**: Illegal kits hard-block; non-default incomplete allowed

---

## Phase 5: User Story 3 — Soft coverage query (P1)

**Goal**: Query-only soft coverage; never blocks save  
**Independent Test**: `coverage_use_cases_test.dart`

- [x] T012 [US3] Implement `coverage_use_cases.dart`
- [x] T013 [US3] Write `packages/app/test/coverage_use_cases_test.dart`
- [x] T014 [US3] Confirm coverage + non-block save scenarios pass

**Checkpoint**: Exit criteria green

---

## Phase 6: Polish & finish

- [x] T015 Update `packages/README.md` for DART-028 modules
- [x] T016 Run `dart test packages/app` (+ pure graph guard if quick)
- [x] T017 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-028 done, pointer → DART-029

---

## Dependencies & Execution Order

- Setup → Foundation → US1 → US2 → US3 → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Ports + hard gates + mappers  
2. Build use cases + tests  
3. Variant use cases + tests  
4. Soft coverage query + tests  
5. Docs + merge
