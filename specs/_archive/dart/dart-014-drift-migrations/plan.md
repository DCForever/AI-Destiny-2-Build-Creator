# Implementation Plan: DART-014 Drift Migrations

**Branch**: `dart-014-drift-migrations` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-014-drift-migrations/spec.md`

## Summary

Extend **`destiny2_db`** with a **migration strategy** that mirrors product historical `ensure*` / column upgrades (`src/lib/db/client.ts`), a **documented version table**, and tests proving **empty→current** green plus **idempotent partial upgrades** for later import (DART-048). No schema shape change → **schemaVersion stays 1**.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: Existing `drift`, `sqlite3`, `path` in `destiny2_db`  
**Storage**: SQLite via Drift  
**Testing**: `dart test packages/db`  
**Target Platform**: Pure Dart package (Windows/CI native sqlite3 first)  
**Project Type**: Workspace library (P1 data)  
**Performance Goals**: Migration suite &lt; 60s  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; pure packages stay pure  
**Scale/Scope**: Migration helpers + docs + tests inside existing `packages/db`

## Constitution Check

- I. Small Testable Increments: US1 empty→current, US2 version table, US3 partial ensure.
- II. Test-First: Migration tests co-land; green before merge.
- III. Green Commit Checkpoints: `dart test packages/db` (+ pure gate optional).
- IV-V. Co-located tests under `packages/db/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-014-drift-migrations/
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
    destiny2_db.dart              # export migration modules
    src/
      app_database.dart           # MigrationStrategy wiring
      migration_version_table.dart # documented version + step catalog
      ensure_upgrades.dart         # idempotent ensure* ports
      schema_notes.dart            # unchanged / minor cross-link
      tables.dart                  # unchanged schema
      app_database.g.dart
  test/
    schema_test.dart              # keep green
    migration_test.dart           # empty→current + partial ensure
```

## Implementation approach

1. **Research**: Map each product `ensure*` to a logical step ID and SQL intent (`research.md` / version table).
2. **Version table**: Constants listing Drift schemaVersion 1 = current; list of `EnsureStepId` with product function names.
3. **ensure_upgrades.dart**: Functions that use raw SQL / PRAGMA table_info via `AppDatabase.customSelect` / `customStatement` (or a small executor interface for tests with raw sqlite). Prefer operating through Drift `QueryExecutor` / `AppDatabase` custom API.
4. **MigrationStrategy**:
   - `onCreate`: `m.createAll()` (current full schema)
   - `onUpgrade`: for future `from < to` bumps — empty body with comment, or apply named steps if we ever split versions
   - `beforeOpen`: `PRAGMA foreign_keys = ON`; call `applyEnsureUpgrades` so legacy/partial files and import paths heal columns even when user_version already 1
5. **Tests**:
   - Empty memory DB: tables + late columns present
   - Raw-SQL partial DB → ensure → columns present; second run no throw
   - Version table completeness (step list non-empty / matches known product ensures)
6. **Docs**: data-model version table; quickstart; roadmap update on finish.

## Structure Decision

Stay inside `packages/db`. Do not add Flutter or path_provider. No new workspace package.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| ensure* in beforeOpen even at schemaVersion 1 | Product DBs and future imports may have v1 user_version without late columns | Bumping schemaVersion without product bump would desync greenfield; pure onUpgrade alone cannot heal user_version==1 partial files |

## Risk notes

- Table rebuild for builds identity (NOT NULL → nullable) must preserve rows when applied.
- Unique constraint on `build_synergy_types(build_id, type, sub_type)` with NULL sub_type: product uses COALESCE in migrate from build_synergies; match product behavior.
