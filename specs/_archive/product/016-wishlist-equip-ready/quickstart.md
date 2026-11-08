# Quickstart: Wishlist Desired Rolls & Equip-Ready Pins

**Feature**: 016-wishlist-equip-ready  
**Branch**: `016-wishlist-equip-ready`

## Prerequisites

- On branch `016-wishlist-equip-ready`
- Signed-in session; inventory synced at least once for pin tests
- `npm run dev`

## Setup

```bash
npx vitest run src/lib/builds
npm run gate
```

## Validation scenarios

### V1 — Wishlist save (US1)

1. On Sets debug, add item to a set **without** instanceId (catalog only).
2. Attach set to a build variant; save.
3. **Expect**: save OK; resolved slot shows wishlist pin status.

### V2 — Pin → equip-ready (US2)

1. Pin owned instances on every applied combat slot via Sets carousel.
2. Fetch resolved on Builds debug.
3. **Expect**: `equipReady: true`, all pinStatuses `pinned`.

### V3 — Gates (US3)

1. Wishlist-only variant → Check equip gate / DIM gate → blocked `NOT_EQUIP_READY`.
2. Equip-ready variant → both gates `allowed: true` (no real equip/export).

### V4 — Stale (US4)

1. Pin an instance; remove it from inventory (or sync after dismantle).
2. Re-fetch resolved → slot `stale`; gates blocked; desired roll retained.
3. Re-pin owned copy → stale cleared; equip-ready when all slots pinned.

## Gate checkpoint

```bash
npm run gate
```
