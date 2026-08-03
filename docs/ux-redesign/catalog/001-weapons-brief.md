# UX brief: catalog / weapons

**Status:** locked  
**Date:** 2026-08-03  
**Hosts:** windows (first exit); mobile deferred for push-detail parity  
**Slice goal:** Weapons browse + detail (owned + manifest) as composition aid: icon grid, multi-facet filter, full-height detail sidebar with selected / can-roll / craft toggles  
**Out of scope:** Armor/Universal tabs; constrained Set/Build pick embeds; live Set/Synergy outbound as MVP gate; Catalog-local Set/Synergy editors; Build kit attach; Peggy; vault transfer/notes/lock; bare hashes as primary UI; catalyst/deepsight gates; invented pools/craft/sources; mobile dual-pane parity this slice  

## Product posture

- **Job:** Find weapon identities and owned copies; inspect rolls for composition (sets/fill later).  
- **Not for:** Product home, vault transfer, build-identity editing, live Set/Synergy create this slice.  
- **Rule IDs:** DBR-PUR-002, DBR-ROLL-001/007/008/010, DBR-UI-001/005/006/007, BR-CAT-001/002/004/005/006/007/008/016c, BR-UI-002/003, DAC-NME-003/004, DAC-CAT-003, DO-WPN-001/010/029/052+  

## Locked decisions (from grill + MOCKUP-APPROVED)

| Topic | Decision |
| --- | --- |
| Role | Composition aid only — not Catalog-as-home |
| Default scope | **All** / manifest; Owned explicit; signed-out never fakes owned |
| Results | **Identity-primary icon grid**; flat by default |
| Default sort | slot → exotic → ammo → archetype; instances power-desc |
| Desktop layout | Main grid + **full-height detail sidebar** (~400px) |
| Mobile (later) | Single-pane list/grid → detail push |
| Filters | Icon/color chips; **one primary line** when space allows + More; OR within / AND across / exclude drop + free-text AND |
| Can roll | Toggle **OFF** default; selected plugs only until on |
| Possible crafted | Toggle **OFF** default; **same column/cell format as Perks**; no duplicate current-craft list |
| Exotic | **Intrinsic** separate, near **Catalyst**; craftable exotic + catalyst independent; soft-only catalyst |
| Outbound | Set/Synergy **disabled stubs** only |
| Implementation posture | Re-skin/reuse Windows catalog semantics; extract god page; pure filter/sort in packages |

## Surfaces

`shell.nav.catalog`, `flow.catalog.weapons`, `catalog.composition-aid`, `catalog.signed-out.weapons`, `catalog.weapons.owned`, `catalog.weapons.manifest`, `catalog.weapons.filters` (+ text/element/ammo/archetype/slot), `catalog.weapons.list`, `catalog.weapon.detail`, `catalog.weapons.perk-grid`, `catalog.filters.open`

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/001-weapons-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-weapons-mobile.html`
- Approval: `docs/ux-redesign/catalog/MOCKUP-APPROVED.md`

## Obsidian

- Target: `requirements/Projects/Destiny 2 Build Creator/UX/UX Catalog — Weapons.md`
- Link from `Areas/Area Catalog.md` Experience section

## Architect notes (from workflow)

### Package placement

- **No new package.** Pure facet/filter/sort in `packages/manifest` (weapons sort: slot→exotic→ammo→archetype; instance power-desc).  
- Optional pure presentation helpers in `packages/app`.  
- Neon widgets in `packages/ui_flutter` (reuse NeonItemCard / detail chrome).  
- Thin page + bridge in `apps/windows_host/lib/catalog` (mobile push deferred).  
- Keep `domain` / `sandbox_data` pure.

### Widget inventory (implement)

CatalogWeaponsWorkspace, CatalogFilterBar, NeonFacetChip, CatalogWeaponsGrid, CatalogWeaponCard, CatalogEmptyState, CatalogLoadingSkeleton, CatalogWeaponDetail, WeaponInstanceStrip, CatalogDetailToggles, CatalogPerkGrid, ExoticIdentityBlock, CatalogHashFooter, CatalogOutboundStubs, CatalogScopeControl, CatalogWeaponsPage (host wire-up).

### Widget test inventory (required)

Facet chip cycle; filter More/RESET; grid selection/owned badges; empty states (zero / owned empty Sync+Settings / missing manifest); toggles default OFF; perk grid selected vs pool; craft columns when toggled; exotic identity soft catalyst; hash footer; outbound stubs disabled; instance strip power-desc; workspace ~400px detail; loading skeleton.

### Anti-bloat / risks (carry into implement)

- Do not invent can-roll/craft pools if data missing.  
- Do not leak live Set/Synergy create into weapons detail.  
- Do not use LibraryWorkspace 320-rail as this layout.  
- Default sort change needs pure-layer + test updates (currently alpha in places).  
- Extract god `CatalogPage` with tests before wholesale rewrite.  

### Verifier residual issues (fix during implement — mockups still SSoT for UX)

Mockups may still show signed-out owned badges, inline perk hashes, mobile group-by drift, detail-exotic-craft gate bugs, etc. **Implement against locked decisions + product rules**, not against known mock bugs. Prefer fixing mock honesty in a follow-up pass if needed.

## Acceptance checklist

- [ ] Signed-out manifest browse with clear not-owned; Owned prompts sign-in  
- [ ] Signed-in All: icon grid, default sort slot→exotic→ammo→archetype  
- [ ] Owned empty: Sync primary + Settings secondary; no invented rows  
- [ ] Owned multi-instance: identity-primary + power-desc strip, default highest  
- [ ] Facet cycle + OR within / AND across / exclude + free-text  
- [ ] Zero matches empty + Clear; missing manifest Reload/Settings  
- [ ] Detail selected plugs; can-roll toggle; possible crafted toggle (perk columns); readable names  
- [ ] Craftable exotic + catalyst independent; never invent options  
- [ ] Unknown perk label; hash footer only; catalyst never gates  
- [ ] Outbound Set/Synergy disabled stubs  
- [ ] Soft &lt;5s filter; Windows smoke; required widget tests  

## Next

```text
/workflow area-implement {"area":"catalog","subarea":"weapons","brief_path":"docs/ux-redesign/catalog/001-weapons-brief.md"}
```
