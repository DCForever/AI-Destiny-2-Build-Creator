# Research: DART-039 Flutter DIM Export UI

**Date**: 2026-07-25  
**Branch**: `dart-039-flutter-dim-export-ui`

## Product parity sources

| Concern | Product source | Dart equivalent |
| ------- | -------------- | --------------- |
| jsonOnly payload | `buildVariantDimLoadout` + dim-export route | Domain `buildJsonOnlyDimExport` (DART-010) |
| equip-ready gate | dim-export-gate / `assertEquipReady` | Same pure assert; UI disables CTA |
| Clipboard UX | Debug / UI copy actions | Flutter `Clipboard.setData` + status |
| dim.gg share | `DimSyncClient` + `DIM_API_KEY` | **Out of slice** (deferred) |

## Decisions

### R1 — Host panel next to equip

**Decision**: Add `DimExportPanel` on Builds detail after/near `EquipPanel`, sharing the same bind lifecycle (build/variant/user).  
**Why**: Exit criteria is clipboard export on compose/equip surface; DART-038 already bound equip-ready evaluation patterns.  
**Alt rejected**: Separate Settings-only export page; new nav destination.

### R2 — Gate ownership

**Decision**: Controller recomputes `computeEquipReady` + calls `buildJsonOnlyDimExport` (which re-asserts). UI `canExport` mirrors equip-ready only (no character / sign-in requirement).  
**Why**: jsonOnly is local; product 409 NOT_EQUIP_READY is the hard block. Sign-in would only matter for future dim.gg.

### R3 — Clipboard injection

**Decision**: `typedef DimClipboardWriter = Future<void> Function(String text);` defaulting to `Clipboard.setData`. Tests pass a list-capturing writer.  
**Why**: Widget tests must assert payload without OS clipboard flakiness.

### R4 — Soft / mods / fashion

**Decision**: Pass build softStatTargets into input; empty modHashes; null fashion/artifact for this slice.  
**Why**: DART-010 supports them when present; host does not yet collect mods/fashion for export. Soft never auto-applies.

### R5 — No network

**Decision**: Zero Bungie/DIM HTTP in this slice.  
**Why**: Port non-goal for early dim.gg; pure Dart I/O only.

## Open items (out of slice)

- dim.gg share URL path (needs API key + auth story).
- collectVariantMods for parameters.mods.
- Full fashion/artifact resolved export notes.
