# Tasks: DART-066 Synergy Picker + Manage + Sets Library

**Input**: Design documents from `/specs/dart-066-synergy-picker-manage-sets-library/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-066-synergy-picker-manage-sets-library`
- [x] T002 Branch `dart-066-synergy-picker-manage-sets-library` from `feature/multiplatform-dart`

## Phase 2: Pure helpers (US1–US8 foundation)

- [x] T003 [P] Add `library_filters.dart` (filterSets, filterSynergies) + tests in `packages/app`
- [x] T004 [P] Add `synergy_picker_presentation.dart` (coverage keys, omit-linked, perk labels, catalog→link) + tests
- [x] T005 [P] Add `set_library_presentation.dart` (readiness, firstEmpty, usedBy labels) + tests

## Phase 3: Controllers

- [x] T006 Windows + Jaspr synergy controllers: search filter state, deleteSelected, catalog search/add draft link
- [x] T007 Windows + Jaspr sets controllers: search/tag/type filters, deleteSelected, readiness accessors

## Phase 4: Windows host UI

- [x] T008 Synergy page: library search/type filters, catalog evidence picker, delete confirm
- [x] T009 Sets page: library search/tags/type, readiness/Fill next/used-by, delete + SET_IN_USE
- [x] T010 Windows tests for filters, picker omit-linked, delete, readiness

## Phase 5: Jaspr host UI

- [x] T011 Synergies page: dual-pane select/detail/edit/links/delete + filters + catalog picker
- [x] T012 Sets page: filters, readiness, Fill next, used-by, delete SET_IN_USE
- [x] T013 Jaspr controller/page tests

## Phase 6: Finish

- [x] T014 Run package + host tests; fix failures
- [x] T015 Update roadmap / gap / fidelity status; commit; merge to `feature/multiplatform-dart`
