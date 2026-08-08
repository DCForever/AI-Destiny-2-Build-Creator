# UX brief: catalog / EntityInfoHotspot

**Status:** locked  
**Date:** 2026-08-08  
**Hosts:** windows, widgetbook  
**Slice goal:** Ship 1+3 entity info chrome on Catalog weapons perk cells — hover/focus (desktop) and long-press / Alt+tap (mobile) show host `EntityPresentation`; click/tap keeps primary select. Consume pure DART-071 resolve; never invent description text. Neon/Flap residual.  
**Out of scope:** Full Catalog redesign; Armor/mods/abilities first wire; invent Destiny description copy; sticky multi-perk inspect sheet (mobile browse-while-inspect residual); L3 wiki/LLM; domain/map algorithm changes; nested group-by; roll-target score algorithm; mobile Catalog push exit gate.

## Product posture

- Job: reveal Destiny definition text for icon-first plugs without inventing copy; keep select as the primary cell action  
- Gap: **GAP-UI-DESC-01** Track B / **UX-CATALOG-ENTITY-DESC** / **FEAT-UI-ENTITY-DESC** (system **DART-071** landed; chrome absent)  
- Rule IDs: DBR-UI-001, DBR-UI-005, DBR-UI-006, DAC-DST-015, DART-071  

## Locked decisions

| Topic | Decision |
| --- | --- |
| First wire | Catalog weapons perk grid (`CatalogPerkCell` / `catalog_perk_grid.dart`) inside `CatalogWeaponDetail` (~400) |
| Info content | From pure `EntityPresentation` (name, kind?, iconPath?, description, metaLines, nameUnknown, hashFooter) — host maps / `resolveEntityPresentation*` only |
| Never invent | Empty / missing description → fixed UI string **`No catalog description`**; never synthesize lore |
| Labels | `displayName` / presentation.name primary; hash never primary label (DBR-UI-006); optional hash footer for unknowns only |
| Desktop interaction | **Hover/focus → full info Flap** (~280px, portaled above detail clip); **click = primary** (select perk / roll-target cycle in edit) — does **not** open or pin info |
| Mobile interaction | **Tap = primary** select; **long-press ≥450ms** or **Alt+tap** → modal bottom sheet (same content model as desktop info) |
| Keyboard | Focus shows info (desktop); Enter/Space = primary select; Esc dismisses info; focus-visible cyan |
| Single-open | One info surface at a time (scoped to detail); opening B closes A |
| Residual cell chrome | ①/②/③ · gold **E** only on ①/② · dashed pool · equal cells @400 · no perk H-scroll — **do not redesign** |
| Enhance | ③/craft = “Can be enhanced” note + single identity cell; base vs enhanced **compare only inside info** when both descs supplied |
| Roll-target | Primary click/tap cycles W/A/none when editor active; hover / long-press / Alt+tap still show info (non-blocking) |
| Portal | Info portaled outside detail clip; no detail widen |
| Empty honesty | null/blank description never invents; unknown label “Unknown perk” + optional hash footer |
| Description source | Build/runtime maps via entity stores (`F:\d2w\entity` / host channel) — fixtures only in mock/Widgetbook |

## State matrix (must demo)

desc-present · desc-empty · desc-null · unknown-perk · enhanced-① · enhance-note-③ · enhance-compare · single-open · hover-leave-or-esc · roll-target-primary · missing-icon · desktop-400 · mobile-390 · keyboard-a11y

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-desktop.html`
- `docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-mobile.html`
- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (EntityInfoHotspot 004 — continue with workflow)
- Baseline residual (do not reopen): perk cell chrome from `001-residual-polish` / roll-target wash from `003`

## Implement notes (`packages/ui_flutter` + thin host)

- Add `EntityInfoHotspot` (or equivalent) primitive under `lib/src/` — portaled Flap desktop + sheet mobile; export from `destiny2_ui_flutter.dart`
- Wire into `catalog_perk_grid.dart` / perk cell: replace name-only Material `Tooltip` path for description surface; **preserve** onTap/select and roll-target cycle as primary
- Props in only: resolved `EntityPresentation` (or maps + hash), tier/meta strings for a11y, optional base/enhanced desc pair for compare, callbacks for primary — **no IO** in ui_flutter
- Host (`windows_host` Catalog detail): resolve via `resolveEntityPresentation` / maps from entity + inventory enrichment; never hardcode Destiny body text
- Single-open registry scoped to detail (Overlay / shared controller)
- Portal above `CatalogWeaponDetail` clip; width ~280 desktop; sheet modal mobile
- Widgetbook: knobs description present|empty|null · tier · enhanced · canBeEnhanced note · base+enh compare; desktop 400 + mobile 390
- Pure package remains source of truth for resolve; ui_flutter only presents

## Widget test inventory (minimum)

- Hover/focus path shows info with supplied description (desktop semantics / tester hover where possible)
- Click/tap does not open info; invokes primary (select) callback
- Mobile: long-press / explicit secondary opens sheet; short tap primary only
- Empty description → exact “No catalog description”; no invented body
- Null description honest empty path
- Unknown: primary label not bare hash; optional footer only
- Single-open: second open closes first
- Esc / leave dismisses info without changing selection
- Residual: E only ①/②; no H-scroll regression @400
- A11y name = displayName (+ tier meta); info dialog labelled by title
- No domain invent; presentation fields only

## Widgetbook backlog

- EntityInfoHotspot · desktop 400 — matrix scenarios  
- EntityInfoHotspot · mobile 390 — long-press / Alt+tap sheet  
- Knobs: description present|empty|null; tier ①|②|③|craft; enhanced; note; compare  
- Catalog perk grid story: hover info + click select dual path  
- Unknown + missing icon letter fallback  
- Dual-truth re-shots after implement → `implementation-shots/004-entity-info-hotspot/`

## Nice-to-have (not gate)

- Sticky / stationary mobile sheet for multi-perk browse-while-inspect (user residual; separate work)
- Keyboard “info” chord beyond focus-show on desktop
- Reuse primitive on meta strip / origin / armor later

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "entity-info-hotspot",
  "brief_path": "docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md",
  "hosts": ["windows", "widgetbook"]
}
```

---

### Structured fields (summary)

| Field | Value |
| --- | --- |
| **title** | catalog / EntityInfoHotspot |
| **slice_goal** | 1+3 info chrome on weapons perk cells; hover/long-press info; click/tap primary select; DART-071 consume; no invent text |
| **out_of_scope** | Full redesign; Armor first wire; invent text; sticky multi-perk sheet; L3; domain changes |
| **mockup_paths** | 004 desktop/mobile + MOCKUP-APPROVED |
| **rule_ids** | DBR-UI-001/005/006, DAC-DST-015, DART-071, GAP-UI-DESC-01, UX-CATALOG-ENTITY-DESC |

```json
{
  "title": "catalog / EntityInfoHotspot",
  "slice_goal": "Ship 1+3 entity info chrome on Catalog weapons perk cells — hover/focus (desktop) and long-press / Alt+tap (mobile) show host EntityPresentation; click/tap keeps primary select. Consume pure DART-071 resolve; never invent description text.",
  "out_of_scope": "Full Catalog redesign; Armor/mods first wire; invent Destiny description copy; sticky multi-perk inspect sheet; L3 wiki/LLM; domain/map algorithm changes; nested group-by; mobile Catalog push exit gate.",
  "locked_decisions": [
    "First wire: Catalog weapons perk grid inside CatalogWeaponDetail (~400)",
    "Info from EntityPresentation only — never invent body; honest empty = No catalog description",
    "Desktop: hover/focus = full info Flap; click = primary select (never opens info)",
    "Mobile: tap = primary; long-press ≥450ms or Alt+tap = info sheet",
    "Single-open stack; Esc/leave/scrim dismiss; portal above detail clip ~280px",
    "Residual cell chrome locked (①/②/③ · E on ①/② only · no H-scroll)",
    "Base vs enhanced compare = info-only when both descs supplied",
    "Hash never primary label; optional hash footer unknowns only"
  ],
  "acceptance": [
    "Hover/focus shows presentation description when present",
    "Click/tap never opens info; primary select still works",
    "Empty/null description shows fixed No catalog description",
    "Single-open + dismiss paths; no 400 widen / perk H-scroll regression",
    "Widget tests + Widgetbook knobs cover state matrix",
    "No invented Destiny text; DART-071 fields only"
  ],
  "mockup_paths": [
    "docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-desktop.html",
    "docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-mobile.html",
    "docs/ux-redesign/catalog/MOCKUP-APPROVED.md"
  ],
  "implement_notes": [
    "EntityInfoHotspot primitive in packages/ui_flutter",
    "Wire catalog_perk_grid primary vs info gestures",
    "Host resolveEntityPresentation maps; fixtures in Widgetbook only",
    "Portal Overlay single-open controller"
  ],
  "widget_test_inventory": [
    "hover/focus opens info with body",
    "click primary not info",
    "mobile long-press/Alt secondary",
    "honest empty string",
    "unknown not bare hash",
    "single-open",
    "Esc dismiss",
    "no H-scroll @400",
    "a11y name = displayName"
  ],
  "widgetbook_backlog": [
    "desktop 400 matrix",
    "mobile 390 sheet",
    "description knobs present|empty|null",
    "tier/enhanced/compare knobs",
    "dual-truth shots folder 004"
  ],
  "rule_ids": [
    "DBR-UI-001",
    "DBR-UI-005",
    "DBR-UI-006",
    "DAC-DST-015",
    "DART-071",
    "GAP-UI-DESC-01",
    "UX-CATALOG-ENTITY-DESC",
    "FEAT-UI-ENTITY-DESC"
  ]
}
```
