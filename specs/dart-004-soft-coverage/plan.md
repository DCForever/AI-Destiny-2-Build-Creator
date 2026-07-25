# Implementation Plan: DART-004 Soft Coverage

**Branch**: `dart-004-soft-coverage` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-004-soft-coverage/spec.md`

## Summary

Port pure soft-coverage and soft-stat estimate/target helpers into `packages/domain` with golden parity against TypeScript `coverage.ts`, `statEstimate.ts`, `softStatTargets.ts` (pure core), and `statNudges.ts`. Soft results use DART-002 coverage/soft-stat models and must never imply hard blocks. No save-path orchestration or IO.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Negligible; pure in-memory evaluators  
**Constraints**: Zero IO/UI deps; soft never hard-blocks; no auto-apply; no Node sidecar  
**Scale/Scope**: One package surface + one primary test file

## Constitution Check

- I. Small Testable Increments: US1 coverage, US2 soft-stats, US3 separation tests — each independently testable.
- II. Test-First: Golden tests written with implementation; full suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`; pure validation for soft-stat normalize.

## Project Structure

### Documentation (this feature)

```text
specs/dart-004-soft-coverage/
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
│   ├── destiny2_domain.dart          # exports
│   └── src/
│       ├── models/                   # DART-002 (reuse + small input DTOs)
│       │   ├── coverage.dart
│       │   ├── soft_stats.dart
│       │   ├── set_bonus.dart        # NEW pure SetBonusRecord
│       │   └── ...
│       └── evaluators/
│           ├── destiny_build_constraints.dart  # DART-003 (unchanged)
│           ├── soft_coverage.dart              # NEW
│           ├── stat_estimate.dart              # NEW
│           ├── soft_stat_targets.dart          # NEW
│           └── stat_nudges.dart                # NEW
└── test/
    ├── hard_constraints_test.dart
    ├── soft_coverage_test.dart       # NEW
    └── models_test.dart
```

## Implementation approach

1. Add pure `SetBonusRecord` / inventory stat map types for evaluator inputs.
2. Port `tierForMatches`, `matchEvidenceLink`, `evaluateCoverage` (including set-bonus soft rows + element soft mismatches + softStats attachment).
3. Port `estimateLoadoutStats` + `softStatWarnings`.
4. Port `normalizeSoftStatTargets` / `mergeSoftStatTargets` with `armorStatMax = 200` and domain validation exception (`INVALID_ITEM`).
5. Port `suggestStatNudges` / `targetsFromAcceptedNudges`.
6. Golden tests + hard/soft separation assertions.
7. Export from library barrel; keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Soft results mistaken for hard blocks | Explicit tests; `CoverageResult` has no hardBlocks field; separation group in tests |
| Inventory/manifest leakage into domain | Only pure maps/DTOs as inputs |
| Over-scoping save pipeline | Explicitly out of scope; no buildService port |

## Complexity Tracking

None — pure function port with existing models.
