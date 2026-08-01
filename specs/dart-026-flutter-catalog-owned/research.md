# Research: DART-026 Flutter Catalog Owned

**Date**: 2026-07-24

## Product parity sources

| Topic | Product source | Dart decision |
| ----- | -------------- | ------------- |
| Scope all/owned | `filterItems.ts` `params.scope` | `CatalogScope.all` / `.owned` on `CatalogClientFilters` |
| Owned counts | `ownedHashesFromInventory` + `applyAggregatedOwnedCounts` | MVP: count by `itemHash` only (no searchName aggregation) |
| Orphan owned rows | `unknownOwnedRow` + `InventoryHashProjection` | Deferred; omit hashes not in base catalog |
| Instance list | `projectInstance.ts` / inventory instances | `CatalogInstanceProjection` from Drift rows; raw plug hashes; power-desc |
| Pointer-only rows | product US4 URL pointer | Host shows inline instance list on select (desktop catalog); no HTTP API |

## Why hash-only ownership (A1)

MVP entity catalog is weapons + exotic armor + subclass pieces + mods. Full legendary armor store and searchName merge are later. Hash match is enough for “owned filter works after sync” with exotic/weapon fixtures and inventory sync rows.

## Local user resolution

DART-025 `InventorySyncController` already ensures user and exposes `localUserId` after `refreshStatus` / `syncNow`. Catalog bridge prefers that id; if null but session signed in, call `ensureUser` with membership id (same pattern as sync card).

## Soft / hard rules

No soft auto-apply. No hard DBR in catalog. Owned is a browse filter only.
