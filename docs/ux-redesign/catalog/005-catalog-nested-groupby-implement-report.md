# Implement report: CatalogNestedGroupBy (005)

**Date:** 2026-08-08  
**Brief:** `005-catalog-nested-groupby-brief.md`  
**Structure gate:** **pass**  
**Dual-truth Capture:** **pending** (must-rows not yet PNGs)

## What shipped

1. **Pure (manifest)**  
   - Family nested tree: `groupWeaponFamilyBrowseNested` / `CatalogFamilyGroupNode`  
   - Path helpers: `catalogGroupAncestorKeys`, `isCatalogGroupPathFullyOpen`, `flattenAllCatalogGroupNodes`, `catalogGroupDimensionAt`  
   - Flat `groupCatalogItems` / `groupWeaponFamilyBrowse` retained  

2. **UI (ui_flutter)**  
   - `CatalogGroupHeader`: `depth`, `dimension` → official icons when mapped (element/ammo/frame CDN, type silhouette, slot K/E/P)  
   - `CatalogGroupOutlineEntry` + hierarchical `CatalogGroupOutlineRail`  
   - `CatalogGroupOutlineStrip` (mobile structure)  
   - `CatalogWeaponsGrid`: `familyTree` / `itemTree`, scroll-spy `onActiveGroupChanged`  

3. **Host (windows)**  
   - Weapons + non-weapons group-by use nested trees  
   - JUMP: expand ancestors + scroll; re-click fully open path **collapses**  
   - Outline lists full tree (JUMP to nested paths)  
   - Scroll spy updates `_outlineActiveKey`  

4. **Widgetbook**  
   - Nested JUMP demo (Slot→Element)  
   - Nested headers + icons use case  

## Verification

| Command | Result |
| --- | --- |
| `dart test packages/manifest/test/group_catalog_test.dart packages/manifest/test/weapon_family_test.dart` | pass |
| `flutter test packages/ui_flutter/test/catalog_weapons_widgets_test.dart` | pass |
| `flutter test apps/widgetbook/test/phase2_use_cases_smoke_test.dart` | pass |
| `dart analyze` (touched packages) | no errors (pre-existing infos only) |

## Acceptance vs brief

| Item | Structure |
| --- | --- |
| Nested multi-dim tree from DART-072 / family nested | yes |
| Segment labels + rollups + depth | yes |
| Path keys ` · ` | yes |
| Collapse view-only; parent hides subtree | yes |
| JUMP expand+scroll; re-click collapse | yes |
| Scroll spy active outline | yes (host) |
| Icons when dim mapped | yes |
| 1-dim / outline ≥2 top-level | yes |
| Dual-truth Capture | **not yet** |

## Next

1. Run host via `F:\d2w\nested` — multi-dim group-by, collapse, JUMP, scroll  
2. Capture shot_matrix → `implementation-shots/005-catalog-nested-groupby/` + `COMPARE.md`  
3. Optional: regenerate Widgetbook directories if use-case discovery is stale  

## ste_map (as shipped)

See `005-catalog-nested-groupby-implement-plan.md`.
