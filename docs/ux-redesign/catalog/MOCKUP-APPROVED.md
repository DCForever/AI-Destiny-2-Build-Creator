# Mockup approvals — Catalog UX

## EntityInfoHotspot (004) — current gate

**continue with workflow**

- Desktop: `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-mobile.html`
- Brief: `docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md` (locked 2026-08-08)
- Approved: 2026-08-08 (plan-approved implement)

### Locked visual notes
- Residual **CatalogPerkCell** hosts 1+3 info; detail width ~400 unchanged.
- **Desktop:** hover/focus → portaled L2 Flap (~280px) above detail clip; leave / Esc dismisses.
- **Mobile:** long-press → modal sheet + scrim; tap = primary only.
- **Click/tap never opens info** (no pin-on-click); primary = select / roll-target cycle.
- Body only from host/fixture presentation map; null/blank → fixed **No catalog description**.
- Hash never primary label; optional hash footer only.
- Residual perk chrome locked (①/②/③ · gold/E · enhance note · equal @400 · no H-scroll).
- Base vs enhanced compare in L2 only when both descs supplied; no E on ③/craft.
- Single-open stack (open B closes A).

---

## CatalogFilterCollections (004) — prior (landed on main)

**continue with workflow**

- Desktop: `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-mobile.html`
- Approved: 2026-08-08 (“continue with workflow”)
- System + chrome: filter collections soft apply · per mode · replace-by-name · cap 20

### Locked visual / product notes
- Filter-band trailing cluster: **Saved → More → Reset** (28px height language, 1px line, r2, Orbitron/mono labels).
- Desktop: dropdown menu under Saved (viewport-clamped). Mobile: bottom sheet (structure-first; not Windows exit gate).
- Soft apply only: host binds `CatalogClientFilters` (+ sort/group via separate host state); **never invent catalog rows** (BR-CAT-006).
- Collections listed **per browse mode**; replace-by-name; soft max **20** per user+mode.
- Dirty: cyan dot when live criteria diverge from active collection.
- Applied: trigger may show collection name; empty/signed-out honesty.
- Save only when criteria ≠ empty defaults (scope all + empty query/facets/exotic/sort/group).

---

## CatalogRollTargets (003) — prior

**continue with workflow** (historical)

- Desktop: `docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-mobile.html`
- Approved: 2026-08-07 (“looks good”)

### Locked visual notes
- Lives on standard **CatalogWeaponDetail** (~400) — not a separate screen.
- **View mode only:** active roll target paints soft **diagonal** wash on can-roll pool cells (lower-right → upper-left, reaches lower-left): **green** = ideal/preferred, **red** = avoid; wash **behind** perk icon.
- **Edit mode:** Want|Avoid|Off via W/A badges only — no diagonal wash.
- Instance strip: dual segs `N/M` + `Av k` when active target scores; base chip power · T{tier} · special unchanged.
- Soft scores only; ≠ equip-ready wishlist; no dismantle CTA.

---

## WeaponInstanceStrip (002) — prior

**continue with workflow** (historical)

- Desktop: `docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-mobile.html`
- Approved: 2026-08-06

### Locked decisions
1. Chip label: **`{power} T{tier} {special?}`** (e.g. `335 T3 Adept`) — no MW/Craft on chip.
2. Segmented readability: bold power · tier plate · special color (Adept gold / Holofoil violet).
3. Layout: **multi-row wrap** (`flex-wrap`) preferred over horizontal scroll at detail width.
4. Power-desc order · highest default selected · empty honesty preserved.
5. Specialness only when the copy is special (Adept, Holofoil, …).
