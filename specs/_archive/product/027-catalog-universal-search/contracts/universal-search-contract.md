# Contract: Catalog Universal Search

**Feature**: 027-catalog-universal-search  
**Endpoint**: `GET /api/catalog/universal-search`  
**Auth**: Optional for browse. Ownership only when session + inventory available.

## Query parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | conditional | Free-text; trim; max 80. Whitespace-only → 200 with empty hits and `code: NEED_QUERY`. |
| `kinds` | string | no | Comma-separated CompositionKind values. Omit = all v1 kinds. |
| `limit` | int | no | Default 48, max 100. |
| `includeOwned` | 0 or 1 | no | Default 1 when authed else 0. |

## Success 200

```json
{
  "query": "melee",
  "kinds": ["weapon_perk", "origin_trait"],
  "hits": [
    {
      "kind": "weapon_perk",
      "id": "weapon_perk:123456",
      "name": "Example Perk",
      "description": "...",
      "icon": "/common/...",
      "hash": 123456,
      "meta": { "sourceLabel": "Legendary perk" },
      "matchField": "description",
      "owned": null,
      "actions": { "set": false, "synergy": true }
    }
  ],
  "truncated": false,
  "manifestReady": true
}
```

### Rules

- Match: case-insensitive substring on name/searchName/description (+ kind other texts).
- Rank: name matches before description-only; soft per-kind caps; then limit.
- `actions.set` / `actions.synergy` reflect eligibility matrix.

## Errors

| Status | When |
|--------|------|
| 400 | Invalid kinds or limit |
| 503 | Manifest/entity cache not ready — body `{ "error": "...", "code": "MANIFEST_NOT_READY" }` (must not look like no matches) |
| 500 | Unexpected |

## Empty 200

| Condition | code |
|-----------|------|
| No matches | (omit) |
| Need query | NEED_QUERY |
| Kind filter empty | FILTERED_EMPTY (optional) |

## Non-goals

Does not replace weapons/armor facet APIs; does not mutate Sets/Synergies.
