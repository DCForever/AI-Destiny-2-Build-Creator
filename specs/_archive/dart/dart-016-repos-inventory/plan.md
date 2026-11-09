# Implementation Plan: DART-016 Repos Inventory

**Branch**: `dart-016-repos-inventory` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-016-repos-inventory/spec.md`

## Summary

Add Drift **inventory repository** APIs on `destiny2_db`: full-replace batch write in one transaction (product `upsertInventoryBatch` shape), sync metadata fields, composite unique upsert behavior, and an in-process **busy lock hook** for exclusive per-user replace. No Bungie HTTP, no Flutter UI.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `drift`, `sqlite3`, `path`, `test` (existing `destiny2_db`)  
**Storage**: SQLite via `AppDatabase` (memory for tests); tables `inventory_items`, `inventory_sync_meta`, `users` already from DART-013  
**Testing**: `dart test packages/db`  
**Target Platform**: Pure Dart package (Windows sqlite native first)  
**Project Type**: Workspace library extension (P1 data)  
**Performance Goals**: Full `packages/db` suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; pure packages stay pure  
**Scale/Scope**: ~3 modules (records, busy lock, inventory repo) + focused tests

## Constitution Check

- I. Small Testable Increments: US1 full-replace, US2 composite unique, US3 busy lock, US4 queries.
- II. Test-First: inventory tests co-land with implementation; green before merge.
- III. Green Commit Checkpoints: `dart test packages/db`.
- IV-V. Co-located tests under `packages/db/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-016-repos-inventory/
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
packages/db/
  lib/
    destiny2_db.dart                 # export inventory repos
    src/
      repos/
        inventory_records.dart       # InventoryItemRecord, InventorySyncStatus
        inventory_busy_lock.dart     # InventoryBusyLock + InventoryReplaceBusyException
        inventory_repository.dart    # replace + queries + status
        json_codec.dart              # extend for string arrays / maps if needed
  test/
    repos_inventory_test.dart        # full-replace, unique, busy, queries
```

## Implementation approach

1. Record types for inventory items + sync status (plain immutable classes).
2. JSON helpers for plugHashes (int[]), rollTags (string[]), statValues (map), socketPlugs (list of maps).
3. `replaceInventoryBatch`: `db.transaction` → upsert each row on `(userId, instanceId)` → delete orphans → upsert meta with incremented syncVersion → update users.lastSyncAt.
4. Query + status functions mirroring product TS.
5. `InventoryBusyLock.runExclusive(userId, action)` + `replaceInventoryBatchExclusive` wrapper.
6. Tests for all exit criteria; export from barrel; README one-line update.
7. No schema migration expected (uniques already present).

## Structure Decision

Inventory repos stay **inside** `packages/db` next to library repos (Drift-bound). Busy lock is pure Dart (no Drift) but co-located for hosts that only depend on `destiny2_db`.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| In-process busy lock in db package | Exit requires busy lock hook before DART-024 | Deferring lock to DART-024 would leave exit incomplete |
