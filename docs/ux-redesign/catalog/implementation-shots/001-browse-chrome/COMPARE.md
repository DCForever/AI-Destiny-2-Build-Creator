# Browse-chrome implementation shots — COMPARE

**Slice:** catalog / browse-chrome  
**Brief:** `docs/ux-redesign/catalog/001-browse-chrome-brief.md`  
**Mockups:** `docs/ux-redesign/catalog/mockups/001-browse-chrome-desktop.html` (+ mobile sibling)  
**Date:** 2026-08-05  
**Capture run:** background_shell `flutter run -d windows -t lib/main_browse_chrome_capture.dart` · DTD + Flutter Driver · `set_frame_sync enabled=false`  
**Dual-truth:** **closed** for GAP-CAT-BROWSE-001–004 + GAP-CAT-PERK-004 (structure + host-fixture PNGs). Mobile structure-only. GAP-CAT-PERK-003 deferred non-blocking.

## Gaps addressed

| Gap | Tokens | Residual |
| --- | --- | --- |
| GAP-CAT-BROWSE-001 | `family-card-one`, `owned-version-chips-readonly`, `detail-all-versions` | **closed** — one Midnight Coup card Base+Adept ×3 no Holofoil; detail VERSIONS all three + openVersion adept max-power |
| GAP-CAT-BROWSE-002 | `group-collapse`, `group-outline-jump` | **closed** — Kinetic collapse view-only; JUMP rail Energy/Kinetic; expand-on-jump |
| GAP-CAT-BROWSE-003 | `sort-priority-reorder`, `group-priority-reorder` | **closed** — SORT & GROUP sheet default priority; multi-dim ENERGY · SOLAR / KINETIC · KINETIC |
| GAP-CAT-BROWSE-004 | `type-filter-icons` | **closed** — primary-line weapon-type silhouette chips (iconOnly); structure Semantics |
| GAP-CAT-PERK-004 | `no-perk-band-labels`, `tier-cell-chrome-only` | **closed** — Possible ON: legend + ①/②/③ cell chrome; no “On this copy” / “Unselected (instance)” / “Possible rolls” band strings |

## Scenario matrix

| Scenario | Mockup | Shot | Residual |
| --- | --- | --- | --- |
| Desktop — family card | `001-browse-chrome-desktop.html` | `desktop-family-card.png` | **closed** — one card/family; Base+Adept owned-only chips; Holofoil omitted; ×3 family sum |
| Desktop — detail versions | same | `desktop-detail-versions.png` | **closed** — Base ×2 / Adept ×1 / Holofoil; openVersion → Adept PL 1810 |
| Desktop — group collapse | same | `desktop-group-collapse.png` | **closed** — Kinetic collapsed; Energy expanded; facets intact; JUMP present |
| Desktop — group outline jump | same | `desktop-group-outline-jump.png` | **closed** — outline JUMP Energy/Kinetic; post jump Energy cards restored |
| Desktop — sort priority sheet | same | `desktop-sort-reorder.png` | **closed** — SORT PRIORITY slot→exotic→ammo→archetype→name; GROUP BY active Slot; “Does not change filters” |
| Desktop — group multi-dim | same | `desktop-group-priority.png` | **closed** — Element+Slot → ENERGY · SOLAR / KINETIC · KINETIC + outline |
| Desktop — type icon filters | same | `desktop-type-icon-filters.png` | **closed** — primary-line type silhouettes (same grid frame as family-card; structure `archetype_chip_*` iconOnly) |
| Desktop — no perk band labels | same | `desktop-detail-no-band-labels.png` | **closed** — Possible ON; legend retained; no per-column band labels; tier badges on cells |
| Widget — signed-out honesty | — | *(widget-test-only)* | structure-only — `catalog_weapons_widgets_test` |
| Widget — openVersion max-power | — | *(widget-test-only)* | structure-only — pure + host smoke |

## Capture notes

| | |
| --- | --- |
| Launch | Shell **background:** `C:\d2f\apps\windows_host` (junction → worktree `flutter/`) · `flutter run -d windows -t lib/main_browse_chrome_capture.dart` · MCP `launch_app` unavailable this session |
| Driver | DTD `ws://127.0.0.1:65440/…` · app `ws://127.0.0.1:65441/…` · `get_health` ok · `set_frame_sync enabled=false` · Driver `screenshot` → PNG decode |
| Session | Browse chrome capture signed-in fixture · OWNED · 3 · 6 catalog seeds / 4 copies |
| Subjects | Midnight Coup family · Ringing Nail · Ace of Spades |
| Integrity | All must-row PNGs valid `89 50 4E 47…` |
| Stop | `destiny2_windows_host` killed after capture |
| Driver entry | `flutter/apps/windows_host/lib/main_browse_chrome_capture.dart` |
| Fixtures | `flutter/apps/windows_host/test/catalog_browse_chrome_fixtures.dart` (keep in sync with capture entry) |

## Structure proof (not PNG-only)

- Host smoke `browse-chrome host fixtures` group in `catalog_weapons_host_smoke_test.dart`
- Pure: `weapon_family_test.dart`, `sort_weapons_test.dart`
- Widgets: `catalog_weapons_widgets_test.dart`, `catalog_weapon_detail_test.dart`, `destiny_official_icons_test.dart`
- PERK-004: asserts `perk_band_*` keys absent + no band text; legend + tier badges remain
- Type icons: `archetype_chip_*` iconOnly + Semantics

## Density

- Grid: `maxCrossAxisExtent` 200 / `mainAxisExtent` 112  
- Detail: `kCatalogWeaponsDetailWidth` 400  

## Open residuals (next redesign)

1. **GAP-CAT-PERK-003** — craftAvailable ON dual-truth (non-blocking).
2. **Mobile Catalog** — structure-only; no dual-truth exit this slice.
3. **Vault UX note** — Obsidian Weapons.md may still describe flat-grid era when mount available.
4. **Live inventory re-shot** — optional when OAuth+sync available (host-fixture is dual-truth proof).

## Checklist

- [x] `desktop-family-card.png`
- [x] `desktop-detail-versions.png`
- [x] `desktop-group-collapse.png`
- [x] `desktop-group-outline-jump.png`
- [x] `desktop-sort-reorder.png`
- [x] `desktop-group-priority.png`
- [x] `desktop-type-icon-filters.png`
- [x] `desktop-detail-no-band-labels.png`
- [ ] mobile shots (structure-only; not dual-truth gate)
