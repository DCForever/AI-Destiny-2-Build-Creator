# Data Model: Equip Post-Sync Reassert

No schema or persistence changes.

## Runtime entities (unchanged shapes)

### ResolvedVariantEquipment

Combat slot map of optional claims (`slot`, `itemHash`, `instanceId?`, …). Post-sync readiness uses the same claims object from `getResolvedVariant`.

### UserInventoryItem

Inventory rows from `listInventoryItems` after sync. Indexed by `instanceId` for pin checks and planning.

### EquipReadyResult

- `equipReady: boolean`
- `pinStatuses: PinStatus[]` with `wishlist` | `pinned` | `stale` (+ optional `reason`)

Computed twice on equip path: once embedded in resolved variant (pre-sync), once explicitly post-sync against fresh inventory.

### PlannedEquipStep

Unchanged. Planner only emits steps when inventory rows exist for claimed combat instances; missing rows are errors, not omissions.
