# Quickstart: Armor Set Optimizer

**Feature**: 026-armor-set-optimizer  
**Branch**: `026-armor-set-optimizer`

## Prerequisites

- Signed-in local user with inventory synced for at least one class
- Owned armor sufficient for a dual-2pc + exotic fixture (or use test fixtures in Vitest)
- Dev server: `npm run dev` (or HTTPS variant if required by auth)
- Operator notes: [DEBUG.md](../../DEBUG.md) for `/debug/*` flows

## 1. Create Sets from Build + attach (seed constraints)

1. Open debug Builds; select a build with filled armor (and optionally weapons/mods).
2. Run **Create sets from build** with `attachNow: true`, categories including `armor`.
3. Expect: new Armor Set in Sets list; Build attachments include the new set as **live**; if a prior Armor Set was attached, it was **detached** (replace-by-type) and remains in the library.
4. Expect on Armor Set: `optimizerConstraints` seeded with Build exotic (if any) + soft-stat priorities/thresholds; `setBonusGoals: []`; `preferReuse: false`.
5. Name collision: suffix ` (2)` etc. — request does not fail solely for duplicate name.
6. API check:

```http
POST /api/user/builds/{buildId}/create-sets
Content-Type: application/json

{ "attachNow": true, "categories": ["armor", "weapon", "mod"] }
```

See [create-sets-from-build-contract.md](./contracts/create-sets-from-build-contract.md).

## 2. Constrained optimize (melee + dual 2pc + exotic)

1. From the same build (or Sets debug), open **Optimize armor**.
2. Confirm seed: class, locked exotic (if build has one), soft-stat thresholds.
3. Add set-bonus goals: two families with `minPieces: 2` each; set `statPriorities` with `Melee` first.
4. Toggle **prefer-reuse** off/on; confirm reuse annotations (`usedInOtherSets`) appear when pieces live in other Armor Sets.
5. Submit; expect ranked **complete** five-slot combinations each containing the exotic and satisfying both 2pc goals.
6. API check:

```http
POST /api/user/armor/optimize
Content-Type: application/json

{
  "buildId": "{buildId}",
  "setBonusGoals": [
    { "setBonusKey": "FamilyA", "minPieces": 2 },
    { "setBonusKey": "FamilyB", "minPieces": 2 }
  ],
  "statPriorities": ["Melee", "Health", "Class", "Grenade", "Super", "Weapons"],
  "includeModEstimates": true,
  "preferReuse": false,
  "maxResults": 25
}
```

See [armor-optimize-contract.md](./contracts/armor-optimize-contract.md).

## 3. Browse results (DIM-like)

1. Inspect each row: five pieces, estimated six stats, set-bonus summary, assumed mods, reuse annotations / `reusePieceCount`.
2. Selecting a row must not create or modify Sets until materialize / apply confirm.

## 4. Mod-aware ranking fixture

1. With `includeModEstimates: true`, confirm assumed mods listed and energy-legal.
2. Toggle `includeModEstimates: false` and confirm estimates drop / assumedMods empty.
3. Automated: Vitest fixture where only mod-aware path meets a Melee threshold (SC-004).

## 5. Materialize + attach (persist constraints)

1. On debug Builds or debug Sets, run **Optimize armor (026)**, then fill the armor set name / `createModSet` / `attachNow` inputs above the results table and click **Materialize** on a result row. The request sends that row's pieces + `constraints` built from the search request just run (not the response `seed`), the armor set name, `createModSet`, and `attachNow`.
2. Reload Sets — Armor Set has pieces **and** stored `optimizerConstraints`; optional `linkedModSetId`.
3. API: [materialize-combination-contract.md](./contracts/materialize-combination-contract.md).

## 6. Refresh constrained Set (in-place)

1. Improve inventory (or fixture) with a superior piece that still meets constraints.
2. `POST /api/user/sets/{armorSetId}/optimize` → expect `hasImprovement: true`. Debug Sets triggers this automatically on-open (see §7) and shows the soft banner in **Optimizer constraints (026)**; the shared **Optimize armor (026)** result rows also expose an **Apply in place** button (visible when an Armor Set is selected) for `POST /api/user/sets/{armorSetId}/apply-combination`.
3. Confirm apply → **same Set id**; items updated; constraints unchanged.
4. See [refresh-constrained-set-contract.md](./contracts/refresh-constrained-set-contract.md).

## 7. Soft improvement suggestions

1. Post-sync hook: sign in, go to **Settings**, click **Sync inventory**. On success the Inventory sync card calls `GET /api/user/armor/improvement-suggestions?afterSync=1` and, when any constrained Armor Set attached to a Build has a better kit, shows a **"Better armor kits found"** banner with **Confirm** / **Dismiss** per Set. Confirm calls `POST /api/user/sets/{armorSetId}/apply-combination`; Dismiss only clears the local banner (never mutates the Set).
2. Manual fetch: on debug Builds, use **Improvement suggestions (026)** → **Fetch improvement suggestions** (`GET /api/user/armor/improvement-suggestions`, no query) for the same suggest-then-confirm flow while iterating.
3. Open an **unattached** (or attached) constrained Set in debug Sets — on-open the page calls `POST /api/user/sets/{id}/optimize` and shows a soft banner in **Optimizer constraints (026)** when a better kit exists; Confirm applies in place, Dismiss clears the banner.
4. **Clear constraints** on a Set (Sets debug → Optimizer constraints → **Clear constraints**, `PATCH` with `optimizerConstraints: null`) → it drops out of post-sync / on-open checks until constraints are set again (**Save constraints** restores eligibility).
5. See [improvement-suggestions-contract.md](./contracts/improvement-suggestions-contract.md).

## 8. Prefer-reuse

1. Fixture two equal-stat kits where only one has higher `reusePieceCount`.
2. `preferReuse: true` → higher-reuse kit ranks first after stat ties; `false` → stats-only order; annotations visible in both cases (SC-008).
3. Persist `preferReuse` on Set constraints when saving; per-search override does not save unless constraints are saved.

## 9. Empty / failure cases

| Case | Expect |
|------|--------|
| No inventory | `emptyReason.code = NO_INVENTORY` |
| Impossible dual 2pc | `SET_BONUS_UNSATISFIABLE` (or `NO_VALID_KITS`) with message |
| Incomplete five-slot kits | Never returned |
| Name collision on create/materialize | Auto-suffix; not a hard failure |
| Dual exotic pieces | Rejected at materialize / never returned from optimize |
| Refresh with no constraints | `400 NO_CONSTRAINTS` |
| Refresh already optimal | `hasImprovement: false` / `itemsUpdated: false` |

## Automated verification

```bash
npm test -- src/lib/optimizer
npm test -- src/app/api/user/armor
npm test -- src/app/api/user/builds
npm test -- src/app/api/user/sets
npm run gate
```

(Adjust globs to match implemented paths.)

## Success checklist

- [x] US1 create-from-build + attach replace-by-type; Armor constraints seeded  
- [x] US2 hard constraints hold on 100% of returned complete kits (fixture)  
- [x] US3 result rows complete; no premature writes  
- [x] US4 mod toggle changes estimates/assumedMods  
- [x] US5 materialize creates Sets + persists constraints + optional attach  
- [x] US5b refresh in place; soft suggestions suggest-then-confirm; clear constraints opts out  
- [x] US7 reuse annotations + prefer-reuse soft tie-break  
- [x] US6 Sets-page optimize without buildId works with manual class  
