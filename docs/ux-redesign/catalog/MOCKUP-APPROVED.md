# Mockup approvals — Catalog UX

## CatalogNestedGroupBy (005) — current gate

**continue with workflow**

- Desktop: `docs/ux-redesign/catalog/mockups/005-catalog-nested-groupby-desktop.html`
- Mobile: `docs/ux-redesign/catalog/mockups/005-catalog-nested-groupby-mobile.html`
- Approved: 2026-08-08 (human mockup gate + chat revisions)
- Brief: `docs/ux-redesign/catalog/005-catalog-nested-groupby-brief.md`
- System: DART-072 `groupCatalogItemsNested` + collapse helpers (landed `e711190`)
- Track: UX-CATALOG-NESTED-GROUP / GAP-UI-CATALOG-11 Track B

### Locked visual / interaction notes (from mock review)

1. **Nested path headers** — segment label only (not flat `A · B · C`); depth indent; rollup count; residual uppercase + mono count + accent chevron.
2. **Collapse** — path-key set, view-only (BR-CAT-007); parent collapse hides full subtree; never rewrites filters (BR-CAT-006).
3. **JUMP** — rail (desktop) / sticky strip (mobile) when ≥2 top-level groups; expand ancestors + scroll; **re-click open path collapses**; never filters.
4. **Scroll spy** — board scroll updates outline `aria-current` / active highlight to the group near the top of the viewport.
5. **Icons when applicable** — official element/ammo CDN; weapon-type silhouettes; slot K/E/P residual glyphs; frame/class text-only until official maps exist.
6. **Path keys (implement)** — use DART-072 `catalogGroupPathSeparator` (` · `), not mock display ` › `.
7. **1-dim** — flat headers + flat JUMP (no nested chrome); empty/loading — no group chrome.

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
