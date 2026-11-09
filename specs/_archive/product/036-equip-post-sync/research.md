# Research: Equip Post-Sync Reassert

**Branch**: `036-equip-post-sync` | **Date**: 2026-07-23

## Problem

`equip/route.ts` calls `assertEquipReady` on `getResolvedVariant` **before** `syncIfStale`, then builds the plan from post-sync inventory. `planEquipSteps` uses `if (!item) continue` for combat claims with `instanceId`, so a pin that vanishes on refresh yields a partial plan and can look like success without touching those slots.

## Decisions

### D1: Recompute readiness on the route after sync (preferred)

**Decision**: After `syncIfStale` and `listInventoryItems`, call `computeEquipReady(resolved, buildInventoryPinIndex(inventory))` then `assertEquipReady`.

**Rationale**: Matches improve R1–R2; reuses existing readiness semantics (wishlist/stale/pinned); keeps planner callers safe when route is correct.

**Alternatives rejected**:
- Trust only pre-sync `resolved.equipReady` — inventory used for planning can differ.
- Only fix planner without route reassert — still allows confusing paths if other callers plan without readiness.

### D2: Planner defense-in-depth hard error

**Decision**: Replace silent `continue` with throw when `claim.instanceId` is set and inventory lacks the instance. Use `ApiError` `NOT_EQUIP_READY` so any leak still returns 409 via `apiErrorResponse`.

**Rationale**: Improve R3 allows route-only OR planner hard error; both is small and safer.

**Alternatives rejected**:
- Return `{ ok: false, ... }` plan result type — larger API surface for one bugfix.
- Keep silent skip — fails acceptance.

### D3: No domain doc churn

**Decision**: Do not edit DBR/DAC; this is a bug fix restoring intended equip-ready behavior.

## References

- `src/app/api/user/builds/[id]/variants/[variantId]/equip/route.ts`
- `src/lib/builds/equipPlan.ts`
- `src/lib/builds/equipReady.ts`
- Improve: `specs/020-bungie-equip/improve/equip-post-sync-reassert.md`
