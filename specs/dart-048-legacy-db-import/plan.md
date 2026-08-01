# Implementation Plan: DART-048 Legacy DB Import

**Branch**: `dart-048-legacy-db-import` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-048-legacy-db-import/spec.md`

## Summary

Provide a pure-Dart migration path that **dry-runs** and **applies** a Next.js local SQLite file (`.cache/app.db`) into multiplatform **StorageRoot** `app.db`. Because Drift schema mirrors product tables, apply is a validated **file replace** plus DART-014 ensure* healing — not a Node sidecar or row-level ETL. Windows Settings exposes the UX; docs describe the single path.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace 3.11.x)

**Primary Dependencies**: `sqlite3` (read source / fixture), `drift`/`AppDatabase` (post-apply open + ensure*), `destiny2_storage` paths (hosts), Flutter Material (Windows card only)

**Storage**: Source = user path to legacy SQLite; Target = `StorageRoot.appDbPath` (app-support, not repo `.cache`)

**Testing**: `dart test packages/db` (importer); `flutter test` windows_host (card)

**Target Platform**: Native/VM I/O (Windows primary); web stub unsupported for file copy

**Project Type**: Shared package API + Windows host UX + docs/CLI

**Performance Goals**: Local single-file copy; sub-second for typical personal DBs

**Constraints**: Pure Dart I/O only; no CLIENT_SECRET; soft never auto-applies; replace not merge; single-writer

**Scale/Scope**: One importer service, one Settings card, one doc, ~15 tasks

## Constitution Check

- I. Small Testable Increments: US1 dry-run → US2 apply → US3 Windows UX
- II. Test-First: importer tests before/with implementation; widget tests for card
- III. Green Commit Checkpoints: package tests green before host; full suite before merge
- IV–V: Co-located tests; validate source before write

## Project Structure

### Documentation (this feature)

```text
specs/dart-048-legacy-db-import/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
docs/multiplatform-dart-legacy-db-import.md
tool/legacy_db_import.dart
```

### Source Code

```text
packages/db/lib/src/legacy_import/
  legacy_db_import.dart          # conditional export
  legacy_db_import_io.dart       # LegacyDbImporter + plan/result
  legacy_db_import_stub.dart     # throws UnsupportedError
packages/db/lib/destiny2_db.dart # export
packages/db/test/legacy_db_import_test.dart

apps/windows_host/lib/settings/
  legacy_db_import_controller.dart
  legacy_db_import_card.dart
  settings_page.dart             # wire card
apps/windows_host/test/
  legacy_db_import_card_test.dart
  legacy_db_import_controller_test.dart
```

**Structure Decision**: Importer lives in `destiny2_db` (already owns schema + ensure* + sqlite3). Host only presents UX and closes/restarts messaging.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
