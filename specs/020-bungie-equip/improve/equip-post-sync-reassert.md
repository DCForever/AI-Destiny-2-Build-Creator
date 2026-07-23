---
status: DONE
priority: P1
effort: S
risk: LOW
category: bug
depends: []
planned_at: 799a9d6
issue: ""
completed_in: specs/036-equip-post-sync
---

# Re-assert equip-ready after inventory sync before planning steps

## Objective

The equip route checks pin readiness **before** `syncIfStale`, then plans transfers from post-sync inventory. `planEquipSteps` **silently skips** combat slots whose instance id is missing (`if (!item) continue`). A pin that disappears or goes stale on refresh can still pass the gate and produce a partial equip that leaves character gear unchanged for those slots—false success vs DBR-ROLL-006 / equip-ready rules. After this lands, readiness is recomputed on post-sync inventory and missing combat pins hard-fail (409) instead of being omitted.

## Current context

- Route: `src/app/api/user/builds/[id]/variants/[variantId]/equip/route.ts`
- Planner: `src/lib/builds/equipPlan.ts`
- Readiness: `src/lib/builds/equipReady.ts` (`computeEquipReady`, `assertEquipReady`)
- Domain: DBR-ROLL-004–006, DBR-EQP-*; best-effort **partial apply after steps start** (DBR-EQP-008) remains valid — this prompt is about not planning missing pins as success-by-omission
- Existing tests: `equipReady.test.ts`, `equipPlan.test.ts`
- Verification: `npm run test`, `npm run typecheck`, `npm run lint`

```ts
// equip/route.ts:59-106
const resolved = await getResolvedVariant(/* ... */);
assertEquipReady({ equipReady: resolved.equipReady, pinStatuses: resolved.pinStatuses });
// ... character checks ...
await syncIfStale(/* ... */);
const inventory = listInventoryItems(db, auth.user.id);
const plan = planEquipSteps({
  equipment: resolved.equipment,
  artifact: resolved.artifact,
  fashion: resolved.fashion,
  inventory,
  characterId: parsed.characterId,
});
```

```ts
// equipPlan.ts:108-112
for (const slot of COMBAT_SLOTS) {
  const claim = input.equipment[slot];
  if (!claim?.instanceId) continue;
  const item = byInstance.get(claim.instanceId);
  if (!item) continue; // silent skip
```

```ts
// equipReady.ts:66-78
export function computeEquipReady(resolved, inventory): EquipReadyResult {
  // wishlist / pinned / stale per applied combat slot
  const equipReady = pinStatuses.length > 0 && pinStatuses.every((s) => s.status === "pinned");
  return { equipReady, pinStatuses };
}
```

## Detailed instructions

### Requirements

- R1: After `syncIfStale` (or equivalent inventory refresh on the equip path), recompute equip readiness with `computeEquipReady` against **post-sync** `listInventoryItems` and the same resolved equipment claims.
- R2: If post-sync readiness is not equip-ready, return the same class of failure as pre-check (`assertEquipReady` / `NOT_EQUIP_READY` 409) and **do not** call `executeEquipPlan`.
- R3: `planEquipSteps` must not silently drop combat slots that have an `instanceId` but no inventory row: either the route never reaches the planner in that state (preferred via R1–R2), or the planner throws/returns a structured hard error for that slot. Empty combat slots (no claim) may still be omitted (gap equip semantics).
- R4: Fashion hash-first-instance behavior is out of scope unless touched incidentally; do not expand fashion pinning.
- R5: Unit tests cover: pre-sync ready + post-sync missing instance → assert/409 path; happy path still plans equip steps for all pinned combat slots.

### Acceptance criteria

- [x] `npm run test` passes with new/updated tests for post-sync stale pin and planner missing-instance behavior
- [x] `npm run typecheck` and `npm run lint` pass
- [x] Code review: equip route orders sync → recompute readiness → plan → execute
- [x] No silent `continue` on missing inventory for combat claims that carried `instanceId` without a hard error path

### Scope boundaries

**In scope**

- `src/app/api/user/builds/[id]/variants/[variantId]/equip/route.ts`
- `src/lib/builds/equipPlan.ts` (if hard-error path chosen there)
- `src/lib/builds/equipReady.ts` only if small helpers needed
- `equipPlan.test.ts`, `equipReady.test.ts`, optional route test

**Out of scope**

- DIM export gate (already separate)
- Changing transfer algorithm for multi-character items
- Fashion instance disambiguation
- Inventory sync implementation itself

### Risks and notes

- Partial apply **after** Bungie writes begin remains domain-correct; do not invent full rollback of in-game gear.
- `getResolvedVariant` already embeds pre-sync readiness — do not trust that object alone after sync.
- Reviewer: confirm non-default gap equip confirmation UX is unchanged (empty claims still skip).