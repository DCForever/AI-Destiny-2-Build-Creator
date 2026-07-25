# Tasks: DART-013 Drift Schema

**Input**: Design documents from `/specs/dart-013-drift-schema/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Clean create + unique/FK required (constitution Test-First).

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create `packages/db/` tree (`lib/`, `lib/src/`, `test/`) per plan.md
- [x] T002 Add `packages/db/pubspec.yaml` (`destiny2_db`, drift/sqlite3/path, drift_dev/build_runner/test/lints, `resolution: workspace`)
- [x] T003 Register `packages/db` in root `pubspec.yaml` `workspace:` and extend `melos.scripts.analyze` package list

---

## Phase 2: Foundational — schema definitions

- [x] T004 [P] Implement Drift table classes in `packages/db/lib/src/tables.dart` (core tables + indexes/uniques)
- [x] T005 Implement `AppDatabase` + memory/file factories + FK pragma in `packages/db/lib/src/app_database.dart`
- [x] T006 [P] Add `schema_notes.dart` critical unique/index documentation constants
- [x] T007 Run `dart run build_runner build` in `packages/db`; commit generated `app_database.g.dart`
- [x] T008 Barrel export `packages/db/lib/destiny2_db.dart`

**Checkpoint**: Package analyzes; ready for tests

---

## Phase 3: User Story 1 — Clean empty DB (P1) 🎯 MVP

**Goal**: Schema creates all core tables with FK ON  
**Independent Test**: Memory DB table list + FK failure

- [x] T009 [US1] Write clean-create + FK tests in `packages/db/test/schema_test.dart`
- [x] T010 [US1] Confirm `dart test packages/db` green for US1 cases

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Critical uniques / indexes (P1)

**Goal**: Product-parity uniques; documented notes  
**Independent Test**: Unique violation inserts + index presence/docs

- [x] T011 [US2] Tests for inventory (user, instance_id), sets (user, type, name), and other critical uniques
- [x] T012 [US2] Assert supporting indexes exist (PRAGMA index_list) and RESTRICT attach semantics
- [x] T013 [US2] Align packages/README + data-model notes

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — File path open (P2)

**Goal**: Temp-file create/reopen  
**Independent Test**: File factory round-trip

- [x] T014 [US3] Temp-file open/close/reopen test

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T015 Verify pure graph guard still passes; `destiny2_db` not in pure list
- [x] T016 Run `dart pub get` + `dart test packages/db` (+ optional analyze); mark tasks complete
- [ ] T017 Commit; merge `dart-013-drift-schema` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-013 done, pointer → DART-014)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Package skeleton + Drift tables for product current schema  
2. Codegen + clean-create tests  
3. Unique/index/RESTRICT tests + notes  
4. File factory test + finish merge  
