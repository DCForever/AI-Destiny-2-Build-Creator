# Data Model: DART-003 Hard Constraints

**Date**: 2026-07-24  
**Note**: Inputs/outputs reuse DART-002 models. This slice adds pure functions, not new persisted entities.

## Inputs (existing)

| Type | Role |
| ---- | ---- |
| `ExoticComposition` | `exoticWeaponHashes`, `exoticArmorHashes` |
| `ModEnergyPiece` | `slot`, `energyUsed`, `energyCapacity` |
| `SubclassKitEvalInput` | `aspectCount`, `fragmentCount`, `fragmentCapacity`, `maxAspects`, `capacityResolved` |
| `AbilityKit` | `superAbility`, `melee`, `grenade`, `classAbility` |
| Synergy designation list | Any non-empty list satisfies; emptiness triggers `NO_SYNERGY` (length only) |

## Outputs (existing)

| Type | Role |
| ---- | ---- |
| `HardBlock` | `code` + `message` — save-blocking |
| `SoftWarning` | `code` + `message` — guidance only |
| `ConstraintEvaluation` | `hardBlocks` + `softWarnings`; `isHardBlocked` |

## Evaluators (new pure functions)

| Function | Hard codes | Soft codes |
| -------- | ---------- | ---------- |
| `evaluateExoticLimits` | `TOO_MANY_EXOTICS` | — |
| `evaluateModEnergy` | `MOD_ENERGY_EXCEEDED` | — |
| `evaluateSubclassKit` | `ILLEGAL_SUBCLASS_KIT` | — |
| `evaluateExoticAbilityMatch` | `EXOTIC_ABILITY_MISMATCH` | `EXOTIC_ABILITY_PIN_PROPOSED` |
| `evaluateSynergyRequirement` | `NO_SYNERGY` | — |
| `mergeConstraintEvaluations` | (passthrough) | (passthrough) |

## capacityResolved field

| Value | Fragment capacity hard check |
| ----- | ---------------------------- |
| `true` (default when omitted) | Enforced |
| `false` | Skipped |

Aspect max remains enforced regardless of this flag.
