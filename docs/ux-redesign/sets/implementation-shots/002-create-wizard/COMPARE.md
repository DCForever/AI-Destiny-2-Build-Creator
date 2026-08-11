# Implementation shots — sets / 002-create-wizard

**Date:** 2026-08-10  
**Status:** **Capture complete** — all `must:true` matrix rows on disk; dual-truth **closed** for Sets Create wizard matrix (mobile structure-only)  
**Hosts:** windows (exit gate); mobile structure-only  
**Brief / plan:** `docs/ux-redesign/sets/002-create-wizard-brief.md`, `002-create-wizard-implement-plan.md`  
**Mockups (structure SSoT):**

- `docs/ux-redesign/sets/mockups/001-armor-desktop.html` (create wizard steps)
- `docs/ux-redesign/sets/mockups/001-armor-mobile.html`

**Capture entry:** `flutter/apps/windows_host/lib/main_sets_armor_capture.dart`  
**Fixtures:** `kSetsCreateWizardMustShotIds` in `sets_armor_capture_fixtures.dart`  
**Driver sequence:** `capture-sequence.json` via `tool/capture_driver_shots.dart`  
**Launch:** `background_shell` (`flutter run -d windows -t lib/main_sets_armor_capture.dart` + `ENABLE_FLUTTER_DRIVER=1` · `set_frame_sync` false via `runUnsynchronized` · `scrollIntoView` before off-screen scenario chips)

## Residual RES-SET-CREATE-01

| Mockup | Ship (after this pass) | Residual |
| --- | --- | --- |
| Multi-step Type → Class → Bonus → Name | `SetsCreateWizard` step machine + host footer | **closed** (widget + host smoke + PNG) |
| Step dots + crumb | `sets_create_step_dots` / `sets_create_crumb` | **closed** |
| Footer Back / Continue / Cancel; Create final | `SetsCreateWizardFooter` | **closed** |
| One step at a time | active step only | **closed** |
| Bonus editor only on Bonus | step 2 mounts `SetsBonusGoalsEditor` | **closed** |
| Hide Quick create product rail | library New (`+`) only; no Quick create | **closed** |
| Post-create empty board layout A | empty `SetsArmorBoard` (Optimize + five Pick) | **closed** |
| Capture must PNGs | all 6 must-rows on disk | **closed** |

## Scenario matrix

| Scenario | Drive | Shot | Proves | Residual |
| --- | --- | --- | --- | --- |
| desktop-create-step-type | host-fixture | `desktop-create-step-type.png` | step-dots; type-grid; continue-gated; one-step | **closed** — Type step only; Armor selected; Continue primary; no Back; pieces hidden |
| desktop-create-step-class | host-fixture | `desktop-create-step-class.png` | class-grid; pieces-hidden; back-visible | **closed** — Class chips; Continue disabled until class; Back visible |
| desktop-create-step-bonus | host-fixture | `desktop-create-step-bonus.png` | bonus-editor-only; searchable-catalog; entity-info-hotspot | **closed** — `SetsBonusGoalsEditor` + search + ⓘ hotspot; Back+Continue |
| desktop-create-step-name | host-fixture | `desktop-create-step-name.png` | name-field; auto-name-preview; create-primary | **closed** — Create primary final; preview Titan · — · — |
| desktop-create-post-board | host-fixture | `desktop-create-post-board.png` | empty-board-layout-a; optimize-primary; five-pick | **closed** — Optimize bar + Σ0 + five Empty/Pick |
| desktop-create-no-quick-create | host-fixture | `desktop-create-no-quick-create.png` | library-new-only; no-quick-create-rail | **closed** — dual-pane library + New (`+`); no Quick create chrome |
| desktop-create-non-armor-thin | host-fixture (optional) | `desktop-create-non-armor-thin.png` | skip-class-bonus; thin-shell | **closed** (optional captured) |
| widget-create-step-machine | widget-test-only | — | full step machine | tests only |

## Verify residuals (shot + structure)

1. **Step machine chrome** — one step visible; dots/crumb track active; footer Back hidden on step 0; Create only final. **closed**.
2. **Type/Class gates** — Continue enabled when type set; disabled on Class until pick. **closed**.
3. **Bonus only on Bonus** — searchable catalog + EntityInfoHotspot (ⓘ); no pieces/compare. **closed**.
4. **Name + Create** — auto-name preview; Create primary. **closed** (label is **Create**, not mockup “Open empty board” — brief accepts Create + auto-open board).
5. **Post-create board A** — Optimize primary; five Pick; Σ zeros. **closed**.
6. **No Quick create** — library New only. **closed**.
7. **Capture harness chrome** — scenario chip rail + DEBUG banner are **not** product Sets chrome (same class as other host-fixture Captures).
8. **Visual polish residuals (next redesign, non-blocking):**
   - Type/Class use `ChoiceChip` / compact chips vs mockup larger choice-grid buttons (structure-equivalent).
   - Bonus chrome is `SetsBonusGoalsEditor` (None + search + family rows) vs mockup mode-seg (brief: reuse editor).
   - Rail column density on library shot (NAME/CLASS/PCS truncate at narrow default rail) — shared with 001-armor residual.

## Checklist

- [x] `desktop-create-step-type.png`
- [x] `desktop-create-step-class.png`
- [x] `desktop-create-step-bonus.png`
- [x] `desktop-create-step-name.png`
- [x] `desktop-create-post-board.png`
- [x] `desktop-create-no-quick-create.png`
- [x] `desktop-create-non-armor-thin.png` (optional)
- [x] Widget step-machine tests
- [x] Host smoke stepped create → board
- [x] Quick create hidden on product rail
- [x] dual_truth_ok after must-rows + residual review (no `blocks_dual_truth` open gaps for sets)

## Deferred / next redesign

- Choice-grid visual density (larger type/class cards) if product wants mockup pixel match beyond structure.
- Bonus mode-seg chrome vs catalog editor (only if product rejects editor reuse).
- product-map parity report lag vs `surfaces.yaml` `sets.create` done (re-run `product-map:parity` after hub sync if needed).
- Mobile structure-only sheets (not Capture gate).

## Next

```text
# Optional: npm run product-map:parity from monorepo root if report still lists sets.create stub
```
