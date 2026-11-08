# Tasks: DART-036 Flutter Optimizer UI

**Input**: Design documents from `/specs/dart-036-flutter-optimizer-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure format helpers + Flutter widget/controller tests (memory DB / injected candidates). No live Bungie. No CLIENT_SECRET. Never silent apply.

## Phase 1: Setup

- [x] T001 Create `specs/dart-036-flutter-optimizer-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm DART-035 exports (`optimizeArmorInIsolate` / `optimizeArmorLocal`, `materializeArmorCombination`, `applyArmorCombinationInPlace`) available to windows_host

---

## Phase 2: Foundational pure helpers

- [x] T003 [P] Implement `apps/windows_host/lib/optimizer/optimizer_format.dart` (advisory caption, combo summary, empty-reason label, top-N window)
- [x] T004 [P] Implement `apps/windows_host/lib/optimizer/optimizer_candidate_map.dart` (inventory bucket → slot + CandidatePiece)
- [x] T005 [P] Write `apps/windows_host/test/optimizer_format_test.dart`

**Checkpoint**: Pure helper tests pass

---

## Phase 3: Controller + workspace UI (US1–US3) 🎯 MVP

**Goal**: Goals → Find kits (no write) → suggestions → confirm apply/materialize  
**Independent Test**: Controller/widget tests with memory DB + injected candidates

- [x] T006 [US1] Implement `apps/windows_host/lib/optimizer/optimizer_controller.dart` (goals draft, findKits no-write, pending confirm)
- [x] T007 [US2] Confirm cancel / confirm apply-in-place / materialize paths on controller
- [x] T008 [US1/US2/US3] Implement `apps/windows_host/lib/optimizer/optimizer_workspace.dart` UI (goals, Find kits, list, confirm dialog, advisory)
- [x] T009 [US1] Embed workspace in `sets_library_page.dart` for armor sets
- [x] T010 [US1/US2/US3] Write `apps/windows_host/test/optimizer_workspace_test.dart` (suggest-no-write, cancel, confirm-apply)

**Checkpoint**: Suggest → confirm exit criteria green

---

## Phase 4: Polish & finish

- [x] T011 Update `apps/windows_host/README.md` + pubspec description for DART-036
- [x] T012 Run optimizer flutter tests + related sets tests
- [x] T013 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-036 done, pointer → DART-037

---

## Dependencies & Execution Order

- Setup → Pure helpers → Controller + UI + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure format + candidate map + tests  
2. Controller confirm-only state machine  
3. Workspace widget + Sets embed  
4. Widget tests for exit criteria  
5. Merge to integration base
