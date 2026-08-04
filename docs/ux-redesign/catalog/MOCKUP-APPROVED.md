# Catalog · Weapons mockup approval

**continue with workflow**

Approved after interactive review of:

- `docs/ux-redesign/catalog/mockups/001-weapons-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-weapons-mobile.html`

## Slice on this gate

**Weapon details** (windows + mobile)  
Out of scope: Armor, Universal, constrained pick, live Set/Synergy outbound

## Locked UX decisions (summary)

### Workspace / cards (prior — still locked)

- Default: **grid of all weapons** (All scope); flat grid by default
- Desktop detail: **full-height sidebar** (~400px)
- Filters: **icon/color** chips; **one primary line** when space allows
- **Can roll**: toggle (off default) — selected plugs only until expanded
- **Possible crafted**: toggle (off default); same column format as Perks
- Mockups = structure SSoT; implement uses **official Destiny icons** (Bungie CDN)

### Weapon details (this slice)

- **Detail meta**: icon-only row — weapon type silhouette, frame, element, slot (K/E/P), ammo; owned as compact ×N (no “Solar / Energy / Primary” text pills; no type text next to type icon)
- **Unowned**: section **POSSIBLE ROLLS** — full definition pools always; no can-roll toggle
- **Owned**: section **PERKS** — selected only until Can roll ON
- **Perk grid**: equal-width columns; **all columns visible without horizontal scroll** (Barrel, Mag, Trait 1/2, **Origin Trait** when present)
- **Perk cells**: icon-first (plug icons when known; letter fallback)
- **Facets**: official element/ammo icons; weapon type icons (destiny-icons / type silhouettes); frame icons when available

Date: 2026-08-04  
Phrase required by workflow gate: continue with workflow  
Slice goal on this resume: **Weapon details**
