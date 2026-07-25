# Implementation Plan: DART-005 Resolve Variant

**Branch**: `dart-005-resolve-variant` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-005-resolve-variant/spec.md`

## Summary

Port pure resolveVariant merge/conflict/completeness helpers into `packages/domain` with golden parity against TypeScript `src/lib/builds/resolveVariant.ts` pure functions. No DB expansion, no equip-ready, no save orchestration. Claims-only resolve returns `ResolvedVariantEquipment`; asserts throw domain exceptions with stable product codes.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Negligible; pure in-memory  
**Constraints**: Zero IO/UI deps; pure Dart only; no Node sidecar; soft guidance not in scope  
**Scale/Scope**: One evaluator module + one test file

## Constitution Check

- I. Small Testable Increments: US1 conflicts, US2 exotic/pair, US3 completeness — each independently testable.
- II. Test-First: Golden tests with implementation; suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-005-resolve-variant/
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
│       ├── models/                    # DART-002 (reuse)
│       └── evaluators/
│           ├── destiny_build_constraints.dart
│           ├── soft_coverage.dart
│           ├── ...
│           └── resolve_variant.dart   # NEW
└── test/
    └── resolve_variant_test.dart      # NEW
```

## Implementation approach

1. Add `ResolveVariantException` with `code`, `message`, optional `details`.
2. Port pure helpers: conflicts, equipment map, claims conversion, exotic inject, pair match, effective weapon.
3. Port asserts for conflicts / empty / full combat loadout (default completeness).
4. Port pure orchestration `resolveVariantClaims` (expanded items + build/variant + optional slots).
5. Optional thin `assertVariantCompleteness` branching on `isDefault` for FR-006 clarity.
6. Golden tests from `resolveVariant.test.ts` + default vs non-default completeness.
7. Export from library barrel; keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Accidental DB load port | Scope only pure helpers; no AppDatabase types |
| Completeness confused with equip-ready | Equip stays DART-006; only DBR-CMPL empty/full rules here |
| ApiError coupling | Domain exception with same codes |

## Complexity Tracking

None — pure function port with existing models.
