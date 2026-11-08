# Tasks: DART-027 App Use Cases Library

**Input**: Design documents from `/specs/dart-027-app-use-cases-library/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: In-memory Drift unit tests. No live Bungie. No CLIENT_SECRET. Soft never auto-applies.

## Phase 1: Setup

- [x] T001 Create `packages/app` pubspec + `lib/destiny2_app.dart` barrel; add to workspace `pubspec.yaml`
- [x] T002 [P] Add `errors.dart`, `clock_ids.dart`, `mappers.dart` skeletons

---

## Phase 2: Foundational

- [x] T003 Implement `UseCaseException` + codes
- [x] T004 Implement now/id generators
- [x] T005 Implement record → domain mappers (GearSet, Synergy, Attachment, SetItem)

**Checkpoint**: Package resolves with `dart pub get`

---

## Phase 3: User Story 1 — Set library CRUD (P1) 🎯 MVP

**Goal**: Set create/list/update/delete + item upsert/remove + domain mapping  
**Independent Test**: `set_use_cases_test.dart`

- [x] T006 [US1] Implement set use cases in `set_use_cases.dart`
- [x] T007 [US1] Write `packages/app/test/set_use_cases_test.dart`
- [x] T008 [US1] Confirm set tests pass

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Synergy CRUD (P1)

**Goal**: Synergy create/list/update/delete + designation immutability  
**Independent Test**: `synergy_use_cases_test.dart`

- [x] T009 [US2] Implement synergy use cases in `synergy_use_cases.dart`
- [x] T010 [US2] Write `packages/app/test/synergy_use_cases_test.dart`
- [x] T011 [US2] Confirm synergy tests pass

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Attach (P1)

**Goal**: prepareAttachments + replaceAttachmentByType  
**Independent Test**: `attachment_use_cases_test.dart`

- [x] T012 [US3] Implement attachment use cases in `attachment_use_cases.dart`
- [x] T013 [US3] Write `packages/app/test/attachment_use_cases_test.dart`
- [x] T014 [US3] Confirm attachment tests pass

**Checkpoint**: Exit criteria green

---

## Phase 6: Polish & finish

- [x] T015 Update `packages/README.md` + workspace analyze script for `packages/app`
- [x] T016 Run `dart test packages/app` and pure graph guard
- [x] T017 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-027 done, pointer → DART-028

---

## Dependencies & Execution Order

- Setup → Foundation → US1 → US2 → US3 → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Scaffold package + errors/mappers  
2. Set use cases + tests  
3. Synergy use cases + tests  
4. Attach use cases + tests  
5. Docs + merge
