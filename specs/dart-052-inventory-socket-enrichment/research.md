# Research: DART-052 Inventory Socket Enrichment

**Date**: 2026-07-25

## Product source of truth

| Artifact | Path |
| -------- | ---- |
| Build stored plugs | `src/lib/inventory/instances/buildStoredSocketPlugs.ts` |
| Classify columns | `src/lib/inventory/instances/classifyWeaponSocket.ts` + `.test.ts` |
| Socket context load | `src/lib/inventory/instances/weaponSocketContext.ts` |
| Types | `src/lib/inventory/instances/types.ts` (`StoredSocketPlug`, `SocketColumnKind`, `RawSocketCapture`) |
| Sync call site | `src/lib/bungie/syncInventory.ts` `buildSocketPlugsForItems` |
| Perk indexes helper | `src/lib/manifest/extractors/common.ts` `getPerkSocketIndexes` |
| Category hash | `WEAPON_PERKS_CATEGORY_HASH = 4241085061` |

## Dart today

| Area | State |
| ---- | ----- |
| `_normalizeItems` | `socketPlugs = raw.socketCapture?.map(toJsonMap)` — **no** columnKind/columnLabel |
| Profile parse | Captures `RawSocketCapture` for weapons + transfer containers |
| Drift column | `socket_plugs` TEXT JSON list of maps (already supports columnKind in tests) |
| Manifest | `getPerkSocketIndexes` exists in `destiny2_manifest` extractors |

## Decisions

### D1 — Pure port location

**Decision**: `packages/bungie/lib/src/inventory/` — `classify_weapon_socket.dart`, `build_stored_socket_plugs.dart`, `weapon_socket_context.dart`.

**Rationale**: Inventory-sync enrichment, same home as DART-051 roll tags. No domain hard-gate coupling.

### D2 — Context without bungie→manifest dep

**Decision**: Injectable `WeaponSocketContextBuilder` + pure `buildWeaponSocketContextFromItemDefs(table, itemHash, plugHashes)` reading Map-shaped DestinyInventoryItemDefinition tables.

**Rationale**: Hosts already load raw tables for roll tags / equipment buckets. Reimplementing `getPerkSocketIndexes` as a thin map walk avoids package dependency cycle.

### D3 — Degradation without context

**Decision**: Without builder/context, weapons keep raw capture JSON (no kinds); non-weapons force `socketPlugs: null`. Document web residual when raw defs absent.

**Rationale**: Empty classify with no indexes drops all plugs → empty array misread as “unavailable”. Raw fallback preserves capture for later re-sync enrichment.

### D4 — Soft / hard

**Decision**: Socket plugs are soft storage metadata for perk grids. Never auto-apply build edits. Hard DBR blocks unchanged.

## Alternatives considered

| Option | Rejected because |
| ------ | ---------------- |
| Depend bungie on destiny2_manifest | Heavy; hosts already inject maps |
| Always null without context | Loses capture data until next full enrich |
| Port full InstancePerkGrid UI | Out of scope; GAP is **stored** shape |

## Open residuals (if any after implement)

- Web / hosts without raw DestinyInventoryItemDefinition cannot build plug categories → raw or unenriched plugs until entity channel / DART-056 — document PROC-06 if claimed partial.
