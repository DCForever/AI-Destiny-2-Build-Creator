# Implementation Plan: DART-019 Flutter Windows Host Skeleton

**Branch**: `dart-019-flutter-windows-host-skeleton` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-019-flutter-windows-host-skeleton/spec.md`

## Summary

Create the first **Flutter Windows** host app: resolve **StorageRoot**, open a **single Drift `AppDatabase`**, and show a **Settings stub** with **manifest status only** (DART-018 API). No OAuth. Pure packages unchanged except workspace/docs wiring.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)  
**Primary Dependencies**: Flutter, path_provider, sqlite3_flutter_libs; path deps `destiny2_storage`, `destiny2_db`, `destiny2_manifest`  
**Storage**: StorageRoot app-support + Drift SQLite `app.db`  
**Testing**: `flutter test` (widget + bootstrap unit)  
**Target Platform**: Windows desktop  
**Project Type**: Flutter desktop application under `apps/windows_host`  
**Constraints**: Pure Dart I/O packages; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; single DB connection  
**Scale/Scope**: One screen stub; no catalog/compose

## Constitution Check

- I. Small Testable Increments: bootstrap → Settings status UI.  
- II. Test-First: co-land tests with bootstrap and Settings.  
- III. Green Commit Checkpoints: `flutter test` (+ analyze/build smoke).  
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-019-flutter-windows-host-skeleton/
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
  pubspec.yaml                 # destiny2_windows_host
  analysis_options.yaml
  lib/
    main.dart                  # binding + bootstrap + runApp
    app.dart                   # MaterialApp / root
    host_bootstrap.dart        # StorageRoot + single DB + ManifestRefreshApi
    settings/
      settings_page.dart       # Settings stub (manifest status)
  test/
    host_bootstrap_test.dart
    settings_page_test.dart
  windows/                     # flutter create platform files
```

Root updates:

- `pubspec.yaml` workspace member `apps/windows_host`
- `packages/README.md` — apps/ entry
- melos analyze script optional include (document; Flutter analyze via flutter)

## Implementation approach

1. `flutter create --platforms=windows apps/windows_host` (or equivalent scaffold).
2. Pubspec: Flutter deps + path packages + sqlite3_flutter_libs + path_provider.
3. Implement `HostBootstrap.open` / `dispose` with injectable overrides for tests.
4. Settings page loads `status()` and renders fields; loading/error states.
5. main.dart wires bootstrap → Inherited/provider of services → Settings home.
6. Tests with temp StorageRoot + fake ManifestRefreshApi; memory or temp file DB.
7. Docs + roadmap finish-spec merge.

## Structure Decision

New **Flutter app package** under `apps/windows_host` — not inside `packages/` pure graph. Domain/db/manifest stay libraries.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Flutter app in monorepo workspace | Path packages use `resolution: workspace` | Outside-workspace path consumer cannot resolve |
| sqlite3_flutter_libs in host only | Native SQLite for Drift on Windows | Putting Flutter dep into destiny2_db would break pure-ish layering |
