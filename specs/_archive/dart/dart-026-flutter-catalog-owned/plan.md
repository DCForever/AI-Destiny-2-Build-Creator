# Implementation Plan: DART-026 Flutter Catalog Owned

**Branch**: `dart-026-flutter-catalog-owned` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-026-flutter-catalog-owned/spec.md`

## Summary

Wire **post-sync inventory** into the Flutter Catalog: pure annotate + all/owned scope filter, instance projections for pickers, and Catalog UI toggle + instance panel. Exit: owned filter works after sync.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_manifest` (catalog), `destiny2_db` (inventory), Flutter Windows host  
**Storage**: Drift inventory (read); entity JSON offline base catalog  
**Testing**: `dart test packages/manifest`; `dart test packages/db`; `flutter test` apps/windows_host  
**Target Platform**: Windows host + pure helpers  
**Project Type**: Library helpers + Flutter Catalog screen  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no live Bungie on browse  
**Scale/Scope**: Fixture-scale lists; hash-level ownership (no searchName aggregation)

## Constitution Check

- I. Small Testable Increments: pure counts/annotate/filter → instance project → host wire → UI.
- II. Test-First: co-land unit + widget tests.
- III. Green Commit Checkpoints before merge.
- IV-V. Co-located tests under package/app `test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-026-flutter-catalog-owned/
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
packages/manifest/lib/src/catalog/
  catalog_item.dart              # owned fields already present
  filter_catalog.dart            # + CatalogScope on filters
  owned_catalog.dart             # NEW: count map helpers + annotate
packages/manifest/test/
  owned_catalog_test.dart        # NEW
  filter_catalog_test.dart       # scope=owned cases

packages/db/lib/src/repos/
  inventory_records.dart         # + CatalogInstanceProjection helpers OR
  instance_projection.dart       # NEW pure project from InventoryItemRecord
packages/db/lib/destiny2_db.dart # export
packages/db/test/
  instance_projection_test.dart  # NEW

apps/windows_host/lib/catalog/
  catalog_page.dart              # All|Owned + instance panel
  owned_catalog_bridge.dart      # NEW: load inventory → annotate → filter
apps/windows_host/test/
  catalog_owned_page_test.dart   # NEW
```

## Implementation approach

1. Add `CatalogScope` + `scope` on `CatalogClientFilters`; filter drops non-owned when `owned`.
2. Pure `countOwnedByItemHash` + `annotateCatalogWithOwned` in manifest.
3. Pure `projectCatalogInstances` / `projectInstancesForHash` in db package from `InventoryItemRecord`.
4. Host bridge: resolve local user (session + ensureUser / inventorySync.localUserId), `listInventoryItems`, annotate base, browse with scope.
5. CatalogPage: scope chips, ownership subtitle, selection → instance list.
6. Tests + finish-spec merge; roadmap DART-026 done, pointer → DART-027.

## Structure Decision

Pure annotate/filter stay in `destiny2_manifest` (no Drift). Instance DTO + project live in `destiny2_db` next to inventory records. Host joins OfflineCatalog + DB without a second SQLite connection.
