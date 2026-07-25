# Implementation Plan: DART-012 Storage Root

**Branch**: `dart-012-storage-root` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-012-storage-root/spec.md`

## Summary

Introduce **`destiny2_storage`** (`packages/storage`): a **StorageRoot** abstraction that resolves canonical on-disk paths for app SQLite, manifest raw tables, entity stores, and user prefs under a host-injected **application support** base — **not** the Next.js repo `.cache` CWD layout. Document Windows `path_provider` host wiring; prove layout with **fake-base unit tests**.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace 3.11.x)  
**Primary Dependencies**: `package:path` (runtime); `package:test` / `lints` (dev). No Flutter, Drift, http, or path_provider runtime deps in this package.  
**Storage**: Path layout only (no SQLite open)  
**Testing**: `dart test packages/storage` with injected fake base paths  
**Target Platform**: Multiplatform path strings; Windows Flutter host is the first consumer (DART-019)  
**Project Type**: Workspace library package (P1 data groundwork)  
**Performance Goals**: Path composition negligible; suite &lt; 30s  
**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; pure packages remain pure  
**Scale/Scope**: One small package + docs + workspace membership

## Constitution Check

- I. Small Testable Increments: US1 paths, US2 Windows layout docs, US3 fake-FS tests.
- II. Test-First: Path composition tests before/with implementation; green before merge.
- III. Green Commit Checkpoints: `dart pub get` + `dart test packages/storage` + pure P0 gate still green.
- IV-V. Co-located tests under `packages/storage/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-012-storage-root/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/storage/
  pubspec.yaml                 # destiny2_storage; path dep; resolution: workspace
  lib/
    destiny2_storage.dart      # barrel
    src/
      storage_root.dart        # StorageRoot class + factories
      version_dir.dart         # versionToDirName sanitization
  test/
    storage_root_test.dart     # fake base path composition + ensureLayout temp

pubspec.yaml                   # workspace: + packages/storage; analyze script update
packages/README.md             # layout + storage package row
docs/…                         # roadmap updated at finish-spec
```

## Implementation approach

1. Add `packages/storage` with SDK + `path` dependency only.
2. Implement `versionToDirName` and `StorageRoot` path getters/methods mirroring product logical layout (no `.cache` parent).
3. Factory `StorageRoot.windowsAppSupport(String applicationSupportPath)` documenting path_provider input.
4. Optional `ensureLayout()` using `dart:io` to create top-level dirs under base (for later Drift/manifest convenience).
5. Unit tests with fixed fake base path; optional temp-dir ensure test.
6. Wire workspace; document in packages README + quickstart.
7. Confirm pure graph guard still passes (storage **not** added to pure list).

## Structure Decision

New Melos/workspace member `packages/storage` alongside pure packages. Not pure: may use `dart:io` for ensureLayout. Hosts (Flutter Windows later) pass path_provider application-support path into `StorageRoot.windowsAppSupport`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
