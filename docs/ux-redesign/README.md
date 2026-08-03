# Area UX redesign loop

Reusable process for rebuilding Flutter product areas one at a time after the **Settings-only** shell baseline.

Design system (`packages/ui_tokens`, `packages/ui_flutter`) stays. Product intent comes from ProjectTracker vault notes + repo DBR/DAC/BR + product-map.

## Workflows

| Workflow | Path | Purpose |
| --- | --- | --- |
| `area-ux-redesign` | [`.grok/workflows/area-ux-redesign.rhai`](../../.grok/workflows/area-ux-redesign.rhai) | Product grill → UX grill → **interactive HTML mockups** → human gate → synthesis → architect → Obsidian UX note |
| `area-implement` | [`.grok/workflows/area-implement.rhai`](../../.grok/workflows/area-implement.rhai) | Implement locked brief + mockups with required widget tests |

Run from Grok Build:

```text
/workflow area-ux-redesign
# args example:
# { "area": "catalog", "subarea": "weapons", "hosts": ["windows", "mobile"] }

/workflow area-implement
# args example:
# { "area": "catalog", "subarea": "weapons", "brief_path": "docs/ux-redesign/catalog/001-weapons-brief.md" }
```

## Artifact layout

```text
docs/ux-redesign/
  README.md
  _template-area-brief.md
  <area>/
    NNN-<slice>-brief.md
    NNN-<slice>-grill.md
    mockups/
      NNN-<slice>-desktop.html
      NNN-<slice>-mobile.html
```

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
5. **Implement** ships unit + higher-level widget tests + host smoke  
6. **Widgetbook** (follow-up after first shared composables)

## First slice

**Catalog — Weapons browse + detail** (owned + manifest). Armor, Universal, live Set/Synergy outbound, and constrained pick are later.
