# Implementation Plan: DART-015 Repos Library

**Branch**: `dart-015-repos-library` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-015-repos-library/spec.md`

## Summary

Add Drift **repository** APIs on `destiny2_db` for library CRUD (builds, sets, set items, synergies, variants/attachments). Prove **round-trip** fixtures and **RESTRICT** set-delete-when-attached with `dart test packages/db`. No Bungie, no inventory sync, no domain hard gates.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `drift`, `sqlite3`, `path`, `test` (existing `destiny2_db`)  
**Storage**: SQLite via `AppDatabase` (memory for tests)  
**Testing**: `dart test packages/db`  
**Target Platform**: Pure Dart package (Windows sqlite native first)  
**Project Type**: Workspace library extension (P1 data)  
**Performance Goals**: Full `packages/db` suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; pure packages stay pure  
**Scale/Scope**: ~6 repo modules + record types + focused tests

## Constitution Check

- I. Small Testable Increments: US1 round-trip, US2 RESTRICT, US3 user scope.
- II. Test-First: repo tests co-land with implementation; green before merge.
- III. Green Commit Checkpoints: `dart test packages/db` (+ optional pure P0 gate).
- IV-V. Co-located tests under `packages/db/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-015-repos-library/
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
    destiny2_db.dart              # export repos
    src/
      repos/
        library_records.dart      # record types
        json_codec.dart           # int-list / soft-stat JSON helpers
        user_repository.dart      # minimal user insert/get
        build_repository.dart
        set_repository.dart
        set_item_repository.dart
        synergy_repository.dart
        variant_repository.dart
  test/
    repos_library_test.dart       # round-trip + RESTRICT + user scope
```

## Implementation approach

1. Add record types + JSON helpers (no freezed required — plain immutable classes).
2. Implement repositories as top-level functions or thin classes taking `AppDatabase` (async Drift API).
3. Mirror product TS method names where practical (`createBuildRecord`, `deleteSetRecord`, …).
4. Tests: seed user; round-trip each family; attach set → delete fails; detach → delete ok; two-user isolation.
5. Export from barrel; update packages/README one line.
6. No schema changes expected (DART-013/014 already have RESTRICT + tables).

## Structure Decision

Repos live **inside** `packages/db` (not a new package) because they are Drift-bound and share `AppDatabase`. Domain stays pure.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Set item CRUD without product validation | Exit needs set round-trip; validation needs entities (DART-017) | Deferring all set items would leave sets empty and rework later |
