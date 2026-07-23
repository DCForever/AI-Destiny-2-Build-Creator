# Contract: Create Build Pickers

## UI — ManifestSearchPicker (single-select)

| State | Visible |
|-------|---------|
| no selection | label, Search field, Browse/Search, results |
| has selection | selected EntityHotspot + Clear only |

Multi-select: unchanged.

## Manifest search params

| Use | Params |
|-----|--------|
| Exotic armor | `category=exotic-armor`, `classType`, `q`, `limit` |
| Pinned super | `category=abilities`, `kind=super`, `classType`, `element`, `subclass`, `q`, `limit` |

## Exotic result presentation

- Group by `slot` order: Helmet, Gauntlets, Chest, Legs, ClassItem
- Sort within group by display name (base sensitivity)
- Row may include synergy chips (designation labels)

## GET /api/user/synergies/by-target (batch extension)

### Single (existing)

`?kind=exotic_armor&itemHash=123` → `{ synergies, count }`

### Batch (new)

`?kind=exotic_armor&itemHash=1&itemHash=2` (repeat) or `itemHashes=1,2`

Response:

```json
{
  "byItemHash": {
    "1": [{ "id": "...", "name": "...", "type": "...", "subType": "..." }],
    "2": []
  }
}
```

Client maps to chips via designation formatter. Empty arrays OK. 401 → client shows no chips.

## Non-goals

- Ability synergy chips
- Create payload changes
