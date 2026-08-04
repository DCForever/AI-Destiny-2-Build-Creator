# Catalog · Weapons — grill answers (Human gate)

**Date:** 2026-08-03  
**Source:** User feedback at area-ux-redesign Human gate  
**Status:** **Approved** — user said `continue with workflow` (2026-08-03). See `MOCKUP-APPROVED.md`.

## Review protocol (owner)

- Feedback in chat → UX evaluates → mockups updated → re-review  
- Do **not** resume the workflow for ordinary feedback  
- Approve only with: **continue with workflow** + `MOCKUP-APPROVED.md`

## Locked UX decisions (so far; still open to revision)

| Topic | Decision |
| --- | --- |
| Default results chrome | **Grid of all weapons** (All / manifest+owned identities by default; flat grid, not dense board rows) |
| Detail | **Sidebar** on desktop (opens when a card is selected) |
| Filters | Prefer **color + icons** when available to reduce chrome size; text labels via tooltip/aria; frames may keep short text |
| Filter layout | **Single line** of primary facet groups when width allows (wrap only when narrow); More expands secondary |
| Detail sidebar | **Full height** of the shell (beside main column, not only beside the grid under chrome) |
| Default group-by | **Flat grid** (group by slot optional under More) |
| Can roll | **Toggle** (off by default): selected plugs only until toggled; then show can-roll pool per column |
| Possible crafted | **Toggle** (off by default). When shown, uses the **same column/cell format as Perks** (barrel/mag/traits), not a bullet list. No duplicate current-craft list. |
| Exotic intrinsic | **Separate** from roll perk columns; shown under **Exotic identity** next to **Catalyst** (fixed trait + catalyst status/plug). |
| Craftable exotics | Craftable is not legendary-only. Craftable exotic may have both possible crafted **and** catalyst independently (DO-WPN-052–054). |
| Card body text | Weapon **type only** — no element/slot/ammo/frame in description |
| Card icons | Element BL bloom+glyph; foot slot/ammo/frame; rarity TR badge; icons &gt; text |
| Hue split | Legendary = warm grape (right); Void = cool violet `❖` (BL); Heavy = gold `▲`; Power `P` = steel-gold (not void) |
| Card density | Compact: desktop ~156×112 min; mobile ~108px tall |

## Mobile

- Same **icon grid** for weapons.
- Detail remains **full-screen push** (no lasting dual-pane on phone); back returns to grid.

## Still open (if needed later)

- Default scope Owned vs All when signed-in+synced (user said “all the weapons” → **All** as default)
- Stub outbound placement (detail-only assumed until stated otherwise)
- Reverse synergies density in slice 1

## Mockups

- `docs/ux-redesign/catalog/mockups/001-weapons-desktop.html` — revised
- `docs/ux-redesign/catalog/mockups/001-weapons-mobile.html` — revised
