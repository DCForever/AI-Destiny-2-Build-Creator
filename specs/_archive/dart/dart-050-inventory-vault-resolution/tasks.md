# Tasks: DART-050 Inventory Vault Resolution

**Input**: Design documents from `/specs/dart-050-inventory-vault-resolution/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first for lookup builder and host vault fixtures; green `dart test packages/bungie` + host inventory tests.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Update `.specify/feature.json` feature_directory to `specs/dart-050-inventory-vault-resolution`
- [x] T002 Confirm branch `dart-050-inventory-vault-resolution` from `feature/multiplatform-dart`

---

## Phase 2: Foundational (library lookup)

- [x] T003 [US1] Add `packages/bungie/lib/src/profile/equipment_bucket_lookup.dart` with `buildEquipmentBucketLookup` (raw def map → itemHash→equipment bucket) and `buildEquipmentBucketLookupFromSlots` (slot label map → buckets)
- [x] T004 [P] [US1] Export from `packages/bungie/lib/destiny2_bungie.dart`
- [x] T005 [US1] Unit tests in `packages/bungie/test/equipment_bucket_lookup_test.dart` (Kinetic kept; non-equipment omitted)
- [x] T006 [US1] Extend `syncUserInventory` / `syncIfStale` to accept optional `FutureOr<Map<int,int>> Function(List<int> transferItemHashes)? equipmentBucketLookupBuilder` (merge with explicit map)
- [x] T007 [US1] Assert `resolvedFromTransfer > 0` + Kinetic vault row in `packages/bungie/test/sync_inventory_test.dart`

**Checkpoint**: Package vault resolution green without host UI

---

## Phase 3: User Story 2 - Host wiring (P1)

- [x] T008 [US2] Add host-side lookup provider helper (Windows: raw table via manifest service when version known; else catalog slots)
- [x] T009 [US2] Wire `InventorySyncController.syncNow` to pass builder/lookup
- [x] T010 [US2] Wire Windows `EquipController` `syncIfStale` with lookup
- [x] T011 [US2] Wire Jaspr `EquipController` `syncIfStale` with lookup
- [x] T012 [US2] Host tests: vault fixtures assert resolution; fail without lookup wiring in `apps/windows_host/test/inventory_sync_controller_test.dart` (+ equip test if present)

**Checkpoint**: Production paths cannot omit lookup for vault fixtures

---

## Phase 4: User Story 3 - Docs + residuals (P1)

- [x] T013 [US3] Update `packages/README.md` inventory section: empty lookup drops vault; production MUST wire lookup
- [x] T014 [US3] Update `docs/multiplatform-dart-feature-gaps.md` GAP-INV-01 + GAP-INV-06 residual notes; PROC-01/02 progress
- [x] T015 [US3] Document Owned still needs entity stores → DART-053 in package or gap docs

---

## Phase 5: User Story 4 - Optional weapon stats (P3)

- [x] T016 [P] [US4] Add `parseWeaponStatValues` + use for weapon/transfer parse in `inventory_parse.dart`
- [x] T017 [US4] Unit tests for combat stat hashes

---

## Phase 6: Polish & finish

- [x] T018 Mark checklist items complete; ensure success criteria vault-specific
- [x] T019 Run tests (`dart test packages/bungie`; windows inventory tests)
- [x] T020 Commit; merge `--no-edit` into `feature/multiplatform-dart`; set roadmap DART-050 **done**; Current pointer → DART-051; commit base

---

## Dependencies & Execution Order

- Phase 2 blocks Phase 3
- Phase 4 can parallel docs after Phase 2 API exists
- Phase 5 optional; may skip with residual note
- Phase 6 last

## Implementation Strategy

1. Library lookup + package tests (MVP)
2. Wire all production sync call sites
3. Docs / gap residual
4. Optional weapon stats
5. Finish-spec merge
