# Tasks: DART-031 Flutter Synergy Library UI

**Input**: Design documents from `/specs/dart-031-flutter-synergy-library-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure designation helper + Flutter widget tests (memory DB). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-031-flutter-synergy-library-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm `destiny2_app` + `destiny2_domain` + `destiny2_ui_tokens` deps on windows_host (already present from DART-030)

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/synergies/synergy_designation.dart` (format designation key)
- [x] T004 [P] Write `apps/windows_host/test/synergy_designation_test.dart`

**Checkpoint**: Pure helper tests pass

---

## Phase 3: User Story 1+2 — Dual-pane create + immutable designation 🎯 MVP

**Goal**: Synergy library list + create + edit name/description; designation read-only after create  
**Independent Test**: Widget create + rename keeps type

- [x] T005 [US1] Implement `synergies_library_controller.dart` (user resolve, list/create/update/load)
- [x] T006 [US1] Implement `synergies_library_page.dart` dual-pane list + create + detail (immutable designation)
- [x] T007 [US1/US4] Wire Synergies destination in `app.dart`
- [x] T008 [US1/US2] Write `synergies_library_page_test.dart` create + designation immutable + nav cases

**Checkpoint**: Create synergy + immutable designation green

---

## Phase 4: User Story 3 — Evidence links editor

**Goal**: Add/remove evidence links and persist  
**Independent Test**: Add exotic_armor link → visible after save

- [x] T009 [US3] Evidence links list + add form + remove + save on detail pane / controller
- [x] T010 [US3] Extend widget tests for evidence link add

**Checkpoint**: Exit “evidence links UI”

---

## Phase 5: Polish & finish

- [x] T011 Update `apps/windows_host/README.md` + packages README note for Synergies
- [x] T012 Run pure designation + synergies library flutter tests (11 passed)
- [x] T013 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-031 done, pointer → DART-032

---

## Dependencies & Execution Order

- Setup → Pure helper → Create/edit UI + nav → Evidence links → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure designation format + tests
2. Controller + dual-pane + nav
3. Links editor
4. Merge to integration base
