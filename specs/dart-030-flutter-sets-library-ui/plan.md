# Implementation Plan: DART-030 Flutter Sets Library UI

**Branch**: `dart-030-flutter-sets-library-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-030-flutter-sets-library-ui/spec.md`

## Summary

Add a **Sets library** dual-pane screen to the Flutter Windows host: list + create/edit via `destiny2_app` set use cases, and **slot fill** through a catalog/owned picker reusing DART-026 bridges. Exit: create/edit set; fill slot from catalog/owned.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_app` (set use cases), `destiny2_db`, `destiny2_domain`, `destiny2_manifest` (catalog), `destiny2_ui_tokens` (rail width), Flutter Windows host  
**Storage**: Drift via existing single `AppServices.db` connection  
**Testing**: `flutter test` apps/windows_host (sets suite); pure mapping unit tests  
**Target Platform**: Flutter Windows host  
**Project Type**: Flutter UI + thin pure helpers  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; in-process use cases only  
**Scale/Scope**: One library screen + picker dialog; fixture-scale lists

## Constitution Check

- I. Small Testable Increments: pure slot map → controller → dual-pane UI → picker → nav.
- II. Test-First: co-land pure + widget tests with implementation.
- III. Green Commit Checkpoints before merge to `feature/multiplatform-dart`.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-030-flutter-sets-library-ui/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/windows_host/
  pubspec.yaml                    # + destiny2_app, destiny2_domain
  lib/
    app.dart                      # + Sets nav destination
    host_bootstrap.dart           # unchanged (reuse AppServices)
    sets/
      set_slot_mapping.dart       # pure slots-for-type + bucket map
      sets_library_controller.dart
      sets_library_page.dart      # dual-pane
      set_catalog_picker.dart     # All/Owned pick → UpsertSetItemCommand
  test/
    set_slot_mapping_test.dart
    sets_library_page_test.dart
```

## Implementation approach

1. **Pure mapping** — `slotsForSetType`, `isSlotValidForSetType`, `mapCatalogBucketToSetSlot`, catalog filter labels for a set slot (Kinetic↔primary, etc.).
2. **Controller** — resolve `userId` (signed-in / local-library); list/create/update/getDetail/upsert/remove via `destiny2_app`.
3. **SetsLibraryPage** — left rail list (`kFlapLibraryRailWidth`), create form, detail editor, slot rows with Fill / Clear.
4. **SetCatalogPicker** — dialog using `OwnedCatalogBridge`; scope All|Owned; optional instance list; returns pick result.
5. **Nav** — add Sets to `NavigationRail` + IndexedStack.
6. **Tests** + finish-spec merge; roadmap DART-030 done, pointer → DART-031.

## Structure Decision

UI lives only in `apps/windows_host` (Flutter shell). Use cases stay in `destiny2_app`. Pure slot strings align with domain `EquipmentSlot` / `FashionSlot` wire names and product `SLOTS_BY_SET_TYPE`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
