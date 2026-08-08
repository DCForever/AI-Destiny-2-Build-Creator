# Implement plan: CatalogRollTargets (003)

**Status:** awaiting human approval (plan gate)  
**Brief:** `docs/ux-redesign/catalog/003-catalog-roll-targets-brief.md`  
**Mockups:** `mockups/003-catalog-roll-targets-desktop.html`, `…-mobile.html`  
**Hosts:** windows, widgetbook  
**Workflow:** `area-implement` (plan phase)

---

## Acceptance (summary)

- Dual segs `N/M` + `Av k` only when active target has score dimensions; base chip power · T{tier} · special unchanged (002).
- Active rank = `rankOwnedForRollTarget`; else power-desc.
- Switcher: named profiles + Off; editor Want|Avoid|Off on ③ pool; soft overlap blocks Save only.
- View: soft diagonal wash (green preferred / red avoid) behind icon; edit: W/A only.
- Host wires `packages/app` roll_target use cases; pure score stays domain; ui_flutter presentation-only.
- Widget + host smoke + Widgetbook 400/390; shot_matrix must rows via host-fixture.

## Files

| Path | Role |
| --- | --- |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_roll_targets.dart` | **New** switcher + editor shell |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_weapon_detail.dart` | Compose detail + strip props |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_perk_grid.dart` | View wash + edit tri-state |
| `flutter/packages/ui_flutter/lib/destiny2_ui_flutter.dart` | Export |
| `flutter/packages/ui_flutter/test/catalog_roll_targets_test.dart` | **New** widget tests |
| `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart` | Extend segs/rank |
| `flutter/apps/windows_host/lib/catalog/catalog_page.dart` | Wire app use cases |
| `flutter/apps/windows_host/test/catalog_roll_targets_host_smoke_test.dart` | Host smoke |
| `flutter/apps/windows_host/test/catalog_roll_targets_fixtures.dart` | Capture fixtures |
| `flutter/apps/widgetbook/lib/use_cases/catalog/detail_use_cases.dart` | Knobs matrix |
| `flutter/apps/widgetbook/lib/fixtures/catalog_fixtures.dart` | Fixtures |
| `docs/product-map/surfaces.yaml` | Rule ID attach (optional same change) |

## Risks

- columnKey map host ↔ editor must match score keys.
- ui_flutter must not import domain/app — host maps scores to presentation DTOs.
- Strip must accept pre-ordered list when ranking (do not re-sort power-desc).
- Selection sticky after rank reorder.

## Deferred

- `GAP-CAT-PERK-003` craft toggle dual-truth (non-blocking).

## Shot matrix (must)

| id | drive | proves |
| --- | --- | --- |
| desktop-detail-active-partial-scores | host-fixture | dual segs, base chip, switcher |
| desktop-detail-active-perfect-clean | host-fixture | perfect + Av0 |
| desktop-detail-active-bad-roll | host-fixture | avoid hits danger |
| desktop-detail-editor-want-avoid | host-fixture | W/A/Off + no view wash |
| desktop-detail-view-wash | host-fixture | diagonal wash behind icon |
| desktop-detail-no-active | host-fixture | no dual segs, power-desc |

*(Additional optional / widget-test-only rows per workflow plan JSON.)*

---

## STE map (architecture → file)

Use **Simplified Technical English**: one idea per line; active voice; verb first.

| # | Architecture | Task (STE) | File |
| --- | --- | --- | --- |
| 1 | Catalog detail surface | Keep the weapon detail shell at 400 width. | `catalog_weapon_detail.dart` |
| 2 | Named roll-target profiles | Add a switcher for named profiles and Off. | `catalog_roll_targets.dart` |
| 3 | Active profile | Wire set-active and get-active on the host. | `catalog_page.dart` |
| 4 | Preferred + avoid scores | Pass match scores into instance chips as trailing segments. | `catalog_weapon_detail.dart` (strip) |
| 5 | Base instance chip | Keep power, tier, and special segments from 002. | `catalog_weapon_detail.dart` |
| 6 | Rank owned copies | Order instances with rank API when a profile is active. | `catalog_page.dart` + strip props |
| 7 | Pure score / rank | Do not re-implement score logic in UI. | `packages/domain` (read-only use) via `packages/app` |
| 8 | Persist targets | Call create, update, delete, and list use cases from the host. | `catalog_page.dart` → `roll_target_use_cases.dart` |
| 9 | Can-roll pool view | Paint soft diagonal wash for preferred and avoid behind the icon. | `catalog_perk_grid.dart` |
| 10 | Can-roll pool edit | Cycle Want, Avoid, and Off on pool cells. | `catalog_perk_grid.dart` |
| 11 | Overlap rule | Block Save when preferred and avoid share a plug. | `catalog_roll_targets.dart` + host validate |
| 12 | Package boundary | Export new catalog widgets from the UI package. | `destiny2_ui_flutter.dart` |
| 13 | Widget tests | Prove segs, rank, switcher, editor, wash, and a11y. | `catalog_roll_targets_test.dart`, `catalog_weapon_detail_test.dart` |
| 14 | Host smoke | Prove host wire and fixtures for Capture. | `catalog_roll_targets_host_smoke_test.dart`, fixtures |
| 15 | Widgetbook | Add knobs for active profile, editor, and score presets. | `detail_use_cases.dart`, `catalog_fixtures.dart` |
| 16 | Dual-truth Capture | Capture must-row PNGs under implementation-shots. | `implementation-shots/003-catalog-roll-targets/` |
| 17 | Product-map IDs | Attach DBR-IDL and FEAT IDs to catalog detail surfaces. | `docs/product-map/surfaces.yaml` (+ sync) |

### STE bullets (scan form)

- **Switcher** — Add named profile + Off control. → `catalog_roll_targets.dart`
- **Dual segs** — Show `N/M` and `Av k` on chips when scored. → strip in `catalog_weapon_detail.dart`
- **Rank** — Sort owned list with app rank when active. → `catalog_page.dart`
- **View wash** — Draw soft diagonal preferred/avoid behind icon. → `catalog_perk_grid.dart`
- **Edit modes** — Cycle Want / Avoid / Off on ③ pool. → `catalog_perk_grid.dart`
- **CRUD** — Wire app roll-target use cases on host. → `catalog_page.dart`
- **Purity** — Keep domain score and db out of `ui_flutter`. → host maps only
- **Tests** — Add widget and host smoke coverage. → `test/*roll_targets*`
- **Book** — Add Widgetbook knobs for states. → `detail_use_cases.dart`
- **Shots** — Capture shot_matrix must rows. → `implementation-shots/003-…/`

---

## Approval

Approve this plan (including **STE map**) to continue implement, or request changes.
