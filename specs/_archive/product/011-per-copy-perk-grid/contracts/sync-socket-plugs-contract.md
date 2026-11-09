# Contract: Sync Socket Plugs Capture

**Feature**: 011-per-copy-perk-grid
**Type**: Extension to existing inventory sync pipeline
**Auth**: Existing `POST /api/bungie/sync` (unchanged route)

## Purpose

Define how inventory sync **captures and persists per-copy socket plug data** so the perk grid can be projected without live Bungie calls. Extends [`profile.ts`](../../../src/lib/bungie/profile.ts) parsing and [`syncInventory.ts`](../../../src/lib/bungie/syncInventory.ts) upsert. See [`data-model.md`](../data-model.md) entity `StoredSocketPlug`.

---

## Bungie profile components (extended)

**Current**: `INVENTORY_COMPONENTS = "102,201,205,300,305"`

**Planned extension** (verify in `profile.test.ts` fixtures before merge):

```
102,201,205,300,305,310[,104,402]
```

| Component | Role |
|-----------|------|
| `305` ItemSockets | Equipped `plugHash` per socket (existing) |
| `310` ItemReusablePlugs | Per-instance reusable plug entries per socket |
| `104` ProfilePlugSets | Profile-scoped plug set membership (if not already returned with 305) |
| `402` CharacterPlugSets | Character-scoped plug set membership (if not already returned with 305) |

---

## Parse: equipped socket row

From component **305** (`extractSocketsMap` + existing socket array):

For each enabled socket on a weapon/exotic weapon item:

```typescript
{
  socketIndex: number;           // array index
  equippedPlugHash: number;      // socket.plugHash when isEnabled !== false
}
```

Skip sockets classified as non-perk by `classifyWeaponSocket` (`includeInGrid: false`).

---

## Parse: reusable alternates

From component **310** (`itemComponents.reusablePlugs.data[instanceId]`):

For each socket index present:

```typescript
reusablePlugHashes: number[]  // plugItemHash where canInsert !== false (and enabled when field present)
```

Merge with plug-set-resolved alternates for sockets whose definition indicates `ProfilePlugSet` / `CharacterPlugSet` / randomized sources (mirror `SocketPlugSources` flags — see Bungie API docs).

**De-duplication**: union equipped + reusable + plug-set hashes, unique by hash.

---

## Persist: `inventory_items.socket_plugs`

JSON array of `StoredSocketPlug`:

```json
[
  {
    "socketIndex": 0,
    "equippedPlugHash": 101,
    "reusablePlugHashes": [101, 102],
    "columnKind": "barrel",
    "columnLabel": "Barrel"
  }
]
```

| Field | Source |
|-------|--------|
| `socketIndex` | 305 socket array index |
| `equippedPlugHash` | 305 enabled plug |
| `reusablePlugHashes` | 310 + plug sets (merged) |
| `columnKind`, `columnLabel` | `classifyWeaponSocket(itemHash, socketIndex)` at sync time |

**Armor and non-weapon items**: `socket_plugs` remains `NULL` (unchanged behavior).

**Backward compatibility**: existing `plug_hashes` column continues to store flat equipped hashes only.

---

## Capture completeness

Set `captureStatus` semantics for grid projection:

| Condition | Grid `captureStatus` |
|-----------|----------------------|
| Weapon row; `socket_plugs` populated with all perk sockets | `complete` |
| Weapon row; `socket_plugs IS NULL` (pre-feature sync) | `pending` |
| Weapon row; sync ran but parse failed / empty weapon sockets | `unavailable` |

Optional: bump `inventory_sync_meta.sync_version` or add `perk_capture_version` constant so clients can detect stale capture format — only if needed during implementation.

---

## Upsert behavior

`upsertInventoryBatch` (`inventoryRepository.ts`):

- Write `socket_plugs` JSON on every weapon/exotic weapon row during full sync.
- On re-sync, **replace** entire `socket_plugs` array for each instance (not merge).
- `plug_hashes` updated in parallel (existing path).

---

## Auto re-sync trigger (client)

Not part of sync route itself. When grid returns `captureStatus: "pending"`:

1. Client calls existing `POST /api/bungie/sync` (full inventory sync).
2. On success, re-fetch perk grid.
3. At most **once per instanceId per picker session** (see `PerkGridRefreshSession` in data-model).

Server sync lock (`SyncInProgressError` → `409`) → client waits or shows pending state; does not retry in a tight loop.

---

## Test expectations

- Fixture with component 310 reusable plugs → persisted `socket_plugs` with alternates ≠ equipped-only.
- Disabled socket plug excluded from equipped hash list (existing behavior preserved).
- Non-weapon item → `socket_plugs` null.
- Re-sync replaces prior `socket_plugs` for instance.
- Migration: `ensureSocketPlugsColumn` adds nullable column; existing rows unaffected until re-sync.
- `profile.test.ts` extended with 310 (+ plug sets if required) fixture.

## Migration

| Location | Change |
|----------|--------|
| `inventory_items.socket_plugs` | `TEXT NULL` |
| `UserInventoryItem.socketPlugs` | parsed JSON field |
| `ensureSocketPlugsColumn` | idempotent in `client.ts` |

No changes to `set_items` schema (010 `instance_id` + `selectedPerks` sufficient).
