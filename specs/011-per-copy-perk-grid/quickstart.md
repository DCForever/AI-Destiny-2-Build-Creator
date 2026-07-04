# Quickstart: Per-Copy Weapon Perk Grid

**Feature**: 011-per-copy-perk-grid | **Date**: 2026-07-04 | **Phase**: 1

Validation/run guide for the **per-copy perk grid** on the debug **Sets** surface. For full debug prerequisites (manifest, OAuth, inventory sync, production route rules) see **`DEBUG.md`**. Contract details: [`contracts/`](./contracts/); data shapes: [`data-model.md`](./data-model.md).

## Prerequisites

- Manifest downloaded and entity stores built (`weapons`, `exotic-weapons`, `weapon-perks`, `origin-traits`). See `DEBUG.md`.
- Signed in via Bungie OAuth and **inventory synced** at least once **after** this feature lands (or allow auto re-sync on grid open). See `DEBUG.md`.
- Test inventory including:
  - A **crafted or multi-perk** weapon copy (alternates in at least one column).
  - **Two copies** of the same random-roll weapon with **different perks**.
  - Optionally an **exotic** with catalyst socket.
- `npm run dev` → `/debug/sets`.

## Commands

```bash
npm run test            # unit/integration (vitest)
npm run gate            # typecheck + lint + test + build (checkpoint bar)
```

## Scenario A — Per-copy grid replaces type pool (US1)

1. Create/pick a **Weapon** set and slot; search and select a weapon owned in multiple copies.
2. Select one copy in the carousel.
   - **Expected**: perk grid loads from `GET /api/user/inventory/instances/:instanceId/perk-grid` (not catalog `perk-options`).
   - **Expected**: columns labeled (Barrel, Magazine, Trait, …); equipped perk marked/preselected (FR-003).
3. Select a **different copy** of the same weapon.
   - **Expected**: grid **changes** to reflect that copy's options (SC-002).
4. Crafted/multi-perk copy.
   - **Expected**: at least one column shows **multiple** options (FR-005).

## Scenario B — Save column selections (US2)

1. On a copy with alternates, change **one column** away from equipped; leave others default.
2. Click **Put item**.
   - **Expected**: set item stores this copy's **`instanceId`** and `selectedPerks` = equipped defaults + your override in **column order** (FR-009, FR-010, SC-004).
3. Repeat with no changes.
   - **Expected**: equipped perks recorded (FR-008).

## Scenario C — Stale copy auto re-sync (US3)

1. Use a weapon copy whose row predates capture (`socket_plugs` null) — or simulate in tests.
2. Select the copy and open the grid.
   - **Expected**: brief loading; **one** automatic `POST /api/bungie/sync`; grid re-fetches.
   - **Expected**: after successful sync, `captureStatus: "complete"` and alternates appear.
3. If sync fails or capture stays incomplete.
   - **Expected**: equipped-only grid + clear indicator; **no** weapon-type pool (FR-015, SC-005).
   - **Expected**: no repeated sync loop on the same copy in one session (FR-018).

## Scenario D — Enhanced + exotic (FR-016, FR-017)

1. Crafted copy with enhanced perk available in a column.
   - **Expected**: base and enhanced appear as **separate options**; enhanced labeled (FR-017).
2. Exotic weapon copy.
   - **Expected**: same grid layout; intrinsic / catalyst columns when present (FR-016).

## Edge cases to verify

- Single-option columns → exactly one entry, equipped (FR-004).
- Unresolved perk name → shown by hash (FR-011).
- Armor copy selected → no perk grid (FR-012).
- Occupied slot → replace confirmation still applies (FR-020).
- Switch carousel copy → grid refreshes (FR-013).

## Automated coverage (expected)

| Area | Test location |
|------|---------------|
| Parse component 310 + persist `socket_plugs` | `src/lib/bungie/profile.test.ts` |
| `socket_plugs` migration | `src/lib/db/schema.test.ts` |
| Socket classification | `src/lib/inventory/instances/classifyWeaponSocket.test.ts` |
| Grid resolution + degradation + enhanced labels | `src/lib/inventory/instances/resolveInstancePerkGrid.test.ts` |
| Perk-grid route | `src/app/api/user/inventory/instances/[instanceId]/perk-grid/route.test.ts` |
| Auto re-sync dedupe | `src/lib/inventory/instances/perkGridRefresh.test.ts` |
| Set attach regression (`instanceId` + `selectedPerks`) | `src/lib/sets/*.test.ts` |

## Docs

Update **`DEBUG.md`** in the implementation change: document perk-grid endpoint, auto re-sync behavior, and that Sets debug **no longer** uses catalog `perk-options` for attachment. Bump **Last reviewed** date per `debug-docs` rule.
