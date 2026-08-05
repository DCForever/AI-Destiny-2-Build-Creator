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
- **Note (2026-08-04):** Toggle chrome now shares `_CatalogViewToggle` with Possible rolls; craft pool cells reuse ③ dashed uniform tiles. Remains open until craftAvailable ON dual-truth re-shot / craft fixture Capture.

---

## Closed gaps

### GAP-CAT-BROWSE-001 — Weapon family cards (version collapse)
- **Status:** closed
- **Closed:** 2026-08-05 (area-implement browse-chrome Capture dual-truth)
- **Area:** catalog
- **Slice:** browse-chrome
- **Kind:** product-behavior
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:** `docs/ux-redesign/catalog/mockups/001-browse-chrome-desktop.html` · mobile sibling · `MOCKUP-APPROVED.md` · brief `001-browse-chrome-brief.md`
- **Proof:**
  - Code: `weapon_family.dart`, family card owned-only chips, detail `_FamilyVersionSwitch`
  - Host smoke + pure tests (`weapon_family_test`, browse-chrome host fixtures)
  - Capture 2026-08-05: `implementation-shots/001-browse-chrome/desktop-family-card.png` (one Midnight Coup card Base+Adept ×3, Holofoil omitted), `desktop-detail-versions.png` (Base/Adept/Holofoil + openVersion Adept PL1810)
  - Entry: `lib/main_browse_chrome_capture.dart`
- **shot_matrix proves tokens:** `family-card-one`, `owned-version-chips-readonly`, `detail-all-versions`

### GAP-CAT-BROWSE-002 — Collapsible groups + outline jump
- **Status:** closed
- **Closed:** 2026-08-05 (area-implement browse-chrome Capture dual-truth)
- **Area:** catalog
- **Slice:** browse-chrome
- **Kind:** interaction
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:** `001-browse-chrome-desktop.html` · mobile · MOCKUP-APPROVED
- **Proof:**
  - Code: `CatalogGroupHeader` view-only collapse; `CatalogGroupOutlineRail`; host `ensureVisible` jump
  - Host smoke: collapse Kinetic leaves Energy; outline jump expands
  - Capture: `desktop-group-collapse.png`, `desktop-group-outline-jump.png`
- **shot_matrix proves tokens:** `group-collapse`, `group-outline-jump`

### GAP-CAT-BROWSE-003 — User sort + group priority reorder
- **Status:** closed
- **Closed:** 2026-08-05 (area-implement browse-chrome Capture dual-truth)
- **Area:** catalog
- **Slice:** browse-chrome
- **Kind:** interaction
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:** `001-browse-chrome-desktop.html` · mobile · MOCKUP-APPROVED
- **Proof:**
  - Code: `CatalogSortGroupSheet` + multi-key sort/group pure tests
  - Capture: `desktop-sort-reorder.png` (SORT PRIORITY list + GROUP BY Slot), `desktop-group-priority.png` (ENERGY · SOLAR / KINETIC · KINETIC)
- **shot_matrix proves tokens:** `sort-priority-reorder`, `group-priority-reorder`

### GAP-CAT-BROWSE-004 — Weapon type filters as official icons
- **Status:** closed
- **Closed:** 2026-08-05 (area-implement browse-chrome Capture dual-truth)
- **Area:** catalog
- **Slice:** browse-chrome
- **Kind:** visual-parity
- **Severity:** P1
- **blocks_dual_truth:** true
- **Mockup SSoT:** `001-browse-chrome-desktop.html` primary-line type silhouettes · MOCKUP-APPROVED
- **Proof:**
  - Code: primary `iconOnly` + `DestinyWeaponTypeIcon` / Semantics; host smoke `archetype_chip_*`
  - Capture: `desktop-type-icon-filters.png` (+ co-visible on `desktop-family-card.png`) — primary-line silhouettes
  - Structure asserts required (not PNG-only); widget/host tests green
- **shot_matrix proves tokens:** `type-filter-icons`

### GAP-CAT-PERK-004 — Remove perk band labels (① On this copy / ② Unselected / ③ Possible rolls)
- **Status:** closed
- **Closed:** 2026-08-05 (area-implement browse-chrome Capture dual-truth)
- **Area:** catalog
- **Slice:** residual-polish / browse-chrome implement
- **Kind:** visual-parity
- **Severity:** P1
- **blocks_dual_truth:** true
- **Mockup SSoT:** User 2026-08-05 — band strings not needed; tier is clear from cell chrome (badges ①②③, chevron, dashed)
- **Proof:**
  - Code: `_PerkBandLabel` / `perk_band_*` removed; legend + cell chrome retained
  - Host smoke: no band keys/text; Capture: `desktop-detail-no-band-labels.png` (Possible ON · legend · tier badges · no column band strings)
- **shot_matrix proves tokens:** `no-perk-band-labels`, `tier-cell-chrome-only`

### GAP-CAT-PERK-001 — Perk grid visual parity vs residual mockups
- **Status:** closed
- **Closed:** 2026-08-04 (area-implement residual-polish perk chrome)
- **Area:** catalog
- **Slice:** residual-polish (also affects full / weapons detail)
- **Kind:** visual-parity
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:**
  - `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html` (detail owned OFF / can-roll ON)
  - same patterns in `001-full-desktop.html` where three-tier bands appear
- **Proof:**
  - `CatalogDetailToggles` → mock pill+knob `_CatalogViewToggle` with `Semantics(toggled:)` (not FilterChip)
  - `_PerkCellTile`: ①/②/③ badges, ② gold chevron, ③ dashed muted, `kCatalogPerkCellMinHeight=48`
  - Band labels + legend when tiers present; equal Expanded @400; no H-scroll
  - Widget tests in `flutter/packages/ui_flutter/test/catalog_weapon_detail_test.dart`
  - Host smoke residual group asserts toggle + badges/chevron
  - Capture re-shot 2026-08-04: `implementation-shots/001-residual-polish/desktop-detail-owned.png`, `desktop-can-roll.png`, `desktop-enhance-note.png` (host-fixture Residual Enhanced HC / Enhance-Note Scout)
- **shot_matrix proves tokens:** `toggle-possible-rolls`, `tier-badges-or-bands`, `perk-uniform-tile`, `possible-dashed-muted`
- **Capture note:** structure asserts required; PNG archive updated with post-chrome host-fixture Driver shots

### GAP-CAT-PERK-002 — Enhanced live path misses DIM-enhanced rolls
- **Status:** closed
- **Closed:** 2026-08-04 (area-implement category enhanced map)
- **Area:** catalog
- **Slice:** residual-polish
- **Kind:** data-wiring
- **Severity:** P0
- **blocks_dual_truth:** true
- **Mockup SSoT:** gold + **E** on ①/② when this copy’s plug is enhanced
- **Proof:**
  - `buildPlugEnhancedMapFromItemDefs` — name + `plugCategoryIdentifier` via `isEnhancedPlug` (not empty-category primary)
  - `WindowsRollTagEnrichment.plugEnhancedMapBuilder` wired through `InventorySyncController` → `OwnedCatalogBridge` fallback
  - Host-fixture residual + widget tests: gold/E on ①/② only; no E on ③
  - Unit: `roll_tags_test` / `owned_catalog_bridge_plug_names_test` category path without "Enhanced" in name
  - Capture re-shot 2026-08-04: `implementation-shots/001-residual-polish/desktop-enhanced-live.png` (E on ① only) · `desktop-can-roll.png` / `desktop-enhance-note.png` (no E on ③)
- **shot_matrix proves tokens:** `e-on-12-live-or-fixture`, `no-e-on-3`, `plugEnhancedByHash-category`

---

## Index (quick scan)

| ID | Status | Area | blocks_dual_truth | Title |
| --- | --- | --- | --- | --- |
| GAP-CAT-BROWSE-001 | closed | catalog | true | Weapon family cards (version collapse) |
| GAP-CAT-BROWSE-002 | closed | catalog | true | Collapsible groups + outline jump |
| GAP-CAT-BROWSE-003 | closed | catalog | true | User sort + group priority reorder |
| GAP-CAT-BROWSE-004 | closed | catalog | true | Weapon type filters as official icons |
| GAP-CAT-PERK-001 | closed | catalog | true | Perk grid visual parity vs residual mockups |
| GAP-CAT-PERK-002 | closed | catalog | true | Enhanced live path misses DIM-enhanced rolls |
| GAP-CAT-PERK-003 | open | catalog | false | Possible crafted toggle visibility vs mock |
| GAP-CAT-PERK-004 | closed | catalog | true | Remove perk band labels (cell chrome only) |
