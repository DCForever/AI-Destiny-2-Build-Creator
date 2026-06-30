# Contract: Armor Instance Stat Sort

**Feature**: 008-sets-catalog-lookup  
**Type**: Extension to owned inventory instance list API  
**Auth**: Signed-in user (existing 003 rules)

## Purpose

Support **highest stat** ranking when a user picks among multiple owned armor copies during set item attachment (FR-007).

---

## GET `/api/user/inventory/instances` (extended)

### New query parameter

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| sortBy | no | `total` \| `Health` \| `Melee` \| `Grenade` \| `Super` \| `Class` \| `Weapons` | Applies when `kind=armor` or bucket is armor. Ignored for weapons (power sort only). Default: `total` when param omitted and listing armor. |

Existing params unchanged: `itemHash`, `bucket`, `kind`, `q`.

### Response 200 — extended instance object

Each instance in `instances[]` gains optional armor fields:

```json
{
  "instanceId": "…",
  "itemHash": 0,
  "kind": "armor",
  "power": 1800,
  "statValues": {
    "Health": 10,
    "Melee": 60,
    "Grenade": 15,
    "Super": 5,
    "Class": 20,
    "Weapons": 30
  },
  "totalStats": 140,
  "statsIncomplete": false,
  "plugs": []
}
```

| Field | Type | Notes |
|-------|------|-------|
| statValues | object? | Six Armor 3.0 keys when synced |
| totalStats | number? | Sum of statValues when complete |
| statsIncomplete | boolean | true when statValues missing or partial |

Weapon instances omit stat fields (or `statsIncomplete: true` if present in mixed list — armor-only lists expected when `sortBy` used).

### Sort order

1. Primary: `sortBy` dimension descending (`total` = `totalStats`).
2. Tie: opposite total or primary stat per [data-model.md](../data-model.md).
3. Tie: `power` descending.
4. Tie: `instanceId` ascending (stable).
5. `statsIncomplete: true` rows after all complete rows.

### Sync dependency

`statValues` populated after inventory sync with 008 pipeline. Pre-migration rows return `statsIncomplete: true` and sort last.

### Errors

Unchanged from 003: `401` unsigned, `400` invalid filter, `200` empty + `syncPrompt` when never synced.

---

## Sync persistence (internal)

| Column | Table | Format |
|--------|-------|--------|
| stat_values | inventory_items | JSON `Record<ArmorStatName, number>` |

Written during `syncInventory` for armor equipment buckets only.

---

## Client usage (Sets picker)

1. User selects armor catalog row.
2. Fetch `GET /api/user/inventory/instances?itemHash={hash}&kind=armor&sortBy=Melee` (example).
3. Present ordered list; user selects top row or any row.
4. Map to `SetItemInput` and `PUT /api/user/sets/:id/items`.

See [catalog-set-lookup-contract.md](./catalog-set-lookup-contract.md).
