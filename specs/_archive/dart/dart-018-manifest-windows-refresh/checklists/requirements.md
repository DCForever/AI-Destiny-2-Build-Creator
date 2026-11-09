# Requirements checklist: DART-018 Manifest Windows Refresh

**Feature**: `dart-018-manifest-windows-refresh`  
**Updated**: 2026-07-24

## Completeness

- [x] Scope limited to Windows download→extract→store + Settings API + isolate rebuild
- [x] Exit criteria mapped: status / isStale / refresh; rebuild off UI isolate
- [x] Out of scope lists Flutter UI, OAuth, catalog, web OPFS full rebuild
- [x] Assumptions documented (API key inject, partial vs full, stale rule, isolate path-only)

## Consistency

- [x] Aligns with DART-017 entity cache + MVP extractors
- [x] Uses StorageRoot paths (DART-012), not repo `.cache`
- [x] Pure Dart I/O; no Node sidecar; no CLIENT_SECRET
- [x] Soft guidance never auto-applies

## Testability

- [x] Injectable HTTP for CI
- [x] Temp StorageRoot fixtures
- [x] Partial vs full download call-count assertions
- [x] Isolate rebuild path testable without Flutter
