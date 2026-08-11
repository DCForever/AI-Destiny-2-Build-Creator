# UX brief: sets / create wizard dual-truth (RES-SET-CREATE-01)

**Status:** locked (residual; mockups already approved under Armor 001)  
**Date:** 2026-08-10  
**Hosts:** windows (exit gate); mobile structure-only  
**Parent brief:** `docs/ux-redesign/sets/001-armor-brief.md`  
**Mockups (approved):**  
- `docs/ux-redesign/sets/mockups/001-armor-desktop.html` (create wizard steps)  
- `docs/ux-redesign/sets/mockups/001-armor-mobile.html`  
**Approval:** `docs/ux-redesign/sets/MOCKUP-APPROVED.md`  
**Plan:** session residual classification — Create Set flow vs mockup  

## Slice goal

Bring **Create Set** on Windows to mockup dual-truth for **flow + chrome**:

1. Multi-step wizard: **Type → Class → Bonus → Name** (tags optional on Name step if already supported)  
2. Step dots + crumb (`New set · type|class|bonus|name`)  
3. Footer **Back** / **Continue** / **Cancel**; Create only on final step  
4. One step visible at a time; choice-grid style for type/class  
5. Set-bonus searchable catalog + EntityInfoHotspot **only on Bonus step** (keep current catalog loader)  
6. Hide product-path **Quick create** on library rail (tests may keep a test-only path if needed)  
7. After successful create: open empty **board** (layout A / `SetsArmorBoard`) not only legacy detail scroll  

## Out of scope

- Owned inventory fill / compare projection (separate residual)  
- Optimize primary shell cutover (separate residual)  
- Full non-Armor Neon boards  
- Synergy Type chrome  
- Reopening package mins / type-fixed domain  

## Product rules (unchanged)

- G-SET-001 modal lifecycle  
- G-SET-004 / G-SET-040 Type + Class before pieces  
- G-SET-013 bonus goals legal combos only  
- G-SET-033 tags hard-block Synergy vocab when tags step present  
- Auto-name Class · pc · bonus · tags when name blank  

## Acceptance

- [x] Armor create: step 0 Type only; Continue disabled until type selected  
- [x] Armor create: step 1 Class only; Continue until class selected; Back works  
- [x] Armor create: step 2 Bonus optional (None or legal G-SET-013); Continue always allowed  
- [x] Armor create: step 3 Name + auto-name preview; Create persists and selects set  
- [x] Non-Armor: skip Class/Bonus; thin shell create still works  
- [x] Pieces/compare UI never shown during create  
- [x] Quick create not visible on product Sets rail (or clearly non-product)  
- [x] Post-create opens board shell with empty layout A (or explicit Open board that is automatic)  
- [x] Widget tests for step machine + host smoke create path  
- [x] Capture fixtures for create steps (type, class, bonus, name) + COMPARE package; PNGs via Capture driver

## Architect notes

- Prefer evolving `SetsCreateWizard` into step-index state (or host `SetsLifecycleController` drives step)  
- Reuse `SetsBonusGoalsEditor` + `loadArmorSetBonusFamilies`  
- `SetsLifecycleModal` footer slots for Back/Continue/Create  
- Do not reinvent set-bonus search/info  

## Residual id

**RES-SET-CREATE-01**
