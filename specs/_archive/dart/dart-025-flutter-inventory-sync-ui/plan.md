# Implementation Plan: DART-025 Flutter Inventory Sync UI

**Branch**: `dart-025-flutter-inventory-sync-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-025-flutter-inventory-sync-ui/spec.md`

## Summary

Wire DART-024 `syncUserInventory` into the Flutter Windows Settings UI: an inventory sync card with Sync now, last-sync metadata, 60s freshness label, and busy/error UX. Host ensures a local user from OAuth membership id, injects a profile client (mockable), and keeps tokens out of SQLite. Completing this slice is the **P2 phase gate** (owned inventory local after Public+PKCE sign-in).

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter (Windows host)  
**Primary Dependencies**: `destiny2_bungie` (sync + profile client), `destiny2_db` (ensureUser, getInventoryStatus), existing host OAuth session  
**Storage**: Host single Drift `AppDatabase`; tokens in `TokenStore` only  
**Testing**: `flutter test` apps/windows_host — fake `BungieProfileClient`, memory DB, memory token store  
**Target Platform**: Flutter Windows host first  
**Project Type**: Host UI vertical slice (P2)  
**Performance Goals**: Widget tests &lt; 60s suite  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no catalog owned UI  
**Scale/Scope**: Controller + card + bootstrap wiring + tests

## Constitution Check

- I. Small Testable Increments: US1 sync action → US2 busy/error → US3 freshness display.
- II. Test-First: co-land controller/widget tests with implementation.
- III. Green Commit Checkpoints: `flutter test` apps/windows_host.
- IV-V. Tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-025-flutter-inventory-sync-ui/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/windows_host/
  lib/
    host_bootstrap.dart              # + profileClient + inventorySync controller
    settings/
      inventory_sync_controller.dart # NEW: ChangeNotifier orchestration
      inventory_sync_card.dart       # NEW: Settings card UI
      settings_page.dart             # + inventory section
  test/
    inventory_sync_controller_test.dart
    inventory_sync_card_test.dart
    settings_page_test.dart          # assert sync card present
```

## Implementation approach

1. **InventorySyncController** (`ChangeNotifier`):
   - Depends on `AppDatabase`, `WindowsOAuthSession`, `BungieProfileClient`.
   - `refreshStatus()`: if signed in → `ensureUser` → `getInventoryStatus`; expose itemCount/syncVersion/lastFullSyncAt/fresh flag.
   - `syncNow()`: guard signed-in + not already syncing; `ensureUser`; `syncUserInventory`; update status; map `SyncInProgressError` and other errors to `errorMessage`.
2. **InventorySyncCard**: ListenableBuilder on controller (+ session for signed-out); keys for tests (`inventory_sync_card`, `inventory_sync_now`, `inventory_sync_busy`, `inventory_sync_error`, meta keys).
3. **HostBootstrap / AppServices**: accept optional `BungieProfileClient` / `InventorySyncController`; default `HttpBungieProfileClient(http: BungieHttpClient(apiKey: …))` when apiKey provided (or empty key with same pattern as manifest).
4. **SettingsPage**: section “Inventory” under Account with the new card.
5. Tests with fake profile client seeding items; no live network.

## Structure Decision

UI orchestration stays in **windows_host** (not bungie package) so Flutter widgets do not leak into libraries. Algorithm remains DART-024 pure-Dart-I/O APIs.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Host owns ensureUser + sync glue | Product requireUser is host/auth concern | Putting UI-facing busy state into bungie package couples Flutter ChangeNotifier to library |
