# Data model: DART-018 Manifest Windows Refresh

## ManifestStatus

| Field | Type | Notes |
| ----- | ---- | ----- |
| cachedVersion | `String?` | From `current-version.json` |
| remoteVersion | `String?` | From Bungie Manifest endpoint; null on failure / no key |
| isStale | `bool` | See research stale rule |
| entityCache | `EntityCacheMeta?` | Meta for cachedVersion if present |

## current-version.json

```json
{ "version": "<bungie-manifest-version-string>" }
```

Path: `StorageRoot.currentVersionPath`.

## On-disk after refresh

```text
<base>/
  current-version.json
  manifest/<versionDir>/<RawTableName>.json
  entities/<versionDir>/meta.json
  entities/<versionDir>/weapons.json
  entities/<versionDir>/exotic-armor.json
  entities/<versionDir>/aspects.json
  entities/<versionDir>/fragments.json
  entities/<versionDir>/abilities.json
  entities/<versionDir>/mods.json
```

## Download table set

Product `RAW_TABLES` (DestinyInventoryItemDefinition, DestinyStatDefinition, … loadout defs). MVP rebuild only **reads** the subset in `mvpRawTables`.

## Settings API

| Method | Returns | Behavior |
| ------ | ------- | -------- |
| status() | ManifestStatus | Remote check + disk read |
| isStale() | bool | `status().isStale` |
| refresh({forceFullDownload}) | ManifestStatus | ensureCurrent + isolate rebuild + status |
