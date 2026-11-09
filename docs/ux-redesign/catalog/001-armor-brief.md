# UX brief: catalog / armor (C8)

**Status:** locked (mockup-approved 2026-08-08; verify residuals open)  
**Date:** 2026-08-08  
**Hosts:** windows (exit gate); mobile structure-only  
**Slice goal:** Catalog Armor mode redesign (C8): identity icon grid (no list-row stat numbers), class/slot/exotic filters, All/Owned honesty, full-height detail with **labeled** base vs live stats, energy/tier, mods when owned, set-bonus and exotic callouts; owned multi-copy instances. Composition aid only.  
**Out of scope:** Armor optimizer/kits; Universal (C9); Set/Build constrained pick embeds (C10); live Set/Synergy create (stubs OK until C11); Build kit attach; vault transfer/notes/lock; inventing stats/mods/sources/stat ranges; treating host Armor tab as redesigned without brief→mock→implement→Capture; weapons residual; armor roll-target chrome; mobile Catalog push as Windows exit gate.

## Product posture

- **Job:** Find armor identities and owned copies; inspect base/live stats, energy/mods, set bonus, exotic for composition (Sets/fill later).  
- **Not for:** Product home, vault manager, optimizer, kit attach, interactive mod planner.  
- **Rule IDs:** `DBR-PUR-002`, `DBR-ROLL-010`, `DBR-UI-001/005/006/008`, `DBR-STAT-008`, `BR-CAT-003/004/006/010/010d/011/011b/011c/012/017/031`, `DO-ARM-001/008/009/011`, `DO-EXO-010`, `DO-ASB-015`  
- **Product SSoT:** vault [[Destiny Armor]] · [[Destiny Exotic Armor]] · [[Destiny Armor Mod]] · [[Destiny Armor Set Bonus]]

## Locked decisions (from grill + mockup approval)

| Topic | Decision |
| --- | --- |
| Scope shape | Single C8 full mode (grid+facets+All/Owned+detail+instances); no C8a/C8b split |
| Workspace | Reuse weapons `LibraryWorkspace` dual-pane ~400 detail; swap facets/card meta/detail body only |
| Cards | One card per definition/hash; no family merge without DO-ARM family SSoT |
| Card chrome | Icon + rarity + class/slot glyphs + exotic badge + owned ×N; **no row stats / mod icons** |
| Default sort (identities) | slot → exotic → class → tier (tier only when def known) |
| Default sort (instances) | base total desc (then power if needed) |
| Facets | class + slot + exotic tri-state + free-text; no set/energy facets v1 |
| All/Owned honesty | Signed-out Owned → sign-in; owned empty → Sync/Settings; never fake owned |
| Unowned detail | **No invented rolls.** Identity-only: set-bonus/exotic **definition** when data exists; omit live/mods/energy; omit base six unless definition provides honest sample (prefer empty “stats unknown”) |
| Owned detail | Simultaneous **labeled Base \| Live** EoF six + totals when instance live (DBR-UI-008); never unlabeled mix |
| Instance strip | Compact multi-copy; select rebinds detail; **Base board must rebind to selected instance’s base roll** (not fixed identity sample) |
| Mods + energy | Read-only DIM-lite when plugs known; **hide** when none (no empty-note clutter) |
| Set bonus | Definition 2pc/4pc or explicit “no set bonus”; no vault progress meters / Set editor |
| Exotic | Exotic perk callout; class-item selected/possible only when data; no invent pools |
| Outbound | Disabled Set/Synergy stubs only; no Build kit attach |
| Exit gate | implement + Capture must-rows + vault UX note; host not claimed redesigned without Capture |
| Windows | Dual-truth Capture exit gate |
| Mobile | Structure-only; not Windows exit gate |

## Surfaces

`shell.nav.catalog`, `flow.catalog.armor`, `catalog.composition-aid`, `catalog.signed-out.armor`, `catalog.armor.owned`, `catalog.armor.manifest`, `catalog.armor.filters`, `catalog.filters.open`, `catalog.armor.detail`, `catalog.armor.stats-panel`

## Interaction model

- Facet cycle: off → include → exclude → off; OR within / AND across / exclude drops / free-text AND  
- Zero-match: Clear filters  
- Desktop: main grid + full-height ~400 detail  
- Mobile: structure mock; push detail later (C12)  
- Soft error banner; loading skeletons; official Destiny icons (no mock Unicode shipping)

## Mockups (approved)

- Desktop: `docs/ux-redesign/catalog/mockups/001-armor-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/001-armor-mobile.html`
- Approval: `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (Catalog Armor C8 / 001-armor)

### Verify residuals (fix before/with implement; do not ship invent)

1. **Unowned base stats** — mock shows concrete Base six; product forbids inventing unpinned rolls. Implement + Capture: empty / unknown unless def-backed.  
2. **Instance Base rebind** — strip Σbase must match Base board for selected copy; switching copies updates Base and Live.  
3. **Live null instance** — show “unavailable for this copy,” not “unpinned.”  
4. **Empty mods** — hide mods/energy block entirely when no plugs.  
5. **System projections** — dual base+live boards, energy used/capacity, tier on identity for sort, class/slot official icons (or residual glyphs until maps exist).  

## Obsidian

- UX note: `requirements/Projects/Destiny 2 Build Creator/UX/UX Catalog — Armor.md`
- Link from Area Catalog Experience + UX Catalog hub

## Architect notes

### Package placement

- **No new package.**  
- Pure armor filter/sort in `packages/manifest` (identity order; one hash per card).  
- Dual base+live + optional energy from `packages/db` / bungie helpers (`computeArmorBaseStatsFromPlugs` etc.).  
- Neon composition in `packages/ui_flutter` — prefer dedicated armor widgets over unlabeled `ItemRichness` as production dossier.  
- Thin mode branch + bridge honesty in `apps/windows_host/lib/catalog`.  
- `domain` / `sandbox_data` stay pure.

### Widget inventory

- `CatalogArmorCard`, `CatalogArmorGrid`, `CatalogArmorDetail`
- `ArmorBaseLiveStatBoard`, `ArmorInstanceStrip`
- `ArmorModsEnergyBlock`, `ArmorSetBonusCallout`, `ArmorExoticPerkCallout`
- `CatalogSoftErrorBanner`
- Reuse: `CatalogWeaponsWorkspace` (~400), `CatalogFilterBar` / `NeonFacetChip`, `CatalogEmptyState` / scope / loading, outbound stubs

### Widget test inventory

- [ ] Armor card: no row stats; owned ×N vs signed-out never fakes  
- [ ] Grid: selection; one card per hash; sort fixture  
- [ ] Facets class/slot/exotic tri-state; zero-match Clear  
- [ ] Empty: signed-out Owned sign-in; owned empty Sync+Settings  
- [ ] Base\|Live board simultaneous labels; base-only / unknown unowned  
- [ ] Instance strip base-total sort; select rebinds Base+Live  
- [ ] Mods/energy visible with data; hidden when none  
- [ ] Set-bonus 2pc/4pc or explicit none; no meters  
- [ ] Exotic callout; class-item omitted without data  
- [ ] Detail unowned omits live/mods/energy  
- [ ] Outbound stubs disabled  
- [ ] Soft error + loading skeletons  
- [ ] Workspace armor detail ~400 beside main  

### Risks / anti-bloat

- God `CatalogPage` growth — extract armor detail early  
- Single-board `preferArmorBaseRollBoard` vs dual labeled boards  
- Inventing energy capacity or set-bonus text  
- Weapon family / roll-target / can-roll chrome leaking into armor mode  
- Unicode class/slot glyphs shipping instead of official maps  
- Claiming host redesigned without Capture  

## Acceptance checklist

- [ ] Signed-out All grid no fake owned; Owned prompts sign-in  
- [ ] Signed-in All: identity icon grid; default sort; no list-row stats  
- [ ] Facets class/slot/exotic + free-text; zero-match Clear  
- [ ] Owned empty: Sync primary + Settings secondary  
- [ ] Unowned detail: no invented rolls; set/exotic def only when data  
- [ ] Owned multi-copy strip; Base rebinds per instance  
- [ ] Labeled Base \| Live when live present  
- [ ] Mods + energy read-only when plugs; hide when none  
- [ ] Set-bonus 2pc/4pc or explicit none  
- [ ] Exotic perk callout; no invent pools  
- [ ] Set/Synergy disabled stubs; no kit attach  
- [ ] Workspace ~400; soft error; skeletons  
- [ ] Widget tests + windows host smoke green  
- [ ] Capture must-rows + COMPARE; vault note; not redesigned without Capture  

## Next

```text
/workflow area-implement
# args:
# {
#   "area": "catalog",
#   "subarea": "armor",
#   "brief_path": "docs/ux-redesign/catalog/001-armor-brief.md"
# }
```

Optional rename to `006-catalog-armor-*` at implement plan time if numbering hygiene desired; keep mockup paths unless renames are bulk-updated.
