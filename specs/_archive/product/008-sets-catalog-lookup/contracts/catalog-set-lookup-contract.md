# Contract: Catalog Extensions for Set Item Lookup

**Feature**: 008-sets-catalog-lookup  
**Type**: Read-only catalog API extensions  
**Auth**: Same as existing `/api/catalog/*` (owned scope requires sign-in + sync)

## Purpose

Extend weapon and armor catalog browse so Sets (and debug Sets UI) can discover items by **perk**, **origin trait**, and **set bonus** using the same endpoints as Catalog.

---

## GET `/api/catalog/weapons` (extended)

### New query parameters

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| perk | no | string | Perk display name substring or numeric perk hash. Filters to weapons in `perkWeaponIndex` for resolved hash. |
| originTrait | no | string | Origin trait name substring or numeric hash. Filters to weapons whose `originTraitHashes` includes resolved hash. |

Existing params unchanged: `scope`, `q`, `slot`, `itemType`, `frame`, `limit`, `includeInstancePointer`.

### Filter semantics

- When `perk` and/or `originTrait` set: apply named filters **before** fuse `q` search.
- When both set: **AND** semantics.
- Unresolvable name (no matching perk/trait in manifest): `{ items: [], count: 0, message: "No matching perk/trait" }` with `200`.
- Invalid hash: `400`.

### Response 200

Unchanged shape:

```json
{
  "items": [{ "hash": 0, "name": "", "ownedCount": 0, "isExotic": false, "owned": false }],
  "count": 0,
  "scope": "owned",
  "syncPrompt": false
}
```

### Errors

- `400` — invalid query (existing + invalid perk/originTrait hash)
- `500` — manifest not loaded / filter failure
- Owned unsigned: `{ items: [], syncPrompt: true, message: "…" }` (existing)

---

## GET `/api/catalog/armor` (extended)

### New query parameters

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| setBonus | no | string | Set bonus family name substring or `set-bonuses` hash. Filters to armor hashes in matching `SetBonusRecord.itemHashes`. |

### Catalog source change

Response `items` MAY include **legendary** armor rows (from `set-bonuses`) in addition to exotic armor. Legendary rows include:

| Field | Type |
|-------|------|
| setBonusName | string |
| setBonusHash | number |

### Filter semantics

- When `setBonus` set: only items in matching set(s); exotics not in set excluded.
- When `setBonus` unset: exotic armor + optional legendary rows per implementation default (all legendary set pieces OR exotic-only when no set filter — **default: exotic-only when no setBonus** to avoid huge unfiltered lists).
- Combine with `slot`, `className`, `q`, `scope` using **AND**.

### Response 200

Same envelope as weapons route.

### Errors

Same as weapons route.

---

## Set slot mapping (client)

Clients attaching to a set MUST pass catalog `slot` derived from set equipment slot:

| Set slot | `slot` query value |
|----------|-------------------|
| primary | Kinetic |
| special | Energy |
| heavy | Power |
| helmet | Helmet |
| arms | Gauntlets |
| chest | Chest |
| legs | Legs |
| class_item | ClassItem |

---

## Instance drill-down (composition)

After selecting a weapon catalog row with owned copies:

```
GET /api/user/inventory/instances?itemHash={hash}&q={perkOrTraitText}
```

Uses existing [003 instance contract](../../003-owned-inventory-instances/contracts/inventory-instances-contract.md). Weapon ordering: power descending (unchanged).

---

## Performance

- Responses SHOULD return within 5 seconds (FR-013).
- Server-side filter + limit; no full-store client download.

See [instance-stat-sort-contract.md](./instance-stat-sort-contract.md) for armor stat ordering.
