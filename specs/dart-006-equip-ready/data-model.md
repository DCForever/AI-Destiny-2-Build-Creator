# Data Model: DART-006 Equip Ready

## Reused (DART-002 / DART-005)

| Type | Role |
| ---- | ---- |
| `EquipmentSlot.combatSlots` | Evaluation order for weapons + armor |
| `SlotClaim` | Applied claim; `instanceId` optional (wishlist) |
| `ResolvedVariantEquipment` | Equipment map input |
| `PinStatusKind` | `wishlist` \| `pinned` \| `stale` |
| `PinStaleReason` | `instance_missing` \| `hash_mismatch` |
| `PinStatus` | Per-slot evaluation result |
| `EquipReadyResult` | Aggregate `equipReady` + `pinStatuses` |
| `DomainFailureCodes.notEquipReady` | `NOT_EQUIP_READY` |

## New this slice

### InventoryPinItem

| Field | Type | Notes |
| ----- | ---- | ----- |
| instanceId | String | Owned copy id |
| itemHash | int | Catalog hash for that instance |

### InventoryPinIndex

| Representation | Notes |
| -------------- | ----- |
| `Map<String, int>` | instanceId → itemHash (pure) |

### EquipReadyException

| Field | Type | Notes |
| ----- | ---- | ----- |
| code | String | `NOT_EQUIP_READY` |
| message | String | Human-readable |
| details | Map\<String, Object?\>? | e.g. pinStatuses summary, `allowed: false` |

No new persistent entities. No DB records.
