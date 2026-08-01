# Research: DART-018 Manifest Windows Refresh

**Date**: 2026-07-24

## Product references

| Topic | Source | Decision |
| ----- | ------ | -------- |
| Download + status | `src/lib/manifest/manifestService.ts` | Port getStatus / ensureCurrent / loadRawTable semantics |
| RAW_TABLES | `src/lib/manifest/types/services.ts` | Same table list for download |
| Refresh orchestration | `src/lib/services.ts` `refreshManifest` | ensureCurrent → entityCache.rebuild → status |
| Paths | DART-012 StorageRoot | app-support root; not CWD `.cache` |
| Entity rebuild | DART-017 `FileEntityCache.rebuild` | MVP extractors only |

## Stale rule (product parity)

```
if cachedVersion == null → isStale = true
else if remoteVersion == null → isStale = false  // cannot prove stale
else isStale = cachedVersion != remoteVersion
```

## Partial vs full

- **Partial (default)**: for each required table, if file exists at `rawTablePath(version, table)`, skip download.
- **Full**: always download and overwrite each required table for the remote version.

## Isolate boundary

Pass only **sendable primitives** into `Isolate.run`: `basePath` (String) + `version` (String). Inside isolate: construct `StorageRoot`, load raw tables from disk, run `FileEntityCache.rebuild`. Download stays on the caller isolate (network + write raw JSON) so isolate work is CPU-bound extract only.

## HTTP injection

```dart
typedef ManifestHttpGet = Future<ManifestHttpResponse> Function(
  Uri uri, {
  Map<String, String>? headers,
});
```

Default implementation uses `HttpClient` (dart:io). Tests inject a fake.

## API key

Host injects `BUNGIE_API_KEY`-equivalent public API key string. Never client secret. Missing key: status may work with remote null; ensureCurrent/refresh throw.

## Open points deferred

- Progress callbacks / cancel tokens for Settings UX → DART-019
- Shared rate-limit/error types → DART-021
