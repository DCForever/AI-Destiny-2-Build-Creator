# Tasks: DART-012 Storage Root

**Input**: Design documents from `/specs/dart-012-storage-root/`

**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Path composition + fake/temp base required (constitution Test-First).

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create `packages/storage/` tree (`lib/`, `lib/src/`, `test/`) per plan.md
- [x] T002 Add `packages/storage/pubspec.yaml` (`destiny2_storage`, `path` runtime dep, `test`/`lints` dev, `resolution: workspace`)
- [x] T003 Register `packages/storage` in root `pubspec.yaml` `workspace:` and extend `melos.scripts.analyze` package list

---

## Phase 2: Foundational

- [x] T004 [P] Implement `versionToDirName` in `packages/storage/lib/src/version_dir.dart`
- [x] T005 Implement `StorageRoot` in `packages/storage/lib/src/storage_root.dart` (paths + `windowsAppSupport` factory + `ensureLayout`)
- [x] T006 Barrel export `packages/storage/lib/destiny2_storage.dart`

**Checkpoint**: Library compiles; ready for tests

---

## Phase 3: User Story 1 — Path composition (P1) 🎯 MVP

**Goal**: Canonical paths under injected base  
**Independent Test**: Fake base path unit tests

- [x] T007 [US1] Write `packages/storage/test/storage_root_test.dart` path composition tests (app.db, manifest, entities, users, current-version, version sanitization)
- [x] T008 [US1] Confirm tests pass with fake base only (`dart test packages/storage`)

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Windows app-support layout (P1)

**Goal**: Documented path_provider host path; no CWD `.cache` default  
**Independent Test**: Factory uses application-support string; docs + tests assert not `.cache`

- [x] T009 [US2] Cover `StorageRoot.windowsAppSupport` in tests (base equals injected support path)
- [x] T010 [US2] Document layout + Windows path_provider pattern in `packages/README.md` and align `specs/dart-012-storage-root/quickstart.md`

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Fake FS / ensureLayout (P1)

**Goal**: CI-friendly tests without real AppData  
**Independent Test**: Temp-dir ensureLayout + pure fake paths

- [x] T011 [US3] Add ensureLayout temp-directory test (create + tearDown)
- [x] T012 [US3] Reject empty base path (documented behavior + test)

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T013 Verify pure graph guard still passes (`dart run tool/pure_package_graph_guard.dart`); storage not in pure list
- [x] T014 Run `dart pub get` + `dart test packages/storage` + optional analyze; mark tasks complete
- [x] T015 Commit; merge `dart-012-storage-root` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-012 done, pointer → DART-013)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Package skeleton + StorageRoot API  
2. Fake-base tests first, implement to green  
3. Docs + workspace wiring  
4. Merge and advance roadmap pointer  

## Evidence (implement)

- `dart pub get` — success (workspace + `destiny2_storage`)
- `dart test packages/storage` — **11/11 passed** (fake base composition, windowsAppSupport, empty reject, ensureLayout temp FS)
- `dart analyze --fatal-infos packages/storage` — no issues
- `dart run tool/pure_package_graph_guard.dart` — OK (domain + sandbox_data only)
- `dart run tool/p0_parity_gate.dart` — P0 gate PASSED
