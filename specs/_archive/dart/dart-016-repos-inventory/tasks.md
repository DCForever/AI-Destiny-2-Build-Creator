# Tasks: DART-016 Repos Inventory

**Input**: Design documents from `/specs/dart-016-repos-inventory/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-016-repos-inventory` from `feature/multiplatform-dart`; specs dir present
- [x] T002 Update `.specify/feature.json` → `specs/dart-016-repos-inventory`

## Phase 2: Foundational

- [x] T003 Implement `packages/db/lib/src/repos/inventory_records.dart` (InventoryItemRecord, InventorySyncStatus)
- [x] T004 Extend `json_codec.dart` for string arrays / map JSON used by inventory
- [x] T005 Implement `packages/db/lib/src/repos/inventory_busy_lock.dart` (lock + busy exception)
- [x] T006 Export new APIs from `packages/db/lib/destiny2_db.dart`

## Phase 3: User Story 1 — Full-replace transaction (P1)

- [x] T007 [US1] Implement `replaceInventoryBatch` + `getInventoryStatus` in `inventory_repository.dart`
- [x] T008 [US1] Tests: first replace, orphan prune, empty clear, syncVersion bump, users.last_sync_at

## Phase 4: User Story 2 — Composite unique (P1)

- [x] T009 [US2] Tests: raw duplicate (user, instance) fails; replace upserts power in place (single row)

## Phase 5: User Story 3 — Busy lock (P1)

- [x] T010 [US3] Implement `replaceInventoryBatchExclusive` using InventoryBusyLock
- [x] T011 [US3] Tests: concurrent A busy throws; B allowed; after release A ok; isBusy

## Phase 6: User Story 4 — Queries (P2)

- [x] T012 [US4] Implement list / by bucket / by hashes / by instance ids
- [x] T013 [US4] User-scope and filter tests

## Phase 7: Polish & finish

- [x] T014 Update `packages/README.md` db package row for inventory repos
- [x] T015 Mark tasks complete; `dart test packages/db` green (43)
- [x] T016 Commit; merge `--no-edit` into `feature/multiplatform-dart`; update roadmap pointer to DART-017; commit base
