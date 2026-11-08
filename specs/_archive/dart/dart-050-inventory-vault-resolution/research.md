# Research: DART-050 Inventory Vault Resolution

**Date**: 2026-07-25

## Decision: Where does `buildEquipmentBucketLookup` live?

**Choice**: Pure function in `packages/bungie` that takes a raw-definition map (or per-hash JSON) and returns `Map<int,int>`, plus a pure slot-label fallback in the same package. Hosts load raw tables via `destiny2_manifest.BungieManifestService.loadRawTable` or build a slot map from OfflineCatalog/entity records.

**Why**: Next’s helper only needs `inventory.bucketTypeHash` + equipment bucket set. Putting it in bungie keeps sync resolution free of a new bungie→manifest dependency and matches existing `equipmentBucketLookup` parameter on `syncUserInventory`.

**Rejected**: Moving sync into manifest package (wrong layer). Auto-loading raw tables inside `syncUserInventory` (would force manifest dependency + StorageRoot into bungie).

## Decision: Production wiring shape

**Choice**: Injectable `Future<Map<int, int>> Function(List<int> transferItemHashes)? equipmentBucketLookupBuilder` on host controllers (or pre-resolved map callback), defaulting to:

1. If raw DestinyInventoryItemDefinition available → `buildEquipmentBucketLookup(table, hashes)`
2. Else OfflineCatalog/entity slot map → `buildEquipmentBucketLookupFromSlots`
3. Else empty map (vault drops; Windows with manifest should rarely hit this)

Also extend `syncUserInventory` / `syncIfStale` to accept an optional async builder that receives transfer item hashes after parse (Next parity: only resolve needed hashes).

**Why**: Hosts currently omit lookup entirely. Explicit builder makes vault fixtures testable and production paths fail visibly when data missing.

## Decision: GAP-INV-07 optional

**Choice**: Implement `parseWeaponStatValues` in inventory_parse (small pure map) and use it for `isWeapon || isTransfer` instead of armor-only parser. Armor path unchanged.

## Decision: GAP-INV-06 residual

**Choice**: Docs only — Owned catalog still joins inventory counts onto entity baseItems. Vault resolution does not populate definition rows. UX warning remains DART-053.

## Next parity reference

- `src/lib/bungie/resolveEquipmentBuckets.ts` — `buildEquipmentBucketLookup`, `resolveTransferContainerBuckets`
- `src/lib/bungie/syncInventory.ts` — builds lookup from transfer item hashes before normalize
- Dart already has `resolveTransferContainerBuckets` + unit drop/resolve proof without host wiring
