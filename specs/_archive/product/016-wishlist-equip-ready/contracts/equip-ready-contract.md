# Contract: Equip-Ready Status

**Feature**: 016-wishlist-equip-ready

## GET `/api/user/builds/:id/variants/:variantId/resolved`

Response extends with:

```json
{
  "equipReady": false,
  "pinStatuses": [
    { "slot": "primary", "status": "wishlist" },
    { "slot": "helmet", "status": "pinned", "instanceId": "..." },
    { "slot": "arms", "status": "stale", "instanceId": "...", "reason": "instance_missing" }
  ]
}
```

`equipReady` is true iff every applied combat slot status is `pinned`.

Empty non-default slots are omitted from `pinStatuses` and do not affect readiness.
