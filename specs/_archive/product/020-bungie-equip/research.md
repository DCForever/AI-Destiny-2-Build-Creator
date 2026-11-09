# Research: Bungie Equip

**Feature**: 020-bungie-equip  
**Date**: 2026-07-10

## R1 — Write client

**Decision**: `BungieWriteClient` interface with `transferItem`, `equipItem`, `applyArtifactConfig`, `applyFashionSlot` (or grouped apply). HTTP impl posts to Destiny2 Actions; `createMockWriteClient` for tests.

**Rationale**: No write APIs exist today; constitution V + testable orchestration.

## R2 — Sync freshness

**Decision**: Before equip, if `lastFullSyncAt` within 60s, skip sync; else call `syncUserInventory`. If sync in progress, wait or return `SYNC_BUSY`. Surface `WAIT` when rate-limited beyond window (document Bungie errors).

**Rationale**: DBR-EQP-007; `lastFullSyncAt` already persisted.

## R3 — Character pick

**Decision**: `POST …/equip` body `{ characterId }`. Reject if character class ≠ build.className (`INVALID_CHARACTER`).

**Rationale**: DBR-EQP-005.

## R4 — Step plan

**Decision**: Pure `planEquipSteps(resolved, inventory, characterId)` → ordered steps: transfers (off-character/vault → target) then equip combat slots with instanceId, then artifact, then fashion specified slots.

**Rationale**: Testable without network; DBR-EQP-006.

## R5 — Partial status

**Decision**: `EquipStatus { steps: [{ id, kind, ok, error? }], completed, failed }`. Never rollback successes. Retry = re-POST (idempotent best-effort).

**Rationale**: DBR-EQP-008.

## R6 — Gate

**Decision**: Call `assertEquipReady` first; reuse 016 `NOT_EQUIP_READY`.

## R7 — Debug

**Decision**: BuildsDebugPage: load characters (class-filtered), Equip button → POST equip → log status JSON.
