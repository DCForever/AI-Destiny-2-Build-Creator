# Plan: Sets area update (domain grill → redesign)

**Status:** grill locked (2026-08-10); brief/mockups not started  
**Date:** 2026-08-09 · **Grill:** 2026-08-10  
**Area:** sets (path phase 3 — **planning** → ready for redesign brief)  
**Hosts:** windows (dual-truth exit gate); mobile structure-only unless re-scoped  
**Product SSoT (intent):** vault [[Domain Set]] · [[Area Sets]] · [[Destiny Armor]] · [[Destiny Armor Set Bonus]]  
**Grill outcomes:** [`000-sets-grill.md`](./000-sets-grill.md) (`G-SET-*`)  
**Repo rules:** `specs/domain-business-rules.md` (DBR-CMP-*, DBR-SETB-*, DBR-STAT-008, …) · `business-rules.md` / DAC-SET-* when re-synced  
**Map:** `docs/product-map/` surfaces `sets.*` · flows library + fill-slot · Build armor/weapon set branches  

## Decisions locked for this plan

### Planning (2026-08-09)

| Topic | Decision |
| --- | --- |
| What “update” means | Domain grill → lock deltas → full area UX redesign → implement |
| Product truth | Mostly locked; grill open edges only |
| First type depth | Armor Sets full MVP |
| Other types in MVP | Library shell + thin detail |
| Catalog relation | Parallel residual OK |
| Sequence | Grill → vault/repo deltas if needed → `area-ux-redesign` → implement → Capture |

### Grill (2026-08-10) — summary

Full table: [`000-sets-grill.md`](./000-sets-grill.md). Highlights:

| Topic | Decision |
| --- | --- |
| Chrome | **Library route + modal lifecycle** (G-SET-001) |
| Fill primary | **Optimizer (DIM-like)** — exotic + stat min/max; many kits as **rows** × slot columns; apply one (G-SET-024, G-SET-027/029/036–037, G-SET-052) |
| Fill secondary | **Compare pick** owned pieces: base six+total+power+bonus fit+exotic; rank total/EoF stats (G-SET-020–023) |
| Not Catalog embed | New compare UI; share with optimizer; Catalog filters/language optional (G-SET-002) |
| Create | Type + **class locked before pieces**; optional **bonus goals after class** (G-SET-013); name optional **auto** Class·XYpc·bonus·tags (G-SET-004–006, G-SET-010, G-SET-040) |
| Bonus goals | **0 · one 2pc · two 2pc (diff families) · one 4pc** (includes that family’s 2pc). Not 4pc+extra 2pc (G-SET-013) |
| Constraint fill | Hard filter non-exotic to **union of goal families**; exotic allowed + soft-warn (G-SET-011) |
| Board | Layout A: slot strips + Σ base + coverage (G-SET-030) |
| Pins | **Owned instances only** MVP (G-SET-031) |
| Synergy Types UI | **Omit** Armor MVP chrome (G-SET-012) |
| Tags | Free multi-select; **hard no overlap** with Synergy Type vocabulary (G-SET-033) |
| Mods | No inline edit; **deep link Mod Set**; hide energy/mods if unknown (G-SET-050–051) |
| Build entry | **Out of MVP**; same modal later (G-SET-003) |
| Honesty | Sign-in/sync for fill; delete confirm + SET_IN_USE used-by (G-SET-041–042) |

## 1. Product understanding (compressed)

### 1.1 Two products (do not collapse)

| Product | Role |
| --- | --- |
| **Domain Set** | What a Set *is*: typed package, slots, mins, Destiny hard rules, attach/delete, Synergy Types, armor bonus constraint |
| **Area Sets** | `/sets` workspace: **one shared lifecycle UI** (create/edit/detail/fill/delete). Other areas open this lifecycle; they do not fork it (BR-SET-020–025) |

Build **attach** is **not** the lifecycle (BR-SET-022a). Variant attach is separate (BR-VAR-*).

### 1.2 Set types

| Type | Package shape (save/attach) | Notes |
| --- | --- | --- |
| **Weapon** | ≥2 items; buckets primary/special/heavy; ≤1 exotic weapon | Full roll data; can-roll / craft display on detail |
| **Armor** | ≥2 items; helmet/arms/chest/legs/class; **class-bound**; ≤1 exotic armor | **Base-roll board only** (DBR-STAT-008); optional **armor set bonus constraint** |
| **Mod** | Mods on ≥2 armor pieces; energy capacity hard | Not class-bound (class filter UX-only) |
| **Pair** | Exotic weapon **and** exotic armor required | Optional convenience; pair armor vs build exotic rules |
| **Fashion** | No combat package min; **no** Synergy Types | Cosmetics layer only |

Type is **fixed after create** (BR-SET-005).

### 1.3 Why Sets exist

- Normal **composition path** for variants (DBR-CMP-001): attach packages, override slots later.  
- Reuse gear groups across builds.  
- **Synergy Type designations** on Weapon/Armor/Mod/Pair mark play-pattern intent (not Build identity; zero OK on save).  
- Optional **armor set bonus constraint** on Armor Sets: family + 2pc/4pc target, hard when set (DBR-SETB-003–007, BR-SET-050–061).

### 1.4 Lifecycle (non-negotiable)

- **One lifecycle** from library and Build entry points (DAC-SET-001).  
- Prefill/focus OK; **same fields, rules, outcomes**.  
- Save progress near Save (counts / completeness).  
- Delete blocked while attached (`SET_IN_USE`).  
- Modal **or** route chrome free **if** behavior matches (BR-SET-025) — **grill edge**.

### 1.5 Armor Set (MVP focus)

| Concern | Rule summary |
| --- | --- |
| Class | Required; fill/attach filter to class |
| Board | Six-stat totals + per-piece **base roll** when pinned; **exclude** mods/MW/tuning |
| Slot rows | Icon + exotic badge + **tiny base six-stat strip**; full mods/bonus on detail |
| Bonus constraint | Optional family + 2pc/4pc; non-exotic members only; exotic soft-warn; fill filters family |
| Soft coverage | Without constraint, may still show detected 2pc/4pc |
| Picker hard | Slot legality, class, second exotic, constraint family — not selectable when known |
| Save | Disabled while hard-blocked; package ≥2; constraint tier when set |

### 1.6 Hard vs soft (Sets)

**Hard on fill/save/attach:** slot/bucket legality, armor class, exotic caps, Pair both slots, mod energy/legality, weapon perk validity, armor bonus constraint when set, package minimums.

**Soft only:** element vs subclass, activity mods, catalyst/deepsight display, empty capacity nudge, Synergy Type nudge, unconstrained bonus coverage.

**Not Set-owned:** dual-exotic **across** attached Sets on a full loadout (variant/compose); Build identity Types; vault transfer.

### 1.7 Area success signals (from Area Sets)

CRUD each type · same lifecycle library/Build · package min errors plain · Synergy Type designate/filter · armor bonus constraint · fill blocks illegal · in-flow open without deep library.

### 1.8 Implementation baseline (not product)

Host/library/readiness/package-min already partially **shipped** (FEAT-NAV-SETS, DART-065/066/068/070, optimizer Windows). This plan is **Neon redesign + domain edge lock**, not greenfield domain invent.

## 2. Grill — complete

Outcomes locked in [`000-sets-grill.md`](./000-sets-grill.md) (G-SET-001–052).  
**Redesign brief locked** 2026-08-10: [`001-armor-brief.md`](./001-armor-brief.md) · mockups approved · next **`area-implement`**.  
**Pre-implement residual:** supersede singular-family set-bonus domain (`DBR-SETB-003` / related BR) to match **G-SET-013** multi-goal, or narrow product — do not ship UI-only multi-goal.

**Do not re-open unless conflict:** package mins, type fixed after create, attach under-min block, one live Set per type (replace-by-type), base-roll board, exotic caps, Fashion no Types, and the G-SET table.

## 3. Redesign MVP (Armor-first)

### In

- Sets **library**: list, type filter, search, tag AND (no Synergy Type filter chrome), readiness honesty; Armor columns per G-SET-032  
- **Modal lifecycle** for Armor (create/edit/board)  
- **Armor:** class + optional constraint on create; layout A board; **Optimize primary**; compare pick secondary (owned-only); save gates; auto-name; Mod Set deep link  
- Delete confirm + in-use block  
- Windows Capture must-rows: library, create, empty board, optimize confirm apply, manual compare pick, constraint filter, under-min, signed-out honesty  

### Out of first MVP

- Full Neon depth for Weapon / Mod / Pair / Fashion boards  
- Synergy Type designate/filter chrome  
- Unowned wishlist pins on Armor Set  
- Build-mounted lifecycle Capture  
- Inline mod edit on Armor Set  
- Auto-apply optimizer without confirm  
- Mobile as Windows exit gate  

### Other types (MVP)

| Surface | Depth |
| --- | --- |
| Library row | Present; filter by type |
| Create type picker | Can create any type |
| Detail / fill | **Legacy/thin** OK until type slices |
| Armor | Full fidelity (optimizer-primary) |

## 4. Phased delivery

```text
P0  Grill locked (2026-08-10) → optional vault Domain Set / Area Sets decision sync
P1  area-ux-redesign: Sets brief + mockups (library + Armor modal + optimize + compare)
P2  area-implement: library + Armor modal + Capture
P3  Weapon Set board/rolls residual
P4  Mod / Pair / Fashion depth + Synergy Type chrome
P5  Build-mounted same modal + attach polish
P6  Wishlist/unowned fill residual
```

Catalog residual (group-by / stat-rank) stays **parallel**, not a Sets gate. Shared **stat rank** ideas feed Armor **compare pick** sort.

## 5. Process (D-LANES)

| Work | Lane |
| --- | --- |
| Domain edge wording | Vault Domain Set / Area Sets; same-change repo `specs/` if enforceable rules change |
| Surfaces / flows | `docs/product-map/` + `product-map:sync` |
| Mockups + chrome | `area-ux-redesign` / `area-implement` under `docs/ux-redesign/sets/` |
| Pure package mins / attach | Already largely landed; only Spec Kit if grill finds API holes |
| Constrained fill pure filters | Prefer existing Catalog/domain filters; system slice only if missing |

## 6. Acceptance sketches (Armor MVP)

1. Create Armor Set → class required → cannot save with &lt;2 pieces (`SET_MIN_ITEMS` plain).  
2. Fill wrong class / wrong slot / second exotic → not offered or Save off.  
3. Set bonus constraint 4pc → non-member non-exotic blocked; &lt;4 members → save/attach fail with plain incomplete.  
4. Board shows **base** totals only when pins known; no unlabeled live mix.  
5. Library start and Build-open lifecycle (if in MVP) match fields/rules/outcomes.  
6. Weapon/Mod/Pair/Fashion appear in library; opening them does not claim redesigned board Capture.

## 7. Risks

| Risk | Mitigation |
| --- | --- |
| Redesign forks Build-local Set editor | BR-SET-021/024; grill attach entry only |
| Fill invents second Catalog product | Constrained embed / shared pick; not full Catalog IA |
| Live stats on Set board | DBR-STAT-008 hard; dual-truth residual |
| MVP scope creep to five full types | Other types library+thin only |
| Catalog residual blocks Sets forever | Path allows parallel residual; Sets grill/plan independent |
| Specs drift vs vault | Product notes win until re-sync; lock grill deltas into both |

## 8. Next actions

1. ~~Run product grill~~ **Done** — [`000-sets-grill.md`](./000-sets-grill.md).  
2. Sync **grill decisions** into vault Domain Set / Area Sets (decisions + open questions closed).  
3. Update repo DBR/BR only if wording must change (MVP owned-only / optimizer-primary fill are **scope** notes, not domain rewrites unless you promote them).  
4. **`area-ux-redesign`** for Sets (Armor-first MVP brief + mockups).  
5. Implement → Capture → advance REDESIGN-PATH phase 3 status.  
6. Vault `UX/UX Sets.md` board when brief locks.

## 9. Pointers

| Need | Where |
| --- | --- |
| Domain rules | vault `Domains/Domain Set.md` |
| Area UI rules | vault `Areas/Area Sets.md` |
| Armor presentation | vault `Destiny Objects/Destiny Armor.md` |
| Bonus object | vault `Destiny Objects/Destiny Armor Set Bonus.md` |
| Path sequence | `docs/ux-redesign/REDESIGN-PATH.md` |
| Catalog residual | `docs/ux-redesign/catalog/006-catalog-armor-groupby-plan.md` |
| Feature baseline | `docs/multiplatform-dart-feature-gaps.md` FEAT-NAV-SETS / GAP-UI-SETS-* |

## 10. Change log

| Date | Note |
| --- | --- |
| 2026-08-09 | Initial plan from product notes + planning Q&A (Armor-first redesign; domain grill first; other types library shell) |
| 2026-08-10 | Grill locked: modal lifecycle, optimizer-primary fill, compare pick, owned-only, tags vs synergy hard split |
