# Dual-truth gap log (workflow memory)

**Purpose:** Human-reported **mockup ↔ ship** understanding gaps that structure tests and PNG presence alone will **not** catch.  
**Consumers:** `area-ux-redesign`, `area-implement` (required load).  
**Protocol:** [`CAPTURE.md`](CAPTURE.md) · loop: [`README.md`](README.md)

This file is the **SSoT for open visual/product parity residuals**. Agents must **not** claim dual-truth closed for a slice while any gap with `blocks_dual_truth: true` and matching `area` remains **open**, unless the human explicitly accepts **structure-only** for that gap.

---

## How you file a gap (human)

When ship ≠ mockup (or ≠ DIM/product truth), add or reopen a section under **Open gaps** using this template. You can paste screenshots into `implementation-shots/<slice>/` and link them.

```markdown
### GAP-<AREA>-<NNN> — short title
- **Status:** open
- **Area:** catalog
- **Slice:** residual-polish | full | weapons | …
- **Kind:** visual-parity | interaction | data-wiring | product-behavior
- **Severity:** P0 | P1 | P2
- **blocks_dual_truth:** true | false
- **Mockup SSoT:** path(s) or mockup scenario
- **Ship evidence:** path to PNG / “live app Ringing Nail” / commit
- **DIM / external (optional):** what reference shows
- **Agreed product (if known):** one line
- **Failure mode:** what agents wrongly treated as “done”
- **Acceptance (must prove):** bullet list
- **shot_matrix proves tokens:** e.g. `perk-uniform-tile`, `toggle-knob`
- **Owner next:** area-implement | area-ux-redesign
```

**Kinds**

| Kind | Means |
| --- | --- |
| `visual-parity` | Mockup structure/chrome not matched (size, badges, bands, toggle shape) |
| `interaction` | Wrong control model (chip vs toggle, default ON, etc.) |
| `data-wiring` | UI code exists but live data path wrong (e.g. enhanced flags) |
| `product-behavior` | Product rule unclear or violated |

**Severity / blocks_dual_truth**

| Severity | `blocks_dual_truth` | Effect |
| --- | --- | --- |
| P0 | usually `true` | Plan/capture must address or explicit structure-only accept |
| P1 | usually `true` for visual-parity on active slice | Same |
| P2 | often `false` | Tracked; may ship under gaps_for_next_redesign |

**Close a gap:** set **Status:** `closed`, add **Closed:** date + commit/shot proof. Move under **Closed gaps** (or leave in place with closed status).

**Reopen:** set **Status:** `open` again with new evidence.

---

## Workflow rules (agents)

1. **Load** `docs/ux-redesign/DUAL-TRUTH-GAPS.md` and any `docs/ux-redesign/<area>/DUAL-TRUTH-GAPS.md`.
2. Collect all sections with **Status:** `open` for the active `area` (and slice if named).
3. **Plan** must list each open gap id in `open_gap_ids` and either:
   - add `shot_matrix` / files / tests that close it, or  
   - mark deferral only if human already accepted structure-only for that id.
4. **Capture `dual_truth_ok`:** false if any open gap has `blocks_dual_truth: true` for this area/slice and is not structure-only-accepted — **even if PNGs exist**. PNG presence ≠ visual parity.
5. **Review** must set `matches_dual_truth: false` while such gaps remain open.
6. **Report** must list remaining open gap ids.
7. Prefer **mockup interaction model** over “tests green” when gap kind is `visual-parity`.

Anti-pattern this log prevents:

> Structure tests + some Driver PNGs → `dual_truth_ok: true` while user can still see mockup and ship side-by-side and they do not match.

---

## Open gaps

### GAP-CAT-PERK-001 — Perk grid visual parity vs residual mockups
- **Status:** open
- **Area:** catalog
- **Slice:** residual-polish (also affects full / weapons detail)
- **Kind:** visual-parity
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:**
  - `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html` (detail owned OFF / can-roll ON)
  - same patterns in `001-full-desktop.html` where three-tier bands appear
- **Ship evidence:** live Catalog weapons detail (e.g. Ringing Nail) — Flutter FilterChip + non-uniform perk tiles; no ①②③ badges / band labels
- **Agreed product:** Possible rolls is a **toggle OFF by default**; three tiers + enhanced orthogonal; mock structure is SSoT for chrome
- **Failure mode:** residual implement closed dual-truth on meta/silhouettes/headers/fixture PNGs without matching **perk cell chrome** to mockup
- **Acceptance (must prove):**
  - Possible rolls control matches mock **toggle** language (not only Material FilterChip look-alike)
  - ① selected / ② unselected / ③ possible have distinct mock-like chrome (badges and/or band labels)
  - ② shows gold chevron (or mock-equivalent) for unselected instance
  - ③ dashed muted cells when Possible rolls ON
  - **Uniform perk tile size** in a column (fixed min size; no content-driven uneven cells)
  - Equal-width columns retained at 400px detail; no H-scroll
- **shot_matrix proves tokens:** `toggle-possible-rolls`, `tier-badges-or-bands`, `perk-uniform-tile`, `possible-dashed-muted`
- **Owner next:** area-implement (ui_flutter CatalogPerkGrid / CatalogDetailToggles / cell tiles)

### GAP-CAT-PERK-002 — Enhanced live path misses DIM-enhanced rolls
- **Status:** open
- **Area:** catalog
- **Slice:** residual-polish
- **Kind:** data-wiring
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:** gold + **E** on ①/② when this copy’s plug is enhanced
- **Ship evidence:** Ringing Nail owned detail — no E marks; DIM overview shows enhanced arrows on this roll’s plugs
- **DIM / external:** DIM weapon overview enhanced indicators on selected plugs for this copy
- **Agreed product:** Enhanced orthogonal to tier; E on instance ①/② only when data says enhanced; never fake E on ③ pool cells
- **Failure mode:** host `isEnhancedPlug(name, '')` with **empty category** → only names containing “enhanced” mark true; Bungie enhanced plugs with base display names + `enhancements.v2` (or equivalent) never enter `plugEnhancedByHash`
- **Acceptance (must prove):**
  - Enhanced resolution uses plug **category** and/or inventory enhanced relation (not name-only empty category)
  - Live or fixture weapon that DIM marks enhanced shows gold/E on matching ①/② cells
  - ③ / unowned still: no E cells; note-only when pool can enhance
- **shot_matrix proves tokens:** `e-on-12-live-or-fixture`, `no-e-on-3`, `plugEnhancedByHash-category`
- **Owner next:** area-implement (windows_host OwnedCatalogBridge + bungie classify / socket category)

### GAP-CAT-PERK-003 — Possible crafted toggle visibility vs mock
- **Status:** open
- **Area:** catalog
- **Slice:** residual-polish
- **Kind:** interaction
- **Severity:** P1
- **blocks_dual_truth:** false
- **Mockup SSoT:** Possible crafted toggle same design as Possible rolls when craft data exists; hidden when not
- **Ship evidence:** craft toggle often absent (correct if no craft columns); when craftable, must match toggle chrome of Possible rolls
- **Agreed product:** craft OFF default; same UI system as Possible rolls; never invent craft pools
- **Failure mode:** craft path tested only as “hidden”; visual parity of craft ON never dual-truthed next to mock
- **Acceptance (must prove):** when `craftAvailable`, toggle chrome matches Possible rolls control; craft pool cells use same ③-style dashed uniform tiles
- **shot_matrix proves tokens:** `toggle-possible-crafted`, `craft-pool-as-possible-style`
- **Owner next:** area-implement when craft fixtures available

---

## Closed gaps

_(None yet for this log. Move closed items here with proof.)_

---

## Index (quick scan)

| ID | Status | Area | blocks_dual_truth | Title |
| --- | --- | --- | --- | --- |
| GAP-CAT-PERK-001 | open | catalog | true | Perk grid visual parity vs residual mockups |
| GAP-CAT-PERK-002 | open | catalog | true | Enhanced live path misses DIM-enhanced rolls |
| GAP-CAT-PERK-003 | open | catalog | false | Possible crafted toggle visibility vs mock |
