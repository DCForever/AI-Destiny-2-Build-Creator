# Tasks: DART-051 Inventory Roll Tags

**Input**: Design documents from `/specs/dart-051-inventory-roll-tags/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first golden `computeRollTags` + sync normalize fixtures; green `dart test packages/bungie`.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Update `.specify/feature.json` feature_directory to `specs/dart-051-inventory-roll-tags`
- [x] T002 Confirm branch `dart-051-inventory-roll-tags` from `feature/multiplatform-dart`

---

## Phase 2: Pure computeRollTags (US1)

- [x] T003 [US1] Add `destiny2_sandbox_data` dependency to `packages/bungie/pubspec.yaml`
- [x] T004 [US1] Implement `packages/bungie/lib/src/inventory/roll_tags.dart` (`RollTagWeaponMeta`, tag constants, `computeRollTags` Next parity)
- [x] T005 [P] [US1] Export from `packages/bungie/lib/destiny2_bungie.dart`
- [x] T006 [US1] Golden tests `packages/bungie/test/roll_tags_test.dart` mirroring `src/lib/inventory/rollTags.test.ts`

**Checkpoint**: Pure golden fixtures green

---

## Phase 3: Sync normalize (US2)

- [x] T007 [US2] Add lookup builders helpers `packages/bungie/lib/src/inventory/roll_tag_lookups.dart` (`buildPerkNameMapFromItemDefs`, `buildWeaponRollMetaFromCatalogRows`)
- [x] T008 [US2] Extend `syncUserInventory` / `syncIfStale` with optional perkNameMap / builders + weaponRollMetaLookup / builders; `_normalizeItems` calls `computeRollTags`
- [x] T009 [US2] Sync inventory tests: MeleeBuildCandidate / ChampionBarrier / Crafted stored when maps provided; empty maps → Crafted-only

**Checkpoint**: Package sync emits full tags with maps

---

## Phase 4: Production host wiring (US3)

- [x] T010 [US3] Windows `roll_tag_lookup_provider.dart` (raw def plug names + OfflineCatalog weapon meta)
- [x] T011 [US3] Wire `InventorySyncController` + `HostBootstrap` + equip paths
- [x] T012 [US3] Wire Jaspr equip path enrichment builders
- [x] T013 [P] [US3] Host or package test that enrichment params are accepted (optional assert tags with fixtures)

**Checkpoint**: Production paths pass enrichment inputs

---

## Phase 5: Docs + finish (US4)

- [x] T014 [US4] Update `packages/README.md` inventory section for roll tags
- [x] T015 [US4] Update `docs/multiplatform-dart-feature-gaps.md` GAP-INV-02 closed (or residual PROC-06)
- [x] T016 Run `dart test packages/bungie` (and host tests if changed)
- [x] T017 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap DART-051 **done**; Current → DART-052; commit base

---

## Dependencies & Execution Order

- Phase 2 blocks Phase 3
- Phase 3 blocks Phase 4
- Phase 5 last

## Implementation Strategy

1. Pure computeRollTags + golden tests (MVP / exit criteria core)
2. Wire normalize + package sync fixtures
3. Host builders
4. Docs / merge
