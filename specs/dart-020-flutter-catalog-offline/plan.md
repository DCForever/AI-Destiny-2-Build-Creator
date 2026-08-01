# Implementation Plan: DART-020 Flutter Catalog Offline

**Branch**: `dart-020-flutter-catalog-offline` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-020-flutter-catalog-offline/spec.md`

## Summary

Add **offline catalog facets + browse**: pure `filterCatalogClient` / `FacetFilter` port in `packages/manifest`, project MVP entity stores into `CatalogItem`s, expose `OfflineCatalog` loader, and a Flutter Catalog screen on the Windows host. No inventory, no OAuth. Completes **P1 phase gate**.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (stable)  
**Primary Dependencies**: Existing `destiny2_manifest`, `destiny2_storage`, Flutter host; no new runtime packages  
**Storage**: Entity JSON under StorageRoot (read-only for catalog); Drift remains single connection for app.db only  
**Testing**: `dart test packages/manifest`; `flutter test` in `apps/windows_host`  
**Target Platform**: Windows desktop host + pure library  
**Project Type**: Library catalog module + Flutter UI screen  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no inventory  
**Scale/Scope**: MVP stores; fixture-scale lists; simple ListView

## Constitution Check

- I. Small Testable Increments: pure filter → projector → offline service → UI.
- II. Test-First: co-land pure + widget tests.
- III. Green Commit Checkpoints: dart/flutter test green before merge.
- IV-V. Co-located tests under package/app `test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-020-flutter-catalog-offline/
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
  catalog_item.dart          # CatalogItem DTO
  facet_filter.dart          # FacetFilter + chip helpers
  filter_catalog.dart        # filterCatalogClient
  filter_options.dart        # chip option constants
  catalog_projector.dart     # MVP records → CatalogItem
  offline_catalog.dart       # load + filter from FileEntityCache
packages/manifest/lib/destiny2_manifest.dart  # exports
packages/manifest/test/
  filter_catalog_test.dart
  catalog_projector_test.dart
  offline_catalog_test.dart

apps/windows_host/lib/
  host_bootstrap.dart        # + OfflineCatalog on AppServices
  app.dart                   # shell with nav Catalog | Settings
  catalog/
    catalog_page.dart        # browse UI
  settings/settings_page.dart
apps/windows_host/test/
  catalog_page_test.dart
```

## Implementation approach

1. Port facet + filter pure API from `src/lib/catalog/filterCatalogClient.ts`.
2. Define CatalogItem (owned always false for now).
3. Projector: weapons, exotic-armor, aspects, fragments, abilities, mods → CatalogItem.
4. OfflineCatalog: resolve version from current-version.json (or inject); load stores; cache base list; `browse(filters)`.
5. Flutter CatalogPage: TextField + FilterChips (element, ammo, exotic tri-state, optional class/slot) + ListView.
6. App shell: NavigationRail or Bottom/Destination bar Catalog + Settings.
7. Tests + docs + finish-spec merge; mark P1 gate done on roadmap.

## Structure Decision

Catalog pure code stays in **`destiny2_manifest`** (entity-adjacent). Flutter UI only in **`apps/windows_host`**. No new package.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| None | — | — |
