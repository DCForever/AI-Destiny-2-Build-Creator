# Tasks: DART-015 Repos Library

**Input**: Design documents from `/specs/dart-015-repos-library/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-015-repos-library` from `feature/multiplatform-dart`; specs dir present
- [x] T002 [P] Create `packages/db/lib/src/repos/` package layout placeholders

## Phase 2: Foundational

- [x] T003 Implement `library_records.dart` + `json_codec.dart` (records + JSON helpers)
- [x] T004 Implement `user_repository.dart` (insertUser / getUser)
- [x] T005 Export repos from `packages/db/lib/destiny2_db.dart`

## Phase 3: User Story 1 — Round-trips (P1)

- [x] T006 [US1] Implement `build_repository.dart` (CRUD + tags + synergy types)
- [x] T007 [US1] Implement `set_repository.dart` (CRUD + tags + findAttachments + findDuplicateName)
- [x] T008 [US1] Implement `set_item_repository.dart` (list/active/upsert/softRemove)
- [x] T009 [US1] Implement `synergy_repository.dart` (CRUD + links)
- [x] T010 [US1] Implement `variant_repository.dart` (CRUD + list/replace attachments)
- [x] T011 [US1] Write `packages/db/test/repos_library_test.dart` round-trip fixtures; run `dart test packages/db`

## Phase 4: User Story 2 — RESTRICT (P1)

- [x] T012 [US2] `deleteSetRecord` pre-check + `SetInUseException`; RESTRICT tests (attached fail / unattached ok)
- [x] T013 [US2] `findAttachmentsBySetId` assertion in tests

## Phase 5: User Story 3 — User scope (P2)

- [x] T014 [US3] Two-user isolation tests for builds/sets/synergies

## Phase 6: Polish & finish

- [x] T015 Update `packages/README.md` db package row for repos
- [x] T016 Mark tasks complete; `dart test packages/db` green (33)
- [ ] T017 Commit; merge `--no-edit` into `feature/multiplatform-dart`; update roadmap pointer to DART-016; commit base
