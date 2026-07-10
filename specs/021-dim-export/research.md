# Research: DIM Export

**Feature**: 021-dim-export  
**Date**: 2026-07-10

## R1 — Gate reuse

**Decision**: Call `assertEquipReady` on `POST …/dim-export` before building/sharing (same as dim-export-gate / equip).

**Rationale**: FR-001 / DBR-EQP-003; single readiness definition.

## R2 — Variant → DimLoadout builder

**Decision**: New `buildVariantDimLoadout` (do not overload sheet `buildDimLoadout`). Map combat `equipment` → `equipped` with `{ hash, id: instanceId }`; `parameters.mods` from collected mod hashes; soft stats → `statConstraints` when present; fashion specified slots → `unequipped` (or notes if schema awkward); artifact → `notes` line + optional parameters metadata.

**Rationale**: Sheet builder has no pins/fashion/artifact; FR-002–003.

## R3 — Mod collection

**Decision**: `collectVariantMods(db, userId, variantId)` walks attachments (live set items + snapshot configs) for mod-type set plugs / item hashes used as armor mods.

**Rationale**: Mods not on resolved equipment today; DBR-EQP-004 requires mods in export.

## R4 — Subclass kit

**Decision**: Encode subclass identity into `notes` (and include any known subclass item hash on equipped if available on build). Full socket-level subclass DIM encoding deferred if hashes unavailable without extra manifest lookup — document in notes for v1.

**Rationale**: Avoid blocking export on incomplete subclass hash plumbing; still surface kit for humans/DIM notes.

## R5 — 503 vs jsonOnly

**Decision**: Default share path **503** when `DIM_API_KEY` missing (match `/api/dim/share`). Body `{ "jsonOnly": true }` returns **200 `{ loadout }`** without calling DIM.

**Rationale**: Spec checklist deferred this; debug/CI need payload without live DIM.

## R6 — Auth

**Decision**: `requireAuthenticatedUser` for variant export (user-scoped resolve). Share still needs Bungie access token + membership for DimSync (same as share route).

**Rationale**: Consistency with equip / dim-export-gate.

## R7 — Keep sheet share

**Decision**: Leave `POST /api/dim/share` unchanged (FR-006).

## R8 — Debug

**Decision**: BuildsDebugPage **Export to DIM** → `POST …/dim-export` (default share; optional jsonOnly checkbox).
