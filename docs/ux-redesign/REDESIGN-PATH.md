# Flutter area UX redesign path

**SSoT for sequencing the large app UI/UX redesign** (Windows-first Neon/Flap rebuild after Settings-only shell baseline).

| | |
| --- | --- |
| **Updated** | 2026-08-08 |
| **Process** | [README.md](./README.md) (area-ux loop, D-LANES) · [CAPTURE.md](./CAPTURE.md) · [DUAL-TRUTH-GAPS.md](./DUAL-TRUTH-GAPS.md) |
| **System lane** | [multiplatform-dart-feature-gaps.md](../multiplatform-dart-feature-gaps.md) · [slice-roadmap](../multiplatform-dart-slice-roadmap.md) — Spec Kit only for pure/IO APIs |
| **Vault hub** | ProjectTracker `UX/UX Redesign Path.md` (narrative) · per-area `UX <Area>.md` boards |
| **Product areas** | Shell · Settings · Catalog · Sets · Synergy · Build · Loadouts |

**This document answers:** what order we rebuild product chrome, when we may leave a mode/area, and what is still deferred.

It does **not** replace DBR/DAC/BR wording or product-map surface IDs.

---

## 1. Principles

1. **Depth before breadth.** Finish the active mode/area to an agreed **exit gate** before opening the next full `area-ux-redesign` for a different mode/area.
2. **Residuals stay on the active track.** Uncommitted polish, dual-truth gaps, and vault residual rows on Weapons do **not** auto-authorize Armor (or any other mode) as the next redesign slice.
3. **Split lanes (D-LANES).** Pure models / score / persist → Spec Kit `DART-NNN`. Mockups, widgets, Widgetbook, dual-truth → this track. Features that need both: system API first (or contract-first fixtures), then UX.
4. **UX chrome uses workflows — always for larger work.** Do **not** jump to ad-hoc implement for user-visible Catalog/area chrome. Required loop:
   - **Full mode/area or multi-surface UX** → `/workflow area-ux-redesign` → human mockup gate → `/workflow area-implement` → Capture  
   - **One control / residual chrome** (e.g. entity hotspot, instance strip) → `/workflow area-ux-component` → human gate → `/workflow area-implement`  
   System-only packages (pure domain/manifest, Drift) may land without area-ux workflows; their **paired UX** still must enter a workflow before host chrome ships.
5. **Composition aid, not product home.** Catalog redesign never becomes Build-as-home (DBR-PUR-002). Live Set/Synergy outbound uses **shared area lifecycles**, not Catalog-local editors.
6. **Windows-first.** Mobile push / dual-pane parity is **deferred** per slice unless the brief explicitly gates it. Structure-only mobile is OK when Capture notes it.
7. **Dual-truth is real.** Structure tests + PNG presence alone do not close a slice while open `blocks_dual_truth` gaps remain (unless human accepts structure-only).
8. **Update this path when order changes.** Same change: repo path + vault hub + active area residual board.

---

## 2. How to advance

| Step | Rule |
| --- | --- |
| **Stay** | Active slice has open P0/P1 dual-truth gaps, blocking residuals on the vault board, or uncommitted chrome that is still “weapons not good enough” |
| **Component polish** | Run **`area-ux-component`** workflow (not freehand implement) for one control (e.g. entity info hotspot, instance strip) |
| **Paired UX after system** | After DART-071/072/073 (or filter-collections system), open **`area-ux-component`** or **`area-ux-redesign`** for chrome — system commit alone never ships visible Catalog changes |
| **System interleave** | DART-071/072/073 may land while Catalog weapons is active; their **UX** pairs may run as Catalog sub-slices **without** starting Armor |
| **Exit → next mode** | Human agrees exit gate (below); residual rows closed or explicitly deferred; then open next brief/mockups |
| **Exit → next area** | Catalog modes through constrained pick (or human re-scope); then Sets / Synergy / Build order below |

### Default exit gate (any full redesign slice)

- [ ] Brief locked + mockups approved (`MOCKUP-APPROVED` flow)
- [ ] Implement + structure tests green
- [ ] Capture `shot_matrix` must-rows present; `COMPARE.md` filled
- [ ] No open gaps with `blocks_dual_truth: true` for that slice (or structure-only accepted)
- [ ] Vault UX note + this path’s **Current pointer** updated
- [ ] Product-map surface bindings still valid (no forked rule IDs)

---

## 3. Global area order (app redesign)

Rebuild **one primary area at a time**. Order balances dependency (auth → browse → library → primary compose) with work already started (Catalog deep dive after Settings baseline).

| Phase | Area | Status | Why this order | Exit before next area |
| --- | --- | --- | --- | --- |
| **0** | **Shell** (nav, theme, signed-out gates) | **partial** — Settings-only baseline + Catalog/Settings reachability | Shared frame for every area | Stable primary nav + auth indicator; no fake private data |
| **1** | **Settings** | **partial** — OAuth, manifest/entity refresh, inventory sync | Unblocks Owned Catalog and compose | Sign-in, refresh, sync CTAs honest; empty states actionable |
| **2** | **Catalog** | **active** — Weapons deep; Armor/Universal not redesigned | Composition aid with densest Destiny chrome; reused by fill pickers | See §4 Catalog path — all planned Catalog phases or explicit re-scope |
| **3** | **Sets** | **planned** | Library + fill-slot depends on Catalog pick patterns | Board, fill, base-roll honesty, attach gates usable under Neon/Flap |
| **4** | **Synergy** | **planned** | Library + reverse tags on Catalog targets | Create/edit/link lifecycle; no Catalog-local fork |
| **5** | **Build** | **planned** | **Primary product spine** (DBR-PUR-002) | Identity, variant areas, soft guidance, finish — composition-first |
| **6** | **Loadouts** | **planned** | Export / equip-adjacent supporting surface | DIM export honesty; no vault-as-home |
| **7** | **Cross-cutting** | **deferred** | Mobile parity, Widgetbook coverage, density passes | Per host; does not reorder 2–6 unless product says so |

**Shell polish** may run as small `area-ux-component` slices any time (nav labels, gates) without jumping the area queue.

**Do not** start Sets/Synergy/Build full redesign while Catalog is still the active deep area, unless Catalog is explicitly paused and the path pointer is updated.

---

## 4. Catalog path (modes and sub-slices)

Catalog is the **active deep redesign**. Modes are sequential; **weapons residual work is not “done enough” to start Armor** until Phase C exit is met (or human overrides this path).

### 4.1 Catalog phase board

| Phase | Id | Focus | Status | Notes / artifacts |
| --- | --- | --- | --- | --- |
| **C0** | Foundation | Pre-redesign DART-062/063 modes + owned join | **done** (system/host baseline) | Modes exist; armor still legacy chrome |
| **C1** | Weapons browse + detail | Identity grid, facets, detail sidebar, can-roll / craft / exotic | **done** (structure) | `001-weapons` |
| **C2** | Weapons residuals / dual-truth | Meta, origin, equal-width perks, enhanced, catalyst honesty | **done** → residual follow-ups | `001-full`, `001-residual-polish` |
| **C3** | Weapons browse chrome | Family cards, group collapse, sort priority, type icons | **done** (dual-truth closed for browse gaps) | `001-browse-chrome` |
| **C4** | Weapon instance strip | Power chips, multi-copy honesty | **landed** / residual polish as needed | `002-weapon-instance-strip` |
| **C5** | Weapon roll targets | Preferred + avoid, rank owned, exotic excluded | **landed** / chrome polish active | `003-catalog-roll-targets` · vault [[UX Catalog — Weapon Roll Targets]] |
| **C6** | **Weapons finish queue** | Residual bugs + optional weapons features | **active** | Vault [[UX Catalog — Weapons]] residuals · uncommitted polish · open dual-truth (e.g. craft ON) |
| **C7** | Catalog system-paired UX | Nested group chrome, entity 1+3 desc (after DART-072 / DART-071) | **planned** (may interleave in C6) | `UX-CATALOG-NESTED-GROUP`, `UX-CATALOG-ENTITY-DESC` |
| **C8** | **Armor redesign** | Armor grid + detail (stats labeled base/live, energy, mods, set bonus, exotic) | **blocked on C6 exit** | No brief/mockups yet · product [[Destiny Armor]] |
| **C9** | **Universal redesign** | Mixed-kind search + shared-lifecycle Set/Synergy CTAs (BR-CAT-009*) | **later** | Keep live CTAs; do not stub regress |
| **C10** | Constrained pick embed | Set/Build fill locks (slot, class, exotic, set type) | **later** | Shared pick chrome; hard domain rules |
| **C11** | Live Set/Synergy outbound | Replace weapons disabled stubs with shared lifecycles | **later** | After Sets/Synergy area chrome exists **or** thin wire to existing host flows |
| **C12** | Mobile Catalog push | Single-pane detail push | **deferred** | Not a Windows exit gate |

### 4.2 Phase C6 — Weapons finish (current)

Stay here until the **Weapons exit gate** is met.

**In scope while active**

- Dual-truth residuals (`DUAL-TRUTH-GAPS.md`, `implementation-shots/*/COMPARE.md`)
- Vault residual / bug rows on [[UX Catalog — Weapons]]
- Roll-target chrome polish (003 follow-through)
- Optional: saved filter collections — **system landed** (`74ce3e4`); UX mockups **approved** (`004-catalog-filter-collections`); next **area-implement** filter-band chrome
- Optional interleave: C7 after system APIs land

**Out of scope while C6 is open**

- Full **Armor** `area-ux-redesign` (C8)
- Universal redesign (C9)
- Treating host armor mode as “redesigned” without C8

**Weapons exit gate (C6 → C8)**

- [ ] Human agrees weapons chrome is good enough to leave the weapons track
- [ ] Blocking dual-truth gaps for weapons closed or explicitly deferred non-blocking
- [ ] Uncommitted weapons polish landed or parked with a clear residual list
- [ ] Vault Weapons residual table updated; open rows either fixed, deferred with owner, or moved to a named next weapons component slice
- [ ] This path’s **Current pointer** set to C8 (or C7 if system-paired UX is next)

**Armor exit gate (C8 → C9)** — summary; detail in future armor brief

- Armor identity grid (no list-row stats v1) + detail with stats/energy/mods/set bonus/exotic callout
- Default sorts per BR-CAT-010d / 011b
- Owned instances; signed-out honesty
- Dual-truth Capture for armor must-rows
- Vault `UX Catalog — Armor` note created

### 4.3 Catalog numbering convention

| Pattern | Use |
| --- | --- |
| `001-*` | Early weapons + residual waves (historical) |
| `002-*` | Component slices (instance strip) |
| `003-*` | Roll targets |
| `004-*` | Filter collections component (`004-catalog-filter-collections`) |
| `005-*` (next free for full mode) | Prefer **Armor** full redesign when C8 starts |
| `00N-<name>` | Later Universal / pick / outbound |

Briefs live under `docs/ux-redesign/catalog/`. Shots under `implementation-shots/<slice-id>/`.

---

## 5. Parallel system tracks (do not reorder Catalog modes alone)

These may run **in parallel** with C6; they are **not** a substitute for C6 exit and **not** permission to start C8.

| System (Spec Kit) | UX pair | Ledger |
| --- | --- | --- |
| **DART-073** weapon roll targets (pure score/persist) | UX-CATALOG-ROLL-TARGETS / 003 | GAP-UI-ROLL-01 |
| **DART-071** entity presentation model | UX-CATALOG-ENTITY-DESC | GAP-UI-DESC-01 |
| **DART-072** nested group tree | UX-CATALOG-NESTED-GROUP | GAP-UI-CATALOG-11 |

Update [feature-gaps current pointer](../multiplatform-dart-feature-gaps.md#current-pointer-post-program--ledger-hygiene) when system vs UX priority shifts; keep **this** path as UI sequence SSoT.

---

## 6. Current pointer (edit every advance)

| Field | Value |
| --- | --- |
| **Active area** | Catalog |
| **Active Catalog phase** | **C6 — Weapons finish queue** |
| **Do not start yet** | C8 Armor full redesign; C9 Universal redesign |
| **Landed (C6 component)** | **CatalogFilterCollections** — system + chrome on main; Capture dual-truth optional |
| **In flight (C6 / C7)** | Entity info hotspot + nested group-by (parallel worktrees / uncommitted mockups) |
| **Next full redesign slice** | **C8 Armor** (after C6 exit; brief/mockups prefer `005-*`+), unless human inserts more C7 first |
| **Open weapons residual board** | Vault `UX/UX Catalog — Weapons.md` · repo `DUAL-TRUTH-GAPS.md` · uncommitted catalog chrome polish |
| **Next area after Catalog** | Sets (phase 3) |

---

## 7. Explicit non-goals (redesign path)

- Catalog as product home / vault manager
- Inventing can-roll, craft pools, sources, or bare-hash primary labels
- Armor optimizer as part of Catalog armor slice (optimizer stays Sets/Finish)
- Confidential OAuth in Flutter hosts
- Spec Kit slices for chrome-only work
- Starting multiple full area redesigns in parallel without updating this path

---

## 8. Where agents and humans look

| Need | Open |
| --- | --- |
| **Sequence / “what next?”** | **This file** |
| Loop, workflows, Capture | [README.md](./README.md), [CAPTURE.md](./CAPTURE.md) |
| Visual parity residuals | [DUAL-TRUTH-GAPS.md](./DUAL-TRUTH-GAPS.md) |
| Catalog weapons residuals | Vault `UX Catalog — Weapons.md` |
| Catalog mode board (narrative) | Vault `UX Catalog.md` |
| System gaps / DART order | [multiplatform-dart-feature-gaps.md](../multiplatform-dart-feature-gaps.md) |
| Product area intent | Vault `Areas/Area *.md` |

---

## 9. Changelog

| Date | Change |
| --- | --- |
| 2026-08-07 | Initial path: global area order; Catalog C0–C12; C6 weapons finish active; Armor blocked until C6 exit |
| 2026-08-08 | C6 active work: roll-target **plug-level N/M** quality score + column-level perfect tint (Duty Bound-style `3/6`) |
| 2026-08-08 | C6 optional: filter collections system + chrome landed on main; Armor renumbered to prefer `005-*` when C8 starts |
| 2026-08-08 | Principle: **larger UX always uses workflows** (`area-ux-redesign` / `area-ux-component` → `area-implement`); no ad-hoc chrome after system APIs |
