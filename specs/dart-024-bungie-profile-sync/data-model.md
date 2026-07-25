# Data Model: DART-024 Bungie Profile Sync

## Profile DTOs (destiny2_bungie)

### DestinyMembership

| Field | Type | Notes |
| ----- | ---- | ----- |
| membershipType | int | Bungie membership type |
| membershipId | String | Destiny membership id |
| displayName | String | Global display name preferred |

### InventoryLocation

Enum-like strings: `vault` | `character` | `equipped`.

### RawInventoryItem

| Field | Type | Notes |
| ----- | ---- | ----- |
| instanceId | String | Required for storage |
| itemHash | int | Definition hash |
| bucketHash | int | Equipment or transfer container |
| location | String | vault/character/equipped |
| characterId | String? | Null for vault |
| power | int | From instance primaryStat |
| plugHashes | List&lt;int&gt; | Enabled sockets |
| isMasterwork | bool | |
| isCrafted | bool | |
| statValues | Map&lt;String, Object?&gt;? | Armor names when known |
| gearTier | int? | Armor / transfer |
| socketCapture | List&lt;RawSocketCapture&gt;? | Weapons / transfer |

### InventoryParseDiagnostics

Membership context + raw counts + parsed counts by location/bucket + dropped reasons (invalidShape, unknownBucket, missingInstanceId).

### SyncInventoryResult

| Field | Type |
| ----- | ---- |
| itemCount | int |
| syncVersion | int |
| lastFullSyncAt | String (ISO-8601) |
| diagnostics | InventoryParseDiagnostics |

### SyncIfStaleResult

| Field | Type |
| ----- | ---- |
| synced | bool |
| lastFullSyncAt | String? |
| result | SyncInventoryResult? |

## Drift (existing — DART-013/016)

No schema migration. Uses:

- `inventory_items` full replace
- `inventory_sync_meta` (`item_count`, `sync_version`, `last_full_sync_at`)
- `users` (`membership_type`, `display_name`, `last_sync_at`)

## Constants

| Name | Value | Source |
| ---- | ----- | ------ |
| kEquipSyncFreshMs | 60000 | DBR-EQP-007 / product |
| Inventory components | `102,201,205,300,304,305,310` | product profile |
)
