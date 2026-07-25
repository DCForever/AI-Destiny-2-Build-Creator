# Tasks: DART-024 Bungie Profile Sync

**Input**: Design documents from `/specs/dart-024-bungie-profile-sync/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Mocked HTTP + memory Drift required. No live Bungie.

## Phase 1: Setup

- [x] T001 Add `destiny2_db` dependency to `packages/bungie/pubspec.yaml`; run `dart pub get`
- [x] T002 [P] Add `updateUserMembership` (and `ensureUser` if missing) on `packages/db/lib/src/repos/user_repository.dart`; export if needed

---

## Phase 2: Foundational — profile types + parse

- [x] T003 [P] Implement `packages/bungie/lib/src/profile/inventory_buckets.dart`
- [x] T004 [P] Implement `packages/bungie/lib/src/profile/profile_types.dart`
- [x] T005 Implement `packages/bungie/lib/src/profile/inventory_parse.dart` (full inventory + diagnostics)
- [x] T006 Implement `packages/bungie/lib/src/profile/bungie_profile_client.dart`
- [x] T007 Barrel-export profile API from `packages/bungie/lib/destiny2_bungie.dart`

**Checkpoint**: Profile library compiles

---

## Phase 3: User Story 1 — Profile fetch (P1) 🎯 MVP

**Goal**: Memberships + full inventory parse via mock HTTP  
**Independent Test**: `profile_client_test.dart`

- [x] T008 [US1] Write `packages/bungie/test/profile_client_test.dart`
- [x] T009 [US1] Confirm tests pass (`dart test packages/bungie/test/profile_client_test.dart`)

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Full-replace sync + sync_version (P1)

**Goal**: syncUserInventory → Drift replace + version bump  
**Independent Test**: `sync_inventory_test.dart`

- [x] T010 Implement `packages/bungie/lib/src/sync/sync_inventory.dart`
- [x] T011 [US2] Write `packages/bungie/test/sync_inventory_test.dart`
- [x] T012 [US2] Confirm tests pass

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — 60s freshness (P1)

**Goal**: isInventoryFresh + syncIfStale  
**Independent Test**: `sync_freshness_test.dart`

- [x] T013 Implement `packages/bungie/lib/src/sync/sync_freshness.dart`
- [x] T014 [US3] Write `packages/bungie/test/sync_freshness_test.dart`
- [x] T015 [US3] Confirm tests pass

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T016 Document package in `packages/README.md`; align quickstart
- [x] T017 Verify no CLIENT_SECRET; pure graph guard still passes
- [x] T018 Run `dart test packages/bungie` (+ db tests if user repo changed); mark tasks complete
- [x] T019 Commit; merge `dart-024-bungie-profile-sync` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-024 done, pointer → DART-025)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Profile parse + client with mock HTTP  
2. Sync into Drift exclusive full-replace  
3. Freshness helper  
4. Docs + merge
