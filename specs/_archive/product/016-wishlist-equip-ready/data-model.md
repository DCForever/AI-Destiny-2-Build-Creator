# Data Model: Wishlist Desired Rolls & Equip-Ready Pins

**Feature**: 016-wishlist-equip-ready  
**Date**: 2026-07-10  
**Spec**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

## Entities

### Desired Roll (on set item / snapshot / claim)

| Field | Notes |
|-------|-------|
| `itemHash` | Catalog identity |
| `itemName` | Display |
| `selectedPerks` | Plug hashes |
| `masterworkHash` / `modHashes` | As today |

No instance id required.

### Owned Instance Pin

| Field | Location | Notes |
|-------|----------|-------|
| `instanceId` | `set_items.instanceId` (canonical) | Nullable |
| propagated | `SnapshotConfig.instanceId`, `SlotClaim.instanceId` | Optional |

### Slot Pin Status (ephemeral)

| Status | Meaning |
|--------|---------|
| `wishlist` | Applied slot, no instanceId |
| `pinned` | instanceId present, in inventory, hash matches |
| `stale` | instanceId present, missing from inventory or hash mismatch |

### Equip-Ready (ephemeral)

Boolean: all **applied combat** slots are `pinned`. Independent of composition completeness.

## Relationships

```text
SetItem --optional--> InventoryItem (instanceId)
Attachment (live|snapshot) --> SlotClaim (+ optional instanceId)
SlotClaim + Inventory --> PinStatus --> EquipReady
```

## Validation

| Rule | Outcome |
|------|---------|
| Wishlist save | OK (composition rules still apply) |
| Equip/DIM gate when not ready | `NOT_EQUIP_READY` + pinStatuses |
| Re-pin | Must match slot itemHash; clears stale |

## Migration

1. Extend snapshot JSON shape to allow `instanceId` (backward compatible omit).
2. No DB column migration required for pins (column exists).
3. Existing null `instanceId` rows = wishlist.
