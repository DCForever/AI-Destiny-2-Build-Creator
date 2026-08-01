# Implementation Plan: DART-007 Finish Gaps

**Branch**: `dart-007-finish-gaps` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-007-finish-gaps/spec.md`

## Summary

Port pure `evaluateFinishGaps` and next-slot / post-mutation walkthrough helpers into `packages/domain` with golden parity against TypeScript `finishGaps.ts` and `finishNextSlot.ts`. Gap list must be stable for default vs non-default fixtures (same attachments/equipment → same gaps; only the default flag on the result differs). No UI, optimizer, or IO.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Negligible; pure in-memory  
**Constraints**: Zero IO/UI deps; pure Dart only; no Node sidecar; soft never auto-applies  
**Scale/Scope**: Two evaluator modules + one test file (or two)

## Constitution Check

- I. Small Testable Increments: US1 gaps, US2 default stability, US3 next-slot — independently testable.
- II. Test-First: Golden tests with implementation; suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-007-finish-gaps/
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
packages/domain/
├── lib/
│   ├── destiny2_domain.dart
│   └── src/
│       ├── models/                    # reuse EquipmentSlot, SetType, AttachmentMode
│       └── evaluators/
│           ├── finish_gaps.dart       # NEW
│           └── finish_next_slot.dart  # NEW
└── test/
    └── finish_gaps_test.dart          # NEW (gaps + next-slot + default stability)
```

## Implementation approach

1. Add finish gap enums/DTOs and `evaluateFinishGaps` in `finish_gaps.dart`.
2. Use `EquipmentSlot.armorSlots` / `weaponSlots` wire names for required slots.
3. Port covering preference (live over snapshot), mod special case, nextActionable skip logic.
4. Port next-slot helpers in `finish_next_slot.dart`.
5. Golden tests from both TS test files + explicit default vs non-default pair.
6. Export from library barrel; update package description; keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Confusing finish gaps with resolve completeness | Completeness is DART-005; finish gaps are set/fill coverage for guided walkthrough |
| Soft mod coverage leaking auto-apply | Only explicit `hasModCoverage` boolean input |
| Slot name `class` vs `class_item` | Always product wire `class_item` from EquipmentSlot |

## Complexity Tracking

None — pure function port with existing slot/set enums.
