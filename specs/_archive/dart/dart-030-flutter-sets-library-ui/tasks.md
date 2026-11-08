# Tasks: DART-030 Flutter Sets Library UI

**Input**: Design documents from `/specs/dart-030-flutter-sets-library-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure slot mapping + Flutter widget tests (memory DB, preloaded catalog). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-030-flutter-sets-library-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Add `destiny2_app` + `destiny2_domain` deps to `apps/windows_host/pubspec.yaml`

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/sets/set_slot_mapping.dart` (slotsForSetType, validity, catalog bucket map)
- [x] T004 [P] Write `apps/windows_host/test/set_slot_mapping_test.dart`

**Checkpoint**: Pure mapping tests pass

---

## Phase 3: User Story 1 — Dual-pane create/edit 🎯 MVP

**Goal**: Sets library list + create/edit  
**Independent Test**: Widget create + rename

- [x] T005 [US1] Implement `sets_library_controller.dart` (user resolve, list/create/update/load detail)
- [x] T006 [US1] Implement `sets_library_page.dart` dual-pane list + identity editor
- [x] T007 [US1] Wire Sets destination in `app.dart`
- [x] T008 [US1] Write `sets_library_page_test.dart` create/edit + nav cases

**Checkpoint**: Create/edit set green

---

## Phase 4: User Story 2 — Slot fill from catalog/owned

**Goal**: Fill/clear slots via catalog picker  
**Independent Test**: Upsert from preloaded catalog fixture

- [x] T009 [US2] Implement `set_catalog_picker.dart` (All/Owned, optional instance)
- [x] T010 [US2] Slot board Fill/Clear on detail pane; controller upsert/remove
- [x] T011 [US2] Extend widget tests for fill slot + owned empty guidance

**Checkpoint**: Exit “fill slot from catalog/owned”

---

## Phase 5: Polish & finish

- [x] T012 Update packages/README or host README note for Sets (if present)
- [x] T013 Run pure mapping + sets library flutter tests
- [x] T014 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-030 done, pointer → DART-031

---

## Dependencies & Execution Order

- Setup → Pure mapping → Create/edit UI → Catalog pick fill → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure slot map + tests
2. Controller + dual-pane + nav
3. Picker + fill/clear
4. Merge to integration base
