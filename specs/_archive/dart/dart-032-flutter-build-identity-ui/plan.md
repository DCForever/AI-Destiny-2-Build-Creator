# Implementation Plan: DART-032 Flutter Build Identity UI

**Branch**: `dart-032-flutter-build-identity-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-032-flutter-build-identity-ui/spec.md`

## Summary

Add a **Builds library** dual-pane screen to the Flutter Windows host: list + create/edit **identity** via `destiny2_app` build use cases (class, synergy types, exotic/super pins). Exit: create build with synergy types.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_app` (build use cases), `destiny2_db`, `destiny2_domain`, `destiny2_ui_tokens`, Flutter Windows host  
**Storage**: Drift via existing single `AppServices.db` connection  
**Testing**: `flutter test` apps/windows_host (builds suite)  
**Target Platform**: Flutter Windows host  
**Project Type**: Flutter UI + thin pure helpers  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; in-process use cases only  
**Scale/Scope**: One library screen; fixture-scale lists

## Constitution Check

- I. Small Testable Increments: pure helpers → controller → dual-pane UI → identity edit → nav.
- II. Test-First: co-land widget tests with implementation.
- III. Green Commit Checkpoints before merge to `feature/multiplatform-dart`.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-032-flutter-build-identity-ui/
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
    app.dart                            # + Builds nav destination
    builds/
      build_identity_format.dart        # pure format helpers (designations, exotics summary)
      builds_library_controller.dart
      builds_library_page.dart          # dual-pane + create/identity detail
  test/
    build_identity_format_test.dart
    builds_library_page_test.dart
```

## Implementation approach

1. **Pure helpers** — format designation list (`melee::Base, grenade`), exotics summary, identity class label.
2. **Controller** — resolve `userId` (local-library pattern); list/create/get/update via `createUserBuild` / `listUserBuilds` / `getBuildDetail` / `updateUserBuild`; draft synergy designations for create form.
3. **BuildsLibraryPage** — left rail (`kFlapLibraryRailWidth` + `kFlapColumnsBuilds`), create form (name/class/synergy chips/exotic/super optional), detail with identity fields + rename/save.
4. **Nav** — add Builds to `NavigationRail` + IndexedStack (Catalog, Sets, Synergies, Builds, Settings).
5. **Tests** + finish-spec merge; roadmap DART-032 done, pointer → DART-033.

## Structure Decision

UI lives only in `apps/windows_host`. Use cases stay in `destiny2_app` (already enforce `NO_SYNERGY` and identity hard gates). No new package.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
