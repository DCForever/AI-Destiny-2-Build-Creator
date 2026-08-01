# Implementation Plan: DART-008 Optimizer Core

**Branch**: `dart-008-optimizer-core` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-008-optimizer-core/spec.md`

## Summary

Port pure armor optimizer enumerate / prune / score (+ kit constraints required by enumerate) into `packages/domain` with golden parity against TypeScript `src/lib/optimizer/{enumerate,prune,score,constraints}.ts`. Unit tests on small fixture boards; truncation flags for `maxCombinations`. No Flutter isolate, inventory load, or optimizeArmor orchestration.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Correctness over speed; default max 250k is API parity only (tests use tiny caps)  
**Constraints**: Zero IO/UI deps; pure Dart only; no Node sidecar; soft never hard-blocks enumerate  
**Scale/Scope**: Candidate/kit models + four evaluator modules + one focused test file (or split by area)

## Constitution Check

- I. Small Testable Increments: US1 enumerate, US2 prune, US3 score — independently testable.
- II. Test-First: Golden tests with implementation; suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-008-optimizer-core/
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
│       ├── models/
│       │   └── optimizer.dart          # NEW — CandidatePiece, KitConstraints, results
│       └── evaluators/
│           ├── optimizer_constraints.dart  # NEW
│           ├── optimizer_enumerate.dart    # NEW
│           ├── optimizer_prune.dart        # NEW
│           └── optimizer_score.dart        # NEW
└── test/
    └── optimizer_core_test.dart            # NEW
```

## Implementation approach

1. Add pure optimizer DTOs in `models/optimizer.dart` (reuse `EquipmentSlot.armorSlots`, `ArmorStatName`).
2. Port kit constraint validators and set-bonus summary.
3. Port score helpers (estimate, sum, compare, soft thresholds, incomplete).
4. Port prune (top-K + locked exotic + set-bonus family retain).
5. Port enumerate (DFS, early dual-exotic skip, maxCombinations truncation).
6. Export from library barrel; golden tests from TS vitest files.
7. Keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into optimizeArmor pipeline | Explicit out-of-scope; only core pure functions |
| Soft thresholds mistaken for hard filters | isKitValid never reads thresholds; tests assert soft separate |
| Slot order drift | Use EquipmentSlot.armorSlots only |
| Truncation off-by-one | Match TS: flag when evaluated >= max before counting next |

## Complexity Tracking

None — pure function port with existing enums.
