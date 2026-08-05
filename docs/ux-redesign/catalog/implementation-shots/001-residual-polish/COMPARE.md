# Implementation shots — catalog / 001-residual-polish

**Date:** 2026-08-04  
**Capture run:** MCP Flutter Driver (`ENABLE_FLUTTER_DRIVER` + `lib/main_mcp.dart` shell fallback; session had no `launch_app`)  
**Hosts:** windows (primary); mobile deferred  
**Brief / approval:** `docs/ux-redesign/catalog/001-residual-polish-brief.md`, `MOCKUP-APPROVED.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-residual-polish-mobile.html`

**Prior ground truth:** `../001-full/` + that folder’s `COMPARE.md`

## Purpose

Close five COMPARE residuals from 001-full on **windows weapons** detail chrome, and freeze dual ground truth for the next redesign:

1. **P1 meta** — fixed **22×22** chips · compact horizontal strip (not full-width bars)
2. **Type silhouettes** — official destiny-icons when mapped; letter last-resort + Semantics
3. **③ ON headers** — ellipsis + Tooltip + Semantics @ `kCatalogWeaponsDetailWidth=400`; no pane widen / no perk-grid H-scroll
4. **Enhanced host map** — `windows_host` `plugEnhancedByHash`; gold+E on **①/② only**
5. **Soft catalyst** — omit-when-empty; display-only when present

Plus enhance-note presentation for ③ / unowned / craft (no E cells; one identity).

## Scenario matrix

| Scenario | Mockup | Shot (this folder) | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop — All grid | `001-residual-polish-desktop.html` | `desktop-grid.png` | Scope **ALL** + OWNED · 790 + facet chrome OK. Frame is **detail+can-roll heavy** (Midnight Coup open, Possible rolls ON) — not a pure grid-only crop. No residual gate. |
| Desktop — detail owned (①+②, Possible rolls OFF) | same | `desktop-detail-owned.png` | **Meta P1 closed:** compact horizontal 22×22 chips (hand-cannon silhouette · frame · element · K · ammo · ×1) — not full-width bars (contrast `001-full/desktop-detail-owned.png`). Type silhouette present. Origin Trait column when data. Craft hidden. Tier lock: ①+② · Possible rolls OFF. Live **Unknown perk** cell (name resolve residual under DBR-UI-006). No gold/E on this copy. |
| Desktop — detail unowned (③-only) | same | `desktop-detail-unowned.png` | Cerberus+1 exotic unowned: compact meta · no ×N · honesty line · POSSIBLE ROLLS ③-only · Set/Synergy disabled stubs. **Can-be-enhanced note not visible** in this shot (structure tests cover note path). Catalyst panel omitted (empty). |
| Desktop — Possible rolls ON @400 | same | `desktop-can-roll.png` | Equal-width Expanded columns; no perk-grid H-scroll at 400. Headers ellipsis (`MASTERWO…` / `ORIGIN TR…`); Tooltip+Semantics covered by widget tests (not visible in PNG). No enhance note / no E on ③ pool cells. |
| Desktop — enhanced live map (gold+E on ①/②) | same | *(not dual-truth captured)* | Code + unit tests: `plugEnhancedByHash` → gold+E on ①/② only; ③/unowned/craft force no E. Host name-heuristic path; **no live inventory fixture PNG**. Structure green; dual-truth reopen. |
| Desktop — exotic soft catalyst | same | `desktop-detail-unowned-exotic.png` | **SHA256 identical to** `desktop-detail-unowned.png` (same Cerberus+1 frame). Proves **omit-when-empty**. **Display-when-present** not dual-truth proven (no Ace/Wish-Keeper catalyst progress subject). |
| Mobile — detail | `001-residual-polish-mobile.html` | *(deferred)* | Push deferred by design — no mobile residual gate this slice. |

## Capture notes

| | |
| --- | --- |
| Launch | Shell: `C:\d2f\apps\windows_host` + `flutter run -d windows -t lib/main_mcp.dart` with `ENABLE_FLUTTER_DRIVER` (MCP `launch_app` / `list_devices` / `stop_app` unavailable this session) |
| Driver | DTD connected · `set_frame_sync enabled=false` before taps · `flutter_driver` `screenshot` |
| Session | Local inventory present (**OWNED · 790** / 1377 copies); LIVE status |
| Subjects | Grid ALL exotics; owned **Midnight Coup** ×1 (search “Midnight”); can-roll ON same; unowned exotic **Cerberus+1** (definition-only pool) |
| Integrity | All five PNGs valid `89 50 4E 47…`; unowned ≡ unowned-exotic (intentional same-frame dual use for omit-empty catalyst) |
| Distinct from 001-full | residual owned/can-roll hashes ≠ 001-full (meta geometry re-proof) |

Widget + host smoke cover residual **structure** (22×22 chips, silhouettes, headers, tiers, plugEnhanced map, catalyst omit):

- `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart`
- `flutter/packages/ui_flutter/test/catalog_weapons_widgets_test.dart`
- `flutter/packages/ui_flutter/test/destiny_official_icons_test.dart`
- `flutter/apps/windows_host/test/catalog_weapons_host_smoke_test.dart`
- `flutter/apps/windows_host/test/owned_catalog_bridge_plug_names_test.dart`

## Visual residuals closed vs 001-full (dual-truth)

1. **Meta geometry** — chips are compact square icons in a horizontal strip; full-width bar layout from 001-full is gone in residual re-shots.
2. **Weapon-type silhouettes** — hand cannon / auto rifle official icons on detail meta (and grid cards); letter last-resort retained for unmapped types (structure tests).
3. **③ ON headers** — ellipsis at 400 equal Expanded; no pane widen; no perk-grid horizontal Scrollable (instance strip H-scroll separate + allowed).
4. **Soft catalyst omit-empty** — Cerberus unowned shows intrinsic + possible rolls only; no empty CATALYST panel.
5. **Tier lock** — owned Midnight Coup: Possible rolls OFF → ①+②; ON expands ③ pool. Unowned: ③-only without craft invent.
6. **Outbound** — Set/Synergy disabled stubs + “Outbound create deferred” honesty on unowned exotic.

## Open residuals (feed next `area-ux-redesign`)

Priority for next catalog residual / polish slice (windows weapons):

1. **Live Enhanced gold/E dual-truth** — capture PNG with real enhanced plugs (or host fixture driving `plugEnhancedByHash` true); unit tests alone today.
2. **Soft catalyst display-when-present** — re-shot Ace / Wish-Keeper (or any exotic with catalyst progress fields non-empty); confirm display-only (no equip/save gate).
3. **Unowned / ③ enhance note** — dual-truth shot where `canBeEnhanced` shows the note; not visible on Cerberus residual frame.
4. **Pure All-grid crop** — optional re-shot without detail can-roll density if next redesign needs grid-only ground truth.
5. **Distinct unowned-exotic subject** — stop aliasing Cerberus as both unowned + exotic catalyst scenarios.
6. **Unknown perk cells** — name resolution residual under DBR-UI-006 (live “Unknown perk” on Midnight Coup).
7. **Host smoke enhanced map fixture** — inventory still weak vs widget-test inventory entry.
8. **Instance strip ↔ ①/②/E rebind per copy** — advisory; multi-PL selection does not rebind selected plugs (out of residual gate).
9. **Mobile Catalog push** — deferred; no residual gate until push lands.
10. **Vault residual-polish UX note** — Obsidian `Weapons.md` still pre-residual Can-roll wording when mount available.

## Checklist

- [x] `desktop-grid.png` — MCP Driver (ALL + detail open / can-roll heavy)
- [x] `desktop-detail-owned.png` — MCP Driver (Midnight Coup · Possible rolls OFF · compact meta)
- [x] `desktop-detail-unowned.png` — MCP Driver (Cerberus+1 · ③-only · omit catalyst)
- [x] `desktop-can-roll.png` — MCP Driver (Midnight Coup · Possible rolls ON @400)
- [x] `desktop-detail-unowned-exotic.png` — MCP Driver (same frame as unowned; omit-empty proof)
- [ ] `desktop-enhanced-live.png` (gold+E fixture / real enhanced plugs) — **next pass**
- [ ] `desktop-catalyst-present.png` (exotic with non-empty catalyst fields) — **next pass**
- [ ] `mobile-detail.png` (when mobile Catalog ships)

## Capture how-to

1. Launch host with Driver: MCP `launch_app` → `target=lib/main_mcp.dart`, device `windows`  
   (or short junction `C:\d2f\apps\windows_host` + `flutter run -d windows -t lib/main_mcp.dart` with Driver env)  
2. Connect DTD; `flutter_driver` `get_health`  
3. **`set_frame_sync` → `enabled=false`** before taps  
4. After OAuth/sync, **hot_restart** if Catalog still shows SIGN IN / 0 copies  
5. Drive scenarios; `screenshot` → PNGs here; update matrix  

See `flutter/apps/windows_host/README.md` and `docs/ux-redesign/README.md`.

## Next workflow

```text
/workflow area-ux-redesign {"area":"catalog","subarea":"residual-polish","hosts":["windows"],"slice_goal":"Live Enhanced gold/E dual-truth + soft catalyst display-when-present + unowned enhance-note shot from implementation-shots/001-residual-polish/COMPARE.md; keep 400 pane equal Expanded; no meta geometry reopen","out_of_scope":"Mobile Catalog push, live Set/Synergy outbound, armor optimizer, craft columns invention, vault transfer, pane widen"}
```
