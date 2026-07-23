# Quickstart: Finish Slot-First Chrome

**Feature**: 029-finish-slot-first  
**Date**: 2026-07-23

## Prerequisites

- Signed-in app; Build with incomplete default variant
- 028 Finish walkthrough already on Builds
- Optional inventory sync for owned fills

## Automated

```powershell
npx vitest run src/lib/builds/finishNextSlot.test.ts src/lib/builds/finishGaps.test.ts src/lib/builds/createSetAndAttach.test.ts
npm run gate
```

## Manual smoke (Finish)

### Weapons cold start

1. Default variant with no Weapons Set and empty weapon slots.
2. Finish build → Weapons.
3. Confirm **no** name field, type chips, tags, or link picker.
4. One-tap **Create Weapons set** → Set appears attached; **first empty weapon slot** fill opens.
5. Fill primary → special opens (or next empty) without create chrome.
6. Complete or Skip for now; overview reflects status.

### Capture path

1. Variant with resolved weapon claims, no Weapons Set.
2. Finish → Weapons shows **Capture** preferred.
3. Capture → attached; if empties remain, fill loop; else category satisfied.

### Sets tab advanced

1. Open variant Sets tab.
2. Link existing Weapons Set or Create with explicit name.
3. Resume Finish → Weapons enters fill or satisfied — not forced recreate.

### Armor interim

1. Finish → Armor → one-tap Create → first empty armor slot (no optimizer kit list).

## Expected outcomes

- Finish create is one confirmation to first empty slot (SC-001).
- Link/tags only outside Finish primary path.
- `npm run gate` green.
- No 031 optimizer UI required.
