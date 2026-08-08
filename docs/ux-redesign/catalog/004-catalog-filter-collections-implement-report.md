# Implement report: CatalogFilterCollections (004)

**Status:** structure green · dual-truth Capture **pending** (human / structure-only OK for C6 component)  
**Date:** 2026-08-08  
**Brief:** `004-catalog-filter-collections-brief.md`  
**Build:** `F:\d2w\filters` → worktree `flutter/`

## Summary

Shipped filter-band **Saved** chrome and thin host wire on top of landed system (`74ce3e4`). Soft apply only — host binds criteria; no invent catalog rows.

## Changed paths

| Path | Notes |
| --- | --- |
| `packages/ui_flutter/lib/src/catalog/catalog_filter_collections.dart` | **new** control + dialogs + presentation model |
| `packages/ui_flutter/lib/src/catalog/catalog_filter_bar.dart` | `trailing` on primary cluster **before** More/Reset |
| `packages/ui_flutter/lib/destiny2_ui_flutter.dart` | export |
| `packages/ui_flutter/test/catalog_filter_collections_test.dart` | **new** widget tests (9) |
| `apps/windows_host/lib/catalog/catalog_page.dart` | list/save/apply/rename/delete + dirty + soft bind |
| `apps/widgetbook/lib/use_cases/catalog/filter_collections_use_cases.dart` | **new** use cases |
| `apps/widgetbook/lib/main.directories.g.dart` | regenerated |

## Behavior

- **Cluster:** Saved → More → Reset  
- **Desktop:** overlay menu; **narrow &lt;520:** bottom sheet  
- **Apply:** `applyCatalogFilterCollection` → bind client filters + sort/group  
- **Save:** replace-by-name confirm when name collides; at-cap blocks **new** names  
- **Dirty:** cyan dot when live criteria ≠ applied snapshot  
- **Signed-out:** honest empty; no save CTA  

## Tests

```text
cd F:\d2w\filters\packages\ui_flutter
flutter test test/catalog_filter_collections_test.dart
# +9 all passed
```

Also: placement test proves Saved.dx &lt; More.dx &lt; Reset.dx.

## Verify-structure

| Check | Result |
| --- | --- |
| analyze (touched files) | clean (no errors) |
| widget tests (004) | green |
| Widgetbook gen | `build_runner` wrote FilterCollections entries |

## shot_matrix coverage

| id | must | status |
| --- | --- | --- |
| desktop-empty | true | structure — Widgetbook + host path; PNG Capture pending |
| desktop-list-apply | true | structure |
| desktop-dirty | true | structure |
| desktop-at-cap | false | structure / Widgetbook |
| mobile-sheet | false | structure-only (not Windows exit) |

## Dual-truth

- Mockups remain SSoT: `mockups/004-catalog-filter-collections-*.html`  
- Capture PNGs → `implementation-shots/004-catalog-filter-collections/` when human runs host Capture  
- Slice may soft-close as **structure-only** for this C6 component if dual-truth not blocked

## Widgetbook

Path: `[Catalog]/FilterCollections` — empty, list, dirty, at-cap, signed-out, sheet 390, filter bar + Saved cluster

## Non-goals honored

- BR-CAT-006 untouched  
- No domain/persist algorithm changes  
- No auto-apply on catalog open  
- Soft apply never invents grid rows  
