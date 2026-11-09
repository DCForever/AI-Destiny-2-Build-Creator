# Implementation Plan: DART-036 Flutter Optimizer UI

**Branch**: `dart-036-flutter-optimizer-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-036-flutter-optimizer-ui/spec.md`

## Summary

Ship a Windows Flutter **Armor optimizer workspace** on Sets library armor detail: goals → **Find kits** (isolate optimize, no writes) → ranked suggestions → **explicit confirm** before apply-in-place or materialize. Soft goals never auto-apply; exit criterion is suggest → user confirm.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter (windows_host)  
**Primary Dependencies**: `destiny2_app` (optimize isolate, materialize/apply), `destiny2_domain` (DTOs), `destiny2_db` (sets/inventory), optional `destiny2_manifest` catalog for names/exotic, `destiny2_ui_tokens`  
**Storage**: Host single Drift `AppDatabase` (memory in tests)  
**Testing**: `flutter test` in `apps/windows_host` (format unit + workspace widget tests)  
**Target Platform**: Flutter Windows host  
**Project Type**: UI shell slice (P4)  
**Performance Goals**: Find kits awaits isolate; UI shows busy state; no UI-thread enumerate  
**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; never silent apply  
**Scale/Scope**: One workspace widget + controller + pure helpers on Sets detail; not full product Finish chrome polish

## Constitution Check

- I. Small Testable Increments: US1 Find kits, US2 confirm apply/materialize, US3 empty/errors.
- II. Test-First: format tests + widget tests co-landed; green before merge.
- III. Green Commit Checkpoints: host flutter tests for optimizer slice.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-036-flutter-optimizer-ui/
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
    optimizer/
      optimizer_format.dart           # pure labels, captions, combo summaries
      optimizer_candidate_map.dart    # inventory bucket → CandidatePiece helpers
      optimizer_controller.dart       # goals, find kits, pending confirm, apply/materialize
      optimizer_workspace.dart        # goals + suggestions + confirm dialog UI
    sets/
      sets_library_page.dart          # embed workspace when armor set selected
  test/
    optimizer_format_test.dart
    optimizer_workspace_test.dart
  README.md                           # document optimizer workspace
  pubspec.yaml                        # description bump DART-036
```

## Implementation approach

1. Pure `optimizer_format` helpers (advisory caption, combo piece line, empty-reason label, top-N window).
2. `optimizer_candidate_map`: map inventory bucket labels (Helmet/Gauntlets/…) → `EquipmentSlot`; parse optional stat maps; optional catalog exotic/name.
3. `OptimizerController`: draft goals; injectable candidates + optimize/materialize/apply runners; `findKits` (no write); `requestApply` / `requestMaterialize` set pending; `confirmPending` / `cancelPending` for confirm-only path.
4. `OptimizerWorkspace` widget: goals form, Find kits, suggestion list (top-3 + see all), confirm dialog, advisory caption.
5. Embed under Sets detail slots for `SetType.armor`.
6. Tests: format unit; workspace: find-no-write, cancel-no-write, confirm-apply writes five slots.
7. README + roadmap finish-spec merge to `feature/multiplatform-dart`.

## Structure Decision

Host UI only; domain/app packages already provide pipeline + confirm-only use cases (DART-035). No new package.
