# Tasks: DART-032 Flutter Build Identity UI

**Input**: Design documents from `/specs/dart-032-flutter-build-identity-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure format helpers + Flutter widget tests (memory DB). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-032-flutter-build-identity-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm `destiny2_app` + `destiny2_domain` + `destiny2_ui_tokens` deps on windows_host (already present)

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/builds/build_identity_format.dart` (designation list + exotics summary)
- [x] T004 [P] Write `apps/windows_host/test/build_identity_format_test.dart`

**Checkpoint**: Pure helper tests pass

---

## Phase 3: User Story 1+2 — Dual-pane create + identity 🎯 MVP

**Goal**: Builds library list + create with class/synergy types + optional exotic/super pins; detail shows identity  
**Independent Test**: Widget create Hunter + melee → list/detail

- [x] T005 [US1] Implement `builds_library_controller.dart` (user resolve, list/create/update/load)
- [x] T006 [US1/US2] Implement `builds_library_page.dart` dual-pane list + create + identity detail
- [x] T007 [US3] Wire Builds destination in `app.dart`
- [x] T008 [US1/US2/US3] Write `builds_library_page_test.dart` create + zero-synergy + nav cases

**Checkpoint**: Create build with synergy types green

---

## Phase 4: Polish & finish

- [x] T009 Update `apps/windows_host/README.md` + pubspec description for Builds
- [x] T010 Run pure format + builds library flutter tests (15 passed)
- [x] T011 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-032 done, pointer → DART-033

---

## Dependencies & Execution Order

- Setup → Pure helper → Create/identity UI + nav → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure format helpers + tests
2. Controller + dual-pane + nav
3. Merge to integration base
