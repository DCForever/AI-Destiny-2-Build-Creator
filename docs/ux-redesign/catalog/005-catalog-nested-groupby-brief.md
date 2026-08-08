# UX brief: catalog / CatalogNestedGroupBy

**Status:** locked  
**Date:** 2026-08-08  
**Hosts:** windows, widgetbook (mobile structure-only)  
**Slice goal:** Replace flat multi-dim composite group headers with nested path headers + hierarchical JUMP, consuming DART-072 `groupCatalogItemsNested` / `CatalogGroupNode` / view-only collapse helpers. Icons on headers and JUMP when the dimension has official art. Neon/Flap residual; BR-CAT-006 filters unchanged; BR-CAT-007 collapse view-only.  
**Out of scope:** Full Catalog redesign; filter/facet semantics; invent group dimensions; Armor full redesign (C8); entity-desc 1+3; roll-target chrome; mobile Catalog push as dual-truth exit gate; new design system.

## Product posture

- Job: browse multi-dim group-by as a **tree** (e.g. Slot → Element) with per-level rollups, independent path collapse, and outline JUMP that expands/scrolls or toggles collapse — never filters  
- Gap: GAP-UI-CATALOG-11 Track B / UX-CATALOG-NESTED-GROUP (system DART-072 landed; chrome absent)  
- Rule IDs: BR-CAT-006, BR-CAT-007, DBR-PUR-002, DBR-UI-001/005/006, FEAT-UI-CATALOG-NESTED-GROUP, DART-072, UX-CATALOG-NESTED-GROUP  

## Locked decisions

| Topic | Decision |
| --- | --- |
| Pure API | Consume `groupCatalogItemsNested` + `CatalogGroupNode`; keep flat `groupCatalogItems` available until host fully migrates |
| Path keys | Full path via `catalogGroupPathSeparator` (` · `) e.g. `Energy · Arc` — stable expand/JUMP/scroll-spy keys |
| Header label | **Segment only** at this depth (e.g. `Arc`), not composite `Energy · Arc` |
| Count | Rollup of all leaf items under the node |
| Depth | Indent headers + outline by depth (~14px desktop / ~12px mobile residual) |
| Collapse model | Host may keep existing **collapsed** `Set` (grid API today) **or** map to pure **expanded** helpers; semantics: parent collapse hides subtree; default all expanded |
| BR-CAT-007 | Collapse / JUMP never rewrite filter match set or tree membership |
| BR-CAT-006 | Facets apply **before** group only |
| JUMP gate | Outline rail/strip only when group-by active **and** ≥2 top-level groups |
| JUMP closed | Expand ancestors + target, scroll into view (does not filter) |
| JUMP open | Re-click fully open path → **collapse that path** (view-only) |
| Scroll spy | Board scroll updates active outline highlight to group nearest top of viewport |
| Icons | When dim maps to official art: **element/ammo** Bungie CDN (`destiny_official_icons`); **type** package silhouettes; **slot** residual K/E/P glyphs. Frame/class: text until maps exist. No invented art |
| 1-dim | Flat headers + flat JUMP (no nested indent required) |
| Empty / loading | No group chrome |
| Chrome residual | Uppercase Orbitron-ish label · mono count · accent chevron; no Material ExpansionTile as product look |
| Density | Keep family cards ~200×112; outline rail ~132–148px; do not redesign card chrome in this slice |
| Hosts | Windows dual-truth gate; mobile structure parity (strip JUMP) not Capture exit |

## State matrix (must demo)

flat-1dim · nested-2dim-expanded · type-icons · parent-collapsed · child-collapsed · jump-expand-scroll · jump-toggle-collapse · scroll-spy-active · single-group-no-outline · empty · loading

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/005-catalog-nested-groupby-desktop.html`
- `docs/ux-redesign/catalog/mockups/005-catalog-nested-groupby-mobile.html`
- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (CatalogNestedGroupBy 005 — continue with workflow)
- Baseline browse groups: `001-browse-chrome-*.html` (flat collapse + JUMP residual)

## Implement notes

### Pure / already landed (`packages/manifest`)

- `groupCatalogItemsNested`, `CatalogGroupNode`, `catalogGroupPathKey`, `isCatalogGroupExpanded`, `expandableCatalogGroupKeys`, `visitVisibleCatalogGroupNodes`
- Do **not** reimplement tree logic in UI packages

### UI (`packages/ui_flutter`)

- Extend `CatalogGroupHeader`: optional `depth`, optional leading icon/widget, segment `label`, rollup `count`, expand chevron; sticky residual chrome
- Extend `CatalogGroupOutlineRail` (desktop) + mobile strip variant if present: hierarchical rows with depth, icons, active key, full-tree keys for JUMP targets
- Resolve icons via `destiny_official_icons` / type silhouettes from dimension + segment label; omit icon when no map hit
- `CatalogWeaponsGrid` (or host list builder): walk nested tree; emit header + child headers or leaf grids; honor collapse set; depth indent padding
- Scroll spy: listen board scroll → set active outline key from visible group sections
- JUMP handler: if path fully open → collapse; else expand ancestors + target + ensureVisible

### Host (`windows_host` catalog)

- After filter: `groupCatalogItemsNested(items, orderedDims)` (or family equivalent)
- Wire collapse toggle + JUMP + scroll-spy active key
- Persist collapse prefs optional (session ok); must not write filters
- Build via `F:\d2w\nested` (worktree link)

### Widgetbook

- Nested tree demo: Slot→Element expanded / parent collapse / child collapse
- JUMP expand+scroll and JUMP toggle-collapse
- Scroll-spy highlight
- Icon matrix: element, slot glyph, type silhouette
- Flat 1-dim + single-group (no rail)

## Widget test inventory (minimum)

- Nested 2-dim renders parent + child segment labels (not flat composite as sole chrome)
- Parent collapse hides children + leaf grids; match set / item membership unchanged
- Child collapse independent when parent expanded
- JUMP on collapsed path expands ancestors + scrolls (no filter rewrite)
- JUMP on fully open path collapses that path
- Outline hidden when &lt;2 top-level or group-by off
- Scroll updates active outline key (structure test or controller-driven)
- Element/type/slot headers show leading icon when official map hits; unknown label text-only
- Path keys use ` · ` separator matching pure API
- 1-dim: flat labels + outline still works
- Empty/loading: no group headers/outline
- A11y: header button + expanded semantics; JUMP labels include count
- No ChoiceChip / Material ExpansionTile as primary chrome

## shot_matrix (implement seed)

| id | must | drive | proves |
| --- | --- | --- | --- |
| desktop-nested-expanded | true | live/fixture | nested-headers, rollups, icons |
| desktop-parent-collapse | true | live | parent-collapse-subtree |
| desktop-child-collapse | true | live | child-collapse-only |
| desktop-jump-expand | true | live | jump-expand-scroll |
| desktop-jump-toggle-collapse | true | live | jump-reclick-collapse |
| desktop-scroll-spy | true | live | outline-active-follows-scroll |
| desktop-flat-1dim | true | live | flat-compat |
| desktop-single-group | true | fixture | outline-hidden |
| mobile-strip-structure | false | structure | strip JUMP + icons structure-only |

## Widgetbook backlog

- CatalogNestedGroupBy · nested Slot→Element desktop
- JUMP toggle collapse + expand scroll
- Scroll-spy active wash
- Type-dim silhouettes / element CDN / slot glyphs
- Mobile 390 strip structure
- Dual-truth re-shots → `implementation-shots/005-catalog-nested-groupby/`

## Nice-to-have (not gate)

- Partial-collapse chevron glyph (parent expanded, some children collapsed)
- 3+ dim stress scenario in Widgetbook

## Canonical segment order (pure SSoT)

Sibling group order and filter chips share `packages/manifest/.../canonical_order.dart`:

| Dim | Order |
| --- | --- |
| Slot | Kinetic → Energy → Power |
| Ammo | Primary → Special → Heavy |
| Element | Kinetic → Stasis → Strand → Arc → Solar → Void (**no Prismatic filter**) |
| Weapon archetype | list order; **Rocket Launcher always last** |

## Acceptance

- [ ] Multi-dim group-by uses nested tree from DART-072; flat composite-only headers gone for multi-dim
- [ ] Segment labels + rollups + depth indent; path keys ` · `
- [ ] Collapse view-only; parent hides subtree; BR-CAT-006 match set stable
- [ ] JUMP ≥2 top-level: expand+scroll; re-click open collapses; never filters
- [ ] Scroll spy updates active outline highlight
- [ ] Icons when dim has official map; no invented art
- [ ] 1-dim / single-group / empty / loading behaviors preserved
- [ ] Widget tests + windows structure green; shot matrix must-rows after Capture
- [ ] Mobile structure-only OK; windows dual-truth gate

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "catalog-nested-groupby",
  "brief_path": "docs/ux-redesign/catalog/005-catalog-nested-groupby-brief.md",
  "hosts": ["windows", "widgetbook"]
}
```

Build: `F:\d2w\nested`
