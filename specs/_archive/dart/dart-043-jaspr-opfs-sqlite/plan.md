# Implementation Plan: DART-043 Jaspr OPFS SQLite

**Branch**: `dart-043-jaspr-opfs-sqlite` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-043-jaspr-opfs-sqlite/spec.md`

## Summary

Enable **Drift WASM + OPFS** on the Jaspr web host with an explicit **single-tab writer** policy: first tab opens `AppDatabase` via `WasmDatabase.open`; additional tabs are **blocked** with Settings UX. Document OPFS/multi-tab limits. Make `destiny2_db` web-safe via conditional native openers.

## Technical Context

**Language/Version**: Dart SDK ^3.5 workspace / web_host ^3.10 (Jaspr)

**Primary Dependencies**: `drift` (`WasmDatabase`), `destiny2_db`, `jaspr` / `jaspr_router`, `destiny2_ui_tokens`

**Storage**: Browser OPFS (preferred) via Drift; IndexedDB / in-memory fallbacks; app-level writer lock

**Testing**: `dart test` in `apps/web_host` (coordinator + Settings); `packages/db` regression if open path changed

**Target Platform**: Browser (Jaspr client SPA)

**Project Type**: Web host + shared db package adjustment

**Performance Goals**: N/A beyond opening DB off critical path with status UI

**Constraints**: Single writer; no Node sidecar; no CLIENT_SECRET; soft never auto-applies

**Scale/Scope**: One host DB bootstrap + Settings status + docs; no compose

## Constitution Check

- I. Small Testable Increments: US1 open, US2 lock, US3 docs.
- II. Test-First: Coordinator + Settings status tests before/with impl.
- III. Green Commit Checkpoints: web_host + db tests green before merge.
- IV–V. Co-located tests; validation of no-Next / no-secret continues.

## Project Structure

### Documentation (this feature)

```text
specs/dart-043-jaspr-opfs-sqlite/
├── plan.md
├── research.md
├── spec.md
├── quickstart.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code

```text
packages/db/lib/src/
  app_database.dart              # no unconditional dart:io / native
  connection/
    open.dart                    # conditional export
    open_native.dart
    open_web.dart
    open_unsupported.dart

apps/web_host/
  lib/db/
    tab_writer_lock.dart         # pure coordinator + models
    tab_lock_backend.dart        # abstract + memory backend
    web_db_status.dart
    web_database_bootstrap.dart  # role → open/skip
    wasm_database_opener.dart    # web-only WasmDatabase (conditional)
  lib/pages/settings_page.dart   # DB status panel
  lib/app.dart / main.client.dart
  web/sqlite3.wasm
  web/drift_worker.js
  web/drift_worker.dart          # optional source for custom worker
  tool/fetch_drift_web_assets.ps1
  test/tab_writer_lock_test.dart
  test/settings_db_status_test.dart
  docs note in README + docs/multiplatform-dart-web-opfs-limits.md
```

**Structure Decision**: Keep schema in `destiny2_db`; host owns WASM open + tab policy + UX (shell-specific).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Conditional open in db package | Web cannot import NativeDatabase | Leaving dart:io in AppDatabase breaks Jaspr compile |
