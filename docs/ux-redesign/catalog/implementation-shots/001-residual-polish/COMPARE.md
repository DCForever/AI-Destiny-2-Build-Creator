# Implementation shots — catalog / 001-residual-polish

**Date:** 2026-08-04  
**Capture run:** MCP Flutter Driver — live-inventory (prior) + host-fixture via `lib/main_residual_capture.dart` shell fallback (`launch_app` unavailable this session)  
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
| Desktop — All grid | `001-residual-polish-desktop.html` | `desktop-grid.png` | Scope **ALL** + OWNED · 790 · facet chrome OK. Frame is **detail+can-roll heavy** (Midnight Coup open, Possible rolls ON) — not a pure grid-only crop. No residual gate. |
| Desktop — detail owned (①+②, Possible rolls OFF) | same | `desktop-detail-owned.png` | **Meta P1 closed:** compact horizontal 22×22 chips (hand-cannon silhouette · frame · element · K · ammo · ×1) — not full-width bars (contrast `001-full/desktop-detail-owned.png`). Type silhouette present. Origin Trait column when data. Craft hidden. Tier lock: ①+② · Possible rolls OFF. Live **Unknown perk** cell (name resolve residual under DBR-UI-006). No gold/E on this copy. |
| Desktop — detail unowned (③-only) | same | `desktop-detail-unowned.png` | Cerberus+1 exotic unowned: compact meta · no ×N · honesty line · POSSIBLE ROLLS ③-only · Set/Synergy disabled stubs. Catalyst panel omitted (empty). Live unowned did not surface enhance note (host-fixture `desktop-enhance-note` closes that dual-truth). |
| Desktop — Possible rolls ON @400 | same | `desktop-can-roll.png` | Equal-width Expanded columns; no perk-grid H-scroll at 400. Headers ellipsis (`MASTERWO…` / `ORIGIN TR…`); Tooltip+Semantics covered by widget tests (not visible in PNG). No E on ③ pool cells. |
| Desktop — enhanced live map (gold+E on ①/②) | same | `desktop-enhanced-live.png` | **Host fixture closed:** `main_residual_capture.dart` + `plugEnhancedByHash` → gold border + **E** on ① Enhanced Frenzy only; ② Overflow unmarked. Possible rolls OFF default. Proves e-on-12-only / plugEnhancedByHash. |
| Desktop — exotic soft catalyst present | same | `desktop-catalyst-present.png` | **Host fixture closed:** Residual Catalyst Exotic shows INTRINSIC + **CATALYST** “Ace of Spades Catalyst” + “Display only — does not gate equip or save”. No equip/save control. |
| Desktop — unowned enhance note | same | `desktop-enhance-note.png` | **Host fixture closed:** Residual Enhance-Note Scout unowned ③-only with **Can be enhanced** note; Rapid Hit + Kill Clip as one-cell family; **no E** marks on pool cells. |
| Desktop — unowned exotic omit-empty | same | `desktop-detail-unowned-exotic.png` | **SHA256 identical to** `desktop-detail-unowned.png` (same Cerberus+1 frame). Proves **omit-when-empty** only; display-when-present is `desktop-catalyst-present.png`. |
| Mobile — detail | `001-residual-polish-mobile.html` | *(deferred)* | Push deferred by design — no mobile residual gate this slice. |

## Capture notes

| | |
| --- | --- |
| Launch (live) | Shell: `C:\d2f\apps\windows_host` + `flutter run -d windows -t lib/main_mcp.dart` (MCP `launch_app` / `list_devices` / `stop_app` unavailable this session) |
| Launch (host-fixture) | Shell: `flutter run -d windows -t lib/main_residual_capture.dart` — residual seeds + `OwnedCatalogBridge(plugEnhancedByHash: …)` |
| Driver | DTD connected · `set_frame_sync enabled=false` before taps · `flutter_driver` `screenshot` |
| Session (live) | Local inventory present (**OWNED · 790** / 1377 copies); LIVE status |
| Session (fixture) | Signed-in residual capture user; 3 fixture weapons; OWNED · 1 |
| Subjects (live) | Grid ALL exotics; owned **Midnight Coup** ×1; can-roll ON same; unowned exotic **Cerberus+1** |
| Subjects (fixture) | Residual Enhanced HC · Residual Catalyst Exotic · Residual Enhance-Note Scout |
| Integrity | All matrix PNGs valid `89 50 4E 47…`; unowned ≡ unowned-exotic (omit-empty dual use) |
| Distinct from 001-full | residual owned/can-roll hashes ≠ 001-full (meta geometry re-proof) |

Widget + host smoke cover residual **structure** (22×22 chips, silhouettes, headers, tiers, plugEnhanced map, catalyst omit/present, enhance note):

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
| `desktop-enhanced-live` | hash 91001 + socket ①=`801` + map `{801: true}` | `main_residual_capture` → tap Residual Enhanced HC |
| `desktop-catalyst-present` | hash 91002 + non-empty `catalystName` | tap Residual Catalyst Exotic |
| `desktop-enhance-note` | hash 91003 + Enhanced identity in pool | tap Residual Enhance-Note Scout |

## Visual residuals closed vs 001-full (dual-truth)

1. **Meta geometry** — chips are compact square icons in a horizontal strip; full-width bar layout from 001-full is gone in residual re-shots.
2. **Weapon-type silhouettes** — hand cannon / auto rifle / scout official icons on detail meta (and grid cards); letter last-resort retained for unmapped types (structure tests).
3. **③ ON headers** — ellipsis at 400 equal Expanded; no pane widen; no perk-grid horizontal Scrollable (instance strip H-scroll separate + allowed).
4. **Soft catalyst omit-empty** — Cerberus unowned shows intrinsic + possible rolls only; no empty CATALYST panel.
5. **Soft catalyst display-when-present** — fixture exotic shows CATALYST name + display-only honesty.
6. **Enhanced gold/E on ①/② only** — fixture owned HC shows E on Enhanced Frenzy only; Overflow unmarked.
7. **Enhance note (unowned/③)** — fixture scout shows note + one cell identity; no E on pool.
8. **Tier lock** — owned Midnight Coup: Possible rolls OFF → ①+②; ON expands ③ pool. Unowned: ③-only without craft invent.
9. **Outbound** — Set/Synergy disabled stubs + “Outbound create deferred” honesty.

## Open residuals (feed next `area-ux-redesign`)

Priority for next catalog residual / polish slice (windows weapons):

1. **Pure All-grid crop** — optional re-shot without detail can-roll density if next redesign needs grid-only ground truth.
2. **Distinct unowned-exotic subject** — stop aliasing Cerberus as both unowned + exotic catalyst omit-empty scenarios in live shots (fixture subject covers present).
3. **Unknown perk cells** — name resolution residual under DBR-UI-006 (live “Unknown perk” on Midnight Coup).
4. **Instance strip ↔ ①/②/E rebind per copy** — advisory; multi-PL selection does not rebind selected plugs (out of residual gate).
5. **Mobile Catalog push** — deferred; no residual gate until push lands.
6. **Vault residual-polish UX note** — Obsidian `Weapons.md` still pre-residual Can-roll wording when mount available.
7. **Live inventory enhanced/catalyst subjects** — dual-truth proven via host-fixture harness; optional live Ace/enhanced re-shot when plug names resolve.

## Checklist

- [x] `desktop-grid.png` — MCP Driver (ALL + detail open / can-roll heavy)
- [x] `desktop-detail-owned.png` — MCP Driver (Midnight Coup · Possible rolls OFF · compact meta)
- [x] `desktop-detail-unowned.png` — MCP Driver (Cerberus+1 · ③-only · omit catalyst)
- [x] `desktop-can-roll.png` — MCP Driver (Midnight Coup · Possible rolls ON @400)
- [x] `desktop-detail-unowned-exotic.png` — MCP Driver (same frame as unowned; omit-empty proof)
- [x] `desktop-enhanced-live.png` — host-fixture Driver (`main_residual_capture` · gold+E ① only)
- [x] `desktop-catalyst-present.png` — host-fixture Driver (catalyst display-only)
- [x] `desktop-enhance-note.png` — host-fixture Driver (Can be enhanced note · no E cells)
- [ ] `mobile-detail.png` (when mobile Catalog ships)

## Capture how-to

1. **Live inventory rows:** MCP `launch_app` → `target=lib/main_mcp.dart`, device `windows`  
   (or shell `flutter run -d windows -t lib/main_mcp.dart` — do **not** also pass `ENABLE_FLUTTER_DRIVER` with `main_mcp` or Driver double-init crashes)
2. **Host-fixture rows:** `flutter run -d windows -t lib/main_residual_capture.dart`
3. Connect DTD; `flutter_driver` `get_health`
4. **`set_frame_sync` → `enabled=false`** before taps
5. Drive scenarios; `screenshot` → PNGs here; update matrix

See `flutter/apps/windows_host/README.md` and `docs/ux-redesign/README.md`.

## Next workflow

```text
/workflow area-ux-redesign {"area":"catalog","subarea":"residual-polish","hosts":["windows"],"slice_goal":"Optional pure All-grid crop + live Unknown-perk name resolve (DBR-UI-006) + instance strip ①/②/E rebind advisory from implementation-shots/001-residual-polish/COMPARE.md; keep 400 pane equal Expanded; no meta geometry reopen","out_of_scope":"Mobile Catalog push, live Set/Synergy outbound, armor optimizer, craft columns invention, vault transfer, pane widen"}
```
