# Data Model: Sets Catalog-Style Item Lookup

**Feature**: 008-sets-catalog-lookup  
**Extends**: [003-owned-inventory-instances](../003-owned-inventory-instances/data-model.md), catalog types in `src/lib/catalog/types.ts`

## Entities

### Catalog Item (extended projection)

Existing `CatalogItem` with optional armor set metadata.

| Field | Type | Notes |
|-------|------|-------|
| hash | number | Manifest item hash |
| name | string | Display name |
| icon | string \| null | Bungie CDN path |
| slot | string? | Inventory bucket label |
| classType | string? | Titan / Hunter / Warlock (armor) |
| setBonusName | string? | **New** — parent set family name (legendary armor) |
| setBonusHash | number? | **New** — `set-bonuses` store hash |
| isExotic | boolean | |
| owned | boolean | |
| ownedCount | number | |
| instancesHref | string? | Owned scope pointer (003) |

**Validation**: `setBonusName` present when row sourced from `set-bonuses.itemHashes`; absent on exotic armor rows unless exotic belongs to a set (edge case).

---

### Legendary Armor Catalog Row (derived)

Built at request time from `SetBonusRecord.itemHashes` + manifest item definitions. Not persisted.

| Field | Source |
|-------|--------|
| hash | `itemHashes[]` |
| name, icon, slot, classType | Manifest `DestinyInventoryItemDefinition` |
| setBonusName, setBonusHash | Parent `SetBonusRecord` |

---

### Armor Stat Values (stored)

Persisted per inventory row for armor equipment buckets.

| Field | Type | Notes |
|-------|------|-------|
| statValues | `Record<ArmorStatName, number>`? | Nullable JSON on `inventory_items`; six keys when complete |

**ArmorStatName**: `Health`, `Melee`, `Grenade`, `Super`, `Class`, `Weapons` (from `src/data/rules/statBenefits.ts`).

**Validation**: Each value 0–200 when present; partial objects allowed during migration with `statsIncomplete: true` on DTO.

---

### Owned Instance Detail (extended DTO)

Extends 003 projection.

| Field | Type | Notes |
|-------|------|-------|
| … | | Existing fields unchanged |
| statValues | `Record<ArmorStatName, number>`? | **New** — armor only |
| statsIncomplete | boolean? | **New** — true when `statValues` missing or partial |
| totalStats | number? | **New** — sum of six stats when computable |

---

### Instance Sort Key (derived)

Computed at list time for armor `sortBy` param.

| Sort mode | Primary key | Tie-break 1 | Tie-break 2 |
|-----------|-------------|-------------|-------------|
| `total` | sum(statValues) desc | power desc | instanceId asc |
| `{ArmorStatName}` | statValues[name] desc | total desc | power desc |

Rows without stats: primary key = -1 (sort last).

---

### Set Item Lookup Context (ephemeral UI)

Not persisted. Binds debug picker state.

| Field | Type | Notes |
|-------|------|-------|
| setId | string | Target set |
| setType | `weapon` \| `armor` | Determines catalog kind |
| slot | EquipmentSlot | Maps to catalog `slot` param |
| scope | `all` \| `owned` | Catalog scope |
| perk | string? | Weapon filter |
| originTrait | string? | Weapon filter |
| setBonus | string? | Armor filter |
| sortBy | string? | Instance stat sort (armor) |

---

## Relationships

```text
SetBonusRecord 1──* Legendary Armor Catalog Row (via itemHashes)
Catalog Item 1──* Owned Instance Detail (via itemHash, owned scope)
Owned Instance Detail *──1 User (via auth)
Set Item lookup → populates set_items.itemHash + selectedPerks from chosen instance plugs
```

---

## State Transitions

### Picker attach flow

1. User selects catalog row → fetch instances (`itemHash` + optional `q` / `sortBy`).
2. User selects instance (or single owned copy) → map to `SetItemInput`:
   - `itemHash` ← instance.itemHash
   - `itemName` ← catalog row name
   - `selectedPerks` ← plug hashes from instance (weapon) or relevant armor plugs
3. `PUT /api/user/sets/:id/items` — existing slot replace rules apply.

No new persistence entity for lookup session.

---

## Filter Composition Rules

| Param combination | Behavior |
|-------------------|----------|
| `perk` + `originTrait` | AND — weapon must match both when both set |
| `setBonus` + `slot` + `className` | AND |
| `q` + trait/perk/setBonus | AND after resolving named filters |
| `scope=owned` + filters | Owned counts on filtered manifest rows; unknown owned hashes still surfaced per 003 |

---

## Migration

| Table | Change |
|-------|--------|
| `inventory_items` | Add `stat_values` TEXT NULL (JSON object) |

Backfill: next full inventory sync writes stats for armor rows.
