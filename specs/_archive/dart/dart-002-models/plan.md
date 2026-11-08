# Implementation Plan: DART-002 Models

**Branch**: `dart-002-models` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-002-models/spec.md`

## Summary

Add pure immutable domain DTOs to `packages/domain` for claims, pins, kits, coverage results, failure codes, and core build/variant/set/synergy shapes used by later pure evaluators. Zero IO/UI deps; no evaluator algorithms in this slice.

## Technical Context

**Language/Version**: Dart SDK ≥ 3.5 (3.11 available)

**Primary Dependencies**: None at runtime (Dart SDK only). Dev: `test`, `lints`

**Storage**: N/A

**Testing**: `dart test packages/domain` / `melos run test`

**Target Platform**: Pure Dart VM

**Project Type**: Pure library package extension (`destiny2_domain`)

**Performance Goals**: Model construction trivial; full package tests &lt; 30s

**Constraints**: Zero IO/UI in domain; soft vs hard types distinct; wire-name parity with TS for slots/set types/failure codes; no freezed codegen this slice (pure Dart equivalent)

**Scale/Scope**: Models under `packages/domain/lib/src/models/`; barrel export; unit tests for construction/parity

## Constitution Check

- I. Small Testable Increments: Models only; algorithms deferred.
- II. Test-First: Model tests land with types; assert wire codes/slots.
- III. Green Commit Checkpoints: Commit after tests green.
- IV-V. Co-located tests under `packages/domain/test/`.

No constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-002-models/
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
    destiny2_domain.dart          # barrel (+ model exports)
    src/
      smoke.dart
      models/
        equipment.dart            # EquipmentSlot, SetType, ClaimSource, FashionSlot
        slot_claim.dart           # SlotClaim, ExpandedSetItem, SlotConflict
        resolved_variant.dart     # ResolvedVariantEquipment
        pin.dart                  # PinStatusKind, PinStaleReason, PinStatus, EquipReadyResult
        failure_codes.dart        # DomainFailureCodes
        constraints.dart          # HardBlock, SoftWarning, ConstraintEvaluation
        kit.dart                  # SubclassKit, AbilityKit, ExoticComposition, ModEnergyPiece
        coverage.dart             # CoverageTier, rows, CoverageResult
        soft_stats.dart           # ArmorStatName, SoftStatTargets shape, estimate/warning rows
        synergy.dart              # SynergyType, link kinds, designations, Synergy, SynergyLink
        library.dart              # Build, Variant, GearSet, SetItem, Attachment, SnapshotConfig
  test/
    smoke_test.dart
    models_test.dart
```

**Structure Decision**: Keep models inside `destiny2_domain` (single purity boundary from DART-001). Hand-written immutable classes (freezed-equivalent).

## Complexity Tracking

> None — pure value types only.
