# Tasks: DART-034 Flutter Soft Guidance UI

**Input**: Design documents from `/specs/dart-034-flutter-soft-guidance-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure format helpers + Flutter widget/controller tests (memory DB). No live Bungie. No CLIENT_SECRET. Soft never auto-applies.

## Phase 1: Setup

- [x] T001 Create `specs/dart-034-flutter-soft-guidance-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm `queryVariantCoverage` + `UpdateBuildCommand.softStatTargets` available to windows_host

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/builds/soft_guidance_format.dart` (tier labels, tone keys, target summary, advisory caption)
- [x] T004 [P] Write `apps/windows_host/test/soft_guidance_format_test.dart`

**Checkpoint**: Pure helper tests pass

---

## Phase 3: User Stories 1–3 — Soft guidance UI 🎯 MVP

**Goal**: Coverage chips; soft stat targets explicit save; never auto-apply  
**Independent Test**: Controller/widget tests with memory DB

- [x] T005 [US1] Extend `builds_library_controller.dart` with coverage query after compose load; expose synergy/set-bonus/element/softStats
- [x] T006 [US2] Controller soft-target draft + `saveSoftStatTargets` via `updateUserBuild`
- [x] T007 [US1/US2/US3] Extend `builds_library_page.dart` with Soft guidance section (chips, targets form, advisory caption)
- [x] T008 [US1/US2/US3] Write `soft_guidance_page_test.dart` (missing chip, target save, no auto-apply)

**Checkpoint**: Soft chips + targets + non-auto-apply green

---

## Phase 4: Polish & finish

- [x] T009 Update `apps/windows_host/README.md` + pubspec description for soft guidance
- [x] T010 Run soft guidance + related flutter tests
- [x] T011 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-034 done, pointer → DART-035; note P3 gate

---

## Dependencies & Execution Order

- Setup → Pure helper → Controller + UI + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure format helpers + tests
2. Controller coverage + soft targets
3. Soft guidance UI section
4. Widget tests for exit criteria
5. Merge to integration base
