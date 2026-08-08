# UX brief: catalog / CatalogRollTargets

**Status:** locked  
**Date:** 2026-08-07  
**Hosts:** windows, widgetbook  
**Slice goal:** Wire Catalog weapon detail to DART-073 roll targets — named preferred+avoid multi-pick editor (Want|Avoid|Off on can-roll pool), active target switch, dual score chips (N/M preferred + avoid hits) on owned instances, rank owned closest/cleanest-first. Consume `packages/app` roll_target_use_cases + domain score; Neon/Flap; no bare hash labels.  
**Out of scope:** No auto-dismantle; no Set/variant equip-ready wishlist push; no domain/score algorithm changes (DBR-IDL already landed); no nested group-by or entity-desc 1+3; no invent can-roll plugs; mobile Catalog push not exit gate.

## Product posture

- Job: author named soft roll targets on Catalog weapon detail, switch active profile, see dual preferred/avoid scores on owned copies, rank closest/cleanest-first when active  
- Gap: GAP-UI-ROLL-01 / UX-CATALOG-ROLL-TARGETS (system DART-073 landed; chrome absent)  
- Rule IDs: DBR-IDL-001–008, DBR-UI-006/007, BR-CAT-016, DBR-PUR-002, FEAT-UI-WEAPON-ROLL-TARGETS, DART-073  

## Locked decisions

| Topic | Decision |
| --- | --- |
| Surface | Lives on standard `CatalogWeaponDetail` (~400) — not a separate screen |
| Chrome | Neon/Flap residual (001 + 002); no Material ChoiceChip; no new design system |
| Base chip (002 lock) | power bold · `T{tier}` plate · special hue; dual score segs **additive trailing only** — never replace power\|tier\|special |
| Dual segs | When active target && `hasAnyScoreDimension`: preferred `N/M` (success-tint when N==M>0) + avoid `Av k` (danger/warn k>0; muted k=0). Hide segs when no active / unscored |
| Rank | Active → `rankOwnedForRollTarget` (preferredRatio desc → avoidHits asc → power/tier). No active → power-desc + highest default (002) |
| Switcher | Named multi-profile list (PvE/PvP…) + Off/none; default active = none/Off; names not bare ids/hashes |
| Editor | Default closed; open via “Edit roll target”; Want\|Avoid\|Off multi-pick on **can-roll ③ pool only** (BR-CAT-016); one mode per plug per column |
| View wash | View mode only: soft diagonal wash behind perk icon (LR→UL) — green preferred / red avoid; **no wash in edit mode** (W/A badges only) |
| Overlap | Preferred∩avoid same column → soft Neon error; save disabled until disjoint (DBR-IDL-004) |
| Soft scores | Never block save/equip/export (DBR-IDL-008); ≠ equip wishlist; no dismantle CTA |
| Exotics | **No roll targets** (DBR-IDL-009) — exotic perks are fixed; hide switcher/editor/scores/rank |
| Labels | Named plug + icon everywhere (DBR-UI-006); hashes only `CatalogHashFooter` unknowns |
| Selection | User-controlled after rank reorder; do not auto-jump on profile switch unless prior instance id missing |
| Empty | “No local copies” honesty (002); unowned may keep switcher+editor on definition ③ pool only |
| Tokens | `--success` preferred, `--danger`/`--warn` avoid hits, `--accent` switcher, radius 2px, chip-h 30 desktop / 32 mobile |

## State matrix (must demo)

owned-no-targets · owned-targets-none-active · active-unscored · active-partial · active-perfect-clean · active-bad-roll · multi-profile-switch · editor-want-avoid-off · editor-overlap-reject · unowned-or-empty · mobile-390 · keyboard-a11y

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-desktop.html`
- `docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-mobile.html`
- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (CatalogRollTargets 003 — continue with workflow)
- Baseline chrome SSoT (do not reopen): `002-weapon-instance-strip-*.html`, `001-residual-polish-*.html`

## Implement notes (`packages/ui_flutter`)

- Add `CatalogRollTargets` chrome (switcher + editor shell) under `lib/src/catalog/`; export from `destiny2_ui_flutter.dart`
- Extend `catalog_weapon_detail.dart` / `WeaponInstanceStrip`: additive dual segs + optional rank order props; preserve 002 base chip
- Extend `catalog_perk_grid.dart`: view diagonal wash + edit Want\|Avoid\|Off tri-state on ③ pool cells; soft overlap error
- Props in only: active target, target list, match results, callbacks — no domain/IO in ui_flutter
- Host wire (`windows_host` `catalog_page.dart`): create/update/delete/list/setActive/getActive + `rankOwnedForRollTarget` from `packages/app` `roll_target_use_cases`; pure score stays domain
- Selected instance stays user-controlled after reorder
- Widgetbook knobs: `activeTarget(none|pve|pvp)`, `showEditor`, score presets (partial|perfect|dirty), `instanceCount`; desktop 400 + mobile 390

## Widget test inventory (minimum)

- Dual segs hidden when no active target or `!hasAnyScoreDimension`
- Dual segs show `N/M` + `Av k` from match; success tint when N==M>0; danger when avoidHits>0
- Base chip still power · T{tier} · special only (no MW/Craft; scores trailing)
- Active rank order matches preferredRatio desc → avoidHits asc → power/tier
- No active → power-desc order unchanged (002)
- Switcher lists target **names** + Off; no bare hash/id primary labels
- Editor: Want\|Avoid\|Off on pool; preferred∩avoid soft error + save disabled
- View wash on preferred/avoid cells; no wash while editing
- Empty instances: “No local copies”; no dual chips
- Overlap reject does not block equip/export paths (soft only)
- A11y: Semantics/aria for named target + “N of M preferred, k avoid hits”
- No ChoiceChip / Material score chrome

## Widgetbook backlog

- Catalog detail · roll targets desktop 400 — matrix scenarios
- Catalog detail · roll targets mobile 390 — switcher full-width, dual-seg wrap, ≥44px
- Knobs: activeTarget none|pve|pvp; showEditor; score partial|perfect|dirty; instanceCount
- Editor open: Want\|Avoid\|Off cycle + overlap soft error case
- Active rank reorder vs power-desc default
- Unowned/empty: no strip dual chips; definition pool editor optional
- Keyboard: Tab switcher → chips → pool; focus-visible cyan ring
- Dual-truth re-shots after implement → `implementation-shots/003-catalog-roll-targets/`

## Nice-to-have (not gate)

- Per-column tooltip legend (matched|miss|unscored / hit|clear|unscored)
- Keyboard cycle Want→Avoid→Off on focused pool cell
- Inline rename / New / Delete on switcher; sticky editor bar mobile 390
- Perfect+clean subtle success pulse on selected chip only
- Micro-note under INSTANCES: “Ranked by roll target” when ranking active

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "catalog-roll-targets",
  "brief_path": "docs/ux-redesign/catalog/003-catalog-roll-targets-brief.md",
  "hosts": ["windows", "widgetbook"]
}
```
```

---

### Structured fields (summary)

| Field | Value |
| --- | --- |
| **title** | catalog / CatalogRollTargets |
| **slice_goal** | Wire detail to DART-073: named preferred+avoid editor, active switch, dual N/M + avoid chips, closest/cleanest rank; app use cases + domain score; Neon/Flap; no bare hashes |
| **out_of_scope** | No auto-dismantle; no wishlist push; no domain/score changes; no nested group-by/1+3; no invent plugs; mobile Catalog push not exit gate |
| **mockup_paths** | 003 desktop/mobile + MOCKUP-APPROVED; 002/001 baseline only |
| **rule_ids** | DBR-IDL-001…008, DBR-UI-006/007, BR-CAT-016, DBR-PUR-002, GAP-UI-ROLL-01, FEAT-UI-WEAPON-ROLL-TARGETS, DART-073, UX-CATALOG-ROLL-TARGETS |

```json
{
  "title": "catalog / CatalogRollTargets",
  "slice_goal": "Wire Catalog weapon detail to DART-073 roll targets: named preferred+avoid multi-pick editor (Want|Avoid|Off on can-roll pool), active target switch, dual score chips (N/M preferred + avoid hits) on owned instances, rank owned closest/cleanest-first. Consume packages/app roll_target_use_cases + domain score; Neon/Flap; no bare hash labels.",
  "out_of_scope": "No auto-dismantle; no Set/variant equip-ready wishlist push; no domain/score algorithm changes (DBR-IDL already landed); no nested group-by or entity-desc 1+3; no invent can-roll plugs; mobile Catalog push not exit gate.",
  "locked_decisions": [
    "Lives on CatalogWeaponDetail (~400); Neon/Flap residual — no Material ChoiceChip or new design system",
    "002 base chip locked (power · T{tier} · special); dual score segs additive trailing only when active && hasAnyScoreDimension",
    "Preferred seg N/M (success when N==M>0); avoid Av k (danger/warn k>0, muted k=0); hide segs when no active/unscored",
    "Active rank = rankOwnedForRollTarget (preferredRatio desc → avoidHits asc → power/tier); else power-desc + highest default",
    "Named multi-profile switcher + Off/none; default active none/Off; names not bare ids/hashes",
    "Editor default closed; Want|Avoid|Off multi-pick on can-roll ③ pool only; one mode per plug per column",
    "View mode: soft diagonal wash behind icon (green preferred / red avoid); edit mode W/A badges only — no wash",
    "Preferred∩avoid same column soft Neon error + save disabled (DBR-IDL-004); scores never block equip/export (DBR-IDL-008)",
    "Named plug+icon labels (DBR-UI-006); CatalogHashFooter unknowns-only; ≠ wishlist; no dismantle CTA",
    "Selection user-controlled after rank reorder; no auto-jump on profile switch unless prior instance id missing"
  ],
  "acceptance": [
    "Dual segs hidden when no active target or !hasAnyScoreDimension",
    "Dual segs show N/M + Av k; success tint when N==M>0; danger/warn when avoidHits>0",
    "Base chip remains power · T{tier} · special only; scores never replace 002 segments",
    "With active target, owned order = rankOwnedForRollTarget; without active, power-desc preserved",
    "Switcher shows named profiles + Off; default Off; no bare target hash/id primary labels",
    "Editor Want|Avoid|Off on ③ can-roll pool; named plug+icon cells; no invent plugs",
    "Preferred∩avoid soft error disables save until disjoint; does not block equip/export",
    "View diagonal wash preferred/avoid behind icon; no wash while editing",
    "Empty instances keep No local copies; no dual chips; unowned may edit definition pool only",
    "Host wires app use cases (CRUD/list/setActive/getActive + rankOwnedForRollTarget); domain score unchanged",
    "Widget tests cover segs/rank/switcher/editor/overlap/a11y; no ChoiceChip score chrome",
    "Widgetbook desktop 400 + mobile 390 cases with knobs for activeTarget, showEditor, score presets, instanceCount"
  ],
  "mockup_paths": [
    "docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-desktop.html",
    "docs/ux-redesign/catalog/mockups/003-catalog-roll-targets-mobile.html",
    "docs/ux-redesign/catalog/MOCKUP-APPROVED.md",
    "docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-desktop.html",
    "docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-mobile.html",
    "docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html",
    "docs/ux-redesign/catalog/mockups/001-residual-polish-mobile.html"
  ],
  "implement_notes": [
    "Add CatalogRollTargets switcher+editor under packages/ui_flutter/lib/src/catalog/; export destiny2_ui_flutter.dart",
    "Extend catalog_weapon_detail.dart WeaponInstanceStrip with additive dual segs + rank order props; preserve 002 base",
    "Extend catalog_perk_grid.dart: view diagonal wash + edit Want|Avoid|Off tri-state; soft overlap error chrome",
    "UI takes presentation props/callbacks only — no domain/IO deps in ui_flutter",
    "windows_host catalog_page.dart wires create/update/delete/list/setActive/getActive + rankOwnedForRollTarget from packages/app",
    "Keep pure score in packages/domain roll_target_score; do not re-implement DART-073 algorithms",
    "Selected instance stays user-controlled after rank reorder unless prior id missing",
    "Widgetbook knobs: activeTarget(none|pve|pvp), showEditor, score partial|perfect|dirty, instanceCount; 400 + 390 cases"
  ],
  "widget_test_inventory": [
    "Dual segs hidden when no active or !hasAnyScoreDimension",
    "Dual segs N/M + Av k from RollTargetMatchResult; success/danger tints",
    "Base chip power|tier|special unchanged (no MW/Craft)",
    "Active rank preferredRatio desc → avoidHits asc → power/tier",
    "No active keeps power-desc order",
    "Switcher names + Off; no bare hash primary labels",
    "Editor Want|Avoid|Off; preferred∩avoid soft error + save disabled",
    "View wash on preferred/avoid; no wash in edit mode",
    "Empty No local copies; no dual chips",
    "Semantics: named target + N of M preferred + avoid hits",
    "No Material ChoiceChip score chrome"
  ],
  "widgetbook_backlog": [
    "Catalog detail roll targets desktop 400 — state matrix scenarios",
    "Catalog detail roll targets mobile 390 — full-width switcher, dual-seg wrap, ≥44px",
    "Knobs: activeTarget none|pve|pvp; showEditor; score partial|perfect|dirty; instanceCount",
    "Editor open + overlap soft error case",
    "Active rank reorder vs power-desc default",
    "Unowned/empty: no strip dual chips; definition pool editor",
    "Keyboard a11y Tab switcher→chips→pool",
    "Post-implement dual-truth shots under implementation-shots/003-catalog-roll-targets/"
  ],
  "rule_ids": [
    "DBR-IDL-001",
    "DBR-IDL-002",
    "DBR-IDL-003",
    "DBR-IDL-004",
    "DBR-IDL-005",
    "DBR-IDL-006",
    "DBR-IDL-007",
    "DBR-IDL-008",
    "DBR-UI-006",
    "DBR-UI-007",
    "BR-CAT-016",
    "DBR-PUR-002",
    "GAP-UI-ROLL-01",
    "FEAT-UI-WEAPON-ROLL-TARGETS",
    "DART-073",
    "UX-CATALOG-ROLL-TARGETS"
  ]
}
``
