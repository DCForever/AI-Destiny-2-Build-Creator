# Implementation shots — {{area}} / {{slice-id}}

**Date:** YYYY-MM-DD  
**Hosts:** windows / mobile  
**Brief:** `docs/ux-redesign/{{area}}/…-brief.md`  
**Mockups (structure SSoT):**  

- `docs/ux-redesign/{{area}}/mockups/…-desktop.html`
- `docs/ux-redesign/{{area}}/mockups/…-mobile.html`

## Purpose

Ground truth for the **next** `area-ux-redesign` round: compare approved mockup structure to the **shipped** Flutter UI. Do not invent product rules from screenshots alone; use shots to prioritize residual UX gaps.

## Scenario matrix

| Scenario | Mockup | Shot (this folder) | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop — grid / browse | `mockups/…-desktop.html` | `desktop-grid.png` | |
| Desktop — detail owned (selected plugs) | same | `desktop-detail-owned.png` | |
| Desktop — detail unowned (POSSIBLE ROLLS) | same | `desktop-detail-unowned.png` | |
| Desktop — can-roll ON | same | `desktop-can-roll.png` | |
| Desktop — empty / signed-out (if relevant) | same | `desktop-empty-or-signed-out.png` | |
| Mobile — list / detail push (if in slice) | `mockups/…-mobile.html` | `mobile-detail.png` | |

Add or drop rows to match the slice’s mockup state matrix.

## Capture notes

- Prefer real app (not mock HTML) on the target host.
- Official Bungie icons/colors in product; mockups remain structure-only.
- If a shot is missing, leave path blank and list under **Human capture still needed**.

## Human capture still needed

- [ ] …

## Next workflow

```text
/workflow area-ux-redesign {"area":"{{area}}","subarea":"…","slice_goal":"… residuals from COMPARE.md"}
```
