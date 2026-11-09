# UX brief: sets / armor (MVP)

**Status:** locked (mockup-approved 2026-08-10; verify residuals open)  
**Date:** 2026-08-10  
**Hosts:** windows (exit gate); mobile structure-only  
**Slice goal:** Sets path phase 3 Armor-first MVP: `/sets` library + large modal lifecycle; Type+Class lock then optional set-bonus goals; board layout A (five slots, base six+Σ+coverage); **PRIMARY** Optimizer confirm-only (seed class/exotic/bonus; replace-all if pins); **SECONDARY** owned-only compare pick (base six+total+power+bonus fit+exotic; rank total/EoF) shared with optimizer—**not** Catalog embed; owned pins only; free tags hard-blocked vs Synergy Type vocab; Mod Set deep link; delete confirm+SET_IN_USE; signed-out honesty; other types library shell+thin detail; Windows Capture exit; mobile structure-only.  
**Out of scope:** Full Neon Weapon/Mod/Pair/Fashion boards; Synergy Type designate/filter chrome; unowned wishlist pins; Build-mounted Capture; inline mod/energy edit; optimizer auto-apply; vault manager; dual-exotic loadout; Catalog as Set editor; reopening package mins/type-fixed/attach gates; inventing stats/sources; mobile as Windows exit gate; C9 Universal Catalog; Synergy/Build full redesign.

## Product posture

- **Job:** Create and maintain Armor Sets as composition packages (pins + base-roll board + optional bonus goals); fill primarily via Optimizer, secondarily via owned compare pick.  
- **Not for:** Catalog browsing as Set editor; Synergy Type chrome; Build attach in this MVP Capture; dual-exotic loadouts; inventing owned armor.  
- **Rule IDs:** `G-SET-001`–`052`, `DBR-CMP-001/005`, `DBR-STAT-008`, `DBR-SETB-003` (**supersession residual** — see verify), `DBR-UI-005/008`, `DBR-ROLL-001` (wishlist residual), `DBR-PUR-002`, `BR-SET-011`, `BR-OPT-004`, `BR-SLOT-006`, `BR-TAG-009`  
- **Product SSoT:** vault Domain Set / Area Sets · Destiny Armor · grill [`000-sets-grill.md`](./000-sets-grill.md) · plan [`000-sets-update-plan.md`](./000-sets-update-plan.md)

## Locked decisions (from grill + mockup approval)

| Topic | Decision |
| --- | --- |
| Chrome | Large **modal** over `/sets` dual-pane library (G-SET-001); Build-mounted Capture out of MVP |
| Fill substrate | New Sets/optimizer compare — **not** Catalog page embed (G-SET-002) |
| Type scope | Create any type (fixed after create); **Armor full fidelity**; others thin/legacy detail |
| Create Armor | Type → Class → optional **G-SET-013** goals → auto-name/tags → empty board; class editable only while **zero pins** |
| Bonus goals | Legal only: **none · 1×2pc · 2×2pc (diff families) · 1×4pc** (4pc includes that family’s 2pc) |
| PRIMARY fill | **Optimize…** confirm-only; seed class/exotic/bonus; replace-all only if ≥1 pin; never silent apply |
| Optimizer chrome | DIM-like: exotic + dual-thumb min/max kit totals; **one kit per row** × Σ · EoF stats · Helm–Class · goals; green/red ± vs current; default exotic = current when re-opt; apply one selected kit |
| SECONDARY fill | Always-visible per-slot **owned** compare (base six+total+power+bonus fit+exotic; rank total/EoF) |
| Board | Layout A: five flap rows + **totals row above pieces**; EoF **Health · Melee · Grenade · Super · Class · Weapons**; base-roll only; hard goals + soft ≥2pc detect |
| Pins | **Owned instances only** (MVP narrow of DBR-ROLL-001 wishlist — residual, do not rewrite domain) |
| Tags | Free multi-select; **editable on Set detail + board**; hard-block Synergy Type vocabulary |
| Synergy Type UI | Omitted from Armor MVP chrome |
| Mods | Deep link Mod Set only; hide energy/mods when unknown |
| Auto-name | `{Class} · {pc} · {Family\|—}[ · tags]`; collision numeric suffix; live preview |
| Library Armor columns | Name · class · pieces · coverage · used-by |
| Delete | Always confirm; SET_IN_USE + used-by when attached |
| Product-map | Rebind `sets.fill-slot` off Catalog-embed in same implement change |
| Windows | Dual-truth Capture exit |
| Mobile | Structure-only; not Windows exit gate |

## Surfaces

`sets.signed-out`, `sets.library`, `sets.library.filter.type`, `sets.library.filter.tags`, `sets.library.search`, `sets.library.new`, `sets.create`, `sets.detail`, `sets.detail.items`, `sets.detail.totals`, `sets.detail.delete`, `sets.edit`, `sets.fill-slot`, `sets.fill-slot.exotic-block`, `sets.optimize`

## Interaction model

- **Desktop:** library dual-pane Flap + large modal for create/board/compare/optimize  
- **Mobile:** structure-only sheet stack  
- **Filters:** type + tags AND + search; Armor-first facets  
- **Detail rail:** board preview + **editable tags** + Open board / Delete  
- **Board:** Optimize hero; Pick per slot; tags; save gates ≥2 pieces + goals complete  
- **Optimizer:** constraints then ranked kit matrix; click row = apply target; confirm apply  
- **Stubs:** Mod Set deep link; non-Armor thin detail  

## Mockups (approved)

- Desktop: `docs/ux-redesign/sets/mockups/001-armor-desktop.html`
- Mobile: `docs/ux-redesign/sets/mockups/001-armor-mobile.html`
- Approval: `docs/ux-redesign/sets/MOCKUP-APPROVED.md`

### Verify residuals (fix before/with implement)

1. **Domain SSoT — multi-goal vs single-family** — G-SET-013 (0 / 1×2pc / 2×2pc / 1×4pc) **contradicts** current `DBR-SETB-003` / BR-SET-050–054 singular-family wording. **Update domain + vault Domain Set / Destiny Armor Set Bonus with supersession in the same implement change** (or before). Do not ship UI-only multi-goal.  
2. **Second exotic hard-block** — manual compare must enforce BR-SLOT-009 / exotic-block (not only optimizer demote).  
3. **Identity vs instance** — owned compare/pins need instance identity (not name-only); multi-copy honesty.  
4. **Product-map** — rebind `sets.fill-slot` off embedded Catalog; drop/repurpose `SetCatalogPicker` catalog-embed path.  
5. **Pure G-SET-013 helper** — domain/app pure legality + goal satisfaction; not UI-only.  
6. **God-page risk** — extract lifecycle modal / board from host `SetsLibraryPage`; place `Sets*` widgets in `ui_flutter`.  
7. **Optimizer single apply path** — one confirm-only shell; no dual silent apply with legacy workspace.  
8. **Mobile gaps** — structure-only OK; desktop is Capture SSoT (2×2pc, multi-kit matrix, tags on detail/board).  
9. **Chrome density** — optimizer sliders + wide matrix at 1080p; progressive disclosure if Capture fails readability.  
10. **Wishlist residual** — owned-only MVP; document DBR-ROLL-001 narrow; do not ship wishlist as Armor fill default.

## Obsidian

- UX note: `requirements/Projects/Destiny 2 Build Creator/UX/UX Sets — Armor.md`
- Link from Area Sets Experience + UX redesign hub

## Architect notes

### Package placement

- **No new package.**  
- **domain:** pure G-SET-013 bonus-combo legality, hard goal satisfaction vs soft ≥2pc, save/occupancy gates.  
- **sandbox_data:** Synergy Type vocab for tag hard-block only.  
- **app:** auto-name+collision, Armor library row projection, owned-compare rank DTOs, optimizer seed+confirm materialize/apply, SET_IN_USE copy — no Flutter.  
- **db/bungie/manifest:** owned base-roll + inventory honesty + set-bonus family keys.  
- **ui_tokens:** Armor library columns + board A stat metrics.  
- **ui_flutter/sets:** lifecycle modal, create wizard, board A, coverage band, owned-compare, optimize confirm shell, tags, honesty empties, Mod Set deep link, non-Armor thin detail — **not** Catalog grid embed.  
- **windows_host/sets:** thin controller/modal/Capture.  
- **mobile_host:** structure-only sheets.  
- **widgetbook:** fixture use-cases.  
- **product-map:** rebind fill in same change.

### Widget inventory

- `SetsLibraryWorkspace`, `SetsLibraryRail`, `SetsArmorLibraryRow`, `SetsHonestyEmpty`
- `SetsCreateWizard`, `SetsBonusGoalsEditor`, `SetsLifecycleModal`
- `SetsArmorBoard`, `SetsCoverageBand`
- `SetsOwnedCompareTable`, `SetsOptimizeConfirmShell`
- `SetsTagMultiSelect`, `SetsDeleteConfirm`, `SetsModSetDeepLink`
- `SetsNonArmorThinDetail`, `SetsSaveGateBanner`

### Widget test inventory

- [ ] Create: piece/compare UI hidden until Type+Class locked  
- [ ] Bonus goals: only legal G-SET-013 combos accepted  
- [ ] Empty board: Optimize primary; five Pick secondary; Σ zeros  
- [ ] Optimize: confirm-only apply; no silent write; one kit  
- [ ] Optimize: replace-all warning only when ≥1 pin; seed class/exotic/bonus  
- [ ] Owned compare: no unowned; rank total and EoF; required columns  
- [ ] Board: base-roll only; hard coverage; soft ≥2pc muted; hide unknown energy/mods  
- [ ] Tags: multi-select on detail+board; Synergy Type labels hard-blocked  
- [ ] Save disabled under-min/hard Destiny/incomplete goals; blank→auto-name+suffix  
- [ ] Delete always confirm; attached SET_IN_USE + used-by blocks  
- [ ] Signed-out/need-sync honesty empty — no fake owned armor  
- [ ] Non-Armor: shell list + thin detail only  
- [ ] Library Armor flap columns Name·class·pieces·coverage·used-by  
- [ ] Mod Set deep link present; fill is not Catalog page embed  
- [ ] Loading skeleton + no-matches honesty  
- [ ] Windows host smoke: library→modal create→board; Capture surface keys  

## Acceptance checklist

- [ ] Matches product rules above (incl. domain supersession for multi-goal if still G-SET-013)  
- [ ] Mockup interaction model realized in Flutter (not pixel-perfect HTML)  
- [ ] Widget tests for higher-level composables  
- [ ] Host smoke tests  
- [ ] Product-map fill rebound  
- [ ] Vault UX note linked  
- [ ] Windows Capture dual-truth (library/create/board/compare/honesty/delete; optimizer structure+confirm residual OK if explicit)  
- [ ] Not claimed redesigned without Capture  

## Next

```text
area-implement
# area=sets subarea=armor
# brief_path=docs/ux-redesign/sets/001-armor-brief.md
```

Workflow report: [`001-armor-workflow-report.md`](./001-armor-workflow-report.md)
