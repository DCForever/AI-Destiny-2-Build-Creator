# Implement plan: EntityInfoHotspot (004)

**Status:** approved 2026-08-08 — **structure + Capture matrix closed**  
**Brief:** `docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md`  
**Mockups:** `mockups/004-entity-info-hotspot-desktop.html`, `…-mobile.html`  
**Hosts:** windows, widgetbook  
**Workflow:** `area-implement` (plan phase)

---

## Load summary

| Field | Value |
| --- | --- |
| Slice | UX-CATALOG-ENTITY-DESC / GAP-UI-DESC-01 Track B |
| System | DART-071 `EntityPresentation` + `resolveEntityPresentation*` **landed** (pure domain) |
| Ship today | Material `Tooltip` on perk cells = name · tier only; no description popover/sheet |
| Rule IDs | DBR-UI-001/005/006, DAC-DST-015, DART-071 |
| Open dual-truth gaps | None specifically `blocks_dual_truth` for entity-desc chrome yet (GAP is product ledger, not DUAL-TRUTH-GAPS visual row) |
| Blocking gaps this slice | `[]` (structure addresses chrome absence) |

## Acceptance (summary)

- Desktop: **hover/focus → full entity info** Flap (~280px, portaled); **click = primary** select (never opens info).
- Mobile: **tap = primary** select; **long-press ≥450ms** or **Alt+tap** → modal info sheet.
- Body only from host-resolved presentation; empty → fixed **`No catalog description`**; never invent text.
- Single-open; Esc / leave / scrim dismiss; residual perk chrome unchanged (①/②/③ · E · no H-scroll @400).
- Host wires description maps via `resolveEntityPresentation` / entity stores; fixtures only in Widgetbook/tests.
- Widget + host smoke + Widgetbook knobs; shot_matrix must rows via host-fixture / widget-test where noted.

## Architecture note (purity)

- **Resolve** stays pure: `packages/domain` `EntityPresentation` / maps.
- **`ui_flutter`** currently has **no** `destiny2_domain` dep. Prefer a thin **presentation DTO** in ui_flutter (`EntityInfoData` / fields mirror) so chrome stays IO-free and package graph unchanged; host maps domain → DTO.
- Optional later: export a shared type — **not required** for this slice if fields match.

## Files

| Path | Role |
| --- | --- |
| `flutter/packages/ui_flutter/lib/src/entity_info_hotspot.dart` | **New** — portal Flap (desktop) + sheet (mobile), single-open controller, empty copy constant |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_perk_grid.dart` | Wire hover/long-press/Alt info vs primary tap; optional `presentationByHash` / `EntityInfoData?` per cell |
| `flutter/packages/ui_flutter/lib/src/catalog/catalog_weapon_detail.dart` | Pass presentation map / scope Overlay for portal if needed |
| `flutter/packages/ui_flutter/lib/destiny2_ui_flutter.dart` | Export hotspot + DTO |
| `flutter/packages/ui_flutter/test/entity_info_hotspot_test.dart` | **New** widget tests (matrix) |
| `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart` | Extend: primary vs info, no H-scroll regression |
| `flutter/apps/windows_host/lib/catalog/owned_catalog_bridge.dart` | Build `descriptionByHash` (and kind/meta if available) from entity/manifest maps — **no invent** |
| `flutter/apps/windows_host/lib/catalog/catalog_page.dart` | Resolve presentations for visible plugs; pass into detail/grid |
| `flutter/apps/windows_host/test/entity_info_hotspot_host_smoke_test.dart` | **New** host smoke + fixtures for Capture |
| `flutter/apps/windows_host/test/entity_info_hotspot_fixtures.dart` | Fixture maps (named plugs + known empty) |
| `flutter/apps/widgetbook/lib/use_cases/catalog/detail_use_cases.dart` | Knobs matrix (desc present\|empty\|null, tier, enhanced, compare) |
| `flutter/apps/widgetbook/lib/fixtures/catalog_fixtures.dart` | Fixture presentations |
| `docs/ux-redesign/catalog/implementation-shots/004-entity-info-hotspot/` | Capture COMPARE + PNGs |

## Interaction implement detail

| Gesture | Behavior |
| --- | --- |
| Desktop mouse enter / focus | Open info Overlay near cell; single-open |
| Desktop mouse leave (cell+popover) | Close info |
| Desktop click / Enter / Space | Primary: select (or roll-target cycle when editing) — **do not** open info |
| Mobile short tap | Primary only |
| Mobile long-press ≥450ms | Open sheet; suppress following tap primary |
| Mobile Alt+tap (desktop Alt+click optional parity) | Open sheet/info |
| Esc / scrim / Close | Dismiss info only |

## Risks

- **Description map source:** host must load real definition descriptions (entity bundle / inventory defs). If map missing → honest empty — never invent. Wire only known fields from existing extractors.
- **Windows AX:** avoid nested Semantics+Tooltip thrash (existing perk-grid pattern); info surface one dialog owner.
- **Hover vs click race:** pointer leave must not fire primary; long-press must cancel select.
- **ui_flutter purity:** no manifest/IO in package; maps/DTOs only.
- **Portal clip:** Overlay entry outside detail `ClipRect` so flap is not clipped at 400.

## Deferred

- Sticky multi-perk inspect sheet (user residual; not gate).
- Armor / meta-strip / origin first wire.
- L3 wiki/LLM.

## Shot matrix

| id | must | drive | proves |
| --- | --- | --- | --- |
| `desktop-info-desc-present` | true | host-fixture | Hover/open info shows fixture body; name header |
| `desktop-info-honest-empty` | true | host-fixture | Empty/null → “No catalog description” |
| `desktop-click-selects-not-info` | true | host-fixture / widget-test | Click selects; info not pinned open by click |
| `mobile-longpress-info-sheet` | true | host-fixture | Long-press opens sheet with body |
| `desktop-unknown-no-hash-primary` | true | host-fixture | Unknown label; no bare hash title |
| `desktop-single-open` | false | widget-test-only | A closes when B opens |
| `desktop-enhanced-chrome` | false | widget-test-only | E residual + info still works |
| `desktop-no-hscroll-400` | false | widget-test-only | Grid width / no H-scroll |

---

## STE map (architecture → file)

| # | Architecture | Task (STE) | File |
| --- | --- | --- | --- |
| 1 | Pure presentation model | Keep resolve in domain; do not re-implement maps in UI. | `packages/domain/.../entity_presentation.dart` (read-only) |
| 2 | UI presentation DTO | Add a chrome-facing entity info data type (name, kind, icon, description, meta, compare pair, hash footer). | `entity_info_hotspot.dart` |
| 3 | Info surface | Add portaled desktop Flap (~280) and mobile bottom sheet with honest empty copy. | `entity_info_hotspot.dart` |
| 4 | Single-open registry | Add a scoped controller so only one info is open per detail. | `entity_info_hotspot.dart` |
| 5 | Perk cell gestures | Wire hover/focus to info; keep click/tap as primary select. | `catalog_perk_grid.dart` |
| 6 | Mobile secondary | Wire long-press and Alt+tap to open info sheet; suppress primary after long-press. | `catalog_perk_grid.dart` |
| 7 | Residual cell chrome | Leave ①/②/③, gold E, wash, and W/A badges unchanged. | `catalog_perk_grid.dart` |
| 8 | Detail compose | Pass presentation map into the perk grid from weapon detail. | `catalog_weapon_detail.dart` |
| 9 | Package export | Export the hotspot widgets from the UI package. | `destiny2_ui_flutter.dart` |
| 10 | Host description maps | Build description (and name/icon) maps from entity/inventory sources without inventing text. | `owned_catalog_bridge.dart` |
| 11 | Host resolve | Call resolve helpers and pass DTOs into Catalog detail. | `catalog_page.dart` |
| 12 | Widget tests | Prove hover info, primary click, empty string, single-open, a11y name. | `entity_info_hotspot_test.dart` |
| 13 | Detail regression | Prove no H-scroll and residual enhance chrome still pass. | `catalog_weapon_detail_test.dart` |
| 14 | Host smoke | Add host fixture smoke for Capture matrix rows. | `entity_info_hotspot_host_smoke_test.dart`, fixtures |
| 15 | Widgetbook | Add knobs for description present\|empty\|null, tier, enhanced, compare. | `detail_use_cases.dart`, fixtures |
| 16 | Dual-truth Capture | Capture must-row PNGs under implementation-shots. | `implementation-shots/004-entity-info-hotspot/` |

### STE bullets (scan form)

- **DTO** — Add chrome entity info fields. → `entity_info_hotspot.dart`
- **Flap/sheet** — Show presentation body; empty fixed string. → `entity_info_hotspot.dart`
- **Gestures** — Hover info; click select; mobile long-press/Alt info. → `catalog_perk_grid.dart`
- **Host maps** — Fill description maps from entity data only. → `owned_catalog_bridge.dart` / `catalog_page.dart`
- **Tests** — Cover primary vs info and honest empty. → `entity_info_hotspot_test.dart`
- **Book** — Add Widgetbook knobs for states. → `detail_use_cases.dart`
- **Shots** — Capture shot_matrix must rows. → `implementation-shots/004-…/`

---

## addresses_gap_ids / deferred

| addresses_gap_ids | deferred_gap_ids |
| --- | --- |
| GAP-UI-DESC-01 (chrome half / Track B structure) | Sticky multi-perk sheet (nice-to-have residual); Armor wire |

## Next

**Approve this plan** (or request changes). On approval, implement → analyze/tests → Capture attempt.
