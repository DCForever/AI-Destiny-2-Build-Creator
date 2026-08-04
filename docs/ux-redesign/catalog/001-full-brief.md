# Catalog / Full — residual pass (weapons mock↔ship + thin surface audit)

**Status:** locked (area-ux-redesign-6 complete)  
**Date:** 2026-08-04  
**Approval:** `docs/ux-redesign/catalog/MOCKUP-APPROVED.md`  
**Mockups:**

- `docs/ux-redesign/catalog/mockups/001-full-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-full-mobile.html`

**Dual ground truth:** `implementation-shots/001-weapons/` + `COMPARE.md` + mockups

---

## Slice goal

Close three COMPARE residuals on **windows weapons** detail/grid (icon-only meta, Origin when data, equal-width no H-scroll under expanded pools) from dual ground truth; thin armor/universal residual audit only; mobile deferred.

## Out of scope

Constrained pick; live Set/Synergy/Build outbound on weapons (stubs only); Catalog-local Set/Synergy editors; armor optimizer; vault transfer/notes/lock; invented can-roll/craft/source/pool/origin; bare hashes as primary labels; new design system outside Neon void / Cool technical Flap; mobile Catalog nav/push as residual gate; greenfield grid density or facet IA redesign.

## Surfaces

- shell.nav.catalog  
- catalog.composition-aid  
- catalog.signed-out.weapons  
- catalog.weapons.owned / manifest / filters / list / perk-grid  
- catalog.weapon.detail  
- catalog.armor.* (audit only)  
- catalog.universal (audit; keep shared-lifecycle CTAs where mapped)  
- flow.catalog.weapons / flow.catalog.armor  

## Locked decisions

1. **Exit A then thin B:** windows weapons residuals first; armor/universal audit backlog only; mobile deferred.  
2. **Success metric:** three COMPARE residuals closed + tests — not multi-mode/host parity or live CTAs.  
3. **Residual priority:** equal-width no H-scroll (P0) → pure icon-only meta (P1) → Origin when data (P2).  
4. Hold **400px** detail + equal-width no H-scroll; compress icon-first cells with tooltip/Semantics; never widen or H-scroll.  
5. **Pure icon-only meta strip** (type·frame·element·slot·ammo) + ×N; drop text subtitle and KINETIC/OWNED text pills.  
6. **Hide Origin** when no origin data; unknown only for known-socket unresolved plug; never invent origin.  
7. Default scope **All**/manifest; Owned explicit; **OWNED · N** after sync; never auto-switch Owned; signed-out never fakes owned.  
8. **Perk tiers:** ① selected · ② unselected · ③ possible rolls; owned ③ via **Possible rolls** toggle **OFF by default**; unowned ③ only (no toggle); **Enhanced (E)** orthogonal to any tier.  
9. Hide **Possible crafted** until craft columns exist; soft catalyst only.  
10. Weapons Set/Synergy **disabled stubs only**; Universal keeps shared-lifecycle CTAs where mapped.  
11. Armor/universal: residual audit + optional Neon chrome align only; no optimizer.  
12. No grid density or facet IA redesign; residual chrome only.  
13. Composition aid only (DBR-PUR-002); Neon void / Cool technical Flap + official Destiny icons only.

## Acceptance

- [ ] Icon-only meta strip on owned+unowned detail; no text subtitle or KINETIC/OWNED text pills  
- [ ] Origin column only when definition/instance has origin data; hidden when none  
- [ ] Expanded ③ / multi-column pools: equal-width columns with **no horizontal scroll** at `kCatalogWeaponsDetailWidth=400`  
- [ ] Owned default shows ①+② only; Possible rolls toggle OFF by default; unowned shows ③ only without that toggle  
- [ ] Enhanced perks marked (gold/E) on any tier when data says enhanced  
- [ ] Craft toggle hidden until craft columns exist; soft catalyst only; never invent craft/pools/origin  
- [ ] Default scope All; after sync OWNED · N chrome; signed-out never fakes owned  
- [ ] Weapons Set/Synergy outbound remain disabled stubs  
- [ ] Armor/universal limited to residual audit notes (optional chrome align); no optimizer or new live weapons CTAs  
- [ ] Widget tests cover residual meta/perk/Origin/scope scenarios; windows host smoke green  
- [ ] Mock interaction model realized in Flutter structure (not pixel-perfect HTML); Neon/Flap tokens + official Destiny icons only  

## Package placement (architect)

Residuals owned by `packages/ui_flutter/lib/src/catalog/` (`CatalogWeaponDetail`, `CatalogPerkGrid`, `buildCatalogPerkColumns`; optional `CatalogWeaponMetaStrip` extract). Host `apps/windows_host/lib/catalog` remains thin wiring + smoke. No new packages; do not invent origin/craft/pools in UI.

## Widget test inventory (minimum)

- Icon-only meta; no type·frame text subtitle; no KINETIC/OWNED text pills  
- Origin present when data; absent when none  
- Perk grid at width 400 with multi-column pool — equal Expanded; no horizontal Scrollable  
- Owned: ①+② default; ③ after Possible rolls ON  
- Unowned: POSSIBLE ROLLS + full ③; no Possible rolls toggle  
- Enhanced flag styling when fixture marks enhanced  
- Craft chip hidden when `craftAvailable: false`  
- Scope All default; OWNED · N host label  
- Outbound Set/Synergy disabled  

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "full",
  "brief_path": "docs/ux-redesign/catalog/001-full-brief.md"
}
```

## Rule IDs

DBR-PUR-002, DBR-ROLL-001, DBR-ROLL-007, DBR-ROLL-008, DBR-ROLL-010, DBR-UI-001, DBR-UI-005, DBR-UI-006, DBR-UI-007, BR-CAT-001, BR-CAT-002, BR-CAT-004, BR-CAT-005, BR-CAT-006, BR-CAT-009, BR-CAT-010, BR-CAT-016a, BR-CAT-016b, BR-CAT-016c, BR-CAT-030, BR-CAT-031, BR-UI-002, BR-UI-003, DAC-CAT-003

## Obsidian

`requirements/Projects/Destiny 2 Build Creator/UX/UX Catalog — Full residual pass.md` (if vault mount present; create/update on implement if missing)

## Verify notes from redesign

- Product OK with note: Universal mock stubs must not regress live Universal CTAs in host.  
- UX issues for implement awareness: mobile scenario can-roll reset; instance strip vs identity perks; density under ③ ON at 400px.  
- Arch issues: P0 perk grid H-scroll/fixed width; god-files; missing residual tests — address in implement plan.  
