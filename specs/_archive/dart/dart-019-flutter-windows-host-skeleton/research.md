# Research: DART-019 Flutter Windows Host Skeleton

**Date**: 2026-07-24  
**Branch**: `dart-019-flutter-windows-host-skeleton`

## Decisions

### R1 — App location and package name

**Decision**: `apps/windows_host/` with pub name `destiny2_windows_host`.  
**Rationale**: packages/README reserved `apps/` for UI shells; Windows is first shell (D-SHELL-1).  
**Alternatives**: root-level `lib/` Flutter app (pollutes Next monorepo root); `packages/app` (blurs pure vs host).

### R2 — Workspace membership

**Decision**: Add `apps/windows_host` to root `pubspec.yaml` `workspace:` so path packages with `resolution: workspace` resolve.  
**Rationale**: All DART packages already use workspace resolution; external path-only consumer fails.  
**Alternatives**: Drop workspace resolution from packages (regressive).

### R3 — Single DB connection ownership

**Decision**: `HostBootstrap` / `AppServices` creates one `AppDatabase.file(storageRoot.appDbPath)`, holds it, closes in `dispose`. Widgets receive the instance via InheritedWidget / constructor injection — never open a second file DB in the host layer.  
**Rationale**: Matches product single-writer SQLite semantics; exit criterion explicit.  
**Alternatives**: Global singleton without dispose (harder to test); open-per-screen (violates single connection).

### R4 — SQLite on Flutter Windows

**Decision**: Depend on `sqlite3_flutter_libs` + existing Drift/`destiny2_db`. Ensure bindings before open if required by platform.  
**Rationale**: Drift native needs sqlite3 shared library on desktop.  
**Alternatives**: Ship custom DLL (unnecessary); wasm (wrong for Windows desktop).

### R5 — Settings stub content

**Decision**: Display-only status from `ManifestRefreshApi.status()`; optional “Reload status” re-queries status. No OAuth, no inventory, no mandatory download refresh button.  
**Rationale**: Exit criteria: “manifest status only.” Full refresh UI can wait.  
**Alternatives**: Full Settings card with refresh/download (scope creep into DART-018 UX polish).

### R6 — Tests

**Decision**: `flutter test` with injectable StorageRoot (temp dir), optional memory DB, fake `ManifestRefreshApi`. Avoid live network.  
**Rationale**: CI-friendly; mirrors package-level injectable patterns.  
**Alternatives**: Only integration/golden (heavier, flaky).

## References

- DART-012 StorageRoot host pattern  
- DART-013 `AppDatabase.file`  
- DART-018 `WindowsManifestRefresh` / `ManifestStatus`  
- docs/multiplatform-dart-port-decisions.md (D-SHELL-1, D-IO)
