# Implementation Plan: DART-018 Manifest Windows Refresh

**Branch**: `dart-018-manifest-windows-refresh` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-018-manifest-windows-refresh/spec.md`

## Summary

Extend **`packages/manifest`** (`destiny2_manifest`) with a Windows-first **manifest refresh pipeline**: Bungie metadata fetch + partial/full raw table download under `StorageRoot`, Settings-level **`status` / `isStale` / `refresh`**, and **MVP entity rebuild via `Isolate.run`**. No Flutter UI; no OAuth; HTTP injectable.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: existing `destiny2_storage`, `destiny2_domain`, `path`; `dart:io`, `dart:convert`, `dart:isolate`  
**HTTP**: injectable callback (default `HttpClient` wrapper) — no hard dependency on `package:http` required  
**Storage**: `StorageRoot` manifest + entities + `current-version.json`  
**Testing**: `dart test packages/manifest` with mock HTTP + temp dirs  
**Target Platform**: Pure Dart library used by Flutter Windows hosts first (DART-019)  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies  
**Scale/Scope**: Product `RAW_TABLES` download set; MVP extractors only on rebuild

## Constitution Check

- I. Small Testable Increments: status → download → refresh+isolate.
- II. Test-First: co-land tests with implementation.
- III. Green Commit Checkpoints: `dart test packages/manifest`.
- IV-V. Co-located tests under `packages/manifest/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-018-manifest-windows-refresh/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (additions)

```text
packages/manifest/
  lib/
    destiny2_manifest.dart          # export new APIs
    src/
      types/services.dart           # ManifestStatus, download RAW_TABLES, HTTP typedefs
      manifest_service.dart         # BungieManifestService
      manifest_refresh.dart         # WindowsManifestRefresh Settings API
      isolate_rebuild.dart          # Isolate.run entry for FileEntityCache.rebuild
  test/
    manifest_service_test.dart
    manifest_refresh_test.dart
```

## Implementation approach

1. Add `ManifestStatus`, product-aligned `downloadRawTables` list, HTTP client typedef, stale helper.
2. Implement `BungieManifestService`: getStatus, ensureCurrent(partial|full), loadRawTable, current-version IO.
3. Implement isolate rebuild helper (top-level, path + version only).
4. Implement `WindowsManifestRefresh`: status, isStale, refresh → ensureCurrent + isolate rebuild.
5. Tests with mock HTTP + fixture raw tables for refresh→entity meta path.
6. Update packages/README + barrel exports.

## Structure Decision

Stay inside **`destiny2_manifest`** (not a new package). Download + Settings API are the natural host of entity cache rebuild. Shared Bungie HTTP package remains DART-021.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Isolate rebuild | Exit criteria: off UI isolate | Sync rebuild only would block Flutter UI later |
| Full product RAW_TABLES list | Parity with TS download set | MVP-only tables would force rework when non-MVP extractors land |
