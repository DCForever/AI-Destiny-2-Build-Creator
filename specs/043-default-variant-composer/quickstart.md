# Quickstart: 043-default-variant-composer

## Prerequisites

- `npm install`
- App running (`npm run dev` or `npm run dev:https`)
- Signed-in user with refreshed manifest
- Optional: inventory sync for optimize / equip-ready pins
- Optional: ≥1 class-compatible armor set and weapon set in library for Reuse paths

## Unit validation (no browser)

```bash
npm run test -- src/lib/builds/composerTabAccess.test.ts
npm run test -- src/lib/builds/finishMissingReasons.test.ts
npm run test -- src/lib/builds/weaponSynergyRank.test.ts
npm run gate
```

Expected: all green.

## Manual scenarios

### 1. New build → General draft

1. Open `/build` signed in → **New build**
2. Expect tabbed composer on **General** (no "Create build" standalone panel)
3. Subclass / Armor / Weapon tabs do not activate without class (and subclass for Subclass)
4. Finish is visible; equip/export disabled with reasons

### 2. Persist + unlock

1. Set class, subclass, ≥1 synergy type → save General
2. Build appears in library; composer is live
3. Open Subclass; edit kit; save
4. Armor → Reuse → attach set → optional Improve appears; skip leaves attachment
5. Armor → Create → optimize or create → set has generated name + concept tags from synergies
6. Weapon → Create → synergy-matching weapons indicated first
7. Finish shows fewer missing reasons as gaps close
8. With full combat coverage + owned pins → equip/DIM enabled

### 3. Non-default light edit

1. Duplicate or add non-default variant
2. Same full tabs
3. Change weapons only → save succeeds without armor recreate

### 4. Regression

1. Zero synergies cannot create/save (`NO_SYNERGY`)
2. Soft guidance does not auto-change pins
3. Illegal kit still hard-blocks

## Canonical UX

- `docs/build-composer-flow - Future direction.excalidraw`
- Contract: [contracts/default-variant-composer-contract.md](./contracts/default-variant-composer-contract.md)
