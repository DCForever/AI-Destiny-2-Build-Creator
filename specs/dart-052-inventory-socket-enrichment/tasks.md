# Tasks: DART-052 Inventory Socket Enrichment

**Input**: Design documents from `/specs/dart-052-inventory-socket-enrichment/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first golden classify/build + sync normalize fixtures; green `dart test packages/bungie`.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Update `.specify/feature.json` feature_directory to `specs/dart-052-inventory-socket-enrichment`
- [x] T002 Confirm branch `dart-052-inventory-socket-enrichment` from `feature/multiplatform-dart`

---

## Phase 2: Pure classify + buildStoredSocketPlugs (US1)

- [x] T003 [US1] Implement `packages/bungie/lib/src/inventory/classify_weapon_socket.dart` (SocketColumnKind, classifyWeaponSocket, isEnhancedPlug)
- [x] T004 [US1] Implement `packages/bungie/lib/src/inventory/build_stored_socket_plugs.dart` (StoredSocketPlug, buildStoredSocketPlugs, deriveCaptureStatus)
- [x] T005 [US1] Implement `packages/bungie/lib/src/inventory/weapon_socket_context.dart` (WeaponSocketContext, buildWeaponSocketContextFromItemDefs, builder typedef)
- [x] T006 [P] [US1] Export from `packages/bungie/lib/destiny2_bungie.dart`
- [x] T007 [US1] Golden tests `packages/bungie/test/classify_weapon_socket_test.dart` mirroring Next classify fixtures
- [x] T008 [US1] Tests `packages/bungie/test/build_stored_socket_plugs_test.dart` end-to-end stored shape

**Checkpoint**: Pure golden fixtures green

---

## Phase 3: Sync normalize (US2)

- [x] T009 [US2] Extend `syncUserInventory` / `syncIfStale` with weaponSocketContextBuilder; `_normalizeItems` emits enriched plugs for weapons
- [x] T010 [US2] Sync inventory tests: columnKind/columnLabel stored when context provided; non-weapon null; no-context raw fallback

**Checkpoint**: Package sync emits enriched plugs with context

---

## Phase 4: Production host wiring (US3)

- [x] T011 [US3] Windows `weapon_socket_context_provider.dart` (raw def context builder)
- [x] T012 [US3] Wire `InventorySyncController` + `HostBootstrap` + equip paths
- [x] T013 [US3] Wire Jaspr equip path when builder available (or document raw-less residual)
- [x] T014 [P] [US3] Package/host acceptance that enrichment params are accepted

**Checkpoint**: Production paths pass socket context

---

## Phase 5: Docs + finish (US4)

- [x] T015 [US4] Update `packages/README.md` inventory section for socket enrichment
- [x] T016 [US4] Update `docs/multiplatform-dart-feature-gaps.md` GAP-INV-03 closed (or residual PROC-06)
- [x] T017 Run `dart test packages/bungie` (and host tests if changed)
- [x] T018 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap DART-052 **done**; Current → DART-053; commit base

---

## Dependencies & Execution Order

- Phase 2 blocks Phase 3
- Phase 3 blocks Phase 4
- Phase 5 last

## Implementation Strategy

1. Pure classify/build + golden tests (MVP / exit criteria core)
2. Wire normalize + package sync fixtures
3. Host builders
4. Docs / merge
