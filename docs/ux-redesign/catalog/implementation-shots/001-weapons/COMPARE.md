# Implementation shots — catalog / 001-weapons

**Date:** 2026-08-04  
**Capture run:** MCP Driver after OAuth sign-in + inventory sync (membership `4096024`, 1377 items)  
**Hosts:** windows (primary); mobile deferred for push-detail  
**Brief / approval:** `docs/ux-redesign/catalog/001-weapons-brief.md`, `MOCKUP-APPROVED.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/catalog/mockups/001-weapons-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-weapons-mobile.html`

## Purpose

Ground truth for the **next** catalog weapons UX round: mockup structure vs **shipped** Flutter Catalog.

## Scenario matrix

| Scenario | Mockup | Shot (this folder) | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop — All grid | `mockups/001-weapons-desktop.html` | `desktop-grid.png` | Facet icons good; post-sign-in prefer OWNED · N over SIGN IN |
| Desktop — detail owned (PERKS, can-roll off) | same | `desktop-detail-owned.png` | **Icon-only meta incomplete** (text subtitle + KINETIC/OWNED chips); selected plugs + icons OK; **Origin Trait present** (Elliptical Orbit in tree; may sit below fold); instance strip + Can roll OFF |
| Desktop — detail unowned (POSSIBLE ROLLS) | same | `desktop-detail-unowned.png` (+ exotic alias) | POSSIBLE ROLLS + named perks (Hung Jury); meta still text; Origin column absent on definition-only legendary; exotic Unknown perk residual |
| Desktop — can-roll ON | same | `desktop-can-roll.png` | Expanded pool (~81 cells); **column H-scroll / fixed-width risk** vs mock equal-flex no H-scroll; Origin Trait column when data present |
| Desktop — owned multi-instance strip | same | `desktop-instance-strip.png` (same frame as owned: 5× PL 550) | Strip chips present; polish vs mock density/selection chrome |
| Desktop — empty owned / missing manifest | same | *(not captured)* | Optional |
| Mobile — detail (when push lands) | `mockups/001-weapons-mobile.html` | *(deferred)* | Push deferred by design |

## Capture notes (this run)

| | |
| --- | --- |
| Launch | Shell: `C:\d2f\apps\windows_host\run-windows.ps1 -EnableFlutterDriver` (MCP session has no `launch_app`) |
| Driver | `set_frame_sync enabled=false` required before taps |
| Session | Signed in after first pass; hot_restart so Catalog rebind OWNED · 790 / 1377 copies |
| Subjects | Grid: exotic ALL; unowned: **Hung Jury SR4**; owned/can-roll/strip: **Chattering Bone** ×5 with socket_plugs |

## Visual residuals (mockup vs shots)

1. **Meta strip** — Mockup: icon-only type / frame / element / slot / ammo. **Shipped:** `Pulse Rifle · Lightweight Frame · Kinetic` text + chips; not icon-only.
2. **Origin Trait** — **Owned** Chattering Bone: ORIGIN TRAIT Elliptical Orbit in widget tree. **Unowned** Hung Jury: no Origin column in shot. Wire/show consistently when definition has origin.
3. **Equal-width columns / no H-scroll** — Selected-only (can-roll off) looks compact; can-roll ON expands heavily — residual vs mock flex equal columns without horizontal scroll.
4. **POSSIBLE ROLLS / PERKS** — Labels correct for unowned vs owned.
5. **Perk icons** — Present for legendary pools and owned selected plugs.
6. **Instance strip** — 5 PL chips for Chattering Bone; multi-copy card badge ×5 on grid.
7. **Can roll** — OFF by default; ON merges definition pool (many cells).

## Capture how-to (required: Flutter MCP + Driver)

1. Launch host with Driver: MCP `launch_app` → `target=lib/main_mcp.dart`, device `windows`  
   (or `.\run-windows.ps1 -EnableFlutterDriver` from short junction `C:\d2f\apps\windows_host`)  
2. Connect DTD; `flutter_driver` `get_health`  
3. **`set_frame_sync` → `enabled=false`** before taps  
4. After OAuth/sync, **hot_restart** if Catalog still shows SIGN IN / 0 copies  
5. Drive scenarios; `screenshot` → PNGs here; update matrix  

See `flutter/apps/windows_host/README.md` and `docs/ux-redesign/README.md`.

## Checklist

- [x] `desktop-grid.png` — MCP Driver  
- [x] `desktop-detail-owned.png` — MCP Driver (Chattering Bone, can-roll off)  
- [x] `desktop-detail-unowned.png` — MCP Driver (Hung Jury SR4)  
- [x] `desktop-detail-unowned-exotic.png` — MCP Driver (Unknown perk residual)  
- [x] `desktop-can-roll.png` — MCP Driver (can-roll ON, expanded pool)  
- [x] `desktop-instance-strip.png` — MCP Driver (×5 instances)  
- [ ] `desktop-empty.png` (optional)  
- [ ] `mobile-detail.png` (when mobile Catalog ships)  

## Next workflow

```text
/workflow area-ux-redesign {"area":"catalog","subarea":"weapons","hosts":["windows","mobile"],"slice_goal":"Weapon details residuals from implementation-shots/001-weapons/COMPARE.md — icon-only meta, Origin Trait consistency, equal-width no H-scroll under can-roll","out_of_scope":"Armor, Universal, constrained pick, live Set/Synergy outbound"}
```
