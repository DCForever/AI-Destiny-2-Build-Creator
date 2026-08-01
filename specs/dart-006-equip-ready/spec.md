# Feature Specification: DART-006 Equip Ready

**Feature Branch**: `dart-006-equip-ready`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port equipReady / wishlist vs owned-pin gates (pure). Wishlist cannot be equip-ready; stale pin rules covered by tests."

**Program ID**: DART-006  
**Phase**: P0  
**Depends**: DART-002 (models), DART-005 (resolved equipment shape)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure equip-ready evaluation in `packages/domain` that mirrors TypeScript `src/lib/builds/equipReady.ts`:

- `buildInventoryPinIndex` (from instanceId → itemHash list)
- `computeEquipReady` over applied combat slots only
- Per-slot pin status: `wishlist` | `pinned` | `stale` (`instance_missing` | `hash_mismatch`)
- `assertEquipReady` with product code `NOT_EQUIP_READY`

**Out of scope (later slices):** finishGaps (DART-007), DIM builders (DART-010), equip orchestrator / Bungie write (DART-037), inventory sync (P2), UI, Drift/IO, Node sidecar, save pipeline, soft guidance auto-apply.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Wishlist is never equip-ready (Priority: P1)

As a multiplatform domain engineer, I can evaluate a resolved variant whose applied combat slots lack owned instance pins and get `equipReady: false` with `wishlist` pin statuses so equip/DIM gates cannot treat wishlist-only kits as ready (DBR-ROLL-005, DBR-EQP-003, DAC-P1-005).

**Why this priority**: Roadmap exit criterion — wishlist cannot be equip-ready.

**Independent Test**: Golden fixture mirrors `equipReady.test.ts` primary without `instanceId` → not equip-ready, status wishlist.

**Acceptance Scenarios**:

1. **Given** a resolved claim on `primary` without `instanceId`, **When** `computeEquipReady` runs, **Then** `equipReady` is false and pin status is `wishlist`.
2. **Given** the same wishlist result, **When** `assertEquipReady` runs, **Then** it throws with code `NOT_EQUIP_READY`.
3. **Given** empty equipment (no applied combat slots), **When** `computeEquipReady` runs, **Then** `equipReady` is false (zero applied slots never counts as ready).

---

### User Story 2 - Owned pins make applied loadouts equip-ready (Priority: P1)

As an engineer, I can pass an inventory pin index of owned instances and get equip-ready when every **applied** combat slot is pinned to a matching owned instance; empty non-default gaps are ignored.

**Why this priority**: Positive path for DBR-ROLL-004 / equip-ready definition.

**Independent Test**: All applied slots pinned with matching hashes → ready; single applied slot with pin → ready even if other combat slots empty.

**Acceptance Scenarios**:

1. **Given** applied `primary` and `helmet` with instance ids present in inventory at matching item hashes, **When** evaluated, **Then** `equipReady` is true and every pin status is `pinned`.
2. **Given** only `primary` applied and pinned, other combat slots empty, **When** evaluated, **Then** `equipReady` is true and `pinStatuses` has length 1.
3. **Given** inventory index built from `{instanceId, itemHash}` rows, **When** used for evaluation, **Then** lookup is by instance id only (pure map; no DB).

---

### User Story 3 - Stale pins after missing instance or hash mismatch (Priority: P1)

As an engineer, I can re-evaluate the same resolved equipment against refreshed inventory so missing instances or hash mismatches mark slots `stale` and block equip-ready (DBR-ROLL-006, post-sync rules).

**Why this priority**: Roadmap exit criterion — stale pin rules covered by tests.

**Independent Test**: Post-sync fixture: pre-ready becomes not ready when one instance disappears; hash mismatch produces `stale` + `hash_mismatch`.

**Acceptance Scenarios**:

1. **Given** a pin whose `instanceId` is absent from inventory, **When** evaluated, **Then** status is `stale` with reason `instance_missing` and `equipReady` is false.
2. **Given** a pin whose inventory row exists but `itemHash` differs from the claim, **When** evaluated, **Then** status is `stale` with reason `hash_mismatch` and `equipReady` is false.
3. **Given** pre-sync all pins valid (equip-ready true), **When** inventory drops one instance and re-evaluates, **Then** that slot is stale and `assertEquipReady` throws `NOT_EQUIP_READY`.
4. **Given** post-sync all claimed instances still present with matching hashes, **When** evaluated, **Then** remains equip-ready and assert does not throw.

---

### Edge Cases

- Fashion / pair / exotic_* identity slots are not in the combat evaluation list; only weapons + armor combat slots from `EquipmentSlot.combatSlots`.
- Partial pins (mix of wishlist and pinned) → not equip-ready.
- Soft coverage / hard constraints do not factor into equip-ready (ownership only).
- Domain package remains zero IO/UI runtime dependencies.
- Inventory index is a pure in-memory map; callers load inventory elsewhere.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure `buildInventoryPinIndex` accepting a list of `{instanceId, itemHash}` and returning a lookup map.
- **FR-002**: Domain MUST export pure `computeEquipReady(resolved, inventory)` evaluating only applied combat slots (skip empty gaps).
- **FR-003**: A claim without `instanceId` MUST yield pin status `wishlist`.
- **FR-004**: A claim with `instanceId` missing from inventory MUST yield `stale` + `instance_missing`.
- **FR-005**: A claim with inventory hash ≠ claim `itemHash` MUST yield `stale` + `hash_mismatch`.
- **FR-006**: A claim with matching owned instance MUST yield `pinned`.
- **FR-007**: `equipReady` MUST be true only when there is at least one applied combat pin status and every status is `pinned`.
- **FR-008**: Domain MUST export `assertEquipReady` that throws with code `NOT_EQUIP_READY` when not ready (no throw when ready).
- **FR-009**: Golden unit tests MUST cover wishlist-not-ready, full pin ready, empty gaps ignored, stale missing, hash mismatch, and post-sync ready/not-ready.
- **FR-010**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **PinStatus / PinStatusKind / PinStaleReason / EquipReadyResult**: DART-002 models (reuse).
- **ResolvedVariantEquipment / SlotClaim**: DART-002/005 shapes (reuse).
- **InventoryPinIndex**: pure map instanceId → itemHash (new thin type or typedef).
- **EquipReadyException**: domain throw type with `code`, `message`, optional `details` (no HTTP).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes equip-ready suite green with parity scenarios above.
- **SC-002**: Wishlist-only applied slots never report `equipReady: true`.
- **SC-003**: Stale pin reasons use wire names `instance_missing` / `hash_mismatch`.
- **SC-004**: Domain `pubspec.yaml` runtime deps remain empty (SDK only).
- **SC-005**: Roadmap row DART-006 marked done after merge to `feature/multiplatform-dart`.

## Assumptions

- Callers supply pre-built `ResolvedVariantEquipment` (from DART-005 pure resolve or later IO adapters) and an inventory pin index; no inventory repository in domain.
- Domain throws `EquipReadyException` instead of HTTP `ApiError`; adapters map `NOT_EQUIP_READY` later (409 in product).
- Combat slot list matches TS: primary, special, heavy, helmet, arms, chest, legs, class_item — already on `EquipmentSlot.combatSlots`.
- Empty applied set ⇒ not equip-ready (same as TS: `pinStatuses.length > 0 && every pinned`).
- Soft guidance never auto-applies; this slice does not evaluate soft coverage.
