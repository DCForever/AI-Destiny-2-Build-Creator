# Contract: Finish one-tap create

**Feature**: 029-finish-slot-first  
**Date**: 2026-07-23

## Endpoint (existing)

`POST /api/user/builds/{buildId}/create-set-attach`

## Finish client body

```json
{
  "variantId": "<active variant id>",
  "type": "weapon",
  "attachNow": true
}
```

- `type` MUST match Finish category (`armor` \| `weapon` \| `mod`).
- `name` MUST be omitted from Finish one-tap (server default).
- `tagIds` MUST be omitted from Finish one-tap.

## Response (unchanged shape)

```json
{
  "set": { "id": "...", "name": "<inherited unique>", "type": "weapon" },
  "attachment": {
    "setId": "...",
    "mode": "live",
    "variantId": "...",
    "replacedSetIds": []
  }
}
```

## Post-success UI obligation

1. Refresh build detail + resolved equipment.
2. Re-run finish gap evaluation.
3. If active category `needs_fill` and live covering: open fill for `emptySlots[0]`.
4. If satisfied: advance overview / next category.
5. Surface success message including `set.name` (FR-013).

## Sets-tab create (non-Finish)

May still POST optional `name` and `tagIds`; not part of Finish one-tap contract.
