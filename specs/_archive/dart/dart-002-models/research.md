# Research: DART-002 Models

**Date**: 2026-07-24

## 1. Where do models live?

**Decision**: Extend existing `packages/domain` (`destiny2_domain`).

**Rationale**: DART-001 reserved this package for models + evaluators; roadmap “models package” means the pure package surface, not a second pub package. One purity boundary simplifies DART-011 graph lint.

**Alternatives rejected**: Separate `packages/models` (extra workspace churn without benefit at P0).

## 2. freezed vs pure Dart classes

**Decision**: Pure Dart 3 immutable classes + enums with wire `name` fields; no freezed/build_runner.

**Rationale**: Exit criteria allow “freezed (or equivalent)”. Codegen adds CI steps and generated files without serialization needs yet. Hand-written `==`/`hashCode` is enough for value equality in tests and later pure pipelines.

**Alternatives rejected**: freezed + json_serializable (defer until wire codecs are required).

## 3. TypeScript sources of truth

| Dart model group | TS source |
| ---------------- | --------- |
| SlotClaim, ResolvedVariantEquipment, ExpandedSetItem | `src/lib/builds/resolveVariant.ts` |
| PinStatus, EquipReadyResult | `src/lib/builds/equipReady.ts` |
| HardBlock, SoftWarning, ConstraintEvaluation, kit/mod/exotic inputs | `src/lib/builds/destinyBuildConstraints.ts` |
| CoverageResult tree | `src/lib/builds/coverage.ts` |
| Soft stats | `src/lib/builds/softStatTargets.ts`, `statEstimate.ts`, `src/data/rules/statBenefits.ts` |
| Equipment slots / set types | `src/lib/sets/schemas.ts` |
| Build/Variant/Attachment | repositories + `builds/schemas.ts` |
| Synergy + links | `synergies/schemas.ts`, `synergyRepository.ts` |
| Failure codes | `src/lib/api/errors.ts` + hard evaluator codes |

## 4. Failure codes scope

**Decision**: Export a `DomainFailureCodes` class of string constants covering pure hard-gate codes plus resolve/equip codes evaluators and pure gates reference: `TOO_MANY_EXOTICS`, `ILLEGAL_SUBCLASS_KIT`, `MOD_ENERGY_EXCEEDED`, `EXOTIC_ABILITY_MISMATCH`, `NO_SYNERGY`, `SLOT_CONFLICT`, `PAIR_ARMOR_MISMATCH`, `VARIANT_EMPTY`, `DEFAULT_VARIANT_INCOMPLETE`, `NOT_EQUIP_READY`. Omit pure HTTP/CRUD codes (`DUPLICATE_SET_NAME`, etc.) from this slice unless needed by pure shapes.

## 5. Soft vs hard separation

**Decision**: Separate types (`HardBlock` vs soft coverage rows / `SoftWarning`). Soft types never subclass hard blocks.

**Rationale**: DBR soft guidance never auto-applies; models encode the distinction for later slices.

## 6. Naming

- `GearSet` for product “Set” (avoids Dart `Set` collection).
- Enum wire names use TS snake_case strings (`class_item`).
- Package public barrel: `package:destiny2_domain/destiny2_domain.dart`.
