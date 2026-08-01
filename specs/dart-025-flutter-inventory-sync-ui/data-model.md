# Data Model: DART-025 Flutter Inventory Sync UI

No new Drift tables. UI state only.

## InventorySyncUiStatus (controller)

| Field | Type | Notes |
| ----- | ---- | ----- |
| phase | enum | `idle`, `loadingStatus`, `syncing`, `error` (error may coexist with last good meta) |
| itemCount | int? | From `InventorySyncStatus` / last `SyncInventoryResult` |
| syncVersion | int? | Same |
| lastFullSyncAt | String? | ISO-8601 |
| isFresh | bool | `isInventoryFresh(lastFullSyncAt)` |
| errorMessage | String? | Short UI string; never tokens |
| isSignedIn | bool | Derived from session |

## Persistence (existing)

| Store | Data |
| ----- | ---- |
| Drift `users` | ensureUser by Bungie membership id |
| Drift `inventory_items` + `inventory_sync_meta` | full replace via DART-024 |
| TokenStore | access/refresh only; not SQLite |

## Relationships

```
WindowsOAuthSession.tokens
        │
        ▼
ensureUser(bungieMembershipId) ──► users.id
        │
        ▼
syncUserInventory(userId, accessToken, profileClient)
        │
        ▼
inventory_items + inventory_sync_meta
```
