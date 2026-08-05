# Catalog / residual-polish — dual-truth chrome close

**Status:** locked (area-ux-redesign-7 complete)  
**Date:** 2026-08-04  
**Approval:** `docs/ux-redesign/catalog/MOCKUP-APPROVED.md`  
**Mockups:**

- `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-residual-polish-mobile.html`

**Dual ground truth:** `implementation-shots/001-full/` + `COMPARE.md` + residual mockups

---

## Slice goal

Close five COMPARE dual-truth residuals after 001-full implement:

1. Compact **22×22** `CatalogWeaponMetaStrip` (horizontal icon strip — not full-width bars)
2. Official weapon-type **silhouettes** with letter last-resort (never invent art)
3. **③ ON** column headers: ellipsis + Tooltip + Semantics at `kCatalogWeaponsDetailWidth=400` without pane widen / perk-grid H-scroll
4. Host **`plugEnhancedByHash`** live path for instance Enhanced gold/E (name-heuristic fallback only)
5. Soft catalyst **omit-when-empty** honesty

Plus locked presentation rules refined at Human Gate:

- Enhanced **E only on ①/②** instance plugs; **③ / unowned / Possible crafted** = single identity + **“Can be enhanced” note** (no duplicate cells; future description popup)
- **Possible crafted** = same design as Possible rolls (toggle OFF default; dashed ③-style columns; hide until craft data)

## Out of scope

Greenfield redesign; armor optimizer; live Set/Synergy weapons CTAs; mobile Catalog push as gate; Confidential OAuth; inventing plugs/origin/craft/farm; craft columns until `craftAvailable`; new design system; widening 400 pane or perk-grid H-scroll; reopening tier defaults; vault transfer/notes; Catalog-as-home.

## Surfaces

- shell.nav.catalog  
- catalog.signed-out.weapons  
- catalog.weapons.manifest / owned / filters / list / instance-card / perk-grid  
- catalog.weapon.detail (+ perks, stats)  
- flow.catalog.weapons  

## Locked decisions

1. **Five residuals + tests/re-shots only**; product-map ID attach optional; armor/mobile not gates.  
2. **Meta:** fixed ~22×22 chips, compact horizontal strip; structure tests + dual-truth re-shots required.  
3. **Type:** official silhouettes when mapped; letter last-resort + a11y name; never invent art; slot stays letter.  
4. **③ ON headers:** ellipsis + Tooltip + Semantics = pass; no widen pane / no perk H-scroll.  
5. **Enhanced (instance):** thin host `plugEnhancedByHash` this slice; gold border + **E** only on **①/②** when this copy’s plug is enhanced; name-heuristic fallback only when map empty.  
6. **Enhanced (definition pools):** unowned, ③ Possible rolls, and Possible crafted show **one cell per perk** — never base+enhanced pair; **note only** when pool can be enhanced; future description popup (not cell chrome).  
7. **Possible crafted:** same UI as Possible rolls (toggle OFF default; ③-style columns); hide until `craftAvailable` + craft columns.  
8. **Soft catalyst:** omit empty panel; display-only when present; never invent progress; no equip/save gate.  
9. **Tier hard lock:** owned ①+② default, Possible rolls OFF; unowned ③-only.  
10. Set/Synergy **disabled stubs only**; composition aid only (DBR-PUR-002); All default; signed-out never fakes owned.  
11. **Windows-only gate**; mobile Catalog deferred; dark primary re-shots; light smoke optional.  
12. Neon void / Cool technical Flap + official Destiny icons only.

## Acceptance

- [ ] Meta strip fixed ~22×22 chips compact horizontal; dual-truth re-shots show no full-width bars  
- [ ] Weapon-type official silhouettes when mapped; letter last-resort + Semantics; never invent type art  
- [ ] ③ ON headers ellipsis+Tooltip+Semantics at 400 equal Expanded; no pane widen; no perk-grid H-scroll  
- [ ] `windows_host` wires `plugEnhancedByHash`; gold+E on ①/② when true; no E on ③/unowned/craft pool cells  
- [ ] Soft catalyst omitted when empty; display-only when present; no invent progress; no equip/save gate  
- [ ] Tier lock preserved: owned ①+② default Possible rolls OFF; unowned ③-only  
- [ ] Unowned / ③ / craft: enhance = note only; one cell per perk identity  
- [ ] Possible crafted toggle OFF default; same column design as Possible rolls; hidden without craft data  
- [ ] Origin only when data; Set/Synergy disabled stubs  
- [ ] Signed-out never fakes owned; DBR-PUR-002 composition aid only  
- [ ] Widget tests + windows host smoke green for residuals  
- [ ] Flutter structure matches mock interaction model; Neon/Flap + official Destiny icons only  
- [ ] COMPARE dual-truth re-shots updated; mobile push not required to close  

## Package placement (architect)

Residual chrome lives in `packages/ui_flutter` (`catalog/*` + `destiny_official_icons` weapon-type map). Thin host wire only in `apps/windows_host/lib/catalog` (`CatalogPage` + `OwnedCatalogBridge` `plugEnhancedByHash`). No domain/sandbox_data/IO package changes; `ui_tokens` only if a shared 22px constant is justified. Keep hosts thin: maps in, widgets render.

## Widget inventory

- `CatalogWeaponMetaStrip` (+ fixed 22×22 chips)  
- `officialWeaponTypeVisual` / `kWeaponTypeOfficial` in `destiny_official_icons.dart`  
- `CatalogPerkGrid` (equal Expanded headers: ellipsis+Tooltip+Semantics @400)  
- `CatalogWeaponDetail` (tiers, enhance note rules, origin/craft honesty)  
- `ExoticIdentityBlock` (omit-empty catalyst)  
- `CatalogDetailToggles` (Possible rolls OFF; craft hidden without data)  
- `CatalogWeaponsWorkspace` (`kCatalogWeaponsDetailWidth=400`)  
- `CatalogWeaponsGrid` / `NeonItemCard`  
- `NeonFacetChip` + `CatalogFilterBar` + `CatalogScopeControl`  
- `CatalogEmptyState`  
- `WeaponInstanceStrip` (H-scroll OK; distinct from meta)  
- `windows_host` CatalogPage + OwnedCatalogBridge  

## Widget test inventory (minimum)

- MetaStrip: chip size == 22×22; strip not full-width bars  
- MetaStrip: mapped type → silhouette; unmapped → letter + Semantics/tooltip  
- MetaStrip: ×N only when owned+count  
- PerkGrid @400: long headers ellipsis + Tooltip + Semantics; equal Expanded; no horizontal Scrollable  
- Detail owned: ①+② default, Possible rolls OFF, origin when data, craft hidden without columns  
- Detail unowned: ③-only; no fake selected; enhance note when canBeEnhanced; no E cells  
- Detail enhanced: map true → gold+E on ①/② only; ③ ON → no E on possible cells  
- Soft catalyst: empty omitted; present display-only  
- Grid: signed-out never owned badges  
- Empty states: zeroMatch Clear; ownedEmpty Sync  
- Facets: off→include→exclude + zero Clear  
- Workspace: detail width == 400  
- Toggles: craftAvailable false hides craft; can-roll OFF default  
- Host smoke: All grid + filters + detail; enhanced map path when fixture supplied  

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "residual-polish",
  "brief_path": "docs/ux-redesign/catalog/001-residual-polish-brief.md",
  "hosts": ["windows"]
}
```

## Rule IDs

DBR-PUR-002, DBR-ROLL-001, DBR-ROLL-007, DBR-ROLL-008, DBR-ROLL-010, DBR-UI-001, DBR-UI-005, DBR-UI-006, DBR-UI-007, BR-CAT-001, BR-CAT-002, BR-CAT-004, BR-CAT-016, BR-CAT-016a, BR-CAT-016b, BR-CAT-016c, BR-CAT-031, BR-UI-002, BR-UI-003, BR-UI-005, DAC-NME-003, DAC-DST-008, DAC-CAT-003, DO-WPN-001

## Obsidian

`requirements/Projects/Destiny 2 Build Creator/UX/UX Catalog — Residual polish.md` (if vault mount present)

## Verify notes from redesign

| Panel | ok | Notes |
| --- | --- | --- |
| Product | true | No blocking product issues |
| UX | false (advisory) | Identity/instance rebind not this residual gate; mock density (legend+notes); mobile fixture gaps |
| Arch | false (expected pre-implement) | Host lacks `plugEnhancedByHash` wire; type silhouette map incomplete; meta chips min-size not fixed; header Tooltip/Semantics gaps — **these are the implement targets** |

Do not treat pre-implement arch fail as redesign blocker; implement closes those gaps against this brief.
