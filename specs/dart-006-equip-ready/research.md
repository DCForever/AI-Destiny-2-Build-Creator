# Research: DART-006 Equip Ready

**Date**: 2026-07-24

## Source modules (TypeScript product)

| TS symbol | Responsibility | Dart target |
| --------- | -------------- | ----------- |
| `buildInventoryPinIndex` | Map instanceId → {itemHash} | `equip_ready.dart` |
| `statusForClaim` (private) | wishlist / pinned / stale reasons | same (private or inline) |
| `computeEquipReady` | Applied combat slots only; equipReady aggregate | same |
| `assertEquipReady` | Throw NOT_EQUIP_READY when false | same (domain exception) |
| `PinStatusKind` / `PinStatus` / `EquipReadyResult` | Result shapes | DART-002 `pin.dart` (already ported) |

## Domain rules preserved

| Rule | Implication |
| ---- | ----------- |
| DBR-ROLL-005 | Save with wishlist OK; equip/export blocked until pins |
| DBR-ROLL-006 | Stale when instance gone; keep desired roll (caller); not equip-ready |
| DBR-EQP-003 | Equip + DIM require owned instance pins |
| DAC-P1-005 | Wishlist vs equip-ready separation |

## Decisions

### R1 — Pure inventory index only

**Decision**: `buildInventoryPinIndex` takes `List<InventoryPinItem>` (or equivalent records) and returns `Map<String, int>` (instanceId → itemHash). No inventory repository types.

**Rationale**: P0 pure domain; inventory load is P1/P2.

### R2 — Exceptions instead of ApiError

**Decision**: `EquipReadyException` with `DomainFailureCodes.notEquipReady` (`NOT_EQUIP_READY`), message matching product intent, `details` including `pinStatuses` / `allowed: false`.

**Rationale**: Matches resolve/soft exception pattern; HTTP 409 mapping is adapter concern.

### R3 — Combat slots from DART-002

**Decision**: Iterate `EquipmentSlot.combatSlots` (already mirrors TS COMBAT_SLOTS). Skip slots with no claim in `resolved.equipment`.

### R4 — Empty applied set

**Decision**: `equipReady = pinStatuses.isNotEmpty && pinStatuses.every((s) => s.status == PinStatusKind.pinned)` — same as TS. Empty variant is never equip-ready.

### R5 — Hash mismatch

**Decision**: Include golden test even though TS test file focuses on instance_missing; source implements hash_mismatch and product rules require item identity match for pins.

## Non-goals this slice

- DIM export builders (DART-010)
- planEquipSteps / Bungie write (DART-037)
- finishGaps listing (DART-007)
- Soft coverage influence on readiness
