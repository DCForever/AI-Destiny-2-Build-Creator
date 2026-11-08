# Tasks: DART-065 Sets Board, Dense Rows, Slot Fill

**Input**: Design documents from `/specs/dart-065-sets-board-rows-fill/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-065-sets-board-rows-fill`
- [x] T002 Branch `dart-065-sets-board-rows-fill` from `feature/multiplatform-dart`

## Phase 2: Pure helpers (US1, US2, US4, US5)

- [x] T003 [P] Add `sumArmorSetStats` pure helper + tests in `packages/db`
- [x] T004 [P] Add `set_board_presentation.dart` (trait perks, replace confirm, meta chips, selectedPerks from instance) + tests in `packages/app`

## Phase 3: Controllers + pick result (US4, US5)

- [x] T005 Extend `SetSlotPickResult` with `selectedPerks` on Windows + Jaspr; wire `UpsertSetItemCommand.selectedPerks`
- [x] T006 Controllers: expose occupied-slot helper for replace confirm; pass selectedPerks on fill

## Phase 4: Windows host (US1–US5)

- [x] T007 Dense slot rows + armor board + replace confirm dialog in `sets_library_page.dart`
- [x] T008 Densify `set_catalog_picker.dart` meta + extract selectedPerks on instance pin
- [x] T009 Windows tests for board/rows/replace/selectedPerks

## Phase 5: Jaspr host (US1–US5)

- [x] T010 Embedded catalog fill panel (search + named list + All|Owned + instance/wishlist); retire hash-only primary
- [x] T011 Dense rows + armor board + replace confirm on `sets_page.dart` / controller
- [x] T012 Jaspr tests for catalog fill, replace confirm, selectedPerks, board

## Phase 6: Finish

- [x] T013 Run package + host tests; fix failures
- [x] T014 Update roadmap / gap / fidelity status; commit; merge to `feature/multiplatform-dart`
