# Data Model: DART-005 Resolve Variant

## Reused (DART-002)

| Type | Role |
| ---- | ---- |
| `EquipmentSlot` | Combat / pair slot enums + weapon/armor lists |
| `SlotClaim` / `ClaimSource` | Per-slot claims after expand/inject |
| `ExpandedSetItem` / `SetType` | Pre-resolved set rows |
| `SlotConflict` / `ResolvedVariantEquipment` | Resolve output |
| `Build` / `Variant` | Exotic pin fields + `isDefault` |
| `DomainFailureCodes` | Stable code strings |

## New this slice

### ResolveVariantException

| Field | Type | Notes |
| ----- | ---- | ----- |
| code | String | Product code (`SLOT_CONFLICT`, etc.) |
| message | String | Human-readable |
| details | Map\<String, Object?\>? | e.g. `missing`, `conflicts`, expected/actual |

### EffectiveExoticWeapon

| Field | Type | Notes |
| ----- | ---- | ----- |
| exoticWeaponHash | int? | Effective hash |
| exoticWeaponName | String? | Display name |
| fromBuild | bool | True when build-shared wins |

### Resolve orchestration inputs (function params)

| Param | Type | Notes |
| ----- | ---- | ----- |
| expandedItems | List\<ExpandedSetItem\> | Pre-loaded; fashion already filtered by caller |
| exoticArmorHash / Name | int? / String? | From build |
| exoticWeapon (effective) | EffectiveExoticWeapon or build+variant | |
| exoticWeaponSlot | EquipmentSlot? | Manifest slot → equipment |
| exoticArmorSlot | EquipmentSlot? | null / armor / class_item |

No new persistent entities. No DB records.
