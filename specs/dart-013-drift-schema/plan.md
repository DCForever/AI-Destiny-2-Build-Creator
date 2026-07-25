# Implementation Plan: DART-013 Drift Schema

**Branch**: `dart-013-drift-schema` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-013-drift-schema/spec.md`

## Summary

Add **`destiny2_db`** (`packages/db`): Drift schema mirroring product core SQLite tables (users, inventory, sets, synergies, builds/variants, attachments, loadouts). Prove **clean create** and **critical uniques/indexes** with `dart test`; document PRAGMA/index notes. No migration history (DART-014) and no CRUD repos (DART-015+).

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace 3.11.x)  
**Primary Dependencies**: `drift`, `sqlite3`, `path` (runtime); `drift_dev`, `build_runner`, `test`, `lints` (dev)  
**Storage**: SQLite via Drift (in-memory + file path)  
**Testing**: `dart test packages/db`  
**Target Platform**: Pure Dart package; Windows native sqlite3 first; WASM later  
**Project Type**: Workspace library (P1 data groundwork)  
**Performance Goals**: Schema create + unit suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; pure packages stay pure; soft never auto-applies  
**Scale/Scope**: One package + schema docs + workspace wiring

## Constitution Check

- I. Small Testable Increments: US1 clean create, US2 uniques/indexes, US3 file open.
- II. Test-First: Schema/unique tests co-land with implementation; green before merge.
- III. Green Commit Checkpoints: `dart pub get` + codegen if needed + `dart test packages/db` + pure P0 gate still green.
- IV-V. Co-located tests under `packages/db/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-013-drift-schema/
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
  pubspec.yaml                 # destiny2_db; drift + sqlite3; resolution: workspace
  lib/
    destiny2_db.dart           # barrel
    src/
      tables.dart              # Drift Table classes + indexes
      app_database.dart        # @DriftDatabase + factories
      app_database.g.dart      # generated
      schema_notes.dart        # documented critical uniques (for tests/docs)
  test/
    schema_test.dart           # clean create, FK, uniques, file reopen

pubspec.yaml                   # workspace: + packages/db; analyze script
packages/README.md             # db package row + schema note pointer
```

## Implementation approach

1. Create `packages/db` with Drift deps; register workspace member.
2. Define tables matching product current columns (research R2/R4).
3. `AppDatabase` with `schemaVersion = 1`, `onCreate: createAll`, FK pragma on open.
4. Factories: `AppDatabase.memory()`, `AppDatabase.file(String path)`.
5. Generate code (`build_runner`); commit `.g.dart`.
6. Tests: table presence, FK fail, unique violations, optional RESTRICT, temp file reopen.
7. Document uniques in `data-model.md` + `schema_notes.dart`.
8. Confirm pure graph guard (db **not** in pure list).

## Structure Decision

New Melos/workspace member `packages/db` alongside `storage`. Depends on Drift/sqlite3 (IO). Optional later dep on `destiny2_storage` for path convenience is **not** required this slice — hosts pass `StorageRoot.appDbPath` string.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
