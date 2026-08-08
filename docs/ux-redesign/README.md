# Area UX redesign loop

Reusable process for rebuilding Flutter product areas one at a time after the **Settings-only** shell baseline.

Design system (`packages/ui_tokens`, `packages/ui_flutter`) stays. Product intent comes from ProjectTracker vault notes + repo DBR/DAC/BR + product-map.

## Lane: UI/UX (not Spec Kit)

**Policy (2026-08-06, D-LANES):** this track owns **UI/UX** changes — mockups, interaction, chrome, Widgetbook, dual-truth Capture, and host presentation wire of **already-shipped** system APIs.

| Do here | Do **not** do here |
| ------- | ------------------ |
| Nested group **headers**, outline JUMP chrome, hotspot/popover **widgets** | Pure group-tree / entity-presentation **models** (those are Spec Kit **DART-NNN**) |
| Density, tokens chrome, dual-truth residuals | Domain/DBR algorithm changes, Drift, inventory sync core |
| Briefs under `docs/ux-redesign/<area>/` | Full Spec Kit `specs/dart-NNN-*` for chrome-only work |

When a feature needs both system + chrome (e.g. nested Catalog group-by, entity descriptions 1+3):

1. Prefer **system Spec Kit first** (or at least a stable pure API) — see [multiplatform-dart-feature-gaps.md](../multiplatform-dart-feature-gaps.md) open GAP split tracks.  
2. Then run this loop with a brief that **depends on** that API (fixtures OK for mockups before land).

Cross-links: [feature-gaps workstream lanes](../multiplatform-dart-feature-gaps.md#workstream-lanes-going-forward) · [slice roadmap Spec Kit vs UI/UX](../multiplatform-dart-slice-roadmap.md) · port decision **D-LANES**.

## Loop (closed)

```text
area-ux-redesign  →  mockups + brief
        ↓
area-implement    →  Flutter + tests (structure gate)
        ↓
Capture           →  shot_matrix dual-truth PNGs next to mockups
        ↓              (pause if must-rows missing — see CAPTURE.md)
next area-ux-redesign uses mockups + shots as dual ground truth
```

**Implement gates:** **structure** (analyze + tests) · **shot matrix** (real PNGs for every `must` row) · **gap log** (open `blocks_dual_truth` items in [`DUAL-TRUTH-GAPS.md`](DUAL-TRUTH-GAPS.md)). Structure green + PNG presence alone is not dual-truth if the user can still see mockup≠ship. Protocol: [`CAPTURE.md`](CAPTURE.md).

**Plan STE map:** every `area-implement` plan must end with **`ste_map`** — Simplified Technical English rows `{ architecture, task, file }` that link product/architecture intent to concrete paths (one idea per task sentence; active voice). See example: `catalog/003-catalog-roll-targets-implement-plan.md`.

**How you flag gaps:** edit [`DUAL-TRUTH-GAPS.md`](DUAL-TRUTH-GAPS.md) (template inside). Paste or link screenshots; set `blocks_dual_truth: true` so implement cannot soft-close.

## Workflows

| Workflow | Path | Purpose |
| --- | --- | --- |
| `area-ux-redesign` | [`.grok/workflows/area-ux-redesign.rhai`](../../.grok/workflows/area-ux-redesign.rhai) | Product grill → UX grill → **interactive HTML mockups** → human gate → synthesis → architect → Obsidian UX note. **Loads prior `implementation-shots/`** when present. |
| `area-ux-component` | [`.grok/workflows/area-ux-component.rhai`](../../.grok/workflows/area-ux-component.rhai) | **Lightweight** one-component UX: context + ship↔mock deltas → focused mockups → human gate → short brief (no full-area grill / Obsidian architect panel). Prefer for `WeaponInstanceStrip`, perk chrome, etc. |
| `area-implement` | [`.grok/workflows/area-implement.rhai`](../../.grok/workflows/area-implement.rhai) | Plan includes **shot_matrix** + **STE map** (architecture → file) → implement → **Verify-structure** → review → **Capture** → report |

Run from Grok Build:

```text
/workflow area-ux-redesign
# args example:
# { "area": "catalog", "subarea": "weapons", "hosts": ["windows", "mobile"] }

/workflow area-ux-component
# args example:
# { "area": "catalog", "component": "WeaponInstanceStrip",
#   "slice_goal": "Match residual .inst-chip chrome; multi-PL H-scroll; power-desc default" }

/workflow area-implement
# args example:
# { "area": "catalog", "subarea": "weapons", "brief_path": "docs/ux-redesign/catalog/001-weapons-brief.md" }
```

## Artifact layout

```text
docs/ux-redesign/
  README.md
  CAPTURE.md                      # dual-truth matrix + Flutter launch rules
  DUAL-TRUTH-GAPS.md              # human gap memory (workflows must load)
  _template-area-brief.md
  _template-implementation-shots-compare.md
  <area>/
    NNN-<slice>-brief.md
    NNN-<slice>-grill.md
    NNN-<slice>-implement-report.md
    MOCKUP-APPROVED.md
    mockups/
      NNN-<slice>-desktop.html
      NNN-<slice>-mobile.html
    implementation-shots/
      README.md
      <slice-id>/                 # e.g. 001-weapons or 002-weapon-details
        COMPARE.md                # mockup ↔ shot table + residuals
        desktop-grid.png
        desktop-detail-owned.png
        desktop-detail-unowned.png
        desktop-can-roll.png
        mobile-detail.png
        …
```

### COMPARE.md (required per slice after implement)

One row per scenario:

| Scenario | Mockup | Implementation shot | Residual for next redesign |
| --- | --- | --- | --- |
| Desktop detail owned | `mockups/001-….html` | `implementation-shots/…/desktop-detail-owned.png` | e.g. icon-only meta still text |

## Vault (Obsidian ProjectTracker)

High-level UX/UI narrative lives under:

```text
requirements/Projects/Destiny 2 Build Creator/UX/
  UX Catalog.md
  …
```

Link each note from the matching `Areas/Area *.md`. Remount the vault junction if needed:

```powershell
pwsh -File scripts/link-projecttracker-requirements.ps1
```

## Gates (summary)

1. **Mockups** interactive in browser before brief lock  
2. **Mockup review loop** (important):
   - Give **feedback in chat** → UX agent evaluates and **updates mockups** → you re-review  
   - **Do not resume** the workflow while still giving feedback  
   - Only when finished reviewing, say **`continue with workflow`**, write `docs/ux-redesign/<area>/MOCKUP-APPROVED.md` containing that phrase, **then** resume  
   - Resume without approval → revision round, not brief lock  
3. **Obsidian** UX note updated same pass  
4. **Architect** lists widget test inventory before implement  
5. **Implement** ships unit + higher-level widget tests + host smoke (**tests always required**)  
6. **Verify** also captures **Flutter MCP + Driver screenshots** (part of testing, not optional polish)  
7. **Capture** organizes those shots into `implementation-shots/` + `COMPARE.md` beside mockups  
8. **Next redesign** must load `implementation-shots/` + mockups  
9. **Widgetbook** — isolated catalog of shared composables  
   App: [`flutter/apps/widgetbook`](../../flutter/apps/widgetbook) · notes: [`widgetbook.md`](widgetbook.md)

## How to capture shots (required path: Flutter MCP + Driver)

**Preferred (agent / area-implement Verify):**

1. Dart MCP: `list_devices` → non-web (e.g. `windows`)  
2. `launch_app` with host root + **`target=lib/main_mcp.dart`** (enables Flutter Driver)  
3. Connect DTD; `flutter_driver` · `get_health`  
4. Drive scenarios via `tap` / `waitFor` using real keys from `get_widget_tree` (never invent finders)  
5. For each scenario: `flutter_driver` · **`screenshot`** → write PNG under  
   `docs/ux-redesign/<area>/implementation-shots/<slice-id>/`  
6. `stop_app` when done; fill `COMPARE.md`

Host docs: `flutter/apps/windows_host/README.md` (Flutter Driver / agent screenshots).

**Manual shell fallback** (only if MCP launch fails):

```powershell
cd flutter/apps/windows_host
.\run-windows.ps1 -EnableFlutterDriver
# or: flutter run -d windows --dart-define=ENABLE_FLUTTER_DRIVER=true ...
# Then agent connects DTD and uses flutter_driver screenshot, or you paste DTD.
```

Do **not** invent screenshots. Human OS capture is last resort only.

## First slice

**Catalog — Weapons browse + detail** (owned + manifest). Armor, Universal, live Set/Synergy outbound, and constrained pick are later.

After the latest implement, drop screenshots under:

`docs/ux-redesign/catalog/implementation-shots/001-weapons/`
