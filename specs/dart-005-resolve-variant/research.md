# Research: DART-005 Resolve Variant

**Date**: 2026-07-24

## Source modules (TypeScript product)

| TS symbol | Responsibility | Dart target |
| --------- | -------------- | ----------- |
| `detectSlotConflicts` | Group claims by slot; multi-claim → conflicts | `resolve_variant.dart` |
| `buildEquipmentMap` | First claim per slot | same |
| `itemsToSlotClaims` | ExpandedSetItem → SlotClaim (pair → pair_set) | same (+ existing `toSlotClaim`) |
| `addExoticWeaponClaim` / `addExoticArmorClaim` | Inject identity pins as claims | same |
| `effectiveExoticWeapon` | Build-shared exotic weapon wins over variant | same |
| `validatePairArmorMatch` | Pair exotic_armor hash must match build | same |
| `assertNoSlotConflicts` / `assertVariantNotEmpty` / `assertFullCombatLoadout` | Hard save gates for resolve | same (domain exception) |
| `resolveVariantEquipment` | DB load + pure merge | **partial**: pure merge only as `resolveVariantClaims` |
| `loadExpandedAttachmentItems` | DB / snapshot expansion | **out of scope** (repos later) |

## Decisions

### R1 — Claims-only resolve API

**Decision**: Export `resolveVariantClaims(...)` that takes pre-expanded `List<ExpandedSetItem>`, build/variant exotic fields, and optional exotic slots. Do not accept DB handles.

**Rationale**: Slice exit criteria and port decisions require pure domain; attachment expansion needs repos (P1).

### R2 — Exceptions instead of ApiError

**Decision**: `ResolveVariantException` with product codes from `DomainFailureCodes` (`SLOT_CONFLICT`, `PAIR_ARMOR_MISMATCH`, `VARIANT_EMPTY`, `DEFAULT_VARIANT_INCOMPLETE`) and optional `details` map (e.g. `missing` list).

**Rationale**: Matches soft-stat exception pattern; adapters map to HTTP later.

### R3 — Default vs non-default completeness

**Decision**:

- Default: `assertVariantNotEmpty` + `assertFullCombatLoadout` (full weapons+armor, className, subclass name, mods flag) — DBR-CMPL-001.
- Non-default: `assertVariantNotEmpty` only — DBR-CMPL-002 allows empty combat slots.

Provide `assertVariantCompleteness(resolved, {required bool isDefault, ...})` as a thin branch helper for tests and later save pipeline.

### R4 — Completeness input shape

**Decision**: `assertFullCombatLoadout` takes `className` as `String?` and `subclassName` as `String?` (not full `Build`) so incomplete drafts can omit class without fighting required `GuardianClass` on `Build`.

### R5 — Intent mode

**Decision**: `exoticArmorSlot == EquipmentSlot.classItem` ⇒ pair validation `intentMode: true` and `skipIfClassItemClaimed: true` on armor inject — matches TS `resolveVariantEquipment`.

## Parity notes

- Required weapon slots: primary, special, heavy
- Required armor slots: helmet, arms, chest, legs, class_item
- Full combat missing keys: slot wire names + `className` + `subclass` + `mods`
- Equipment map first-writer: first claim in list order wins
- Pair source: `setType == pair` → `ClaimSource.pairSet`
