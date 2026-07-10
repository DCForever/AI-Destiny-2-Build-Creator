# Contract: Equip & DIM Export Gates

**Feature**: 016-wishlist-equip-ready

## POST `/api/user/builds/:id/variants/:variantId/equip-gate`

## POST `/api/user/builds/:id/variants/:variantId/dim-export-gate`

Both use the same equip-ready definition.

### Not ready

```json
{
  "allowed": false,
  "error": "NOT_EQUIP_READY",
  "code": "NOT_EQUIP_READY",
  "pinStatuses": []
}
```

Status: 409 (or 400 consistent with project gate patterns — prefer **409**).

### Ready

```json
{ "allowed": true, "equipReady": true, "pinStatuses": [] }
```

No Bungie write and no DIM file generation in this feature.
