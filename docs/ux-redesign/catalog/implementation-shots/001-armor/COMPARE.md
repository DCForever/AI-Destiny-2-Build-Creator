# Implementation shots — catalog / 001-armor (C8)

**Date:** 2026-08-08  
**Status:** **Capture complete** — must-rows on disk; dual-truth **closed** for armor matrix (mobile structure-only)  
**Hosts:** windows (exit gate); mobile structure-only via Widgetbook  
**Brief / approval:** `docs/ux-redesign/catalog/001-armor-brief.md`, `MOCKUP-APPROVED.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/catalog/mockups/001-armor-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-armor-mobile.html`

**Capture entry:** `flutter/apps/windows_host/lib/main_armor_capture.dart`  
**Fixtures:** `flutter/apps/windows_host/lib/catalog/armor_capture_fixtures.dart`  
**Driver sequence:** `capture-sequence.json` via `tool/capture_driver_shots.dart`  
**Launch:** background_shell (`flutter run -d windows -t lib/main_armor_capture.dart` + ENABLE_FLUTTER_DRIVER)

## Purpose

Ground truth for Catalog Armor redesign: mockup interaction model vs **shipped** Flutter Catalog armor widgets (`CatalogArmorGrid` / `CatalogArmorDetail` / empty / soft error). Dual-truth is **not** closed on PNG presence alone — residuals reviewed below.

## Scenario matrix

| Scenario | Drive | Shot | Proves | Residual |
| --- | --- | --- | --- | --- |
| Desktop — All grid | host-fixture | `desktop-grid.png` | identity icon grid; no row stats; class/slot/exotic facets; owned ×N honest | **closed** — letter glyphs residual until official Destiny icon maps |
| Desktop — detail owned | host-fixture | `desktop-detail-owned.png` | labeled Base\|Live; ~400 width; owned dossier; mods+set+exotic | **closed** — simultaneous Base/Live values differ (Σ138 base / Σ190 live) |
| Desktop — multi-copy strip | host-fixture | `desktop-instance-strip.png` | base-total sort (Σ138 first); Base+Live rebind keys | **closed** — strip shows Σ138/Σ80/Σ66 |
| Desktop — detail unowned | host-fixture | `desktop-detail-unowned.png` | no invent rolls; omit live/mods/energy; Stats unknown | **closed** |
| Desktop — set bonus | host-fixture | `desktop-set-bonus.png` | 2pc/4pc Techsec; no vault meters | **closed** widget chrome; **reopen wiring** — `CatalogPage` still calls `armorSetBonusFromDefinition()` with no args (definition map unbound) |
| Desktop — mods/energy | host-fixture | `desktop-mods-energy.png` | mods when plugs; energy 5/10; hide empty path tested separately | **closed** |
| Desktop — exotic callout | host-fixture | `desktop-exotic-callout.png` | exotic perk definition; no invent pools | **closed** |
| Desktop — owned empty | host-fixture | `desktop-owned-empty.png` | Sync primary + Settings secondary | **closed** |
| Desktop — signed-out Owned | host-fixture | `desktop-signed-out-owned.png` | sign-in empty; no fake owned | **closed** |
| Desktop — live-null copy | host-fixture | `desktop-live-null-copy.png` | “Live unavailable for this copy” not unpinned | **closed** (optional must:false) |
| Desktop — soft error | host-fixture | `desktop-soft-error.png` | soft error banner | **closed** (optional must:false) |
| Mobile structure grid | widget-test-only | — | 390 structure; no forced 400 overflow | Widgetbook only |

## Verify residuals (shot + structure)

1. **Unowned base stats** — `desktop-detail-unowned.png` shows **Stats unknown**; no invented six. **closed**
2. **Instance Base rebind** — strip Σbase matches Base board for selected copy (Σ138 ↔ Base Σ 138). **closed** on fixture projection
3. **Live null instance** — “Live unavailable for this copy.” **closed** (`desktop-live-null-copy.png`)
4. **Empty mods** — hide mods/energy when none (live-null / unowned omit block). **closed**
5. **System projections** — dual boards, energy used/capacity when known, tier on strip (T5/T2/T3). Class/slot **letter glyphs** residual until official maps. **closed** with glyph residual
6. **Set-bonus host path** — Capture proves `CatalogArmorDetail` + DTO chrome. Host `catalog_page.dart` `_buildArmorDetailPanel` still `armorSetBonusFromDefinition()` empty → set-bonus absent until definition map wired. Track for next implement pass (not invent text to match mock).
7. **Capture harness chrome** — scenario chip rail + DEBUG banner are **not** product CatalogPage chrome (same class of residual as other host-fixture Captures).

## Checklist

- [x] `desktop-grid.png`
- [x] `desktop-detail-owned.png`
- [x] `desktop-instance-strip.png`
- [x] `desktop-detail-unowned.png`
- [x] `desktop-set-bonus.png`
- [x] `desktop-mods-energy.png`
- [x] `desktop-exotic-callout.png`
- [x] `desktop-owned-empty.png`
- [x] `desktop-signed-out-owned.png`
- [x] `desktop-live-null-copy.png` (optional)
- [x] `desktop-soft-error.png` (optional)
- [x] dual_truth_ok after must-rows + residual review (no `blocks_dual_truth` open gaps for armor)

## Deferred

- **GAP-CAT-PERK-003** — crafted toggle dual-truth (weapons residual; `blocks_dual_truth: false`).
- Mobile Catalog push detail (C12) — structure-only here.
- Live Set/Synergy create — disabled stubs only (visible on unowned/live-null shots).
- Official class/slot Destiny icon maps (letter glyphs interim).
- Host set-bonus definition map bind on `CatalogPage`.

## Next

```text
# product-map: catalog.armor.* flutter-windows stub→done after this Capture proof
# npm run product-map:sync / product-map:parity from monorepo root when hub edited
# Next redesign: class/slot official icons; set-bonus definition wiring residual
```
