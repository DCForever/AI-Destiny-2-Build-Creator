# Contract: Resolved Artifact + Fashion

`GET /api/user/builds/:id/variants/:variantId/resolved` returns existing fields plus:

```json
{
  "resolved": {
    "equipment": {},
    "conflicts": [],
    "equipReady": false,
    "pinStatuses": [],
    "artifact": {
      "hash": 123,
      "name": "Queensfoil Censer",
      "config": [111, 222]
    },
    "fashion": {
      "setId": "set-uuid",
      "slots": {
        "ghost": { "itemHash": 1, "itemName": "Ghost" },
        "finisher": { "itemHash": 2, "itemName": "Finisher" }
      }
    }
  }
}
```

- `artifact` is `null` when unset.
- `fashion` is `null` when no fashion attachment; `slots` omits empty fashion slots (leave-as-is later).
- No Bungie side effects from this GET.
