# Tasks: DART-025 Flutter Inventory Sync UI

**Input**: Design documents from `/specs/dart-025-flutter-inventory-sync-ui/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Fake profile client + memory DB + memory token store. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 [P] Create `apps/windows_host/lib/settings/inventory_sync_controller.dart` skeleton
- [x] T002 [P] Create `apps/windows_host/lib/settings/inventory_sync_card.dart` skeleton
- [x] T003 Wire `BungieProfileClient` + `InventorySyncController` into `host_bootstrap.dart` / `AppServices`

---

## Phase 2: Foundational — controller behavior

- [x] T004 Implement `InventorySyncController.refreshStatus` + `syncNow` (ensureUser, syncUserInventory, busy/error)
- [x] T005 Export/use from settings page structure

**Checkpoint**: Controller compiles against destiny2_bungie + destiny2_db

---

## Phase 3: User Story 1 — Sync from Settings (P1) 🎯 MVP

**Goal**: Signed-in Sync now writes inventory to Drift and updates card  
**Independent Test**: controller + card tests

- [x] T006 [US1] Write `apps/windows_host/test/inventory_sync_controller_test.dart` (sync success + replace)
- [x] T007 [US1] Implement/finalize `InventorySyncCard` + embed in `settings_page.dart`
- [x] T008 [US1] Write/update widget tests for card + settings page presence
- [x] T009 [US1] Confirm US1 tests pass

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Busy / error UX (P1)

**Goal**: Busy indicator + error messages  
**Independent Test**: controller tests for busy double-call + thrown errors

- [x] T010 [US2] Tests for in-flight busy, SyncInProgressError, profile failure
- [x] T011 [US2] Card shows busy + error keys; confirm tests pass

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Freshness display (P2)

**Goal**: Fresh/stale label from 60s window  
**Independent Test**: seed lastFullSyncAt

- [x] T012 [US3] Tests for fresh vs stale labels on controller/card
- [x] T013 [US3] Confirm tests pass

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T014 Update host README / packages README note if present for inventory sync Settings
- [x] T015 Run `flutter test` apps/windows_host; pure graph guard still green
- [x] T016 Mark tasks complete; commit; merge `dart-025-flutter-inventory-sync-ui` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-025 done, **P2 gate**, pointer → DART-026)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Controller with injectable profile client  
2. Card + Settings section  
3. Busy/error + freshness tests  
4. Merge + P2 gate roadmap note
