# Contract: Instance Perk Grid

**Feature**: 011-per-copy-perk-grid
**Type**: New read-only inventory endpoint (per-copy)
**Auth**: Same as other `/api/user/inventory/*` routes (signed-in user; instance must belong to user)

## Purpose

Return a **DIM-style per-column perk grid** for one owned weapon copy: each column lists the perks **that copy** can slot (equipped + alternates), with the equipped perk marked. Replaces the debug Sets use of `GET /catalog/weapons/perk-options` (weapon-type pool). See [`data-model.md`](../data-model.md) for entity definitions.

---

## GET `/api/user/inventory/instances/:instanceId/perk-grid`

### Path parameters

| Param | Required | Type | Notes |
|-------|----------|------|-------|
| `instanceId` | yes | string | Owned copy instance ID. |

### Response 200 — `InstancePerkGrid`

```json
{
  "instanceId": "6912345678901234567",
  "itemHash": 1044610667,
  "captureStatus": "complete",
  "columns": [
    {
      "columnKind": "barrel",
      "label": "Barrel",
      "socketIndex": 0,
      "equippedPlugHash": 101,
      "options": [
        { "hash": 101, "name": "Corkscrew Rifling", "displayName": "Corkscrew Rifling", "isEnhanced": false, "isEquipped": true },
        { "hash": 102, "name": "Fluted Barrel", "displayName": "Fluted Barrel", "isEnhanced": false, "isEquipped": false }
      ]
    },
    {
      "columnKind": "trait",
      "label": "Trait 1",
      "socketIndex": 2,
      "equippedPlugHash": 201,
      "options": [
        { "hash": 201, "name": "Zen Moment", "displayName": "Zen Moment", "isEnhanced": false, "isEquipped": true },
        { "hash": 202, "name": "Zen Moment", "displayName": "Zen Moment (Enhanced)", "isEnhanced": true, "isEquipped": false }
      ]
    }
  ]
}
```

| Field | Type | Notes |
|-------|------|-------|
| `instanceId` | string | Echoes path param. |
| `itemHash` | number | Manifest hash of the copy. |
| `captureStatus` | `"complete" \| "pending" \| "unavailable"` | See data-model §6. |
| `columns` | array | Ordered perk columns; omitted kinds with no options. |
| `columns[].columnKind` | string | `barrel`, `magazine`, `trait`, `intrinsic`, `origin`, `masterwork`, `catalyst`. |
| `columns[].label` | string | UI column heading. |
| `columns[].socketIndex` | number | Source socket index (305 order). |
| `columns[].equippedPlugHash` | number | Currently equipped plug. |
| `columns[].options` | array | Perks this copy can slot in this column. |
| `columns[].options[].hash` | number | Plug item hash. |
| `columns[].options[].name` | string \| null | Resolved name when available. |
| `columns[].options[].displayName` | string | Shown label; enhanced suffix when applicable (FR-017). |
| `columns[].options[].isEnhanced` | boolean | Enhanced variant flag. |
| `columns[].options[].isEquipped` | boolean | True for the copy's current plug in this column. |

### Rules

- **Weapons only**: armor copies → `404` or `400` with `{ error: "Not a weapon" }` (consistent with kind check on instance row).
- Options MUST come from stored per-copy capture (`socket_plugs`) — **never** from `WeaponRecord.perkColumns` / catalog type pool (FR-002, FR-015).
- When `captureStatus` is `pending` or `unavailable`, each column's `options` contains **only the equipped plug** (degraded grid) plus the status signals the client to auto re-sync once (FR-018).
- Unresolved perk names → `displayName` falls back to hash string (FR-011).
- Exotic weapons use the same response shape; catalyst column included when present (FR-016).

### Degradation / errors

| Condition | Response |
|-----------|----------|
| Not signed in | `401` |
| Instance not found for user | `404` |
| Never synced / sync prompt | `200` with `syncPrompt: true` (match instances list pattern) OR `404` — pick one in implementation; document in `DEBUG.md` |
| Non-weapon instance | `400` or `404` |
| `captureStatus: "pending"` | `200` full shape; equipped-only options; client triggers re-sync |
| `captureStatus: "unavailable"` | `200` full shape; equipped-only options; indicator in UI |

### Client integration (Sets debug)

1. User selects weapon copy in carousel → `GET .../perk-grid`.
2. If `captureStatus === "pending"` and copy not yet refreshed this session → `POST /api/bungie/sync` once → re-fetch grid.
3. Initialize selection: each column → `equippedPlugHash`.
4. On "Put item" → `PUT /user/sets/:id/items` with `instanceId` + `selectedPerks` = column-ordered chosen hashes.

## Internal resolution

`resolveInstancePerkGrid(...)` (`src/lib/inventory/instances/resolveInstancePerkGrid.ts`):
1. Load `UserInventoryItem` by `instanceId`.
2. If weapon: read `socketPlugs` + `plugHashes`; determine `captureStatus`.
3. Classify sockets / build columns via stored `columnKind`/`columnLabel`.
4. Resolve names via plug map; mark enhanced variants.
5. Return `InstancePerkGrid`.

## Test expectations

- Crafted copy with multi-perk column → column lists >1 option; equipped flagged.
- Two copies same `itemHash`, different rolls → different `options` arrays.
- Row with `socket_plugs = null` → `captureStatus: "pending"`, equipped-only options.
- Enhanced + base in same column → two options; enhanced has `isEnhanced: true` and labeled displayName.
- Exotic with catalyst socket → catalyst column present.
- Armor instance → error response, no grid.
- Route never returns hashes absent from stored capture + equipped set (no type-pool leakage).

## Supersedes (Sets debug only)

`GET /api/catalog/weapons/perk-options` remains for backward compatibility but **must not** be used for set attachment perk selection after this feature (FR-015).
