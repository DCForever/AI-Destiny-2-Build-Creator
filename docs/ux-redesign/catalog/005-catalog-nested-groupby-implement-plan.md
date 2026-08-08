# Implement plan: CatalogNestedGroupBy (005)

**Brief:** `005-catalog-nested-groupby-brief.md`  
**Status:** executed (structure)  
**Date:** 2026-08-08

## files

- `flutter/packages/manifest/lib/src/catalog/group_catalog.dart` — path ancestors, fully-open, flatten-all, dim-at
- `flutter/packages/manifest/lib/src/catalog/weapon_family.dart` — `CatalogFamilyGroupNode` + nested family tree
- `flutter/packages/ui_flutter/lib/src/catalog/catalog_group_chrome.dart` — depth, icons, hierarchical JUMP, strip
- `flutter/packages/ui_flutter/lib/src/catalog/catalog_weapons_grid.dart` — nested tree walk + scroll spy
- `flutter/apps/windows_host/lib/catalog/catalog_page.dart` — nested wire, JUMP toggle, outline entries
- Widgetbook + tests under ui_flutter / manifest / widgetbook

## tests

- Pure: path helpers, nested family labels/keys
- Widget: nested headers, parent collapse, dim icons, outline entries
- Widgetbook phase2 smoke: JUMP demo

## acceptance

Matches brief structure gate (nested headers, collapse view-only, JUMP expand/toggle, icons when mapped, path ` · `). Capture dual-truth deferred.

## risks

- Scroll-spy uses global Y of headers (host window chrome may offset threshold)
- Sibling order still pure alpha (not Destiny slot order) — locked non-goal in brief

## addresses_gap_ids

- GAP-UI-CATALOG-11 Track B (structure)

## deferred_gap_ids

- Dual-truth Capture PNGs (`implementation-shots/005-catalog-nested-groupby/`)
- Mobile strip dual-truth

## shot_matrix

| id | must | drive | proves |
| --- | --- | --- | --- |
| desktop-nested-expanded | true | live | nested-headers, rollups, icons |
| desktop-parent-collapse | true | live | parent-collapse-subtree |
| desktop-child-collapse | true | live | child-collapse-only |
| desktop-jump-expand | true | live | jump-expand-scroll |
| desktop-jump-toggle-collapse | true | live | jump-reclick-collapse |
| desktop-scroll-spy | true | live | outline-active-follows-scroll |
| desktop-flat-1dim | true | live | flat-compat |
| desktop-single-group | true | fixture | outline-hidden |

## ste_map

| architecture | task | file |
| --- | --- | --- |
| Pure nested tree for items | Keep DART-072 API; add path/collapse host helpers | `packages/manifest/.../group_catalog.dart` |
| Pure nested tree for families | Partition families with segment labels + path keys | `packages/manifest/.../weapon_family.dart` |
| Nested header chrome | Depth indent, segment label, dim icon, chevron | `packages/ui_flutter/.../catalog_group_chrome.dart` |
| Hierarchical JUMP | Outline entries with depth + icons + active wash | `catalog_group_chrome.dart` |
| Grid walk | Emit visible tree headers + leaf grids under collapse set | `catalog_weapons_grid.dart` |
| Host wire | Nested browse, JUMP toggle-collapse, scroll spy | `windows_host/.../catalog_page.dart` |
