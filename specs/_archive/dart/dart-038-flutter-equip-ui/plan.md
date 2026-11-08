# Implementation Plan: DART-038 Flutter Equip UI

**Branch**: `dart-038-flutter-equip-ui` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-038-flutter-equip-ui/spec.md`

## Summary

Ship Windows Flutter **equip UI** on Builds library detail: class-filtered **character pick**, equip-ready **gate**, **gaps confirm** when empty combat slots remain, **Apply** → `planEquipSteps` + `executeEquipPlan` (DART-037), and **step report**. Soft never auto-applies; no CLIENT_SECRET.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter (windows_host)  
**Primary Dependencies**: `destiny2_domain` (equipReady, planEquipSteps), `destiny2_bungie` (getCharacters, write client, executeEquipPlan, syncIfStale), `destiny2_app` (resolveUserVariant), `destiny2_db` (inventory list), `destiny2_ui_tokens`  
**Storage**: Host single Drift `AppDatabase` (memory in tests)  
**Testing**: `flutter test` in `apps/windows_host`; `dart test` in `packages/bungie` for getCharacters parse  
**Target Platform**: Flutter Windows host  
**Project Type**: UI shell slice (P4)  
**Performance Goals**: Equip busy indicator; network only for characters + optional sync + write steps  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; equip-ready hard gate; soft never auto-applies  
**Scale/Scope**: Equip panel + controller + format helpers on Builds detail; character list API on profile client

## Constitution Check

- I. Small Testable Increments: US1 gate/character, US2 gaps+report, US3 hard block.
- II. Test-First: format + widget/controller tests co-landed.
- III. Green Commit Checkpoints: windows_host + bungie tests for this slice.
- IV-V. Co-located tests under `apps/windows_host/test/` and `packages/bungie/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-038-flutter-equip-ui/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/bungie/
  lib/src/profile/
    profile_types.dart            # + CharacterSummary
    bungie_profile_client.dart    # + getCharacters
    character_parse.dart          # parse characters component 200 (new)
  test/
    character_parse_test.dart     # or extend profile_client_test

apps/windows_host/
  lib/
    equip/
      equip_format.dart           # pure labels, CTA enable, step report lines
      equip_controller.dart       # readiness, characters, gaps confirm, execute
      equip_panel.dart            # character pick + CTA + gaps + step report UI
    builds/
      builds_library_page.dart    # embed EquipPanel when variant selected
    host_bootstrap.dart           # optional writeClient on AppServices
  test/
    equip_format_test.dart
    equip_panel_test.dart
  README.md
  pubspec.yaml
```

## Implementation approach

1. Add `CharacterSummary` + `getCharacters` (profile components=200) with class wire names Titan/Hunter/Warlock.
2. Pure `equip_format` helpers (pin gap label, empty combat summary, step line, CTA enablement predicate).
3. `EquipController`: refresh readiness via resolveUserVariant + inventory pin index; load characters; select character; `requestEquip` enforces gate; empty combat gaps → pending confirm; execute plan with write client; store `EquipStatus` for report.
4. `EquipPanel` widget: dropdown/list of matching characters, readiness/gaps list, Apply button, confirm dialog, step report.
5. Embed under Builds detail (after variant compose / before or after soft guidance).
6. Tests: format unit; panel/controller: not-ready no write; gaps cancel/confirm; mock success step report.
7. README + roadmap finish-spec merge to `feature/multiplatform-dart`.

## Structure Decision

Host UI + minimal bungie profile surface for characters. Domain equip-ready/plan and bungie write/orchestrator already exist (DART-006/037). No new package.
