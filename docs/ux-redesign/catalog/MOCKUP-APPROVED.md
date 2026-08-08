# Mockup approvals — Catalog UX

## EntityInfoHotspot (004) — current gate

**continue with workflow**

- Desktop: `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-mobile.html`
- Approved: 2026-08-08 (human review + interaction lock)
- Brief: `docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md`

### Locked interaction notes
- **Desktop:** hover/focus → full entity info Flap; **click = primary** (select / roll-target cycle) — never opens or pins info.
- **Mobile:** **tap = primary** select; **long-press (≥450ms)** or **Alt+tap** → info sheet (same content model as desktop hover).
- Info body only from host `EntityPresentation` (DART-071); never invent Destiny text.
- Honest empty: fixed **`No catalog description`**.
- Residual perk cell chrome locked (①/②/③ · gold/E · equal @400 · no H-scroll).
- **Out of this gate:** stationary multi-perk inspect sheet on mobile (browse-while-inspect residual — not this brief).

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
