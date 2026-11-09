# Data Model: DART-002 Models

Pure in-memory value types. No persistence.

## Enums / wire values

| Concept | Values (wire) |
| ------- | ------------- |
| EquipmentSlot | primary, special, heavy, helmet, arms, chest, legs, class_item, exotic_weapon, exotic_armor |
| FashionSlot | shader_ornament, ghost, sparrow, ship, emblem, finisher |
| SetType | weapon, armor, mod, pair, fashion |
| ClaimSource | set, build_exotic_armor, variant_exotic_weapon, pair_set |
| PinStatusKind | wishlist, pinned, stale |
| PinStaleReason | instance_missing, hash_mismatch |
| AttachmentMode | live, snapshot |
| CoverageTier | supported, weak, missing |
| SetBonusSoftStatus | active, partial, inactive |
| ArmorStatName | Health, Melee, Grenade, Super, Class, Weapons |
| GuardianClass | Titan, Hunter, Warlock |
| SynergyLinkKind | weapon, weapon_perk, origin_trait, armor_set_bonus, exotic_armor, artifact_perk |
| SynergyType | creatable + legacy list from product schemas |

## Core entities (fields)

### SlotClaim
- slot, itemHash, itemName, source, setId?, selectedPerks?, instanceId?

### ExpandedSetItem
- slot, itemHash, itemName, setId, setType, selectedPerks?, instanceId?

### SlotConflict
- slot, claimants: List&lt;SlotClaim&gt;

### ResolvedVariantEquipment
- equipment: Map&lt;EquipmentSlot, SlotClaim&gt; (partial)
- conflicts: List&lt;SlotConflict&gt;

### PinStatus / EquipReadyResult
- PinStatus: slot, status, instanceId?, reason?
- EquipReadyResult: equipReady, pinStatuses

### HardBlock / SoftWarning / ConstraintEvaluation
- code + message; lists in evaluation envelope

### Kits
- SubclassKit: aspects, fragments, super?, melee?, grenade?, classAbility?, name?
- AbilityKit: super?, melee?, grenade?, classAbility?
- ExoticComposition: exoticWeaponHashes, exoticArmorHashes
- ModEnergyPiece: slot, energyUsed, energyCapacity

### Coverage
- SynergyCoverageRow, SetBonusSoftRow, ElementSoftMismatch, CoverageResult
- SoftStatTargets (map), StatEstimate, SoftStatWarningRow

### Library shapes
- Build: id, name, className, subclass (kit), exotic pins, pinnedSuper?, softStatTargets, synergyTypes, tagIds
- Variant: id, buildId, name, isDefault, exotic weapon/artifact pins, notes?
- Attachment: id, variantId, setId, mode, snapshotConfigs?
- SnapshotConfig / SetItem: slot + item identity + perks/mods/instance
- GearSet: id, name, type, tagIds, linkedModSetId?
- Synergy + SynergyLink + SynergyTypeDesignation

## Relationships (logical)

```
Build 1—* Variant 1—* Attachment *—1 GearSet 1—* SetItem
Build *—* SynergyTypeDesignation → matched Synergy 1—* SynergyLink
Variant → SlotClaim* → ResolvedVariantEquipment → PinStatus*
```
