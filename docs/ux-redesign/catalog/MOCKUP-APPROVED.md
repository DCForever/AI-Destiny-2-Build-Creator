# Catalog · Full residual pass — mockup approval

**continue with workflow**

Approved after interactive review of:

- `docs/ux-redesign/catalog/mockups/001-full-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-full-mobile.html`

**Workflow:** `area-ux-redesign-6`  
**Date:** 2026-08-04  
**Dual ground truth:** implementation-shots/001-weapons + COMPARE residuals + DIM reference

---

## Slice on this gate

**Full Catalog residual pass** (windows + mobile)  
Out of scope: constrained pick, live Set/Synergy outbound, new design system

## Locked UX decisions

### Perk detail — three tiers + enhanced

| Tier | Name | Meaning | Visual |
| --- | --- | --- | --- |
| **①** | **Selected** | On this owned instance | Blue fill, badge `1` |
| **②** | **Unselected** | Other options on this owned instance | Solid + gold chevron, badge `2` |
| **③** | **Possible rolls** | Weapon definition can-roll pool | Dashed muted, badge `3` |
| **E** | **Enhanced** | Enhanced variant (any of ①/②/③) | Gold ring + **E** mark |

### Rules

- **Owned default:** ① + ② only; **③ hidden**
- **Owned + “Possible rolls” toggle ON:** show ③ (toggle **off by default**)
- **Unowned:** section Possible rolls — **③ only** (no toggle)
- **Enhanced** orthogonal to tier — any legendary plug can be enhanced
- Origin column only when data exists
- Equal-width columns; no H-scroll at ~400px detail
- Icon-only meta strip (type · frame · element · slot · ammo + ×N)
- Stub outbound Set/Synergy only
- Craft toggle only when craft data exists
- Mock structure SSoT; implement uses official Destiny icons

Phrase required by workflow gate: continue with workflow
