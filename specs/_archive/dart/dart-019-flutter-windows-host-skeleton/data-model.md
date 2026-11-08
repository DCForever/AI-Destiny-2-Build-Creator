# Data Model: DART-019 Flutter Windows Host Skeleton

**Date**: 2026-07-24

This slice introduces **host runtime objects**, not new SQLite tables. Schema remains DART-013/014.

## HostBootstrap / AppServices

| Field | Type | Notes |
| ----- | ---- | ----- |
| storageRoot | `StorageRoot` | App-support base; layout ensured |
| db | `AppDatabase` | Single file connection at `appDbPath` |
| manifestRefresh | `ManifestRefreshApi` | Default `WindowsManifestRefresh` |
| apiKey | `String?` | Host-injected public key only |

**Lifecycle**

1. Resolve base path (path_provider or test override)  
2. `StorageRoot.windowsAppSupport` / construct + `ensureLayout`  
3. Open one `AppDatabase.file(appDbPath)` (or test override)  
4. Touch open (e.g. `listUserTableNames` or `SELECT 1`) so migrations run  
5. Construct `WindowsManifestRefresh(storageRoot:, apiKey:)`  
6. On shutdown: `db.close()`

## ManifestStatus (display projection)

UI binds read-only fields from existing DART-018 model:

| Field | Display |
| ----- | ------- |
| cachedVersion | Local version or “none” |
| remoteVersion | Remote version or “unknown” |
| isStale | Stale / up to date |
| entityCache | Optional short summary (version + store counts if available) |

## No new persistence entities

- No OAuth tokens  
- No new Drift tables  
- No preference rows required for this stub
