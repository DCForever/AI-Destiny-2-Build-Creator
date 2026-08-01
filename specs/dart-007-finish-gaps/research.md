# Research: DART-007 Finish Gaps

**Date**: 2026-07-24

## Source modules (TypeScript product)

| TS symbol | Responsibility | Dart target |
| --------- | -------------- | ----------- |
| `evaluateFinishGaps` | Category gap statuses + nextActionable | `finish_gaps.dart` |
| `FinishGap` / `FinishGapsResult` | Result shapes | same |
| `finishCategoryLabel` | Display labels | same (optional helper) |
| `firstEmptyRequiredSlot` | Next empty slot from gap | `finish_next_slot.dart` |
| `resolvePostMutationStep` | Walkthrough step after mutation | same |
| `shouldOpenArmorOptimize` | Live armor covering → optimizer | same |
| `showFinishCreateActions` | needs_set / capture_available | same |
| `finishCategoryToSetType` | Category → set type | same |
| `finishGapsFromDetail` | Detail → finish input adapter | **out of scope** (IO-shaped; callers map) |

## Domain rules preserved

| Rule | Implication |
| ---- | ----------- |
| Soft never auto-applies | `hasModCoverage` is explicit input only |
| Hard blocks stay hard | This module does not soft-pass exotic/mod energy hard rules |
| Finish order armor → weapon → mod | Fixed category order for gaps and nextActionable |

## Decisions

### R1 — Default flag is passthrough only

**Decision**: `isDefaultVariant` is stored on `FinishGapsResult` but does not affect status math. Golden tests prove default and non-default fixtures share the same gap list.

**Rationale**: Matches TS `evaluateFinishGaps` body; roadmap exit criterion “gap list stable for default vs non-default fixtures.”

### R2 — Required slots from EquipmentSlot

**Decision**: Armor/weapon required slots are `EquipmentSlot.armorSlots` / `weaponSlots` wire names (`class_item` included).

**Rationale**: Single source of truth with DART-002; matches TS ARMOR_SLOTS / WEAPON_SLOTS.

### R3 — No finishGapsFromDetail in domain

**Decision**: Do not port detail-record mapping that depends on nested set entities from API/DB. Pure inputs only.

**Rationale**: Keeps domain free of presentation/API shapes; later use-case adapters can map.

### R4 — Walkthrough step enum as strings/enums with wire names

**Decision**: Use Dart enums with string wire names for steps and gap statuses for JSON-friendly hosts later.

## Non-goals this slice

- Optimizer enumerate/score (DART-008)
- Equip-ready (already DART-006)
- Flutter finish UI
- Soft coverage evaluation inside finishGaps
