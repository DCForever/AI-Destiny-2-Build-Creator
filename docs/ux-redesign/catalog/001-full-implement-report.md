# Catalog / Full — implement report (residual pass)

**Date:** 2026-08-04  
**Brief:** `docs/ux-redesign/catalog/001-full-brief.md`  
**Status:** code + widget/host tests green; MCP Driver screenshot matrix **complete** under `implementation-shots/001-full/`

## What shipped

### P0 — Equal-width perk grid, no H-scroll at 400

- `CatalogPerkGrid` no longer uses horizontal `SingleChildScrollView` + fixed 72px columns.
- Columns are equal-width `Expanded` children of a `Row` (icon-first cells, ellipsis captions).
- Detail pane remains `kCatalogWeaponsDetailWidth = 400` on `CatalogWeaponsWorkspace`.

### P1 — Pure icon-only meta strip

- New `CatalogWeaponMetaStrip` (type · frame · element · slot · ammo + ×N).
- `CatalogWeaponDetail` drops text subtitle and KINETIC/OWNED text pills.
- Official Destiny icons for frame/element/ammo; slot/type structure glyphs with tooltips.

### P2 — Origin only when data

- Columns built only from real socket/definition plugs; empty origin omitted.
- Widget tests cover present (Elliptical Orbit fixture) and absent (definition-only no origin).

### Perk tiers + Enhanced

- Owned default: ① selected + ② instance reusables; ③ definition pool only when **Possible rolls** ON.
- Unowned: ③-only section label `POSSIBLE ROLLS`; no possible-rolls/craft toggles.
- Toggle label renamed to **Possible rolls**; finder key `catalog_toggle_can_roll` preserved.
- Craft chip hidden when `craftAvailable: false` (host stays false without craft columns).
- Enhanced: gold chrome + `E` mark via name heuristic and optional `plugEnhancedByHash`.

### Host / stubs

- Weapons path still thin wiring; Set/Synergy `onPressed: null`.
- Armor/universal unchanged this slice (audit-only; host Universal live CTAs not regressed).
- Mobile Catalog push deferred.

## Files

| Path | Change |
| --- | --- |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_weapon_meta_strip.dart` | **New** icon-only meta |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_weapon_detail.dart` | Tiers, grid, enhanced, meta wire |
| `flutter/packages/ui_flutter/lib/destiny2_ui_flutter.dart` | Export meta strip |
| `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart` | Residual inventory |
| `flutter/packages/ui_flutter/test/catalog_weapons_widgets_test.dart` | Scope OWNED · N |
| `docs/ux-redesign/catalog/implementation-shots/001-full/COMPARE.md` | Shot matrix + residual close notes |
| `docs/ux-redesign/catalog/implementation-shots/README.md` | Index 001-full |
| `docs/ux-redesign/catalog/001-full-implement-report.md` | This report |

## Tests

```text
cd flutter/packages/ui_flutter
flutter test test/catalog_weapon_detail_test.dart test/catalog_weapons_widgets_test.dart

cd flutter/apps/windows_host
flutter test test/catalog_weapons_host_smoke_test.dart
```

All green at implement time.

## Acceptance checklist

- [x] Icon-only meta strip; no text subtitle or KINETIC/OWNED text pills  
- [x] Origin column only when data; hidden when none  
- [x] Expanded ③ multi-column: equal Expanded; no perk-grid H-scroll at 400  
- [x] Owned ①+② default; Possible rolls OFF; unowned ③-only without toggle  
- [x] Enhanced gold/E when data says enhanced  
- [x] Craft toggle hidden without craft data  
- [x] Scope All default; OWNED · N label path; signed-out never fakes owned  
- [x] Weapons Set/Synergy disabled stubs  
- [x] Armor/universal audit-only (no structural change)  
- [x] Widget tests + windows host smoke green  
- [x] MCP Driver PNGs under `implementation-shots/001-full/` (grid, owned, can-roll, unowned, exotic, instance strip; local inventory OWNED · 790; OAuth refresh unavailable — owned chrome from local DB)

## Product map

No hub edit this slice (no new surfaces; residual rule IDs already on catalog weapons surfaces). Skip `product-map:sync`.

## Risks / follow-ups

- **P1 meta strip layout reopen** (dual-truth shots): `_MetaGlyphChip` / `_OwnedCountChip` expand to full-width bars under Wrap; type uses letter abbrev not silhouettes. Feed next redesign from `implementation-shots/001-full/COMPARE.md`.
- Enhanced without plug category remains name-heuristic unless host supplies `plugEnhancedByHash`.
- Density under ③ ON at 400px is tight by design (icon-first + ellipsis; never widen pane).
- Soft catalyst under-verified when catalyst fields empty (Ace unowned shot shows intrinsic only).
- Mobile Catalog push deferred; armor/universal residual audit still notes-only.
