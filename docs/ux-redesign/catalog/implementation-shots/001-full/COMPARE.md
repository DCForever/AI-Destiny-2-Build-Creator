# Implementation shots — catalog / 001-full (residual pass)

**Date:** 2026-08-04  
**Capture run:** MCP Flutter Driver (`ENABLE_FLUTTER_DRIVER` shell launch; this session has no `launch_app`)  
**Hosts:** windows (primary); mobile deferred  
**Brief / approval:** `docs/ux-redesign/catalog/001-full-brief.md`, `MOCKUP-APPROVED.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/catalog/mockups/001-full-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-full-mobile.html`

**Prior ground truth:** `../001-weapons/` + that folder’s `COMPARE.md`

## Purpose

Close three COMPARE residuals from 001-weapons on **windows weapons** detail/grid, and freeze dual ground truth for the next redesign:

1. **P0** Equal-width perk columns · no H-scroll at `kCatalogWeaponsDetailWidth=400`
2. **P1** Pure icon-only meta strip (type · frame · el · slot · ammo + ×N)
3. **P2** Origin column only when definition/instance has origin data

Plus tier model: owned ①+② default · Possible rolls OFF; unowned ③-only; Enhanced gold/E.

## Scenario matrix

| Scenario | Mockup | Shot (this folder) | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop — All grid | `001-full-desktop.html` | `desktop-grid.png` | Scope **All** default; **OWNED · 790** after local inventory; facet icon-only chrome OK. No residual gate. |
| Desktop — detail owned (PERKS, Possible rolls OFF) | same | `desktop-detail-owned.png` | **Meta strip layout reopen (P1):** glyph chips expand to full-width bars (Wrap + `Container`+`alignment`); type is letter abbrev **PR** not silhouette. Content wins: no text subtitle / no KINETIC·OWNED text pills; ①+② PERKS; **Origin Trait** Elliptical Orbit present; craft hidden; Possible rolls OFF. |
| Desktop — detail unowned (POSSIBLE ROLLS) | same | `desktop-detail-unowned.png` | Full ③ pool (Hung Jury SR4); no Possible rolls / craft toggles; Origin omitted without data (correct). Same **full-width meta bar** residual; type **SR** letter. |
| Desktop — Possible rolls ON | same | `desktop-can-roll.png` | Equal-width columns; no perk-grid H-scroll at 400 (**P0 closed**). Label truncation under ③ ON (`MASTERW…` / `ORIGIN TR…`) accepted density — still UX-visible. Enhanced gold/E rare in live host (name-heuristic only). |
| Desktop — owned multi-instance strip | same | `desktop-instance-strip.png` | **Same frame as** `desktop-detail-owned.png` (SHA256 identical): ×5 PL 550 chips + meta ×5. Distinct crop optional next pass. |
| Desktop — exotic soft catalyst | same | `desktop-detail-unowned-exotic.png` | Ace of Spades: intrinsic + POSSIBLE ROLLS; Set/Synergy disabled stubs; soft catalyst under-verified (fields empty — display-only path). Meta full-width **HC** residual. |
| Mobile — detail | `001-full-mobile.html` | *(deferred)* | Push deferred by design — no mobile residual gate this slice. |

## Capture notes

| | |
| --- | --- |
| Launch | Shell: `C:\d2f\apps\windows_host\run-windows.ps1 -EnableFlutterDriver` (MCP session has no `launch_app`; Driver via `ENABLE_FLUTTER_DRIVER` / `lib/main_mcp.dart`) |
| Driver | DTD connected · `set_frame_sync enabled=false` before taps · `flutter_driver` `screenshot` |
| Session | Local inventory present (**OWNED · 790** / 1377 copies); OAuth access expired with no refresh — owned chrome from local DB, not live re-auth |
| Subjects | Grid ALL; unowned Hung Jury SR4; owned Chattering Bone ×5; can-roll ON same; exotic Ace of Spades |
| Integrity | All six PNGs valid `89 50 4E 47…`; owned ≡ instance-strip (intentional same-frame dual use) |

Widget + host smoke cover residual **structure** (meta keys, Origin poles, 400 pane, tiers, craft hidden):

- `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart`
- `flutter/packages/ui_flutter/test/catalog_weapons_widgets_test.dart`
- `flutter/apps/windows_host/test/catalog_weapons_host_smoke_test.dart`

## Visual residuals closed in code (vs 001-weapons)

1. **Meta content** — no type·frame text subtitle; no KINETIC/OWNED **text** pills; ×N only for owned count.
2. **Origin Trait** — shown when socket/definition carries origin plugs; empty origin omitted; never invented.
3. **Equal-width / no H-scroll** — `CatalogPerkGrid` equal `Expanded` columns; no horizontal Scrollable on perk grid (instance strip H-scroll separate + allowed).
4. **Tiers** — owned default ①+②; ③ behind **Possible rolls** (key `catalog_toggle_can_roll`, OFF default); unowned ③-only without toggle.
5. **Enhanced** — gold border + **E** when name heuristic or host `plugEnhancedByHash` (host rarely supplies map).
6. **Craft** — Possible crafted hidden until `craftAvailable` (host false without craft columns).
7. **Outbound** — Set/Synergy disabled stubs on weapons path.

## Open residuals (feed next `area-ux-redesign`)

Priority for next catalog residual slice (windows weapons detail chrome):

1. **P1 meta strip layout** — compact horizontal icon strip (fixed ~22px chips in a `Row`/`Wrap` that does **not** expand). Root cause: `_MetaGlyphChip` / `_OwnedCountChip` use `Container(alignment: …)` without fixed width under full-width Wrap max constraint → full-width bars in dual-truth shots.
2. **Weapon-type silhouettes** — mockup uses official type mask icons (pulse/scout/hand cannon); ship uses letter abbrev (PR/HC/SR). Wire type icon path or destiny-icons silhouettes.
3. **③ ON density** — column headers truncate at 400; keep pane width; improve ellipsis/tooltip/Semantics only.
4. **Enhanced gold/E live proof** — host should pass `plugEnhancedByHash` (or category) so Enhanced is not name-only; Widgetbook + fixture still cover chrome.
5. **Soft catalyst** — re-shot when catalyst progress fields non-empty; confirm display-only (no equip/save gate).
6. **Optional product-map** — attach residual rule IDs `BR-CAT-016*`, `DBR-UI-006`, `DBR-UI-007` on `catalog.weapon.detail` + `catalog.weapons.perk-grid` if missing; no new surfaces.
7. **Armor / universal** — residual audit-only notes still not a written artifact; optional thin Neon align next slice.
8. **Mobile Catalog push** — deferred; no residual gate until push lands.
9. **Vault UX note** — residual-pass Obsidian note / Weapons.md “Can roll” wording drift (out of this package; update when vault mount available).

## Checklist

- [x] `desktop-grid.png` — MCP Driver  
- [x] `desktop-detail-owned.png` — MCP Driver (Possible rolls OFF; Chattering Bone ×5)  
- [x] `desktop-detail-unowned.png` — MCP Driver (Hung Jury SR4)  
- [x] `desktop-can-roll.png` — MCP Driver (Possible rolls ON)  
- [x] `desktop-instance-strip.png` — MCP Driver (same frame as owned; ×5 instances)  
- [x] `desktop-detail-unowned-exotic.png` — MCP Driver (Ace of Spades)  
- [ ] `mobile-detail.png` (when mobile Catalog ships)  

## Capture how-to

1. Launch host with Driver: MCP `launch_app` → `target=lib/main_mcp.dart`, device `windows`  
   (or `.\run-windows.ps1 -EnableFlutterDriver` from short junction `C:\d2f\apps\windows_host`)  
2. Connect DTD; `flutter_driver` `get_health`  
3. **`set_frame_sync` → `enabled=false`** before taps  
4. After OAuth/sync, **hot_restart** if Catalog still shows SIGN IN / 0 copies  
5. Drive scenarios; `screenshot` → PNGs here; update matrix  

See `flutter/apps/windows_host/README.md` and `docs/ux-redesign/README.md`.

## Next workflow

```text
/workflow area-ux-redesign {"area":"catalog","subarea":"full","hosts":["windows"],"slice_goal":"Meta strip compact horizontal layout + weapon-type silhouettes from implementation-shots/001-full/COMPARE.md; keep 400 pane equal Expanded; Enhanced host map; optional soft-catalyst re-shot","out_of_scope":"Mobile Catalog push, live Set/Synergy outbound, armor optimizer, craft columns invention, vault transfer"}
```
