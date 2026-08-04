# area-implement report — catalog / weapons

**Date:** 2026-08-03  
**Status:** implemented (Windows-first exit)

## Load

Brief: `docs/ux-redesign/catalog/001-weapons-brief.md`  
Mockups: structure SSoT only; production uses official Bungie icons/colors.  
Rules: DBR-PUR-002, DBR-ROLL-001/007/008/010, DBR-UI-001/005/006/007, BR-CAT-*, BR-UI-002/003, DAC-NME-003/004, DAC-CAT-003, DO-WPN-001/010.

## Ship summary

- **Pure:** `sortCatalogWeapons` (slot → exotic → ammo → archetype → name); facet OR-within / AND-across / exclude; armor/universal keep alpha.
- **ui_flutter:** CatalogWeaponsWorkspace (~400px detail), CatalogFilterBar, NeonFacetChip (official icon-only element/ammo), CatalogWeaponsGrid, empty states, loading skeleton, CatalogWeaponDetail + perk/craft toggles OFF default, exotic identity soft catalyst, hash footer, outbound Set/Synergy stubs disabled, instance strip power-desc.
- **windows_host:** CatalogPage re-skinned — primary filter line **always on** (scope + free-text + element/slot chips); More secondary only (no double-collapse ListTile); weapons detail stubs; `craftAvailable: false` when craftColumns empty; `onOpenSettings` from shell; signed-out never fakes owned badges.
- **product-map:** `shell.nav.catalog`, `catalog.signed-out.weapons`, `catalog.composition-aid` → flutter-windows `done` @ `/catalog`; owned/manifest/filters/list/detail already done.

## Acceptance

| Gate | Result |
| --- | --- |
| Signed-out All browse; no fake owned | pass |
| Sort slot→exotic→ammo→archetype | pass |
| Owned empty Sync+Settings; multi-instance power-desc | pass |
| Primary filters always on; More secondary; RESET | pass |
| Zero-match Clear; missing Reload+Settings | pass |
| Detail toggles OFF; no invent craft; stubs disabled | pass |
| ~400px full-height detail; not LibraryWorkspace 320 | pass |
| Widget inventory + host smoke green | pass |

## Residuals (deferred)

- Live craft pool / pattern data when entity stores expose it (`craftAvailable` stays false until columns exist).
- Armor/Universal polish; mobile dual-pane push.
- Live Set/Synergy create remains universal-only (not weapons detail).
- `product-map:sync` may need `web/NextJS` yaml install for generated inventory/drawio.

## Tests

```text
dart test packages/manifest/test/sort_weapons_test.dart packages/manifest/test/filter_catalog_test.dart packages/manifest/test/group_catalog_test.dart
flutter test test/catalog_weapons_widgets_test.dart test/catalog_weapon_detail_test.dart   # ui_flutter
flutter test test/catalog_page_test.dart test/catalog_owned_page_test.dart test/catalog_weapons_host_smoke_test.dart  # windows_host
```
