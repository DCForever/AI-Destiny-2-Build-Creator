# Research: DART-024 Bungie Profile Sync

**Date**: 2026-07-24

## Decisions

### R1 — Where sync orchestration lives

**Decision**: Implement profile client + sync + freshness in `packages/bungie` (`destiny2_bungie`), with a dependency on `destiny2_db` for full-replace and status.

**Rationale**: Product keeps `syncInventory.ts` / `syncFreshness.ts` next to profile. Roadmap exit is algorithm into Drift, not Settings UI (DART-025). Host stays thin.

**Alternatives rejected**: Sync only in `windows_host` (harder pure unit tests); sync only in `destiny2_db` (pulls HTTP into schema package).

### R2 — Transfer-container resolution

**Decision**: Accept optional `Map<itemHash, equipmentBucketHash>` (or equivalent) on sync. Without lookup, drop transfer-container items (product drops when resolution fails).

**Rationale**: Full resolution needs `DestinyInventoryItemDefinition` (manifest package). Avoid coupling this slice to manifest download.

### R3 — Freshness window

**Decision**: `kEquipSyncFreshMs = 60000` matching product `EQUIP_SYNC_FRESH_MS` / DBR-EQP-007.

**Rationale**: Domain rule; equip and Settings reuse the same helper.

### R4 — Enrichment depth

**Decision**: MVP store power, plugs, location, bucket labels, crafted/masterwork, simplified socket capture, armor named stats when present. Roll tags: empty or `Crafted` only.

**Rationale**: Exit criteria is full replace + sync_version + freshness — not catalog roll parity.

### R5 — Busy errors

**Decision**: Use DART-016 exclusive replace; expose `SyncInProgressError` for product-shaped callers (wrap/map busy exception).

## Product references

- `src/lib/bungie/profile.ts` — GetProfile parse
- `src/lib/bungie/syncInventory.ts` — membership + replace
- `src/lib/bungie/syncFreshness.ts` — 60s window
- `src/lib/bungie/inventoryBuckets.ts` — hashes/labels
- `packages/db` — `replaceInventoryBatchExclusive`, `getInventoryStatus`
)
