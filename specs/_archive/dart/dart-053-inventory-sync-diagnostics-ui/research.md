# Research: DART-053 Inventory Sync Diagnostics UI

**Date**: 2026-07-25

## Decision: Pure formatSyncDiagnostics in destiny2_bungie

**Choice**: Port Next `ManifestCard.formatSyncDiagnostics` to pure Dart under `packages/bungie/lib/src/sync/format_sync_diagnostics.dart`.

**Rationale**: Same diagnostics model already on `SyncInventoryResult`; hosts should not re-implement string shapes. Unit-testable without Flutter.

**Alternatives rejected**:
- Inline strings only in InventorySyncCard — duplicates web/tests and drifts from Next.
- New app package — overkill for one pure function.

## Decision: Session-ephemeral lastDiagnostics

**Choice**: Controller holds `InventoryParseDiagnostics? lastDiagnostics` set only on successful `syncNow`. Not written to Drift. Cleared on signed-out refresh.

**Rationale**: Product Next keeps diagnostics in React state the same way; Drift already has itemCount/syncVersion/lastFullSyncAt.

## Decision: Entity-cache warning placement

**Choice**:
1. Settings: banner when `ManifestStatus.entityCache` null or total entity count == 0.
2. Catalog Owned empty: if `CatalogEmptyReason.noVersion|noStores`, message prioritizes entity stores over “Sync now only”.

**Rationale**: GAP-INV-06 — Owned = entities × inventory; empty cache ≠ empty vault.

## Decision: Web parity path (thinned intentionally)

**Choice**: Web Settings shows Owned/entity dependency warning panel; does **not** ship full inventory Sync now card (DART-056). Shared pure formatter is available for when web sync lands.

**Rationale**: Roadmap splits web sync depth to DART-056; exit criteria say “web parity path” not full sync UI. Document residual — not pure product thinning of diagnostics meaning on Windows.

## Next reference

- `src/components/settings/ManifestCard.tsx` — `formatSyncDiagnostics`
- `src/lib/bungie/syncInventory.ts` — `logInventorySyncDiagnostics`
