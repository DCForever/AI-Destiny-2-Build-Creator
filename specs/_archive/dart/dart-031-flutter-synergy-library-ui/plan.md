# Implementation Plan: DART-031 Flutter Synergy Library UI

**Branch**: `dart-031-flutter-synergy-library-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-031-flutter-synergy-library-ui/spec.md`

## Summary

Add a **Synergy library** dual-pane screen to the Flutter Windows host: list + create/edit via `destiny2_app` synergy use cases, **immutable designation** after create, and **evidence links** editor. Exit: create synergy; designation immutable after create.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_app` (synergy use cases), `destiny2_db`, `destiny2_domain`, `destiny2_ui_tokens`, Flutter Windows host  
**Storage**: Drift via existing single `AppServices.db` connection  
**Testing**: `flutter test` apps/windows_host (synergy suite)  
**Target Platform**: Flutter Windows host  
**Project Type**: Flutter UI + thin pure helpers  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; in-process use cases only  
**Scale/Scope**: One library screen; fixture-scale lists

## Constitution Check

- I. Small Testable Increments: pure helpers → controller → dual-pane UI → links editor → nav.
- II. Test-First: co-land widget tests with implementation.
- III. Green Commit Checkpoints before merge to `feature/multiplatform-dart`.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-031-flutter-synergy-library-ui/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/windows_host/
  lib/
    app.dart                            # + Synergies nav destination
    synergies/
      synergy_designation.dart          # pure designationKey display helper
      synergies_library_controller.dart
      synergies_library_page.dart       # dual-pane + links editor
  test/
    synergy_designation_test.dart
    synergies_library_page_test.dart
```

## Implementation approach

1. **Pure helper** — `formatSynergyDesignation(type, subType)` → `type` or `type::subType` (parity with domain designationKey).
2. **Controller** — resolve `userId` (reuse local-library pattern from DART-030); list/create/get/update via `destiny2_app` synergy use cases; methods for save identity, save links; optional probe that designation change errors.
3. **SynergiesLibraryPage** — left rail (`kFlapLibraryRailWidth` + `kFlapColumnsSynergy` headers), create form (name/type/subtype/description), detail with immutable designation chips, evidence link list + add form + save.
4. **Nav** — add Synergies to `NavigationRail` + IndexedStack (order: Catalog, Sets, Synergies, Settings).
5. **Tests** + finish-spec merge; roadmap DART-031 done, pointer → DART-032.

## Structure Decision

UI lives only in `apps/windows_host`. Use cases stay in `destiny2_app` (already enforce designation immutability). No new package.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
