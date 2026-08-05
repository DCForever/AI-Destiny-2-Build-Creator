# Implementation shots — catalog / 001-residual-polish

**Date:** 2026-08-04  
**Capture run (perk-chrome re-shot):** background_shell `flutter run -d windows -t lib/main_residual_capture.dart` · DTD + Flutter Driver · `set_frame_sync enabled=false`  
**Hosts:** windows (primary); mobile deferred  
**Brief / approval:** `docs/ux-redesign/catalog/001-residual-polish-brief.md`, `MOCKUP-APPROVED.md`  
**Dual-truth gaps:** [`DUAL-TRUTH-GAPS.md`](../../DUAL-TRUTH-GAPS.md) — **GAP-CAT-PERK-001** / **GAP-CAT-PERK-002** **closed** (structure + category path + post-chrome host-fixture PNGs). **GAP-CAT-PERK-003** open (P1, craft ON dual-truth; `blocks_dual_truth: false`).  
**Mockups (structure SSoT):**

- `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-residual-polish-mobile.html`

**Prior ground truth:** `../001-full/` + that folder’s `COMPARE.md` (live multi-column Midnight Coup still there for equal Expanded @400 archive)

## Purpose

Close five COMPARE residuals from 001-full on **windows weapons** detail chrome, and freeze dual ground truth for the next redesign:

1. **P1 meta** — fixed **22×22** chips · compact horizontal strip (not full-width bars)
2. **Type silhouettes** — official destiny-icons when mapped; letter last-resort + Semantics
3. **③ ON headers** — ellipsis + Tooltip + Semantics @ `kCatalogWeaponsDetailWidth=400`; no pane widen / no perk-grid H-scroll
4. **Enhanced host map** — `windows_host` `plugEnhancedByHash`; gold+E on **①/② only**
5. **Soft catalyst** — omit-when-empty; display-only when present

Plus enhance-note presentation for ③ / unowned / craft (no E cells; one identity) and **perk chrome** (pill+knob toggle · ①/②/③ badges · ② gold chevron · ③ dashed uniform tiles).

## Scenario matrix

| Scenario | Mockup | Shot (this folder) | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop — All grid | `001-residual-polish-desktop.html` | `desktop-grid.png` | Prior live crop (ALL + detail heavy). Optional pure grid re-shot. No residual gate. |
| Desktop — detail owned (①+②, Possible rolls OFF) | same | `desktop-detail-owned.png` | **Host-fixture re-shot (Residual Enhanced HC):** POSSIBLE ROLLS pill+knob **OFF**; band labels ① ON THIS COPY / ② UNSELECTED; ① badge + gold **E** on Enhanced Frenzy; ② badge + gold chevron on Overflow; compact 22×22 meta · ×1 · craft hidden. Proves `toggle-possible-rolls` · `tier-badges-or-bands` · `perk-uniform-tile` · `tier-12-default` · `e-on-12`. |
| Desktop — detail unowned (③-only) | same | `desktop-detail-unowned.png` | Prior live Cerberus+1 unowned ③-only · omit catalyst. Host-fixture enhance-note covers dashed ③ + Can-be-enhanced. |
| Desktop — Possible rolls ON @400 | same | `desktop-can-roll.png` | **Host-fixture re-shot (Residual Enhanced HC · Possible ON):** pill+knob **ON**; legend ①/②/③; dashed muted ③ Rapid Hit; no E on ③; gold E stays on ① only; Can-be-enhanced note. Multi-column equal Expanded @400 still proven by structure tests + `../001-full/desktop-can-roll.png` (live Midnight Coup). |
| Desktop — enhanced live map (gold/E on ①/②) | same | `desktop-enhanced-live.png` | Same frame as owned OFF residual Enhanced HC · `plugEnhancedByHash` / category map · gold+E on ① only. Proves `e-on-12-live-or-fixture` · `plugEnhancedByHash-category` · `no-e-on-3` (pool hidden). |
| Desktop — exotic soft catalyst present | same | `desktop-catalyst-present.png` | Residual Catalyst Exotic · INTRINSIC Memento Mori · **CATALYST** Ace of Spades Catalyst · display-only honesty · no equip/save control. |
| Desktop — unowned enhance note | same | `desktop-enhance-note.png` | Residual Enhance-Note Scout unowned · **Can be enhanced** note · Rapid Hit + Kill Clip as **③ dashed** uniform tiles · no E · legend “③ Possible rolls only”. |
| Desktop — unowned exotic omit-empty | same | `desktop-detail-unowned-exotic.png` | SHA256-alias of prior live Cerberus unowned (omit-empty only). Present path is `desktop-catalyst-present.png`. |
| Mobile — detail | `001-residual-polish-mobile.html` | *(deferred)* | Push deferred — no mobile residual gate this slice. |

## Capture notes

| | |
| --- | --- |
| Launch (this run) | Shell **background:** `C:\d2f\apps\windows_host` (junction → worktree `flutter/`) · `flutter run -d windows -t lib/main_residual_capture.dart` · MCP `launch_app` unavailable |
| Driver | DTD `ws://127.0.0.1:56103/…` · app `ws://127.0.0.1:56104/…` · `get_health` ok · `set_frame_sync enabled=false` · Driver `screenshot` → PNG decode |
| Session | Residual capture signed-in fixture user · OWNED · 1 · 3 catalog seeds |
| Subjects (fixture) | Residual Enhanced HC · Residual Catalyst Exotic · Residual Enhance-Note Scout |
| Subjects (prior live, retained files) | `desktop-grid` / `desktop-detail-unowned*` — Midnight Coup / Cerberus+1 era crops |
| Integrity | Must-row PNGs valid `89 50 4E 47…`; owned ≡ enhanced-live (same OFF frame dual use for tier-12 + e-on-12) |
| Stop | `destiny2_windows_host` + residual `flutter run` killed after capture |

Widget + host smoke cover residual **structure** (22×22 chips, silhouettes, headers, tiers, plugEnhanced map, catalyst omit/present, enhance note, perk chrome):

- `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart`
- `flutter/packages/ui_flutter/test/catalog_weapons_widgets_test.dart`
- `flutter/packages/ui_flutter/test/destiny_official_icons_test.dart`
- `flutter/apps/windows_host/test/catalog_weapons_host_smoke_test.dart` (incl. residual-polish host fixtures group)
- `flutter/apps/windows_host/test/owned_catalog_bridge_plug_names_test.dart`
- **Host-fixture seeds:** `flutter/apps/windows_host/test/catalog_residual_polish_fixtures.dart`
- **Driver capture entry:** `flutter/apps/windows_host/lib/main_residual_capture.dart`

### Host fixtures for Capture (`drive: host-fixture`)

| Matrix id | Seed | How to drive |
| --- | --- | --- |
| `desktop-enhanced-live` / owned OFF | hash 91001 + socket ①=`801` + map `{801: true}` | `main_residual_capture` → tap Residual Enhanced HC · Possible OFF |
| `desktop-can-roll` | same + randomized pool | tap Possible rolls toggle ON (`catalog_toggle_can_roll`) |
| `desktop-catalyst-present` | hash 91002 + non-empty `catalystName` | tap Residual Catalyst Exotic |
| `desktop-enhance-note` | hash 91003 + Enhanced identity in pool | tap Residual Enhance-Note Scout |

## Visual residuals closed vs 001-full (dual-truth)

1. **Meta geometry** — chips are compact square icons in a horizontal strip; full-width bar layout from 001-full is gone.
2. **Weapon-type silhouettes** — hand cannon / scout official icons on detail meta (and grid cards); letter last-resort retained for unmapped types (structure tests).
3. **③ ON headers** — ellipsis at 400 equal Expanded; no pane widen; no perk-grid horizontal Scrollable (structure + 001-full multi-col archive).
4. **Soft catalyst omit-empty** — Cerberus unowned shows intrinsic + possible rolls only; no empty CATALYST panel.
5. **Soft catalyst display-when-present** — fixture exotic shows CATALYST name + display-only honesty.
6. **Enhanced gold/E on ①/② only** — fixture owned HC shows E on Enhanced Frenzy only; Overflow unmarked; pool ③ never E.
7. **Enhance note (unowned/③)** — fixture scout shows note + one cell identity; dashed ③ tiles; no E on pool.
8. **Tier lock** — owned fixture: Possible rolls OFF → ①+②; ON expands ③ pool. Unowned: ③-only without craft invent.
9. **Outbound** — Set/Synergy disabled stubs + “Outbound create deferred” honesty.
10. **Perk chrome (GAP-CAT-PERK-001)** — pill+knob Possible rolls (not FilterChip); ①/②/③ badges; ② gold chevron; ③ dashed muted; uniform minHeight; band labels + legend.

## Perk chrome + enhanced path close (2026-08-04)

| Token | Ship proof |
| --- | --- |
| `toggle-possible-rolls` | `_CatalogViewToggle` pill+knob · `Semantics(toggled:)` · key `catalog_toggle_can_roll` · PNGs owned OFF / can-roll ON |
| `tier-badges-or-bands` | ①/②/③ corner badges · band labels · legend — visible on owned / can-roll / enhance-note PNGs |
| `perk-uniform-tile` | `kCatalogPerkCellMinHeight=48` + structure tests |
| `possible-dashed-muted` | ③ Rapid Hit / unowned Rapid Hit+Kill Clip dashed cells in can-roll + enhance-note PNGs |
| `e-on-12-live-or-fixture` | gold/E on ① Enhanced Frenzy only in owned / enhanced-live / can-roll PNGs |
| `no-e-on-3` | pool Rapid Hit and unowned pool cells have no E mark |
| `plugEnhancedByHash-category` | `buildPlugEnhancedMapFromItemDefs` + host `plugEnhancedMapBuilder` via inventorySync · fixture map `{801:true}` |

**Code:** `catalog_weapon_detail.dart`, `roll_tag_lookups.dart`, `OwnedCatalogBridge`, `roll_tag_lookup_provider.dart`, `inventory_sync_controller.dart`, `host_bootstrap.dart`  
**Tests:** `catalog_weapon_detail_test.dart`, `roll_tags_test.dart`, `classify_weapon_socket_test.dart`, `owned_catalog_bridge_plug_names_test.dart`, `catalog_weapons_host_smoke_test.dart`  
**Fixtures:** `catalog_residual_polish_fixtures.dart` · capture entry `main_residual_capture.dart`

## Open residuals (feed next `area-ux-redesign`)

1. **GAP-CAT-PERK-003** — craftAvailable ON dual-truth (toggle chrome shared; need craft fixture Capture).
2. **Pure All-grid crop** — optional re-shot without detail density if next redesign needs grid-only ground truth.
3. **Distinct unowned-exotic subject** — stop aliasing Cerberus as both unowned + exotic omit-empty in live shots (fixture present covers catalyst).
4. **Unknown perk cells** — name resolution residual under DBR-UI-006 (live-era “Unknown perk” on Midnight Coup).
5. **Instance strip ↔ ①/②/E rebind per copy** — advisory; multi-PL selection does not rebind selected plugs (out of residual gate).
6. **Mobile Catalog push** — deferred; no residual gate until push lands.
7. **Vault residual-polish UX note** — Obsidian `Weapons.md` still pre-residual Can-roll wording when mount available.
8. **Live inventory enhanced/catalyst subjects** — dual-truth proven via host-fixture harness; optional live Ace/enhanced re-shot when OAuth+sync available (main_mcp had no stored tokens this session).
9. **Multi-column equal Expanded visual** — residual re-shots are single-trait fixtures; multi-col archive remains `../001-full/desktop-can-roll.png` + structure tests @400.

## Checklist

- [x] `desktop-grid.png` — prior live (ALL / detail-heavy)
- [x] `desktop-detail-owned.png` — residual fixture · Possible OFF · ①+② badges · pill toggle · gold E
- [x] `desktop-detail-unowned.png` — prior live Cerberus ③-only
- [x] `desktop-can-roll.png` — residual fixture · Possible ON · dashed ③ · no E on pool
- [x] `desktop-detail-unowned-exotic.png` — prior live omit-empty alias
- [x] `desktop-enhanced-live.png` — residual fixture gold+E ① only
- [x] `desktop-catalyst-present.png` — residual fixture catalyst display-only
- [x] `desktop-enhance-note.png` — residual fixture note + dashed ③ · no E
- [ ] `mobile-detail.png` (when mobile Catalog ships)

## Capture how-to

1. **Live inventory rows:** MCP `launch_app` → `target=lib/main_mcp.dart`, device `windows`  
   (or shell `flutter run -d windows -t lib/main_mcp.dart` — do **not** also pass `ENABLE_FLUTTER_DRIVER` with `main_mcp` or Driver double-init crashes)
2. **Host-fixture rows:** `flutter run -d windows -t lib/main_residual_capture.dart` (background_shell for agents)
3. Connect DTD; `flutter_driver` `get_health`
4. **`set_frame_sync` → `enabled=false`** before taps
5. Drive scenarios; `screenshot` → PNGs here; update matrix

See `flutter/apps/windows_host/README.md` and `docs/ux-redesign/README.md`.

## Next workflow

```text
/workflow area-ux-redesign {"area":"catalog","subarea":"residual-polish","hosts":["windows"],"slice_goal":"Optional craftAvailable ON dual-truth (GAP-CAT-PERK-003) + pure All-grid crop + live Unknown-perk name resolve (DBR-UI-006); keep 400 pane equal Expanded; no meta geometry reopen","out_of_scope":"Mobile Catalog push, live Set/Synergy outbound, armor optimizer, craft columns invention, vault transfer, pane widen"}
```
