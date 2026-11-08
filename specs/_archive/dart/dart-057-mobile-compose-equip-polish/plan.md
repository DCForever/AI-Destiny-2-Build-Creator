# Implementation Plan: DART-057 Mobile Compose / Equip Polish

**Branch**: `dart-057-mobile-compose-equip-polish` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-057-mobile-compose-equip-polish/spec.md`

## Summary

Close residual P7 polish: publish the mobile AppShell surface matrix (product-mark equip/catalog/DIM N/A on phone), complete Jaspr soft-stat editor for all `ArmorStatName`, and wire pure `evaluateFinishGaps` into Windows + Jaspr compose with finish-complete ∧ equip-ready CTA policy. Optimizer mobile/web stays deferred.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: Flutter (mobile/windows hosts), Jaspr (web_host), `destiny2_domain` pure evaluators, `destiny2_app` / Drift use cases (unchanged)  

**Storage**: Existing Drift `AppDatabase` — no schema changes  

**Testing**: `flutter test` (mobile_host, windows_host), `dart test` (web_host)  

**Target Platform**: Flutter Android/iOS (matrix + Settings), Flutter Windows (finish gaps + CTA), Jaspr web (soft stats + finish gaps + CTA)  

**Project Type**: Multiplatform monorepo hosts  

**Performance Goals**: Finish-gap eval is pure in-memory from already-loaded attachments/pins — no extra network  

**Constraints**: Pure domain remains IO-free; soft never auto-applies; no CLIENT_SECRET; no Node sidecar  

**Scale/Scope**: Three hosts touch UI; one shared domain API already shipped (DART-007)

## Constitution Check

- I. Small Testable Increments: US1 matrix → US2 soft stats → US3 finish gaps  
- II. Test-First: format/nav/finish tests land with implementation  
- III. Green Commit Checkpoints: host test suites green before merge  
- IV–V. Co-located host tests; validation via normalizeSoftStatTargets / evaluateFinishGaps  

## Project Structure

### Documentation (this feature)

```text
specs/dart-057-mobile-compose-equip-polish/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code (touched)

```text
apps/mobile_host/lib/
  surface_matrix.dart          # published matrix + nav keys
  app.dart                     # unchanged nav (asserted)
  settings/settings_page.dart  # matrix card
  builds/build_detail_page.dart # optional finish display
  builds/finish_gaps_format.dart
  builds/builds_controller.dart # finishGaps getter
apps/mobile_host/test/
  shell_nav_test.dart
  surface_matrix_test.dart
  finish_gaps_format_test.dart

apps/web_host/lib/
  builds/build_compose_page.dart  # all ArmorStatName + finish panel + CTA gates
  builds/builds_controller.dart   # finishGaps getter
  compose/finish_gaps_format.dart
  equip/equip_format.dart         # finish-aware CTA helper
  dim_export/dim_export_format.dart
apps/web_host/test/
  soft_guidance_format_test.dart
  finish_gaps_format_test.dart
  equip_format_test.dart
  dim_export_format_test.dart

apps/windows_host/lib/
  builds/builds_library_controller.dart
  builds/builds_library_page.dart
  builds/finish_gaps_format.dart
  equip/equip_panel.dart
  equip/equip_format.dart
  dim_export/dim_export_panel.dart
  dim_export/dim_export_format.dart
apps/windows_host/test/
  finish_gaps_format_test.dart
  equip_format_test.dart
  dim_export_format_test.dart

docs/multiplatform-dart-feature-gaps.md
docs/multiplatform-dart-slice-roadmap.md
docs/multiplatform-dart-cutover-parity-checklist.md  # finish residual note
```

## Implementation approach

### US1 — Mobile matrix

1. Add `surface_matrix.dart` with status enum + const entries + `kMobileBottomNavKeys`.
2. Settings card lists matrix rows.
3. Tests: matrix completeness; shell_nav still Builds|Settings; nav keys ⊆ matrix shipped destinations.

### US2 — Jaspr soft stats

1. Replace single Health field with map of controllers / field state for `ArmorStatName.all`.
2. Save via existing `saveSoftStatTargetsFromFields`.
3. Extend soft_guidance_format tests for multi-stat maps.

### US3 — Finish gaps hosts

1. Shared-pattern pure helper `buildFinishGapsInput` + formatters per host (duplicate thin host format files — no Flutter in domain).
2. Controllers expose `FinishGapsResult? get finishGaps` from attachments + slot pins.
3. UI section: category rows, complete chip, policy caption.
4. Equip/DIM panels accept `finishComplete`; CTA = existing equipReady gates ∧ finishComplete.
5. Format tests cover policy AND.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Per-host finish_gaps_format.dart copies | Hosts cannot share Flutter/Jaspr widgets; domain already owns pure eval | Single package of UI strings would pull UI into domain or add ui package churn for thin formatters |
