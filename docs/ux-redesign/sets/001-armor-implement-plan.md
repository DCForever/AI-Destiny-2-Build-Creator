# Implement plan: Sets Armor MVP (001)

**Status:** implementing (2026-08-10 — domain/app/ui_flutter + host smoke/fixtures)  
**Brief:** `docs/ux-redesign/sets/001-armor-brief.md`  
**Mockups:** `mockups/001-armor-desktop.html`, `…-mobile.html`  
**Hosts:** windows (Capture exit), mobile (structure-only)  
**Workflow:** `area-implement` (plan phase)  
**Blocking dual-truth gaps:** none for area sets (root log has only `GAP-CAT-PERK-003`, non-blocking catalog).  
**Verify residuals (implement prerequisites, not gap IDs):** multi-goal domain supersession; fill rebind; exotic-block on compare; instance identity; god-page extract.

---

## Acceptance (summary)

- `/sets` dual-pane library + **large modal** create/board (G-SET-001); fill is **owned compare / optimize**, **not** Catalog page embed (G-SET-002).
- Create Armor: Type → Class lock → optional **G-SET-013** goals → auto-name/tags → empty board; piece UI hidden until Type+Class locked.
- Board layout A: five slots; totals row above pieces; base six + Σ + hard coverage + soft ≥2pc muted; hide unknown energy/mods (DBR-STAT-008).
- PRIMARY Optimize: confirm-only apply; seed class/exotic/bonus; replace-all warning only when ≥1 pin; one kit selected (BR-OPT-004).
- SECONDARY owned-only compare: base six+total+power+bonus fit+exotic; rank total/EoF; instance identity; second-exotic hard-block (BR-SLOT-009).
- Tags multi-select on detail+board; Synergy Type vocab hard-blocked (G-SET-033 / BR-TAG-009).
- Save disabled under-min / incomplete hard goals; blank name → auto-name + collision suffix.
- Delete always confirm; `SET_IN_USE` + used-by when attached.
- Signed-out / need-sync honesty empties — no fake owned armor (DBR-PUR-002).
- Non-Armor: library shell + thin detail only.
- Domain: supersede `DBR-SETB-003` (and BR-SET-050–054 singular-family) for multi-goal G-SET-013 in same change.
- Product-map: rebind `sets.fill-slot` off Catalog embed in same change.
- Windows Capture dual-truth for must shot_matrix rows; mobile structure-only.

---

## Mockup region → Flutter map

| Mockup region (desktop) | Product surface | Widget / host |
| --- | --- | --- |
| Dual-pane library + Armor flap columns | `sets.library` | `SetsLibraryWorkspace` + `SetsLibraryRail` + `SetsArmorLibraryRow` |
| Signed-out / need-sync / no-matches / loading | `sets.signed-out` + honesty | `SetsHonestyEmpty` (+ skeleton) |
| Detail rail: preview, tags, Open board, Delete, Mod Set | `sets.detail` | Thin rail compose in host + `SetsTagMultiSelect`, `SetsModSetDeepLink`, `SetsDeleteConfirm` |
| Create wizard Type+Class → goals → name | `sets.create` | `SetsCreateWizard` + `SetsBonusGoalsEditor` |
| Board modal layout A (totals above pieces) | `sets.detail` / `sets.edit` | `SetsLifecycleModal` → `SetsArmorBoard` + `SetsCoverageBand` + `SetsSaveGateBanner` |
| Pick / owned compare table | `sets.fill-slot` | `SetsOwnedCompareTable` (replaces Catalog embed) |
| Optimize constraints + kit matrix + confirm | `sets.optimize` | `SetsOptimizeConfirmShell` (reuse app optimizer materialize/apply; retire dual silent path) |
| Non-Armor thin detail | `sets.detail` (non-armor) | `SetsNonArmorThinDetail` |
| Mobile sheet stack | same surfaces | Structure-only sheets in `mobile_host` |

**Do not** reintroduce Catalog grid as Set fill. Keep `SetCatalogPicker` only if temporarily behind a dead path; prefer delete/repurpose to owned-compare host bridge.

---

## Package placement (no new packages)

| Layer | Responsibility |
| --- | --- |
| **domain** | Pure G-SET-013 bonus-combo legality + hard goal satisfaction vs soft ≥2pc detect; occupancy/save gates unchanged. |
| **sandbox_data** | Synergy Type vocabulary source for tag hard-block (read-only). |
| **app** | Auto-name + collision suffix; Armor library row projection; owned-compare rank DTOs; optimizer seed + confirm materialize/apply; SET_IN_USE copy; tag block helper. **No Flutter.** |
| **db / bungie / manifest** | Owned base-roll + instance identity + set-bonus family keys (existing providers; extend projection only if missing). |
| **ui_tokens** | Armor library column template (Name·class·pieces·coverage·used-by) + board A EoF stat metrics labels. **Do not** change color/spacing design tokens. |
| **ui_flutter/sets/** | All presentation widgets listed in brief inventory. |
| **windows_host/sets/** | Thin page + lifecycle controller + Capture keys; wire app use cases. |
| **mobile_host** | Structure-only library + sheet stack. |
| **widgetbook** | Fixture use-cases for board/compare/honesty. |
| **docs/product-map + specs** | Fill rebind + DBR-SETB-003 supersession. |

### Purity / layering (hard)

- `domain` / `sandbox_data`: pure Dart only.
- `ui_flutter` presentation-only: host maps domain/app DTOs → view models; no Drift/http.
- Do not embed `BUNGIE_CLIENT_SECRET`.
- Optimizer apply path is **confirm-only** (`ApplyArmorCombinationCommand` / materialize) — one shell.

---

## Domain supersession (same change)

Update wording (not UI-only multi-goal):

| ID | Change |
| --- | --- |
| `DBR-SETB-003` | Zero goals **or** legal G-SET-013 combo: none · 1×2pc · 2×2pc (different families) · 1×4pc (includes that family’s 2pc). Only Armor Sets. |
| `DBR-SETB-004` | When goals set: every non-exotic filled piece must be a member of the **union** of goal families; each goal’s minPieces must be met on save/attach. |
| `BR-SET-050`–`054` | Align with multi-goal; note supersession date. |
| DAC-SETB / related | Satisfaction checks per goal, not singular-family only. |

Pure helper (domain): `isLegalSetBonusGoalCombo`, `satisfiesHardSetBonusGoals`, soft coverage detect ≥2pc remaining independent (DBR-SETB-006).

---

## Files (primary ≤24 tracked in plan JSON)

| Path | Role |
| --- | --- |
| `specs/domain-business-rules.md` | Supersede `DBR-SETB-003`+ multi-goal |
| `specs/business-rules.md` | Align `BR-SET-050`–054 with G-SET-013 |
| `flutter/packages/domain/lib/src/evaluators/set_bonus_goals.dart` | **New** G-SET-013 legality + hard satisfaction |
| `flutter/packages/domain/lib/destiny2_domain.dart` | Export helper |
| `flutter/packages/domain/test/set_bonus_goals_test.dart` | Pure unit tests |
| `flutter/packages/app/lib/src/set_auto_name.dart` | **New** `{Class} · {pc} · {Family\|—}[ · tags]` + suffix |
| `flutter/packages/app/lib/src/set_owned_compare.dart` | **New** owned rank DTO + EoF/total rank |
| `flutter/packages/app/lib/src/set_tag_rules.dart` | **New** hard-block vs Synergy Type vocab |
| `flutter/packages/app/lib/src/set_use_cases.dart` | Wire class/goals on create/update; save gates |
| `flutter/packages/ui_tokens/lib/src/flap_board_layout.dart` | Armor Sets column template |
| `flutter/packages/ui_flutter/lib/src/sets/` | **New** widget tree (workspace, wizard, board, compare, optimize, tags, honesty, delete, thin detail) |
| `flutter/packages/ui_flutter/lib/destiny2_ui_flutter.dart` | Export sets widgets |
| `flutter/packages/ui_flutter/test/sets_armor_widgets_test.dart` | Higher-level widget tests |
| `flutter/apps/windows_host/lib/sets/sets_library_page.dart` | Thin host: dual-pane + modal open; no god-page board |
| `flutter/apps/windows_host/lib/sets/sets_lifecycle_controller.dart` | **New** modal lifecycle + fill/opt wiring |
| `flutter/apps/windows_host/lib/sets/set_catalog_picker.dart` | **Remove Catalog embed**; bridge to owned-compare only or delete |
| `flutter/apps/windows_host/lib/optimizer/optimizer_workspace.dart` | Embed/seed only via confirm shell (no silent dual apply) |
| `flutter/apps/windows_host/test/sets_armor_host_smoke_test.dart` | Host smoke + Capture keys |
| `flutter/apps/windows_host/test/sets_armor_capture_fixtures.dart` | host-fixture seeds for shots |
| `flutter/apps/mobile_host/lib/sets/sets_structure_pages.dart` | **New** structure-only sheets |
| `flutter/apps/widgetbook/lib/use_cases/sets/armor_use_cases.dart` | Widgetbook knobs |
| `docs/product-map/surfaces.yaml` | Rebind `sets.fill-slot`; attach G-SET / DBR IDs |
| `docs/product-map/flows.yaml` | Create → goals → board; fill = compare/optimize |
| `docs/ux-redesign/sets/implementation-shots/001-armor/` | Capture package (COMPARE + PNGs) |

**Supporting (out of JSON file cap, same PR as needed):** `set_library_presentation.dart`, `set_board_presentation.dart`, `optimizer_use_cases.dart`, `armor_base_roll_provider.dart`, domain export tests, vault Domain Set note if mount present.

---

## Implementation steps (ordered)

1. **Domain supersession + pure G-SET-013 helper** — docs + `set_bonus_goals.dart` + tests.  
2. **App pure helpers** — auto-name, tag block, owned-compare rank, library Armor row projection; extend create/update for class + goals JSON.  
3. **ui_tokens** — Armor flap columns (do not alter color/spacing tokens).  
4. **ui_flutter/sets** — extract widgets per inventory; presentation DTOs only.  
5. **windows_host** — thin page + lifecycle controller; replace Catalog picker with owned compare; wire optimizer confirm shell; Capture surface keys.  
6. **mobile_host** — structure-only library/create/board sheets.  
7. **Tests** — widget inventory + host smoke.  
8. **product-map** — rebind fill; seed flutter-windows statuses; `npm run product-map:sync`.  
9. **Widgetbook** — fixture scenarios.  
10. **Capture** — must shot_matrix rows under `implementation-shots/001-armor/`.

---

## Tests (always)

| Test | Proves |
| --- | --- |
| domain `set_bonus_goals_test` | Legal/illegal G-SET-013 combos; hard satisfaction; 4pc includes 2pc family |
| app unit (auto-name, tags, compare rank) | Collision suffix; blocked tags; owned-only rank total/EoF |
| widget: create lock | Piece/compare UI hidden until Type+Class locked |
| widget: bonus goals | Only legal combos accepted |
| widget: empty board | Optimize primary; five Pick; Σ zeros |
| widget: optimize shell | Confirm-only; no silent write; one kit; replace-all only if pin |
| widget: owned compare | No unowned; columns; rank; exotic-block feedback |
| widget: board | Base-roll only; hard/soft coverage; hide unknown energy/mods |
| widget: tags | Multi-select; Synergy Type hard-blocked |
| widget: save gate | Under-min / incomplete goals disable Save; blank→auto-name |
| widget: delete | Always confirm; SET_IN_USE + used-by |
| widget: honesty | Signed-out / need-sync empty — no fake armor |
| widget: non-armor | Shell + thin detail only |
| widget: library flap | Name·class·pieces·coverage·used-by |
| widget: mod deep link + no catalog embed | Deep link present; fill is compare not Catalog page |
| widget: loading / no-matches | Skeleton + honesty |
| host smoke Windows | library→modal create→board; Capture surface keys |
| mobile structure smoke | Sheets mount without Catalog fill |

---

## Shot matrix

| id | must | drive | proves |
| --- | --- | --- | --- |
| `desktop-library-armor` | true | host-fixture | dual-pane, Armor columns, used-by |
| `desktop-signed-out-honesty` | true | host-fixture | signed-out empty, no fake owned |
| `desktop-create-type-class` | true | host-fixture | Type+Class lock; piece UI hidden |
| `desktop-empty-board` | true | host-fixture | Optimize primary; five Pick; Σ zeros |
| `desktop-filled-board-coverage` | true | host-fixture | layout A totals above pieces; hard+soft coverage |
| `desktop-owned-compare` | true | host-fixture | owned-only columns; instance ids; no Catalog chrome |
| `desktop-optimize-confirm` | true | host-fixture | kit matrix; confirm-only; replace-all when pins |
| `desktop-delete-set-in-use` | true | host-fixture | confirm + SET_IN_USE used-by |
| `desktop-tags-blocked` | false | host-fixture | Synergy Type chip hard-blocked |
| `desktop-need-sync` | false | host-fixture | need-sync honesty gate |
| `desktop-non-armor-thin` | false | host-fixture | thin detail only |
| `widget-bonus-goals-illegal` | false | widget-test-only | illegal combo rejected |

Capture dir: `docs/ux-redesign/sets/implementation-shots/001-armor/`.  
Optimizer chrome density at 1080p: progressive disclosure OK if Capture readability fails (brief residual 9).

---

## Risks

1. **God-page extract** — `SetsLibraryPage` is large; incomplete extract reintroduces Catalog embed or dual apply paths.  
2. **DBR-SETB-003 supersession** — Next.js still singular-family; dual-run must not regress Next until ported, but Dart domain must match G-SET-013 for this MVP.  
3. **Instance identity** — name-only pins break multi-copy honesty; compare/apply must carry `instanceId`.  
4. **Optimizer matrix density** — wide DIM-like table may fail Capture readability at 1080p.  
5. **Tag vocab source** — must use real Synergy Type labels, not only concept tags (sandbox/app designation chrome).  
6. **Existing host tests** — smoke tests still expect Catalog fill keys; update in same change.  
7. **Wishlist residual** — document owned-only narrow of DBR-ROLL-001; do not ship wishlist pins.  
8. **Mobile** — structure-only must not block Windows Capture exit.

---

## Deferred

| Item | Reason |
| --- | --- |
| Full Neon Weapon/Mod/Pair/Fashion boards | Out of Armor MVP |
| Synergy Type designate/filter chrome | G-SET-012 omit |
| Unowned wishlist pins | DBR-ROLL-001 residual narrow |
| Build-mounted Capture | G-SET-003 out |
| Inline mod/energy edit | G-SET-050 deep link only |
| `GAP-CAT-PERK-003` | Catalog area; non-blocking |

---

## STE map (architecture → file)

| # | Architecture | Task (STE) | File |
| --- | --- | --- | --- |
| 1 | Multi-goal domain rule | Update DBR-SETB-003 for legal multi-goal combos. | `specs/domain-business-rules.md` |
| 2 | Bonus goal legality | Add pure G-SET-013 legality and hard satisfaction helpers. | `domain/.../set_bonus_goals.dart` |
| 3 | Auto-name | Generate Class·pc·family·tags names with collision suffix. | `app/.../set_auto_name.dart` |
| 4 | Owned compare rank | Rank owned instances by total and EoF stats. | `app/.../set_owned_compare.dart` |
| 5 | Tag hard-block | Block tags that match Synergy Type vocabulary. | `app/.../set_tag_rules.dart` |
| 6 | Set CRUD | Persist class, goals, tags, and save gates on create/update. | `app/.../set_use_cases.dart` |
| 7 | Armor library columns | Define Name·class·pieces·coverage·used-by template. | `ui_tokens/.../flap_board_layout.dart` |
| 8 | Sets UI package | Add Sets lifecycle widgets under sets/. | `ui_flutter/lib/src/sets/*` |
| 9 | Board layout A | Render five slots with totals row above pieces. | `sets_armor_board.dart` |
| 10 | Fill secondary | Show owned-only compare table with instance identity. | `sets_owned_compare_table.dart` |
| 11 | Fill primary | Show optimizer confirm shell with one-kit apply. | `sets_optimize_confirm_shell.dart` |
| 12 | Host wire | Thin the library page and open the lifecycle modal. | `windows_host/.../sets_library_page.dart` |
| 13 | Catalog embed removal | Replace Catalog picker with owned-compare bridge. | `set_catalog_picker.dart` / lifecycle controller |
| 14 | Mobile structure | Add structure-only Sets sheets. | `mobile_host/.../sets_structure_pages.dart` |
| 15 | Widget tests | Prove board, compare, tags, honesty, and gates. | `ui_flutter/test/sets_armor_widgets_test.dart` |
| 16 | Host smoke | Prove library→create→board and Capture keys. | `sets_armor_host_smoke_test.dart` |
| 17 | Widgetbook | Add fixture use-cases for Armor Sets states. | `widgetbook/.../sets/armor_use_cases.dart` |
| 18 | Product-map fill | Rebind sets.fill-slot off Catalog embed. | `docs/product-map/surfaces.yaml` |
| 19 | Dual-truth Capture | Capture must-row PNGs under implementation-shots. | `sets/implementation-shots/001-armor/` |

### STE bullets (scan)

- **Supersede domain** — Allow multi-goal G-SET-013. → specs + `set_bonus_goals.dart`  
- **Library** — Armor flap columns + honesty empties. → `SetsLibraryWorkspace`  
- **Create** — Lock Type+Class before pieces. → `SetsCreateWizard`  
- **Board A** — Totals above five slots. → `SetsArmorBoard`  
- **Compare** — Owned-only rank table. → `SetsOwnedCompareTable`  
- **Optimize** — Confirm-only one kit. → `SetsOptimizeConfirmShell`  
- **Tags** — Hard-block Synergy Type labels. → `SetsTagMultiSelect` + `set_tag_rules.dart`  
- **Delete** — Confirm + SET_IN_USE. → `SetsDeleteConfirm`  
- **Host** — Thin page; no Catalog embed. → `sets_library_page.dart`  
- **Map** — Rebind fill surface. → `surfaces.yaml` + sync  

---

## Approval

Approve this plan (including **STE map**, **shot_matrix**, and **domain supersession**) to continue implement, or request changes.
