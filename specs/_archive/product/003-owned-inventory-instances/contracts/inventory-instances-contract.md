# Contract: Owned Inventory Instances API

**Feature**: 003-owned-inventory-instances  
**Consumers**: `CatalogDebugPage`, future set editor, LLM tools  
**Version**: 1.0

## GET /api/user/inventory/instances

**Auth**: Required. Returns only authenticated user's synced inventory (FR-008).

### Query parameters (all optional)

| Param | Type | Description |
|-------|------|-------------|
| `itemHash` | positive integer | Filter to copies of one manifest item (FR-002) |
| `bucket` | string | Exact bucket (`Kinetic`, `Helmet`, …) |
| `kind` | `weapons` \| `armor` | Restrict to weapon or armor buckets (FR-003) |
| `q` | string | Case-insensitive substring on resolved plug display names (FR-003) |

When multiple params provided, results must match **all** (AND).

### Response `200`

```json
{
  "instances": [
    {
      "instanceId": "691352…",
      "itemHash": 1363886209,
      "kind": "weapon",
      "bucket": "Kinetic",
      "location": "vault",
      "characterId": null,
      "className": null,
      "characterDisplayName": null,
      "power": 1810,
      "isMasterwork": true,
      "isCrafted": false,
      "rollTags": ["ChampionBarrier"],
      "plugs": [
        { "hash": 2820048189, "name": "Arrowhead Brake", "displayName": "Arrowhead Brake", "resolved": true },
        { "hash": 9999999999, "name": null, "displayName": "9999999999", "resolved": false }
      ],
      "syncedAt": "2026-06-28T12:00:00.000Z"
    }
  ],
  "count": 1,
  "syncPrompt": false,
  "filter": { "itemHash": 1363886209 }
}
```

### Never synced (signed in, empty inventory)

```json
{
  "instances": [],
  "count": 0,
  "syncPrompt": true,
  "message": "Sync inventory to see owned copies"
}
```

`200` — not an error (consistent with owned catalog).

### Errors

| Status | Condition |
|--------|-----------|
| 401 | Not signed in |
| 400 | Invalid query (bad integer, unknown `kind`) |

### Empty filter result (synced user, no matches)

`200` with `instances: []`, `syncPrompt: false`.

---

## GET /api/user/inventory/instances/:instanceId

**Auth**: Required.

### Response `200`

Single `OwnedInstanceDetail` object (same shape as list item).

### Errors

| Status | Condition |
|--------|-----------|
| 401 | Not signed in |
| 404 | Instance not found for user |
| 200 + syncPrompt | User never synced (same as list) |

---

## Pure function: `projectInstance`

**Module**: `src/lib/inventory/instances/projectInstance.ts`

```typescript
projectInstance(
  item: UserInventoryItem,
  plugMap: Map<number, string>
): OwnedInstanceDetail
```

- Idempotent; does not mutate input
- `kind` derived from bucket
- Each plug hash mapped via `plugMap`; unresolved uses hash as `displayName`

---

## Pure function: `filterInstances`

**Module**: `src/lib/inventory/instances/filterInstances.ts`

```typescript
filterInstances(
  items: UserInventoryItem[],
  criteria: InstanceFilterCriteria,
  projected?: OwnedInstanceDetail[]
): UserInventoryItem[] | OwnedInstanceDetail[]
```

- `q` matches if any plug `displayName` contains normalized query
- Excludes non-weapon/armor buckets (e.g. `Subclass`, `Unknown`)
- Results sorted **power descending** when multiple instances (FR-015)

---

## Catalog extension (optional, FR-011)

### GET /api/catalog/weapons | /api/catalog/armor

**New query param**: `includeInstancePointer=1` (only valid with `scope=owned`)

When enabled, each owned catalog item may include:

```json
{
  "hash": 1363886209,
  "name": "Funnelweb",
  "ownedCount": 3,
  "instancesHref": "/api/user/inventory/instances?itemHash=1363886209"
}
```

No inline `ownedInstances` array. Debug catalog **auto-fetches** `instancesHref` on row select.

Existing fields unchanged. Clients ignoring `instancesHref` continue to work (SC-006).

---

## UI contract: debug catalog drill-down (FR-009)

On `/debug/catalog` with `scope=owned`:

1. User searches catalog → selects a row with `hash` and `ownedCount > 0`
2. Page fetches `GET /api/user/inventory/instances?itemHash={hash}`
3. Instance panel shows each copy: power, location, flags, plug list
4. Sheet/catalog search remains visible (no navigation away)

Production: `/debug/*` returns 404 (existing layout rule).

---

## Non-goals (v1)

- Stat breakdown bars, kill tracker, weapon XP (FR-014)
- Pagination
- Inventory re-sync trigger
- Production inventory browser page
