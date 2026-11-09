# Data Model: Lookup-Only Fields

No new persisted tables. This feature constrains **how values are chosen** before they enter existing shapes.

## Entities (UI / request)

### GameConceptSelection

| Field | Type | Notes |
|-------|------|--------|
| kind | enum | `subclass` \| `ability` \| `aspect` \| `fragment` \| `exoticArmor` \| `exoticWeapon` \| `weaponType` \| … |
| name | string | Display / stored name from catalog or vocabulary |
| hash | number \| null | Present for exotics when lookup returns hash |

### ProseField

Unconstrained string: build/set name, notes, playstyle, rationale, analyzer paste.

## Existing persistence (unchanged)

### Build create payload (relevant fields)

| Field | Source after this feature |
|-------|---------------------------|
| `className` | Class chips/select |
| `subclass.name` | `SUBCLASSES_BY_CLASS[class]` select |
| `subclass.super` / `pinnedSuper` | Super lookup pick (optional) |
| `subclass` other kit fields | Defaults or debug form picks only |
| `exoticArmorHash` / `exoticArmorName` | ExoticArmorLookup |
| `synergyTypes` | Existing SynergyTypeMultiSelect |

### LLM BuildRequest preferences

| Field | Source after this feature |
|-------|---------------------------|
| `preferredExotic` | Exotic lookup → name |
| `preferredWeapon` | Weapon lookup → name |
| `weaponTypePreferences.include/exclude` | Multi-select from `KNOWN_WEAPON_TYPES` |

## Validation rules

1. Subclass name ∈ `SUBCLASSES_BY_CLASS[className]`.
2. Pinned super / ability / aspect / fragment names set only via pick from search results (UI invariant); optional empty.
3. Weapon type preference arrays ⊆ known weapon type vocabulary.
4. Class/subclass change clears incompatible selected concepts (`clearIncompatibleSubclassSelections` and create-panel resets).

## State transitions

```text
Class change → subclass reset to first/default for class → clear pinned super if incompatible
Subclass change → clear incompatible abilities/aspects/fragments (debug form)
Exotic clear → hash/name null
```
