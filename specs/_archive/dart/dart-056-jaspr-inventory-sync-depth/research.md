# Research: DART-056 Jaspr Inventory Sync Depth

## R1 — Why web Settings was thinner

**Decision:** DART-050 wired vault lookup on **Jaspr equip** `syncIfStale` only; Settings sync UI and Catalog Owned were deferred to DART-056 (GAP-WEB-01 / RB-02).

**Evidence:** `apps/web_host/lib/app.dart` builds `equipmentBucketLookupBuilder` for `ComposeServices` equip; `settings_page.dart` has OAuth + entity-owned warning but no Sync now; `catalog_page.dart` subtitle: "No inventory owned filter yet."

## R2 — Resolution source on web

**Decision:** Use `createWebEquipmentBucketLookupBuilder` (OfflineCatalog slot → `buildEquipmentBucketLookupFromSlots`). Same as equip path. Do **not** download full raw DestinyInventoryItemDefinition on web (D-WEB-DB / DART-044 prebuilt).

**Residual (PROC-06):** Legendary armor without slot labels in MVP bundle may not resolve transfer containers; weapons/exotics with slots resolve. Not intentional pure-function thinning; document under closed GAP-WEB-01 residual note if needed.

## R3 — Owned → pin path

**Decision:** Catalog Owned + instance projections with visible `instanceId` is sufficient for equip/DIM pin usability (compose already has free-text pin). Optional "copy instance id" affordance in UI text.

## R4 — Controller reuse

**Decision:** Port Windows `InventorySyncController` semantics to web with `WebOAuthSession` (not share Flutter ChangeNotifier file). Package `syncUserInventory` is already pure-host-agnostic.

## R5 — Docs / cutover

**Decision:** Closing GAP-WEB-01 + RB-02 updates RC-SYNC status so web owned depth is no longer the sole FAIL reason. Live Next-vs-Dart dual-run remains under RC-OPS / harness (DART-054); not re-opened as web depth gap.
