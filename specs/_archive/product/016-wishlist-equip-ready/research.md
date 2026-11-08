# Research: Wishlist Desired Rolls & Equip-Ready Pins

**Feature**: 016-wishlist-equip-ready  
**Date**: 2026-07-10  
**Spec**: [spec.md](./spec.md)

Phase 0 decisions. No NEEDS CLARIFICATION remaining.

---

## 1. Where owned-instance pins live

**Decision**: Canonical pin = `set_items.instanceId`. Propagate into `SnapshotConfig`, expanded set items, and `SlotClaim` as optional `instanceId`. No separate variant pin table in this slice.

**Rationale**: Spec starts from set-item `instanceId` + `selectedPerks`. Live resolve currently drops pins; snapshots omit them — both must carry pins for equip-ready on resolved claims.

**Alternatives considered**: set_items only without snapshot/SlotClaim (breaks snapshot semantics); variant-level pin map (duplicates set data; defer).

---

## 2. Equip-ready computation

**Decision**: Pure `computeEquipReady(resolved, inventory)` in `src/lib/builds/equipReady.ts`. Per applied combat slot: `wishlist` | `pinned` | `stale`. `equipReady` iff every applied combat slot is `pinned` (non-stale, instance in inventory, hash matches). Independent of `assertFullCombatLoadout`.

**Rationale**: FR-006–008, FR-014; unit-testable without HTTP.

**Alternatives considered**: Persist `equip_ready` column (stale after sync); fold into composition assert (violates FR-014).

---

## 3. Stale detection

**Decision**: Evaluate-on-read against current `inventory_items`. No required `pin_stale` column. Sync refreshes inventory; next evaluate is correct.

**Rationale**: Spec assumption; avoids sync fan-out; FR-009 satisfied by recomputed status.

**Alternatives considered**: Persist stale flag on sync; clear `instanceId` on missing (violates keep desired roll).

---

## 4. Gate API shape

**Decision**: Extend `GET .../variants/:id/resolved` with `equipReady` + `pinStatuses[]`. Shared `assertEquipReady` / gate helper for thin `POST` equip-gate and dim-export-gate routes returning `{ allowed, reason, pinStatuses }` without Bungie write or DIM payload.

**Rationale**: US2/US4 need status on resolve; US3 needs explicit gate entry points for later equip/DIM.

**Alternatives considered**: Only dedicated `/equip-ready` GET; gates as query flags only.

---

## 5. Debug UI

**Decision**: Extend `BuildsDebugPage`: show equip-ready + per-slot statuses after Fetch Resolved; buttons for equip/DIM gate checks. Keep pinning on Sets debug + InstanceCarousel.

**Rationale**: SC-006; sets UI already writes `instanceId`.

---

## 6. Error / status codes

| Code | When |
|------|------|
| `NOT_EQUIP_READY` | Equip or DIM gate when missing/stale pins |
| (reuse) | Composition errors from 015 unchanged |

---

## Tech stack

Existing Next.js + SQLite + vitest + `npm run gate`. No new dependencies.
