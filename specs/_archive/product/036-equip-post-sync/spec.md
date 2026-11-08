# Feature Specification: Equip Post-Sync Reassert

**Feature Branch**: `036-equip-post-sync`

**Created**: 2026-07-23

**Status**: Draft

**Input**: Improve prompt `specs/020-bungie-equip/improve/equip-post-sync-reassert.md` — after `syncIfStale`, recompute equip readiness; 409 if not ready; no silent skip of missing combat pin instances in planner when `instanceId` is set.

**Source improve**: [equip-post-sync-reassert.md](../020-bungie-equip/improve/equip-post-sync-reassert.md)

**Prior slices**: [020-bungie-equip](../020-bungie-equip/spec.md), [016-wishlist-equip-ready](../016-wishlist-equip-ready/spec.md)

## Clarifications

Interactive clarify skipped. Assumptions documented below.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Post-sync readiness hard-fail (Priority: P1)

A builder starts equip on a variant that was equip-ready at gate time. Inventory sync refreshes and a combat pin instance is no longer present (or is hash-mismatched). Equip must **not** partially plan around the missing pin; the API returns the same not-equip-ready failure (409 / `NOT_EQUIP_READY`) and does not execute Bungie write steps.

**Why this priority**: Prevents false-success partial equips that leave combat slots unchanged while reporting success-by-omission (violates equip-ready intent).

**Independent Test**: Unit/integration: pre-sync ready inventory → post-sync inventory missing claimed instance → `computeEquipReady` false → `assertEquipReady` throws 409; route never calls planner execution.

**Acceptance Scenarios**:

1. **Given** resolved equipment with combat `instanceId` pins that were ready pre-sync, **When** post-sync inventory lacks one claimed instance, **Then** readiness recomputation yields not equip-ready and equip fails with `NOT_EQUIP_READY` (409) without executing the plan.
2. **Given** post-sync inventory still contains all claimed instances with matching hashes, **When** equip continues, **Then** readiness passes and planning proceeds.

---

### User Story 2 - Planner never silently drops claimed combat instances (Priority: P1)

When the planner is invoked with a combat claim that has `instanceId` but no matching inventory row, it must hard-error rather than `continue`. Empty combat slots (no claim / no `instanceId`) may still be omitted (gap equip).

**Why this priority**: Defense in depth if a caller skips post-sync reassert; closes the silent-skip bug at the planner boundary.

**Independent Test**: Call `planEquipSteps` with a helmet claim `instanceId` and empty inventory → throws structured error; happy path still emits equip steps for all pinned combat slots present in inventory.

**Acceptance Scenarios**:

1. **Given** a combat slot claim with `instanceId` and inventory without that instance, **When** `planEquipSteps` runs, **Then** it throws (does not omit the slot).
2. **Given** all claimed combat instances present on inventory, **When** `planEquipSteps` runs, **Then** each claimed combat slot produces an equip step (plus transfers as needed).
3. **Given** empty combat gaps (no claim), **When** planning, **Then** those slots remain omitted.

---

### Edge Cases

- Wishlist-only applied slots (no `instanceId`) remain not equip-ready at compute time; planner still skips claims without `instanceId` (gap/wishlist semantics).
- Hash mismatch post-sync is stale, not ready — same 409 path as missing instance.
- Fashion hash-first-instance behavior unchanged.
- Partial apply **after** Bungie writes begin remains valid; this feature only blocks planning when pins are already missing post-sync.
- Pre-sync `assertEquipReady` on `getResolvedVariant` remains as a fast fail; post-sync reassert is additional and authoritative for inventory used by the planner.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After inventory refresh on the equip path (`syncIfStale` or equivalent), the system MUST recompute equip readiness with `computeEquipReady` against **post-sync** inventory and the same resolved equipment claims.
- **FR-002**: If post-sync readiness is not equip-ready, the system MUST fail with the same class of error as the pre-check (`assertEquipReady` / `NOT_EQUIP_READY` 409) and MUST NOT call `executeEquipPlan`.
- **FR-003**: `planEquipSteps` MUST NOT silently drop combat slots that have an `instanceId` but no inventory row; it MUST throw a structured hard error for that condition. Empty combat slots (no claim) MAY still be omitted.
- **FR-004**: Fashion hash-first-instance behavior MUST remain unchanged unless touched incidentally; do not expand fashion pinning.
- **FR-005**: Automated tests MUST cover pre-ready + post-sync missing instance → assert/409 path, and happy path planning for all pinned combat slots.

### Key Entities

- **Resolved equipment claims**: Per-combat-slot pin with optional `instanceId` / `itemHash`.
- **Post-sync inventory**: `listInventoryItems` rows after freshness sync.
- **Equip readiness result**: `equipReady` boolean + `pinStatuses` (wishlist / pinned / stale).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Automated tests demonstrate post-sync missing pin → not equip-ready / 409 path without plan execution.
- **SC-002**: Automated tests demonstrate planner throws when combat `instanceId` lacks inventory row.
- **SC-003**: Happy-path tests still plan equip steps for all pinned combat slots.
- **SC-004**: `npm run test`, `npm run typecheck`, and `npm run lint` pass.
- **SC-005**: Equip route order is: pre-check → character/manifest checks → sync → list inventory → recompute readiness → plan → execute.

## Assumptions

- Prefer route-level reassert via existing `computeEquipReady` + `assertEquipReady` + `buildInventoryPinIndex`; no new API error codes.
- Planner hard-error uses `ApiError` with `NOT_EQUIP_READY` (or a clear `Error` that route maps consistently); prefer `ApiError` for uniform 409 responses if planner is reached incorrectly.
- No domain doc (DBR/DAC) changes: behavior restores intended equip-ready semantics already implied by DBR-ROLL / DBR-EQP; no new product rule.
- DIM export gate and inventory sync implementation are out of scope.
- Pre-sync gate on `resolved.equipReady` stays for early rejection without requiring a sync.

## Out of Scope

- DIM export gate
- Transfer algorithm changes for multi-character items
- Fashion instance disambiguation
- Inventory sync implementation itself
- Full rollback of in-game gear after writes begin
