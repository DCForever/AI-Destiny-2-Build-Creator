# Implementation shots — sets / 001-armor

**Date:** 2026-08-10  
**Status:** **Capture complete** — all `must:true` matrix rows on disk; dual-truth **closed** for Sets Armor MVP matrix (mobile structure-only)  
**Hosts:** windows (exit gate); mobile structure-only  
**Brief / plan:** `docs/ux-redesign/sets/001-armor-brief.md`, `001-armor-implement-plan.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/sets/mockups/001-armor-desktop.html`
- `docs/ux-redesign/sets/mockups/001-armor-mobile.html`

**Capture entry:** `flutter/apps/windows_host/lib/main_sets_armor_capture.dart`  
**Fixtures:** `flutter/apps/windows_host/lib/sets/sets_armor_capture_fixtures.dart`  
**Driver sequence:** `capture-sequence.json` via `tool/capture_driver_shots.dart`  
**Launch:** `background_shell` (`flutter run -d windows -t lib/main_sets_armor_capture.dart` + `ENABLE_FLUTTER_DRIVER=1`)

## Purpose

Ground truth for Sets Armor redesign: mockup dual-pane library + create lock + board layout A + owned compare + optimize confirm-only vs **shipped** Flutter Sets widgets (`SetsLibraryWorkspace` / `SetsCreateWizard` / `SetsArmorBoard` / `SetsOwnedCompareTable` / `SetsOptimizeConfirmShell` / `SetsDeleteConfirm` / `SetsHonestyEmpty`). Dual-truth is **not** closed on PNG presence alone — residuals reviewed below.

## Scenario matrix

| Scenario | Drive | Shot | Proves | Residual |
| --- | --- | --- | --- | --- |
| Desktop — library Armor | host-fixture | `desktop-library-armor.png` | dual-pane; Name·class·pcs·cover·used-by; Mod Set deep link | **closed** on ship widget — rail headers truncated at narrow default rail (COVER/USED clip); host god-page still residual |
| Desktop — signed-out honesty | host-fixture | `desktop-signed-out-honesty.png` | signed-out empty; no fake owned | **closed** |
| Desktop — create Type+Class | host-fixture | `desktop-create-type-class.png` | type-class lock; pieces hidden until Class | **closed** (armor type selected, class null → pieces hidden key) |
| Desktop — empty board | host-fixture | `desktop-empty-board.png` | Optimize primary; five Pick; Σ zeros | **closed** |
| Desktop — filled board + coverage | host-fixture | `desktop-filled-board-coverage.png` | layout A totals; hard TechSec 2pc; soft ≥2pc muted | **closed** |
| Desktop — owned compare | host-fixture | `desktop-owned-compare.png` | owned-only; instance ids; no Catalog embed; exotic-block | **closed** on widget; host inventory projection still residual (empty rows on live SetsLibraryPage) |
| Desktop — optimize confirm | host-fixture | `desktop-optimize-confirm.png` | kit matrix; confirm-only; replace-all when pins | **closed** on ship shell; host still may open OptimizerWorkspace residual |
| Desktop — delete SET_IN_USE | host-fixture | `desktop-delete-set-in-use.png` | confirm dialog; SET_IN_USE; used-by; no Delete | **closed** |
| Desktop — tags blocked (optional) | host-fixture | `desktop-tags-blocked.png` | Synergy Type hard-block control present | **structure-only** interaction (blocked message needs type+add; not forced in still) |
| Desktop — need-sync (optional) | host-fixture | `desktop-need-sync.png` | need-sync honesty | **closed** (optional) |
| Desktop — non-Armor thin (optional) | host-fixture | `desktop-non-armor-thin.png` | thin detail only | **closed** (optional) |
| Widget — illegal bonus goals | widget-test-only | — | illegal combo rejected | tests only |

## Verify residuals (shot + structure)

1. **Library dual-pane + Armor columns** — Capture proves `SetsLibraryWorkspace` columns Name·CLASS·PCS·COVER·USED (+ used-by on detail). **closed** for ship widget. **reopen host:** `SetsLibraryPage` residual god-page / generic `kFlapColumnsSets` until cutover mounts workspace.
2. **Create lock** — Type armor + class null shows pieces-hidden. **closed**.
3. **Empty board layout A** — Optimize primary, Σ 0, five Pick. **closed**.
4. **Filled + coverage** — totals above pieces; hard TechSec 2pc chip; soft ≥2pc muted. **closed**.
5. **Owned compare** — instance ids, rank total/EoF, exotic blocked label, no `catalog_weapons_workspace`. **closed** on fixture. **reopen host:** inventory projection not mapped → empty fill on product page.
6. **Optimize confirm-only** — kit matrix, seeds class/exotic/goals, replace-all banner, Apply only on confirm. **closed** on shell. **reopen host:** PRIMARY may still be `OptimizerWorkspace` until board sole primary.
7. **Delete SET_IN_USE** — used-by list; Delete button absent. **closed**.
8. **Capture harness chrome** — scenario chip rail + DEBUG banner are **not** product Sets chrome (same class as other host-fixture Captures).
9. **Fixture exotic-block** — capture maps `exoticBlocked: isExotic` for honesty demo; product second-exotic exclusivity remains host responsibility (DBR residual note).

## Checklist

- [x] `desktop-library-armor.png`
- [x] `desktop-signed-out-honesty.png`
- [x] `desktop-create-type-class.png`
- [x] `desktop-empty-board.png`
- [x] `desktop-filled-board-coverage.png`
- [x] `desktop-owned-compare.png`
- [x] `desktop-optimize-confirm.png`
- [x] `desktop-delete-set-in-use.png`
- [x] `desktop-tags-blocked.png` (optional)
- [x] `desktop-need-sync.png` (optional)
- [x] `desktop-non-armor-thin.png` (optional)
- [x] dual_truth_ok after must-rows + residual review (no `blocks_dual_truth` open gaps for sets/armor)

## Deferred / next redesign

- Host cutover: mount `SetsLibraryWorkspace` / board / optimize shell on live `SetsLibraryPage` (god-page extract).
- Owned inventory projection → compare rows (empty fill residual).
- Product-map flutter-windows create/detail/fill/optimize stub→done after host cutover.
- Rail column density (truncate vs wider default rail).
- DBR-ROLL-001 wishlist must not ship as default fill.
- Mobile structure-only sheets (not Capture gate).
- Optional: tags blocked-message still after type+add interaction shot.

## Next

```text
# product-map: sets.* flutter-windows partial/stub → done after host cutover
# npm run product-map:sync / product-map:parity from monorepo root when hub edited
# Next implement: host wire residuals; next redesign: rail density + live fill projection
```
