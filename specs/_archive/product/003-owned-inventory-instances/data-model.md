# Data Model: Owned Inventory Instance Detail

**Feature**: 003-owned-inventory-instances  
**Source tables**: `inventory_items`, `inventory_sync_meta` (read-only for this feature)

## Entities

### Inventory Instance (stored)

Persisted row representing one owned copy. Maps 1:1 to `UserInventoryItem` in `src/lib/db/types.ts`.

| Field | Type | Notes |
|-------|------|-------|
| instanceId | string | Bungie item instance id; unique per user |
| itemHash | number | Manifest definition hash |
| bucket | string | `Kinetic`, `Energy`, `Power`, `Helmet`, … |
| location | enum | `vault` \| `character` \| `equipped` |
| characterId | string? | Present when not vault |
| power | number | Item power level |
| isMasterwork | boolean | |
| isCrafted | boolean | |
| plugHashes | number[] | Equipped socket plugs from sync |
| rollTags | RollTag[] | Computed at sync |
| syncedAt | ISO string | Row freshness |

**Validation**: Existing sync + repository upsert; no new constraints.

---

### Resolved Plug (derived)

| Field | Type | Notes |
|-------|------|-------|
| hash | number | Manifest plug hash |
| name | string \| null | Resolved display name when found |
| displayName | string | `name ?? String(hash)` for UI (FR-006) |
| resolved | boolean | `name !== null` |
| socketType | string? | **Future** — optional socket role; omitted in v1 |

v1: one entry per hash in `UserInventoryItem.plugHashes` (no filtering).

---

### Owned Instance Detail (API DTO)

Projection returned by list and detail endpoints.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| instanceId | string | yes | Stable id for future set pick (FR-012) |
| itemHash | number | yes | Manifest identity |
| kind | `weapon` \| `armor` | yes | Derived from bucket |
| bucket | string | yes | Inventory bucket label |
| location | enum | yes | vault / character / equipped |
| characterId | string? | no | When not vault |
| className | enum? | no | Titan / Hunter / Warlock when character resolvable |
| characterDisplayName | string? | no | Bungie display name when roster available |
| power | number | yes | |
| isMasterwork | boolean | yes | |
| isCrafted | boolean | yes | |
| rollTags | RollTag[] | yes | May be empty |
| plugs | ResolvedPlug[] | yes | May be empty (edge case) |
| syncedAt | ISO string | yes | From row |

**Relationships**:
- Many `Owned Instance Detail` → one manifest catalog item (`itemHash`)
- Owned by exactly one `user` (implicit via auth; never exposed in DTO)

---

### Owned Instance Summary (catalog optional)

Lightweight embed on catalog rows when `includeInstances=1`.

| Field | Type | Notes |
|-------|------|-------|
| instanceId | string | |
| power | number | |
| location | enum | |
| perkNames | string[] | Resolved plug display names (deduped optional) |

---

### Instance List Response (wrapper)

| Field | Type | Notes |
|-------|------|-------|
| instances | OwnedInstanceDetail[] | |
| count | number | `instances.length` |
| syncPrompt | boolean | true when never synced |
| message | string? | Actionable guidance |
| filter | object? | Echo normalized query when filters applied |

Default sort when multiple instances: **power descending** (FR-015).

---

## Filter Criteria (query)

| Param | Type | Semantics |
|-------|------|-----------|
| itemHash | number | Exact manifest hash; all copies |
| bucket | string | Exact bucket label |
| kind | `weapons` \| `armor` | Restrict to weapon or armor bucket sets |
| q | string | Substring match on resolved plug display names |

All filters are AND when combined. Omit all → full user inventory (weapons + armor buckets only; exclude `Subclass` etc.).

---

## State Transitions

Not applicable — read-only API over sync snapshot. Sync updates replace rows via existing `upsertInventoryBatch`.

---

## Bucket → Kind mapping

Uses `WEAPON_INVENTORY_BUCKETS` and `ARMOR_INVENTORY_BUCKETS` from `src/lib/catalog/filterItems.ts`.

---

## Future consumers

- **Set item attachment**: `SetItem` may add optional `instanceId` referencing `OwnedInstanceDetail.instanceId` (out of v1 scope).
- **Build sheet annotation**: `annotateWeaponsWithInventory` already uses `instanceId`; instance API enables explicit roll pick.
