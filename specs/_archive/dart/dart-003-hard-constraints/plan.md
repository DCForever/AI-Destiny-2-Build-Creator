# Implementation Plan: DART-003 Hard Constraints

**Branch**: `dart-003-hard-constraints` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-003-hard-constraints/spec.md`

## Summary

Port pure hard-block evaluators from TypeScript `destinyBuildConstraints.ts` into `packages/domain` as Dart functions operating on DART-002 models. Golden tests mirror the vitest suite. Document `capacityResolved` semantics for subclass kit fragment enforcement.

## Technical Context

**Language/Version**: Dart SDK ≥ 3.5

**Primary Dependencies**: None at runtime (Dart SDK only). Dev: `test`, `lints`

**Storage**: N/A

**Testing**: `dart test packages/domain` / `melos run test`

**Target Platform**: Pure Dart VM

**Project Type**: Pure library extension (`destiny2_domain`)

**Performance Goals**: Evaluator calls trivial; full package tests &lt; 30s

**Constraints**: Zero IO/UI; hard vs soft separation preserved; stable failure codes; no auto-apply of soft guidance; no Node sidecar

**Scale/Scope**: One evaluator module + one golden test file + capacityResolved docs in research/quickstart/API comments

## Constitution Check

- I. Small Testable Increments: Pure evaluators only; no save pipeline.
- II. Test-First: Golden tests land with (or immediately before) implementation; parity with TS fixtures.
- III. Green Commit Checkpoints: Commit after tests + analyze green.
- IV-V. Co-located tests under `packages/domain/test/`.

No constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-003-hard-constraints/
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
  lib/
    destiny2_domain.dart                 # barrel (+ evaluator exports)
    src/
      models/                            # DART-002 (unchanged inputs)
      evaluators/
        destiny_build_constraints.dart   # pure hard evaluators
  test/
    smoke_test.dart
    models_test.dart
    hard_constraints_test.dart           # golden parity vs TS vitest
```

**Structure Decision**: Place evaluators under `lib/src/evaluators/` in the same pure package (DART-001 purity boundary). Do not introduce a second package for this slice.

## Implementation approach

1. Add `destiny_build_constraints.dart` with:
   - `maxSubclassAspects` re-export / use existing `maxSubclassAspects` from kit models
   - `evaluateExoticLimits(ExoticComposition)`
   - `evaluateSynergyRequirement(List<Object?> synergyTypes)` (or `Iterable` length-based)
   - `evaluateSubclassKit({...} | SubclassKitEvalInput)`
   - `evaluateModEnergy(List<ModEnergyPiece>)`
   - `evaluateExoticAbilityMatch({required, kit, pinnedSuper})`
   - `mergeConstraintEvaluations(List<ConstraintEvaluation> parts)`
2. Port helper logic: `uniquePositive`, `namesMatch` as private functions.
3. Golden tests: port every case from `destinyBuildConstraints.test.ts`.
4. Document `capacityResolved` in research.md, quickstart.md, and dartdoc on the eval input / function.

## Dependencies

- DART-002 models: `ExoticComposition`, `ModEnergyPiece`, `SubclassKitEvalInput`, `AbilityKit`, `HardBlock`, `SoftWarning`, `ConstraintEvaluation`, `DomainFailureCodes`.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Message string drift vs TS | Copy TS message templates exactly in Dart |
| capacityResolved default wrong | Explicit tests for omit/true/false; document |
| Soft warning logic subtle | Port control-flow from TS lines 190–197 verbatim |

## Finish criteria

- Tasks marked complete; tests green; branch merged to `feature/multiplatform-dart`; roadmap row **done**; Current pointer → DART-004.
