# Implementation Plan: DART-039 Flutter DIM Export UI

**Branch**: `dart-039-flutter-dim-export-ui` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-039-flutter-dim-export-ui/spec.md`

## Summary

Ship Windows Flutter **DIM jsonOnly clipboard export** on Builds library detail: equip-ready **gate**, **Copy DIM JSON** CTA using pure `buildJsonOnlyDimExport` (DART-010), clipboard write with status/preview. Blocked when not equip-ready. Soft never auto-applies; no CLIENT_SECRET; no dim.gg network.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter (windows_host)  
**Primary Dependencies**: `destiny2_domain` (`buildJsonOnlyDimExport`, `computeEquipReady`, DimLoadout), `destiny2_app` (`resolveUserVariant`, `getBuild`/`softStatTargets`), `destiny2_db` (inventory list), Flutter `services` clipboard  
**Storage**: Host single Drift `AppDatabase` (memory in tests) — read-only for export path  
**Testing**: `flutter test` in `apps/windows_host`  
**Target Platform**: Flutter Windows host  
**Project Type**: UI shell slice (P4)  
**Performance Goals**: Export is pure local JSON encode + clipboard; no network  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; equip-ready hard gate; soft never auto-applies; no dim.gg  
**Scale/Scope**: Dim export panel + controller + format helpers on Builds detail

## Constitution Check

- I. Small Testable Increments: US1 gate block, US2 clipboard success, US3 status/preview.
- II. Test-First: format + widget/controller tests co-landed.
- III. Green Commit Checkpoints: windows_host dim export tests green.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-039-flutter-dim-export-ui/
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
    dim_export/
      dim_export_format.dart      # pure labels, CTA enable, JSON encode
      dim_export_controller.dart  # readiness, build payload, clipboard
      dim_export_panel.dart       # CTA + readiness + status/preview UI
    builds/
      builds_library_page.dart    # embed DimExportPanel when variant selected
  test/
    dim_export_format_test.dart
    dim_export_panel_test.dart
  README.md
  pubspec.yaml
```

## Implementation approach

1. Pure `dim_export_format` helpers (CTA enablement, blocked summary, pretty JSON encode of map).
2. `DimExportController`: bind build/variant/user; refresh readiness via resolveUserVariant + inventory pin index; `requestExport` asserts via `buildJsonOnlyDimExport`, writes clipboard, stores last JSON / status.
3. `DimExportPanel` widget: readiness summary, Copy button, error/status, optional truncated preview.
4. Embed under Builds detail (after Equip panel or adjacent).
5. Tests: format unit; panel/controller: not-ready no clipboard; ready payload has `loadout`.
6. README + roadmap finish-spec merge to `feature/multiplatform-dart`.

## Structure Decision

Host UI only. Domain builders already exist (DART-010). No new package. No bungie dependency for this slice.
