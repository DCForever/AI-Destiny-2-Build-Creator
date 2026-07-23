# Quickstart: Build Inline Sets

**Feature**: 028-build-inline-sets  
**Date**: 2026-07-23

## Prerequisites

- Signed-in local app with at least one Build (default variant)
- Manifest/entity cache ready
- Optional: inventory sync for instance pins

## Automated

```powershell
# Domain
npx vitest run src/lib/builds/finishGaps.test.ts src/lib/builds/createSetAndAttach.test.ts src/lib/builds/createSetsFromBuild.test.ts

# Gate when implementing
npm run gate
```

## Manual smoke (production Builds)

### Cold start (no sets)

1. Open a Build whose default variant has **no** armor/weapon sets.
2. Confirm **Finish build** (or equivalent) is visible.
3. Start walkthrough → **Armor** first.
4. **Create empty** Armor Set → confirm live-attached.
5. Fill at least one empty armor slot from the walkthrough (catalog or owned).
6. Continue to Weapons → create or link → fill or **Skip for now**.
7. Exit mid-flow → reopen Finish build → prior Sets/fills still present; skips not marked done.

### Capture path

1. Variant with resolved armor claims but no Armor Set (or use debug compose then detach sets).
2. Finish build → Armor shows **Capture current gear** preferred.
3. Capture → Armor Set created, live-attached, pieces match claims; prior same-type live set replaced if any.

### Link existing

1. Library already has an Armor Set.
2. Walkthrough Armor → **Link existing** → pick set → attached live (replace-by-type).
3. Empty slots → fill from Builds without opening Sets library page.

### Completeness

1. Satisfy Armor + Weapons required slots with covering sets.
2. Walkthrough completes or only Mods remains; default variant incomplete guidance clears when complete per product rules.

## Expected outcomes

- No mandatory navigation to `/sets` to finish.
- Skip for now never equals satisfied.
- Order always Armor → Weapons → Mods.
- `npm run gate` green at each story checkpoint.
