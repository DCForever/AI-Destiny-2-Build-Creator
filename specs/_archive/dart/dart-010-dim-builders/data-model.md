# Data model: DART-010 DIM Builders

## DimLoadoutItem

| Field | Type | Notes |
| ----- | ---- | ----- |
| id | String? | Inventory instance id when pinned |
| hash | int | Item definition hash |
| amount | int? | Optional; usually omitted |
| socketOverrides | Map\<int,int\>? | index → plug hash from selectedPerks |

## DimStatConstraint

| Field | Type | Notes |
| ----- | ---- | ----- |
| statHash | int | DIM / Destiny stat hash |
| minStat | int? | Soft target |
| maxStat | int? | Unused in current product builder |

## DimLoadoutParameters

| Field | Type | Notes |
| ----- | ---- | ----- |
| statConstraints | List\<DimStatConstraint\>? | Sorted desc by minStat |
| mods | List\<int\>? | Allow duplicates |
| exoticArmorHash | int? | From `build_exotic_armor` claim |
| autoStatMods | bool | Always true in builder |
| includeRuntimeStatBenefits | bool | Always true in builder |

## DimLoadout

| Field | Type | Notes |
| ----- | ---- | ----- |
| id | String | Injectable |
| name | String | ≤120 chars |
| notes | String? | ≤1024 chars |
| classType | int | 0 Titan / 1 Hunter / 2 Warlock |
| equipped | List\<DimLoadoutItem\> | Combat slot order |
| unequipped | List\<DimLoadoutItem\> | Fashion hashes |
| parameters | DimLoadoutParameters? | Always set by builder |

## Constants

- **classType**: Titan=0, Hunter=1, Warlock=2  
- **stat hashes**: Weapons 2996146975, Health 392767087, Class 1943323491, Grenade 1735777505, Super 144602215, Melee 4244567218

## VariantDimLoadoutInput

| Field | Type |
| ----- | ---- |
| buildName | String |
| className | GuardianClass |
| variantName | String? |
| subclass | DimSubclassNote? (name, superName) |
| softStatTargets | SoftStatTargets? |
| equipment | Map\<EquipmentSlot, SlotClaim\> |
| artifact | DimArtifact? (hash, name, config) |
| fashion | DimFashion? (setId, pieces) |
| modHashes | List\<int\> |

## JsonOnly envelope

```json
{ "loadout": { /* DimLoadout toJson */ } }
```

Produced only after `assertEquipReady` succeeds.

## Reused domain types

- `SlotClaim`, `EquipmentSlot.combatSlots`, `ClaimSource.buildExoticArmor`
- `SoftStatTargets`, `ArmorStatName`
- `EquipReadyResult`, `assertEquipReady`, `DomainFailureCodes.notEquipReady`
