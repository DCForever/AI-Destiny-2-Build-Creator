# Catalog / browse-chrome — family cards, groups, sort/group priority, type icons

**Status:** locked (area-ux-redesign-8 complete)  
**Date:** 2026-08-05  
**Approval:** `docs/ux-redesign/catalog/MOCKUP-APPROVED.md`  
**Mockups:**

- `docs/ux-redesign/catalog/mockups/001-browse-chrome-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-browse-chrome-mobile.html`

**Gaps:** GAP-CAT-BROWSE-001 … 004 (`docs/ux-redesign/DUAL-TRUTH-GAPS.md`)

---

## Slice goal

Family weapon cards (one card per regular/adept/holofoil family): owned-only **non-selectable** version indicator chips on grid; card opens **primary** version (see openVersion); detail shows **all** family versions with full-rebind switch. Collapsible group-by + outline jump rail. User-reorderable sort priority and group-by dimension priority. Weapon type filters as official type silhouette icons. Dual-truth exit closes GAP-CAT-BROWSE-001–004 together on **windows**.

## Out of scope

Live Set/Synergy CTAs or Catalog-local create/edit; armor family parity as dual-truth gate; inventing collectible/pattern graph beyond name-normalized + slot/element/type guard; **selectable version chips on grid**; Catalog-as-home; greenfield design system or board density redesign (keep ~200×112 cards / 400 detail); mobile Catalog push as exit gate; GAP-CAT-PERK-003 as blocker; vault transfer/notes/lock; changing BR-CAT-006 filter semantics.

---

## Locked decisions

1. **Single dual-truth exit** for GAP-CAT-BROWSE-001–004; windows gate; mobile structure-only.  
2. **Family merge:** Adept/Holofoil-class via **name-normalized + slot/element/type** only; no invented collectible graph; under-merge OK.  
3. **One grid card per family;** base art + cleaned name when present else first member.  
4. **openVersion (card tap):** prefer **owned max-power** among family members when power data exists; else base/non-Adept/non-Holofoil when present; else stable first. When filters disambiguate to a single matching member, open that member.  
5. **Grid version chips:** **owned-only**, **non-selectable** static indicators; omit unowned; signed-out never fakes owned; not NeonFacetChip cycle.  
6. **Owned ×N** = sum across family members; family visible if **any** member matches (exclude drops only if all excluded).  
7. **Detail:** all family versions + switch; full hash rebind (perks/pools/catalyst/instances); unowned listable for inspect; family card selection sticky.  
8. **Groups:** all expanded default; header label+count+chevron toggles collapse only (**no filter rewrite**, BR-CAT-007).  
9. **Outline rail** only when group-by active and ≥2 groups; sticky; jump/scroll + expand; never filters.  
10. **Sort & group progressive sheet:** reorderable sort keys (default slot → exotic → ammo → archetype → name) + active group dims; persist last; no permanent dual lists.  
11. **Weapon-type filters:** primary-line iconOnly `kWeaponTypeOfficial` + Semantics/tooltip; letter last-resort; drop text archetype from More for weapons.  
12. Density lock maxCrossAxisExtent **200** / mainAxisExtent **112** / `kCatalogWeaponsDetailWidth` **400**.  
13. Composition aid only (DBR-PUR-002); Set/Synergy disabled stubs only.  
14. Residual-polish perk chrome held; GAP-CAT-PERK-003 non-blocking.  
15. Neon/Flap + official Destiny icons only.

## Surfaces

- catalog.signed-out.weapons  
- catalog.weapons.owned / manifest / filters / list  
- catalog.weapons.filter.element / ammo / archetype / slot / groupby  
- catalog.weapon.detail  
- catalog.composition-aid  
- flow.catalog.weapons  

## Acceptance

- [ ] One family card per name-normalized + slot/element/type family (not one definition hash)  
- [ ] Owned-only non-selectable version chips on grid; omit unowned; signed-out never fakes owned  
- [ ] Card art/name base-primary; tap uses openVersion (owned max-power → base → stable; filter disambiguation)  
- [ ] Detail lists all family versions + full identity rebind switch; family grid selection sticky  
- [ ] Owned ×N sums family instances; family shows if any member matches; exclude only if all excluded  
- [ ] Collapsible group sections default expanded; collapse does not filter  
- [ ] Outline jump rail only when group-by + ≥2 groups; scroll/expand only; never filters  
- [ ] Sort & group progressive sheet: reorderable sort keys + active group dims; persist; default slot→exotic→ammo→archetype→name  
- [ ] Primary-line weapon-type silhouette filters + Semantics/tooltip; no text archetype under More  
- [ ] BR-CAT-006 filter semantics unchanged; density 200×112 cards + 400 detail; Neon/Flap only  
- [ ] Set/Synergy stubs disabled; residual perk rules held  
- [ ] Widget tests + windows host smoke green; shot matrix proves family/group/sort/type tokens  
- [ ] Mobile structure parity only — not dual-truth exit gate  

## Package placement (architect)

- Pure: `packages/manifest` — family merge, multi-key sort, ordered group-by, any-member filter survival  
- UI: `packages/ui_flutter` catalog only — family card, owned chips, collapse headers, outline, sort/group sheet, type icon facets, detail version switch  
- Host: thin `windows_host` catalog — state, sticky family, openVersion, persist prefs IO  
- No new package; domain/sandbox_data stay pure  

## Widget test inventory (minimum)

- Family card one-per-family; base name/art  
- Owned-only non-interactive chips; signed-out honesty  
- openVersion pure + UI  
- Group collapse view-only; outline hidden when flat/<2 groups; jump no filter rewrite  
- Sort/group reorder changes order/nesting  
- Type iconOnly silhouette + a11y  
- Detail all versions + rebind  
- Sticky family across rebind/refilter  
- BR-CAT-006 facet cycle; empty/workspace density  

## shot_matrix (implement seed)

| id | must | drive | proves |
| --- | --- | --- | --- |
| desktop-family-card | true | live-inventory or fixture | family-card-one, owned-version-chips-readonly |
| desktop-detail-versions | true | live/fixture | detail-all-versions |
| desktop-group-collapse | true | live | group-collapse |
| desktop-group-outline-jump | true | live | group-outline-jump |
| desktop-sort-reorder | true | host-fixture or UI test + shot | sort-priority-reorder |
| desktop-type-icon-filters | true | live | type-filter-icons |

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "browse-chrome",
  "brief_path": "docs/ux-redesign/catalog/001-browse-chrome-brief.md",
  "hosts": ["windows"]
}
```

## Rule IDs

DBR-PUR-002, DBR-ROLL-010, DBR-UI-001, DBR-UI-005, DBR-UI-006, DBR-UI-007, DAC-NME-003, BR-CAT-001, BR-CAT-002, BR-CAT-004, BR-CAT-006, BR-CAT-007, BR-CAT-016b, GAP-CAT-BROWSE-001–004

## Verify notes from redesign

- Product: reconcile openVersion to **owned max-power** (this brief) vs any mock JS that used base-only  
- Do not invent BR-CAT-006a/006b/010c — add real BR rows only when shipping rules  
- Update DUAL-TRUTH-GAPS mockup SSoT paths to `001-browse-chrome-*.html`  
- Residual perk chrome not re-proven in browse mock — held by prior residual-polish dual-truth  
