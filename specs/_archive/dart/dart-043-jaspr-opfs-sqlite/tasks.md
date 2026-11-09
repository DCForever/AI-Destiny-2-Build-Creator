# Tasks: DART-043 Jaspr OPFS SQLite

**Input**: Design documents from `/specs/dart-043-jaspr-opfs-sqlite/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `apps/web_host` + `packages/db` if open path changed. No live Bungie. No CLIENT_SECRET. No Next.

## Phase 1: Setup

- [x] T001 Create `specs/dart-043-jaspr-opfs-sqlite/` docs + set `.specify/feature.json`
- [x] T002 [P] Write limits doc `docs/multiplatform-dart-web-opfs-limits.md`
- [x] T003 [P] Add `apps/web_host/tool/fetch_drift_web_assets.ps1` and fetch wasm/worker into `web/`

---

## Phase 2: Foundational — web-safe destiny2_db

**Goal**: Schema package importable without unconditional native/IO  
**Independent Test**: `dart test` in packages/db still green

- [x] T004 Refactor `packages/db/lib/src/app_database.dart` to conditional connection openers
- [x] T005 Export/open wiring; verify memory/file factories on native; web stubs

**Checkpoint**: packages/db tests pass

---

## Phase 3: User Story 2 — Single-tab writer lock (P1) 🎯

**Goal**: Exclusive writer; second session blocked  
**Independent Test**: `tab_writer_lock_test.dart`

- [x] T006 Implement pure `TabWriterCoordinator` + `TabLockBackend` + memory backend in `apps/web_host/lib/db/`
- [x] T007 [P] Write `test/tab_writer_lock_test.dart` (writer, blocked second, reacquire after release)
- [x] T008 Implement browser tab lock backend (localStorage heartbeat / js_interop)

---

## Phase 4: User Story 1 — WASM open + bootstrap (P1)

**Goal**: Writer opens Drift WASM; status model  
**Independent Test**: bootstrap unit test with fake opener

- [x] T009 Add `destiny2_db` + `drift` deps to `apps/web_host/pubspec.yaml`
- [x] T010 Implement `WebDbSessionStatus` + `WebDatabaseBootstrap` (lock → open/skip)
- [x] T011 Implement wasm opener (conditional / browser path) using `WasmDatabase.open`
- [x] T012 Wire bootstrap from app/main; inject status into Settings

---

## Phase 5: Settings UX + docs polish

- [x] T013 Update Settings page DB panel for writer / blocked / error / loading
- [x] T014 Write Settings status component tests
- [x] T015 Update `apps/web_host/README.md` + packages README note for DART-043
- [x] T016 Mark tasks complete; run tests

**Checkpoint**: `dart test` web_host green; db green

---

## Phase 6: Finish

- [x] T017 Commit remaining work on `dart-043-jaspr-opfs-sqlite`
- [x] T018 Merge into `feature/multiplatform-dart` (--no-edit); roadmap DART-043 done; pointer → DART-044; commit base

---

## Dependencies & Execution Order

- Setup → db web-safe → lock → bootstrap/open → Settings/docs → finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec + limits + assets script  
2. Conditional db open  
3. Lock tests then impl  
4. Bootstrap + Settings  
5. Merge + roadmap (next: DART-044 jaspr-entity-bundles)
