# Data model: DART-017 Manifest Entities

## MVP stores

| Store file | Record type | Key fields for hard path |
| ---------- | ----------- | ------------------------ |
| `weapons.json` | WeaponRecord | hash, name, searchName, perkColumns[] |
| `exotic-armor.json` | ExoticArmorRecord | hash, name, classType, slot, intrinsic |
| `aspects.json` | AspectRecord | hash, name, fragmentCapacity |
| `fragments.json` | FragmentRecord | hash, name, element, statModifiers |
| `abilities.json` | AbilityRecord | hash, name, kind, element, classType |
| `mods.json` | ModRecord | hash, name, slotCategory, energyCost |

## EntityCacheMeta

```json
{
  "manifestVersion": "test-1.0",
  "builtAt": "2026-07-24T00:00:00.000Z",
  "counts": {
    "weapons": 1,
    "exotic-armor": 1,
    "aspects": 2,
    "fragments": 2,
    "abilities": 6,
    "mods": N
  }
}
```

## Paths (StorageRoot)

- `entities/<versionDir>/<store>.json`
- `entities/<versionDir>/meta.json`

## Adapter inputs/outputs

### Subclass kit

- In: aspect names, fragment names (counts)
- Entity: sum `fragmentCapacity` for resolved aspects
- Out: `ConstraintEvaluation` from `evaluateSubclassKit`

### Mod energy

- In: list of `{ slot, modHashes, tier? }`
- Entity: look up mod.energyCost + slotCategory legality
- Out: `ConstraintEvaluation` from `evaluateModEnergy` (+ illegal slot messages)
