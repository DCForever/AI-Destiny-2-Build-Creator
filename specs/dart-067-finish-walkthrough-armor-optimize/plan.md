# Implementation Plan: DART-067 Finish Walkthrough / Armor Optimize / Post-Sync

**Branch**: `dart-067-finish-walkthrough-armor-optimize` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-067-finish-walkthrough-armor-optimize/spec.md`

## Summary

Close host UI fidelity residuals: Finish one-tap Create/Capture/first-empty fill (Windows + Jaspr), Windows Build Finish armor improve (confirm-only), and Windows Settings post-sync better-kit banner (Confirm/Dismiss only). Reuse domain finish helpers and existing optimizer confirm path. Soft never auto-applies; no CLIENT_SECRET; cutover GO unchanged.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: Flutter (Windows host), Jaspr (web host), destiny2_domain, destiny2_app, destiny2_db  

**Storage**: Existing Drift sets/attachments/inventory (no schema change)  

**Testing**: `dart test` on packages/app + packages/domain; Flutter tests under apps/windows_host; Jaspr tests under apps/web_host  

**Target Platform**: Flutter Windows (primary for optimizer + post-sync); Jaspr web (walkthrough Create/Capture/fill only)  

**Project Type**: Multiplatform monorepo (Melos)  

**Performance Goals**: Post-sync suggestion scan best-effort; must not block sync success UX if scan fails  

**Constraints**: Soft never auto-applies; Find kits never writes; pure Dart I/O; no CLIENT_SECRET  

**Scale/Scope**: Three GAP closures; ≤ ~20 tasks

## Constitution Check

- I. Small Testable Increments: US1 Create, US2 Capture/fill, US3 armor improve, US4 post-sync — independently testable.
- II. Test-First: Use-case and pure helper tests before/with UI wiring.
- III. Green Commit Checkpoints: package tests then host tests before merge.
- Soft/hard: kit suggestions soft; equip finish gates unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/dart-067-finish-walkthrough-armor-optimize/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/domain/lib/src/evaluators/
  optimizer_score.dart          # + detectImprovement
packages/app/lib/src/
  finish_walkthrough_use_cases.dart
  optimizer_constraints_json.dart
  improvement_suggestions.dart
packages/app/test/
  finish_walkthrough_use_cases_test.dart
  improvement_suggestions_test.dart
  optimizer_constraints_json_test.dart
apps/windows_host/lib/builds/
  builds_library_controller.dart  # create/capture/fill finish actions
  builds_library_page.dart        # walkthrough UI + armor workspace
  finish_gaps_format.dart         # captions / action labels
apps/windows_host/lib/settings/
  inventory_sync_controller.dart  # post-sync suggestion hooks
  inventory_sync_card.dart        # banner Confirm/Dismiss
apps/web_host/lib/builds/
  builds_controller.dart
  build_compose_page.dart
  finish_gaps_format.dart
apps/*/test/
  finish_walkthrough_*_test.dart
  inventory_sync_*_post_sync_test.dart (windows)
```

## Implementation approach

### Phase A — Pure / app

1. `detectImprovement(current, candidate, priorities, preferReuse)` → compareCombinations < 0.
2. JSON parse/serialize for armor set optimizer constraints (eligibility + request fields).
3. `createSetAndAttach` + `createSetsFromBuild` (capture) use cases.
4. `buildImprovementSuggestions` (afterSync scan of constrained attached armor sets).

### Phase B — Windows Finish

1. Controller: finish step state helpers optional; methods oneTapCreate, captureCategory, fillFinishSlot.
2. UI: replace list-only finish panel with category actions + fill picker dialog + embedded OptimizerWorkspace for armor_optimize.
3. Tests for create/capture and confirm-only armor path wiring.

### Phase C — Windows post-sync

1. After successful sync, run suggestions (injectable for tests).
2. Banner UI Confirm/Dismiss; Confirm → applyArmorCombinationInPlace.
3. Test: sync alone does not apply; Confirm applies; Dismiss no write.

### Phase D — Jaspr Finish residual

1. Create/Capture/fill actions on finish panel; no optimizer / no post-sync banner.
2. Controller methods mirror Windows use cases.

### Phase E — Docs + merge

1. Mark GAPs closed in feature-gaps + ui-fidelity; roadmap DART-067 done; pointer DART-068.
2. Merge to feature/multiplatform-dart.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Full improve detection needs classType/candidates | Inject candidates in tests; production uses inventory map + set pieces |
| Capture mod empty | Skip mod like product; surface NOTHING_TO_CREATE |
| Scope creep into DART-068 chrome | Explicit non-goals |

## Complexity Tracking

None — reuses DART-007/036/057/025 paths.
