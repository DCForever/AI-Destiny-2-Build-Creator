# Implementation Plan: DART-044 Jaspr Entity Bundles

**Branch**: `dart-044-jaspr-entity-bundles` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-044-jaspr-entity-bundles/spec.md`

## Summary

Enable the Jaspr web host to load **prebuilt MVP entity bundles** (static JSON) and run **offline catalog facets** without any full raw manifest rebuild in the browser. Extend `destiny2_manifest` with a pure bundle document + memory cache reader, make IO-backed paths web-safe via conditional imports, ship a fixture under `apps/web_host/web/entities/`, and add a Catalog page with query/facet UI.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (packages) / ^3.10 (web_host)

**Primary Dependencies**: `destiny2_manifest`, `destiny2_storage`, Jaspr client SPA (`destiny2_web_host`)

**Storage**: Prebuilt static JSON under `web/entities/` (not SQLite for entities); Drift/OPFS remains DART-043 for app DB only

**Testing**: `dart test` in `packages/manifest` + `apps/web_host`

**Target Platform**: Jaspr web (browser); pure bundle APIs also usable on native

**Project Type**: Monorepo packages + web host app

**Performance Goals**: Fixture-sized catalog load; pure in-process facet filter

**Constraints**: No raw rebuild in browser; no CLIENT_SECRET; no Node sidecar; soft never auto-applies

**Scale/Scope**: MVP stores only; fixture bundle for demo/tests

## Constitution Check

- I. Small Testable Increments: US1 parse → US2 Catalog UI → US3 no-rebuild docs
- II. Test-First: bundle + catalog tests before/with implementation
- III. Green Commit Checkpoints: tests green before finish merge
- IV-V. Co-located tests; validation of empty/error states

## Project Structure

### Documentation (this feature)

```text
specs/dart-044-jaspr-entity-bundles/
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
  lib/src/storage_root.dart          # pure paths; conditional ensureLayout
packages/manifest/
  lib/src/entity_cache_reader.dart   # abstract reader
  lib/src/memory_entity_cache.dart   # pure memory cache
  lib/src/entity_bundle.dart         # prebuilt document parse + project
  lib/src/io/text_file_*.dart        # conditional file IO
  lib/src/entity_cache.dart          # FileEntityCache via text_file
  lib/src/catalog/offline_catalog.dart  # accept EntityCacheReader; web-safe
  lib/src/http_client.dart / isolate_rebuild.dart / manifest_service.dart
                                     # conditional IO so library compiles on web
apps/web_host/
  web/entities/prebuilt/bundle.json  # fixture MVP bundle
  lib/catalog/…                      # bootstrap + Catalog page
  lib/app.dart / shell_header.dart   # /catalog route + nav
```

## Implementation approach

1. **Pure bundle layer** in `destiny2_manifest`: `EntityBundleDocument.parse`, `MemoryEntityCache`, project helper → `OfflineCatalogLoadResult` / items.
2. **Web-safe IO**: conditional `text_file` + stubs for HttpClient/Isolate rebuild so web can import catalog exports.
3. **OfflineCatalog**: accept `EntityCacheReader` (File or Memory); optional `StorageRoot` when version comes from cache meta; avoid `dart:io` direct imports.
4. **Web host**: fetch `/entities/prebuilt/bundle.json` (injectable fetcher for tests); Catalog page with element/ammo/exotic chips + query; nav Catalog | Settings.
5. **Docs**: README + quickstart; note desktop rebuild vs web prebuilt.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| `destiny2_manifest` dart:io breaks web compile | Conditional IO stubs for all exported IO paths |
| Large real entity files | Fixture-only this slice; production CDN later |
| StorageRoot.ensureLayout on web | Conditional no-op / IO create |

## Exit criteria mapping

| Exit | Delivery |
| ---- | -------- |
| Load prebuilt entity bundles | `EntityBundleDocument` + web bootstrap fetch |
| No full raw rebuild in browser | Load-only path; rebuild remains isolate/file IO |
| Offline catalog facets on web | Catalog page + pure filters |
