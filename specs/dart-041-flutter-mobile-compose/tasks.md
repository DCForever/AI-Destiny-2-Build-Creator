# Tasks: DART-041 Flutter Mobile Compose

**Input**: Design documents from `/specs/dart-041-flutter-mobile-compose/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Flutter widget/unit tests (memory DB). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-041-flutter-mobile-compose/` docs + set `.specify/feature.json`
- [x] T002 Add pure format helpers `variant_compose_format.dart` + `soft_guidance_format.dart` under mobile builds

---

## Phase 2: Controller compose API (US1–US3)

**Goal**: create/variant/attach/pin/soft via shared use cases  
**Independent Test**: controller unit paths in widget tests

- [x] T003 Extend `BuildsController` with createBuild, variants, attach/detach, pinSlot, soft coverage/targets
- [x] T004 Write format unit tests (`variant_compose_format_test`, `soft_guidance_format_test`)

---

## Phase 3: UI sheets + linear detail 🎯 MVP

**Goal**: Create sheet, attach sheet, linear compose detail, soft section  
**Independent Test**: `mobile_compose_test.dart`

- [x] T005 Implement `create_build_sheet.dart` + list FAB entry
- [x] T006 Implement `attach_set_sheet.dart`
- [x] T007 Rewrite `build_detail_page.dart` linear sections (identity, variants, attachments/pins, soft)
- [x] T008 Wire list create success → Focus Swap open detail
- [x] T009 Write `mobile_compose_test.dart` (create → attach → soft chips + non-auto-apply)
- [x] T010 Update list empty copy / existing list tests if needed

**Checkpoint**: All mobile_host flutter tests green

---

## Phase 4: Polish & finish

- [x] T011 Update mobile README + packages notes if needed
- [x] T012 Run `flutter test` in mobile_host
- [x] T013 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-041 done, pointer → DART-042; **P4 phase gate** note

---

## Dependencies & Execution Order

- Setup → Controller + formats → UI + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Formats + controller compose  
3. Sheets + linear detail + tests  
4. Merge + roadmap pointer (next: DART-042 jaspr-app-skeleton)
