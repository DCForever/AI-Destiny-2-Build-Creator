# Tasks: DART-039 Flutter DIM Export UI

**Input**: Design documents from `/specs/dart-039-flutter-dim-export-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Format helpers + Flutter widget/controller tests (memory DB, injectable clipboard). No live Bungie. No CLIENT_SECRET. No dim.gg network.

## Phase 1: Setup

- [x] T001 Create `specs/dart-039-flutter-dim-export-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm DART-010 exports (`buildJsonOnlyDimExport`, DimLoadout) available to windows_host

---

## Phase 2: Format + controller + panel (US1–US3) 🎯 MVP

**Goal**: Equip-ready gate, jsonOnly clipboard export, status/preview  
**Independent Test**: `dim_export_format_test.dart` + `dim_export_panel_test.dart`

- [x] T003 [P] Implement `apps/windows_host/lib/dim_export/dim_export_format.dart`
- [x] T004 [P] Write `apps/windows_host/test/dim_export_format_test.dart`
- [x] T005 Implement `apps/windows_host/lib/dim_export/dim_export_controller.dart` (readiness, requestExport, clipboard writer)
- [x] T006 Implement `apps/windows_host/lib/dim_export/dim_export_panel.dart` UI
- [x] T007 Embed DimExportPanel in `builds_library_page.dart`; bind lifecycle with variant selection
- [x] T008 Write `apps/windows_host/test/dim_export_panel_test.dart` (blocked when not ready; clipboard on ready)

**Checkpoint**: dim export tests green; soft never auto-applies; no clipboard when not equip-ready

---

## Phase 3: Polish & finish

- [x] T009 Update `apps/windows_host/README.md` + pubspec description for DIM export UI
- [x] T010 Run dim export flutter tests
- [x] T011 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-039 done, pointer → DART-040

---

## Dependencies & Execution Order

- Setup → Format/controller/panel + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Format + controller + panel + embed + tests  
3. Merge to integration base + roadmap pointer  
