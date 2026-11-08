# Tasks: DART-033 Flutter Variant Compose UI

**Input**: Design documents from `/specs/dart-033-flutter-variant-compose-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure format helpers + Flutter widget/controller tests (memory DB). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-033-flutter-variant-compose-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm `destiny2_app` variant/attachment/set use cases available to windows_host (already present)

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/builds/variant_compose_format.dart` (pin label, attachment summary)
- [x] T004 [P] Write `apps/windows_host/test/variant_compose_format_test.dart`

**Checkpoint**: Pure helper tests pass

---

## Phase 3: User Stories 1–4 — Variant compose 🎯 MVP

**Goal**: List/create/select variants; attach/detach sets; slot pins wishlist/instance; conflict errors  
**Independent Test**: Controller/widget tests with memory DB

- [x] T005 [US1/US4] Extend `builds_library_controller.dart` with variant select/create, attachable sets, attachments load, attach/detach
- [x] T006 [US2] Controller pin/clear slot instance on live-attached set items + slot pin view models
- [x] T007 [US1/US2/US3/US4] Extend `builds_library_page.dart` with Variants / Attachments / Slot pins UI + status for conflicts
- [x] T008 [US1/US2/US3/US4] Write `variant_compose_page_test.dart` (attach, pin, conflict, create variant)

**Checkpoint**: Attach + pin + conflict surface green

---

## Phase 4: Polish & finish

- [x] T009 Update `apps/windows_host/README.md` + pubspec description for variant compose
- [x] T010 Run pure format + variant compose flutter tests (16 passed with builds suite)
- [x] T011 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-033 done, pointer → DART-034

---

## Dependencies & Execution Order

- Setup → Pure helper → Controller + UI + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure format helpers + tests
2. Controller orchestration + UI section
3. Widget tests for exit criteria
4. Merge to integration base
