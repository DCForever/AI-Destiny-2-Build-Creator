# Contract: Loadout Exotic Filter API

**Feature**: 002-exotic-loadouts-by-type  
**Consumers**: `LoadoutsPage`, optional `/debug/loadouts`  
**Version**: 1.0

## GET /api/user/loadouts

**Auth**: Required (existing session). Returns only authenticated user's loadouts (FR-009).

### Response (extended)

```json
{
  "loadouts": [
    {
      "id": "uuid",
      "name": "Arc Hunter GM",
      "source": "generator",
      "className": "Hunter",
      "createdAt": "ISO",
      "updatedAt": "ISO",
      "manifestVersion": "…",
      "exoticSummary": {
        "exoticArmor": {
          "hash": 123,
          "name": "Crown of Tempests",
          "slot": "Helmet",
          "classType": "Warlock",
          "status": "verified"
        },
        "exoticWeapon": {
          "hash": 456,
          "name": "Witherhoard",
          "slot": "Kinetic",
          "status": "verified"
        }
      }
    }
  ],
  "filter": { "applied": false }
}
```

When query filters are active and valid, `filter.applied` is `true` and `filter.criteria` echoes normalized criteria. Only matching loadouts appear in `loadouts`.

### Query parameters (all optional)

Independent armor and weapon dimensions (FR-006). Omit a dimension to leave it unconstrained.

#### Armor

| Param | Values | Required with |
|-------|--------|---------------|
| `armorMode` | `exact` \| `slot` | — |
| `armorHash` | integer | `armorMode=exact` (preferred) |
| `armorName` | string | `armorMode=exact` when hash omitted |
| `armorSlot` | `Helmet` \| `Gauntlets` \| `Chest` \| `Legs` \| `ClassItem` | `armorMode=slot` |

#### Weapon

| Param | Values | Required with |
|-------|--------|---------------|
| `weaponMode` | `exact` \| `slot` | — |
| `weaponHash` | integer | `weaponMode=exact` (preferred) |
| `weaponName` | string | `weaponMode=exact` when hash omitted |
| `weaponSlot` | `Kinetic` \| `Energy` \| `Power` | `weaponMode=slot` |

### Validation errors (400)

| Code | Condition |
|------|-----------|
| `INVALID_FILTER` | `armorMode=exact` without hash or name |
| `INVALID_FILTER` | `armorMode=slot` without valid `armorSlot` |
| `INVALID_FILTER` | `weaponMode=exact` without hash or name |
| `INVALID_FILTER` | `weaponMode=slot` without valid `weaponSlot` |
| `INVALID_FILTER` | unknown enum value |

### Empty results

`200` with `loadouts: []` and `filter.applied: true`. Client shows informative empty state (FR acceptance).

## Pure function contract: `classifyLoadoutExotics`

**Module**: `src/lib/loadouts/classifyExotics.ts`

```typescript
classifyLoadoutExotics(
  loadout: SavedLoadout,
  manifest?: { exoticArmor: ExoticArmorRecord[]; exoticWeapons: ExoticWeaponRecord[] }
): LoadoutExoticSummary
```

- Idempotent for same inputs
- Does not mutate loadout
- Uses manifest stores only to enrich armor slot/class when hash resolves

## Pure function contract: `filterLoadouts`

**Module**: `src/lib/loadouts/filterLoadouts.ts`

```typescript
filterLoadouts(
  loadouts: SavedLoadout[],
  criteria: ExoticFilterCriteria,
  summaries: Map<string, LoadoutExoticSummary>
): SavedLoadout[]
```

**Semantics**:
- When both `armor` and `weapon` criteria set: **AND** (loadout must match both)
- Missing exotic on loadout → fails that dimension's filter
- Armor slot filter enforces class match (see data-model)

## UI contract: contextual discovery

From `EditableBuildSheet` when viewing a saved loadout:

| Action | Sets criteria |
|--------|----------------|
| "Loadouts with this exotic" (armor) | `armorMode=exact`, hash/name from current armor |
| "Loadouts with exotic helmets" (armor) | `armorMode=slot`, slot from summary |
| "Loadouts with this exotic" (weapon) | `weaponMode=exact`, hash/name from weapon |
| "Loadouts with exotic in this slot" (weapon) | `weaponMode=slot`, slot from weapon |

Actions call parent callback → `LoadoutsPage` updates filter state, collapses or scrolls list, **does not** PATCH loadout.

## Non-goals (v1)

- Filter `builds` table
- DIM-shared or community loadouts
- Weapon archetype sub-filters (e.g. "exotic sniper")
- Pagination
