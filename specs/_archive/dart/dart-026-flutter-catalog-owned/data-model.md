# Data Model: DART-026 Flutter Catalog Owned

## CatalogScope

| Value | Meaning |
| ----- | ------- |
| `all` | Full base catalog (after annotate); unowned rows keep `owned: false` |
| `owned` | Only rows with `ownedCount > 0` |

## OwnedCounts

`Map<int, int>` — itemHash → number of inventory instances for the local user.

## CatalogItem (annotated fields)

| Field | Type | Notes |
| ----- | ---- | ----- |
| owned | bool | `ownedCount > 0` |
| ownedCount | int | Instance count for hash |

Other fields unchanged from DART-020.

## CatalogInstanceProjection

| Field | Type | Notes |
| ----- | ---- | ----- |
| instanceId | String | Stable copy id |
| itemHash | int | Definition hash |
| bucket | String | Equipment bucket label from sync |
| location | String | vault \| character \| equipped |
| characterId | String? | When on character |
| power | int | Sort key desc |
| isMasterwork | bool | |
| isCrafted | bool | |
| plugHashes | List&lt;int&gt; | Raw stored plugs |
| rollTags | List&lt;String&gt; | |
| syncedAt | String | ISO from row |

## Relationships

```
User 1──* InventoryItemRecord
CatalogItem (definition) ──annotated── ownedCount from count(InventoryItemRecord by itemHash)
CatalogItem.hash 1──* CatalogInstanceProjection (picker copies)
```
