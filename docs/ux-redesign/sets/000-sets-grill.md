# Sets domain / UX grill

**Status:** locked (2026-08-10)  
**Started:** 2026-08-10  
**Plan:** [`000-sets-update-plan.md`](./000-sets-update-plan.md)  
**Scope:** open edges only — product package/Destiny rules mostly locked  

## Pre-locked (do not re-open unless conflict)

- Package minimums (Weapon/Armor ≥2, Mod multi-piece, Pair both exotics)  
- Type fixed after create  
- One shared lifecycle (library + Build entry) — **chrome:** library route + modal lifecycle  
- Attach under-min blocked; one live Set per type replace-by-type  
- Armor base-roll board only; optional set-bonus constraint hard when set  
- Fashion no Synergy Types; zero Types OK on save (Types **chrome omitted** Armor MVP)  
- Armor-first redesign MVP; other types library shell + thin detail  
- Attach ≠ lifecycle (variant attach separate)  

---

## Locked this grill (2026-08-10)

### R1 — Lifecycle, fill entry, Build, create

| Id | Decision |
| --- | --- |
| **G-SET-001** | **Library route + modal lifecycle.** `/sets` is the list; create/edit/fill run in a large modal (same widget Build will mount later). |
| **G-SET-002** | **Fill is not “reuse Catalog grid as-is.”** Armor slot pick needs a **comparison-first UI** (base stats + set-bonus fit). Catalog pure filters/projectors and visual language may be shared, but the pick surface is a **new compare experience**. That compare UI is also the substrate for **Optimizer** results/review. |
| **G-SET-003** | **Build entry out of Armor MVP.** Redesign/Capture proves library → modal only. Shared lifecycle for Build is design-locked for later (DAC-SET-001); do not ship dual editors. |
| **G-SET-004** | **Type and Class locked before any piece is shown or chosen.** |
| **G-SET-005** | **Name optional.** If skipped, **auto-generate** from set information (see G-SET-006). User may rename anytime. |
| **G-SET-006** | **Auto-name ingredients (Armor):** Class · **XYpc** (coverage / target tier when constrained or detected) · **bonus family** when set · **Tags** (and Synergies later when Types UI returns). Exact string template to brief/mockups. |

### R2 — Constraint, family fill, Synergy Types chrome

| Id | Decision |
| --- | --- |
| **G-SET-010** | **Offer optional armor set-bonus goals on create after class** (skip = none). Then open empty board modal. |
| **G-SET-011** | When any goal is set: **hard filter non-exotic to the union of goal families**; **exotic always allowed** under exotic rules; soft-warn if exotic blocks meeting goals. |
| **G-SET-013** | **Legal bonus goal combinations only:** (1) **none**; (2) **one 2pc** (one family); (3) **two 2pc** from **different** armor set-bonus families; (4) **one 4pc** on a single family (**includes that family’s 2pc** naturally). **Not legal:** three 2pcs, two 4pcs, 4pc + a second family’s 2pc, two 2pcs of the same family. Save/attach/optimize require every goal’s piece count met (exotic does not count toward tier). |
| **G-SET-012** | **Synergy Type chrome omitted from Armor MVP** (no designate UI, no library Type filter in redesigned chrome). Domain still allows designations; thin/legacy or later slice. |

### R3 — Compare pick + optimizer relationship

| Id | Decision |
| --- | --- |
| **G-SET-020** | Slot pick primary job: **compare owned copies** (and identities only if later scope expands) by **base stats** and **bonus fit**. |
| **G-SET-021** | Compare must show: **base six + total + power + family/bonus fit + exotic**. |
| **G-SET-022** | **Owned only in MVP** for candidates on the pick list. |
| **G-SET-023** | Rank/sort in pick: **base total + each EoF stat** (same spirit as Catalog armor stat-rank). |
| **G-SET-024** | **Optimizer is the primary way to fill Armor Set slots** in the redesigned lifecycle. Manual per-slot compare pick remains available (secondary), not the default hero path. |
| **G-SET-025** | Optimizer and manual pick **share compare components**. Optimizer remains **confirm-only** apply (never silent auto-write). |
| **G-SET-026** | Optimize with existing pieces: **seed constraints** from Set (class, exotic lock if any, bonus goals) and **replace-all with confirm**. |
| **G-SET-027** | Optimizer returns a **ranked list of many proposals** (kits), not a single kit. User can sort (Σ base, key stats, goal fit). |
| **G-SET-028** | *(superseded for chrome)* Prefer **DIM-style result matrix**: each kit is a **row**; columns = Helm · Arms · Chest · Legs · Class (+ Σ / per-stat totals). Click row to select. |
| **G-SET-029** | **Apply** always targets **exactly one** selected row after confirm. |
| **G-SET-035** | Optional **Current board** as a result **row** when slots already filled. |
| **G-SET-036** | Optimizer constraints (DIM-like): **exotic** = Any · No exotic · specific owned exotic; **per-stat kit totals** with optional **min** and/or **max** (base roll). Filters the proposal list. |
| **G-SET-036a** | When opening Optimize on a board that already has pins: default Exotic to the **current exotic** if one is pinned; if filled with **no** exotic, default to **No exotic**; empty board stays **Any**. User may change afterward. |
| **G-SET-037** | Class + Armor set-bonus goals (G-SET-013) still seed/filter optimize; non-exotic family rules unchanged. |

### R4 — Board, pins, library, tags, replace

| Id | Decision |
| --- | --- |
| **G-SET-030** | Board / Set detail: **stat columns** (Health…Weapons + Σ). **Kit totals row sits directly above piece rows** (aligned columns). Each piece row: slot + name/power + per-stat base values + Pick/Change. Base roll only. Bonus coverage band above the table when constrained. |
| **G-SET-031** | **Owned instances only** on the Set in MVP (no unowned wishlist pins on the package). Aligns with Owned-only pick. |
| **G-SET-032** | Library Armor row: **Name · class · piece count · bonus coverage · used-by**. |
| **G-SET-033** | **Tags:** free multi-select, user-extendable list; library AND filter. **Hard block:** tag labels/keys must **not overlap Synergy Type vocabulary** (e.g. cannot tag “Melee” if that is a Synergy Type). Tags ≠ Synergy Types (BR-TAG-009). **Editable on Set detail and board** (not create-only). |
| **G-SET-034** | Occupied slot: **confirm then replace** (BR-SLOT-006). |

### R5 — Create flow, honesty, delete

| Id | Decision |
| --- | --- |
| **G-SET-040** | Create Armor: **Type → Class → optional bonus constraint → empty board modal**. |
| **G-SET-041** | Signed-out / no inventory: **honest empty**; create/fill prompt **sign-in + sync** (no fake owned armor). |
| **G-SET-042** | Delete: **confirm always**; if attached, **block** with used-by builds/variants (`SET_IN_USE`). |

### R6 — Mods energy + optimizer entry

| Id | Decision |
| --- | --- |
| **G-SET-050** | **No inline mod edit on Armor Set.** **Deep link** to **Mod Set** for the kit (create/open related Mod Set). Loadout combat mods stay Mod-Set-owned (DBR-CMP-005). |
| **G-SET-051** | If instance has no energy/plugs data: **hide** energy/mods UI entirely (Catalog honesty). |
| **G-SET-052** | Primary fill CTA on Armor board: **Optimize…** (confirm-only workspace → apply with confirm). Secondary: per-slot manual pick/compare. |

---

## MVP Armor lifecycle sketch (post-grill)

```text
/sets library
  → New Armor Set
      → lock Type=Armor, Class
      → optional bonus goals (none | 1×2pc | 2×2pc | 1×4pc)
      → modal: empty board (auto-name if blank)
           [Optimize…] primary
           per-slot Pick (compare owned) secondary
           Σ base board + coverage
           deep link → Mod Set
           Save (gates: ≥2, hard Destiny, constraint tier)
  → Open existing → same modal
```

---

## Implications for redesign / system

| Implication | Action |
| --- | --- |
| New **Armor compare / pick** surface | Not Catalog page embed; design in `area-ux-redesign` mockups; share with optimizer review |
| Optimizer **primary fill** | Brief + mockups put Optimize as hero; manual fill secondary; confirm apply |
| Owned-only package | Temporary product narrowing vs DBR-ROLL-001 wishlist on Sets — **document as MVP scope**, residual wishlist fill later |
| Synergy Type UI deferred | Domain rules remain; chrome residual; tags must hard-exclude Type vocabulary |
| Auto-name | Spec string rules in brief; uniqueness per user per type still holds (may suffix) |
| Build path later | Same modal widget; no second editor |

---

## Open / deferred (not blocking lock)

| Topic | Notes |
| --- | --- |
| Exact auto-name template string | Mockup/brief |
| Board layout A may change | Explicit “for now” |
| Wishlist / unowned on Set | Post-MVP |
| Synergy Type chrome | Post-MVP |
| Build-mounted modal Capture | Post Armor library MVP |
| Instance pin change without full replace | Not grilled; treat as replace flow |
| Multi-character location columns in compare | Not grilled; residual |
| Keyboard density of compare table | Mockup residual |
| Migration of existing Sets rows | Existing data opens thin/legacy or new modal with same ids — brief should state no data wipe |

---

## Acceptance sketches (updated)

1. Create Armor: cannot see pick list until class locked.  
2. Empty board modal: **Optimize** is the primary fill control.  
3. Optimize apply requires confirm; seeds class/exotic/bonus; replace-all confirm if slots filled.  
4. Manual pick: owned-only compare with base six+total+power+bonus fit+exotic; rank by total or EoF stat.  
5. Constraint: hard family filter for non-exotic; exotic allowed + soft-warn.  
6. Board: layout A base strips + Σ; hide mods/energy if unknown; Mod Set deep link present.  
7. Save: ≥2, hard blocks, constraint tier; auto-name if blank.  
8. Tags cannot equal Synergy Type labels.  
9. Delete blocked with used-by when attached.  
10. Signed-out: no fake owned fill.

---

## Change log

| Date | Note |
| --- | --- |
| 2026-08-10 | Grill rounds 1–6 locked; optimizer primary fill; compare pick; library+modal; owned-only MVP |
| 2026-08-10 | **G-SET-013** multi bonus goals: 0 / 1×2pc / 2×2pc / 1×4pc (4pc includes 2pc); mockups updated |
| 2026-08-10 | **G-SET-027–029, 035** optimizer multi-proposal list + side-by-side compare + single primary apply |
| 2026-08-10 | **G-SET-036–037** DIM-like exotic + min/max stats; results as kit rows × slot columns |
