# Contract: Equip POST post-sync readiness

**Route**: `POST /api/user/builds/:id/variants/:variantId/equip`

## Ordering (normative)

1. Auth + load build/variant
2. Pre-sync `assertEquipReady` on resolved variant (early reject)
3. Character class match + manifest ready
4. `syncIfStale` (inventory refresh subject to freshness window)
5. `listInventoryItems`
6. **Post-sync** `computeEquipReady` + `assertEquipReady` on resolved equipment + post-sync inventory
7. `planEquipSteps`
8. `executeEquipPlan`

## Failure: post-sync not ready

- **Status**: 409
- **Code**: `NOT_EQUIP_READY` (same as pre-check)
- **Body**: existing `ApiError` / `apiErrorResponse` shape including `pinStatuses` when provided
- **Side effects**: MUST NOT call Bungie write / `executeEquipPlan`

## Planner invariant

If `planEquipSteps` receives a combat claim with `instanceId` and no inventory row for that id, it MUST hard-error (prefer same `NOT_EQUIP_READY` 409), never omit the slot silently.
