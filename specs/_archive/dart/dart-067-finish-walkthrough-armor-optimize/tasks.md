# Tasks: DART-067 Finish Walkthrough / Armor Optimize / Post-Sync

**Input**: Design documents from `/specs/dart-067-finish-walkthrough-armor-optimize/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-067-finish-walkthrough-armor-optimize`
- [x] T002 Branch `dart-067-finish-walkthrough-armor-optimize` from `feature/multiplatform-dart`

## Phase 2: Pure / app foundation

- [x] T003 [P] Add `detectImprovement` in `packages/domain` + unit test
- [x] T004 [P] Add `optimizer_constraints_json.dart` parse/serialize + tests in `packages/app`
- [x] T005 Add `finish_walkthrough_use_cases.dart` (`createSetAndAttach`, `createSetsFromBuild`) + tests
- [x] T006 Add `improvement_suggestions.dart` + tests (detect better kit; never write)

## Phase 3: Windows Finish walkthrough + armor improve (US1–US3)

- [x] T007 BuildsLibraryController: oneTapCreateCategory, captureCategory, fillFinishSlot + post-mutation target helpers
- [x] T008 builds_library_page Finish panel: Create/Capture/Fill + armor OptimizerWorkspace confirm path
- [x] T009 Windows tests for finish walkthrough actions and armor confirm-only wiring

## Phase 4: Windows post-sync banner (US4)

- [x] T010 InventorySyncController + card: post-sync suggestions list, Confirm/Dismiss
- [x] T011 Windows tests: no auto-apply on sync; Confirm applies; Dismiss no write

## Phase 5: Jaspr Finish residual (US1–US2)

- [x] T012 BuildsController + build_compose_page: Create/Capture/fill (no optimizer)
- [x] T013 Jaspr tests for finish walkthrough actions

## Phase 6: Finish

- [x] T014 Run package + host tests; fix failures
- [x] T015 Update roadmap / gap / fidelity status; commit; merge to `feature/multiplatform-dart`
