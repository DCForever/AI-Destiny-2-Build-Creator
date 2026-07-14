# Quickstart: Armor Set Optimizer

**Feature**: 026-armor-set-optimizer  
**Branch**: `026-armor-set-optimizer`

## Prerequisites

- Signed-in local user with inventory synced for at least one class
- Owned armor sufficient for a dual-2pc + exotic fixture (or use test fixtures in Vitest)
- Dev server: `npm run dev` (or HTTPS variant if required by auth)

## 1. Create Sets from Build + attach

1. Open debug Builds; select a build with filled armor (and optionally weapons/mods).
2. Run **Create sets from build** with `attachNow: true`, categories including `armor`.
3. Expect: new Armor Set in Sets list; Build attachments include the new set as **live**.
4. API check:

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
4. Submit; expect ranked combinations each containing the exotic and satisfying both 2pc goals.
5. API check:

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
  "maxResults": 25
}
```

See [armor-optimize-contract.md](./contracts/armor-optimize-contract.md).

## 3. Browse results (DIM-like)

1. Inspect each row: five pieces, estimated six stats, set-bonus summary, assumed mods.
2. Selecting a row must not create Sets until materialize confirm.

## 4. Mod-aware ranking fixture

1. With `includeModEstimates: true`, confirm assumed mods listed and energy-legal.
2. Toggle `includeModEstimates: false` and confirm estimates drop / assumedMods empty.
3. Automated: Vitest fixture where only mod-aware path meets a Melee threshold (SC-004).

## 5. Materialize + attach

1. Confirm materialize with armor set name; enable create Mod Set if mods present; `attachNow` to build.
2. Reload Sets + Build attachments — Armor (+ Mod) Sets present and attached.
3. API: [materialize-combination-contract.md](./contracts/materialize-combination-contract.md).

## 6. Empty / failure cases

| Case | Expect |
|------|--------|
| No inventory | `emptyReason.code = NO_INVENTORY` |
| Impossible dual 2pc | `SET_BONUS_UNSATISFIABLE` (or `NO_VALID_KITS`) with message |
| Duplicate set name on materialize | `409 DUPLICATE_SET_NAME` |
| Dual exotic pieces | Rejected at materialize / never returned from optimize |

## Automated verification

```bash
npm test -- src/lib/optimizer
npm test -- src/app/api/user/armor
npm test -- src/app/api/user/builds
npm run gate
```

(Adjust globs to match implemented paths.)

## Success checklist

- [ ] US1 create-from-build + attach without second attach step  
- [ ] US2 hard constraints hold on 100% of returned kits (fixture)  
- [ ] US3 result rows complete; no premature writes  
- [ ] US4 mod toggle changes estimates/assumedMods  
- [ ] US5 materialize creates Sets + optional attach  
- [ ] US6 Sets-page optimize without buildId works with manual class  
