# Data model: DART-016 inventory records

Records are **persistence DTOs** over Drift tables from DART-013. Not pure domain models.

## InventoryItemRecord

| Field | Storage column | Notes |
| ----- | -------------- | ----- |
| instanceId | instance_id | Part of composite unique with userId |
| itemHash | item_hash | |
| bucket | bucket | string label (e.g. kinetic, helmet) |
| location | location | `vault` \| `character` \| `equipped` |
| characterId | character_id | nullable |
| power | power | default 0 |
| isMasterwork | is_masterwork | bool ↔ 0/1 |
| isCrafted | is_crafted | bool ↔ 0/1 |
| plugHashes | plug_hashes | JSON int array |
| rollTags | roll_tags | JSON string array |
| statValues | stat_values | JSON object or null |
| gearTier | gear_tier | nullable int |
| socketPlugs | socket_plugs | JSON list of maps or null |
| syncedAt | synced_at | ISO text |

Row also has surrogate `id` (autoincrement) and `user_id` (FK → users CASCADE).

## InventorySyncStatus

| Field | Storage |
| ----- | ------- |
| itemCount | inventory_sync_meta.item_count |
| syncVersion | inventory_sync_meta.sync_version |
| lastFullSyncAt | inventory_sync_meta.last_full_sync_at |

PK: `user_id`.

## Composite unique

`inventory_items (user_id, instance_id)` — critical unique from DART-013 `schema_notes.dart`.

## Busy lock (not persisted)

| Concept | Shape |
| ------- | ----- |
| InventoryBusyLock | In-process map userId → in-flight Future |
| InventoryReplaceBusyException | Thrown when exclusive replace already held |

## Transaction contents (full-replace)

Within one SQLite transaction:

1. Upsert all batch rows for user
2. Delete orphans (or all if empty batch)
3. Upsert sync meta with incremented version
4. Update users.last_sync_at
