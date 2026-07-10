# Research: Class-Item Intent Lock

**Feature**: 022-class-item-intent  
**Date**: 2026-07-10

## R1 — Detection

**Decision**: `isExoticClassItem(hash)` via exotic-armor catalog `slot === "ClassItem"`. Mode `classic` | `class_item_intent` from build hash and/or resolved `class_item` exotic claim.

**Rationale**: Catalog already exposes `ArmorSlotName` including ClassItem.

## R2 — Identity confirm skip

**Decision**: `exoticArmorHash` change does **not** require confirm when both before/after are class-item intent (or both null→class-item within intent). Classic↔classic different hash still confirms. Classic↔intent (or clear that flips mode) confirms (FR-006).

**Rationale**: DBR-ID-005 / FR-003 / FR-006.

## R3 — Perk config storage

**Decision**: Prefer existing armor-set / pair attachment at `class_item` with `selectedPerks` (live or snapshot). Ensure `addExoticArmorClaim` / resolve prefers variant class_item claim with perks in intent mode over bare build hash injection.

**Rationale**: DBR-ROLL-009 already modeled on set items; avoid new columns unless needed.

## R4 — Pair match

**Decision**: In intent mode, pair exotic_armor need not equal build hash exactly if both are exotic class items (or pair supplies the variant class item).

**Rationale**: Hash-lock pair rule is for classic identity.

## R5 — Coverage

**Decision**: Fix coverage exotic slot lookup (stop hardcoding chest). Soft tiers already express intent fitness; no new hard block.

**Rationale**: FR-004 / 017.

## R6 — Shared lookup

**Decision**: Centralize `lookupExoticSlots` / armor slot mapping used by buildService, compareVariants, coverageService.

## R7 — Debug

**Decision**: BuildsDebugPage: PATCH exotic armor on selected build with identity confirm/fork; show intent vs classic mode; rely on Sets debug for perk editing if needed.
