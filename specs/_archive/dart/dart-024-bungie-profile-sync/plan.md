# Implementation Plan: DART-024 Bungie Profile Sync

**Branch**: `dart-024-bungie-profile-sync` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-024-bungie-profile-sync/spec.md`

## Summary

Port product profile fetch + inventory sync algorithm into pure Dart: Bungie profile client (memberships + GetProfile inventory parse) on `destiny2_bungie`, full-replace into Drift via DART-016 exclusive replace (sync_version / lastFullSyncAt), and a 60s `isInventoryFresh` / `syncIfStale` helper (DBR-EQP-007). No Flutter UI, no CLIENT_SECRET.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: Existing `destiny2_bungie` (HTTP + OAuth); add runtime dep on `destiny2_db` for Drift write/status; `test`  
**Storage**: Drift `AppDatabase` (memory in tests); inventory tables from DART-013/016  
**Testing**: `dart test packages/bungie` with mock transport + memory DB  
**Target Platform**: Shared library for Flutter Windows / mobile / Jaspr hosts  
**Project Type**: Workspace library extension (P2 auth+sync)  
**Performance Goals**: Full package suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no Settings UI  
**Scale/Scope**: Profile client + parse + sync + freshness (~6–8 modules) + tests

## Constitution Check

- I. Small Testable Increments: US1 profile fetch → US2 Drift sync → US3 freshness.
- II. Test-First: co-land mock HTTP + memory DB tests with implementation.
- III. Green Commit Checkpoints: `dart test packages/bungie`.
- IV-V. Co-located tests under `packages/bungie/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-024-bungie-profile-sync/
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
packages/bungie/
  pubspec.yaml                    # + destiny2_db dependency
  lib/
    destiny2_bungie.dart          # export profile + sync
    src/
      profile/
        inventory_buckets.dart
        profile_types.dart
        inventory_parse.dart
        bungie_profile_client.dart
      sync/
        sync_inventory.dart
        sync_freshness.dart
  test/
    profile_client_test.dart
    sync_inventory_test.dart
    sync_freshness_test.dart

packages/db/
  lib/src/repos/user_repository.dart  # updateUserMembership (+ ensureUser if needed)
```

## Implementation approach

1. Inventory bucket constants + equipment/transfer helpers (product `inventoryBuckets.ts`).
2. Profile DTOs + inventory parse (vault / char inventory / equipped + instances/sockets/stats subset).
3. `BungieProfileClient` over `BungieHttpClient` (memberships + full inventory).
4. User membership update helper on `destiny2_db`.
5. `syncUserInventory`: membership → inventory → optional transfer resolve → normalize records → `replaceInventoryBatchExclusive`.
6. `isInventoryFresh` / `syncIfStale` with 60_000 ms default.
7. Tests; barrel exports; README note; pure graph guard still green.

## Structure Decision

**Sync lives in `destiny2_bungie`** and depends on `destiny2_db` so profile parse + Drift replace stay one library hosts call without Flutter. DART-025 only wires Settings UI. Manifest-backed equipment lookup is **injectable** (no hard dep on `destiny2_manifest` this slice).

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| bungie → db dependency | Exit requires algorithm “into Drift” testable without Flutter | Host-only sync would force DART-025 to own algorithm + tests |
| Deferred full roll-tag/socket columnKind | Needs entity cache/manifest wiring | Blocks exit criteria without improving P2 gate |
)
