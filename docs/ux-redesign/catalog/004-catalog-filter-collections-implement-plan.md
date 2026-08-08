# Implement plan: CatalogFilterCollections (004)

**Brief:** `004-catalog-filter-collections-brief.md`  
**Hosts:** windows, widgetbook  
**System:** landed (`74ce3e4`) — soft apply, per mode, replace-by-name, cap 20

## Files

| Path | Change |
| --- | --- |
| `packages/ui_flutter/lib/src/catalog/catalog_filter_collections.dart` | **new** presentation chrome (trigger, menu/sheet, dialogs) |
| `packages/ui_flutter/lib/src/catalog/catalog_filter_bar.dart` | Place `trailing` **before** More/Reset on primary action row |
| `packages/ui_flutter/lib/destiny2_ui_flutter.dart` | export |
| `packages/ui_flutter/test/catalog_filter_collections_test.dart` | **new** widget tests |
| `apps/windows_host/lib/catalog/catalog_page.dart` | list/save/apply/rename/delete + soft bind + dirty |
| `apps/widgetbook/lib/use_cases/catalog/filter_collections_use_cases.dart` | **new** knobs matrix |

## ste_map

| architecture | task | file |
| --- | --- | --- |
| Filter-band trailing cluster | Put Saved left of More/Reset | `catalog_filter_bar.dart` |
| Neon Saved menu chrome | Build trigger + desktop menu + mobile sheet + name dialogs | `catalog_filter_collections.dart` |
| Presentation list model | Host maps domain → id/name/summary rows | `catalog_filter_collections.dart` |
| Soft apply host bind | Apply criteria only via use cases + sort/group | `catalog_page.dart` |
| Persist CRUD | list/save/rename/delete through app use cases | `catalog_page.dart` |
| Structure proof | Widget tests for placement, apply, cap, signed-out | `catalog_filter_collections_test.dart` |
| Widgetbook | Demo matrix knobs | `filter_collections_use_cases.dart` |

## shot_matrix

| id | must | proves | drive |
| --- | --- | --- | --- |
| desktop-empty | true | Saved + empty menu Save CTA | Open Saved, 0 collections, savable live filters |
| desktop-list-apply | true | Soft apply paints band; grid not invented by chrome | Apply "Void HC PvP" row |
| desktop-dirty | true | Cyan dirty dot when criteria diverge | Apply then toggle facet |
| desktop-at-cap | false | Cap hint when 20 | Fixture 20 collections |
| mobile-sheet | false | Bottom sheet structure | Width 390 (structure-only OK) |

## Tests

- Saved before More/Reset in action cluster
- Apply callback with id; no result invention in widget
- Empty + Save CTA; list rows name/summary
- Dirty dot + active label
- At-cap blocks new name path
- Signed-out honesty
- Rename/delete callbacks

## Risks

- Host always has default sort keys — savable must not treat defaults alone as criteria
- `trailing` was unused on primary row — must fix placement without breaking More secondary trailing duplicate
- Cap/replace errors must surface soft status, not invent success

## Acceptance

- Brief locks honored; BR-CAT-006 untouched; soft apply only
- analyze + widget tests green on `F:\d2w\filters`
