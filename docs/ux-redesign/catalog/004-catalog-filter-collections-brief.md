# UX brief: catalog / CatalogFilterCollections

**Status:** locked  
**Date:** 2026-08-08  
**Hosts:** windows, widgetbook  
**Slice goal:** Ship filter-band chrome for named saved filter collections on Catalog — Saved trigger + list/menu (desktop) / sheet (mobile), save/rename/delete dialogs, soft apply of criteria only. Consume landed `packages/domain` + Drift + `packages/app` use cases (`FEAT-20260807-004` / `74ce3e4`). Neon/Flap residual; no invent filter results.  
**Out of scope:** Domain/persist algorithm changes; BR-CAT-006 facet semantics rewrite; item-hash include/exclude presets; auto-apply on catalog open; Armor/Universal full redesign; mobile Catalog push as exit gate; Set/Synergy/Build surfaces.

## Product posture

- Job: save/restore named filter **criteria** (scope, query, exotic, facets, optional sort/group) per browse mode so the user can re-enter a known Catalog setup without re-clicking chips  
- System: pure model + Drift `catalog_filter_collections` + app use cases already landed — this slice is **chrome + thin host wire** only  
- Rule IDs: BR-CAT-006, DBR-PUR-002, DBR-UI-001/005 (presentation honesty), FEAT-20260807-004, C6 optional weapons finish  

## Locked decisions

| Topic | Decision |
| --- | --- |
| Surface | Catalog **filter band** trailing actions — not a separate page |
| Cluster order | **Saved → More → Reset** (Saved left of More/Reset) |
| Chrome | Neon/Flap residual (001 browse + filter bar); no new design system; no Material menu as product chrome |
| Soft apply | Apply loads collection → host binds criteria only; **fixture/results never invented** by the preset layer |
| Host bind | Prefer `applyCatalogFilterCollection` / `catalogClientFiltersFromCollection` + host applies sortKeys/groupBy via `catalogSortKeysFromCollection` / `catalogGroupByFromCollection` |
| Scope | **Per browse mode** (`weapons` \| `armor` \| `universal`); list and cap are mode-local |
| Replace-by-name | Same name under user+mode **replaces** (id preserved when possible) |
| Cap | Soft max **20** per user+mode; block **new** name at cap; replace existing name still allowed |
| Dirty | Cyan **dot** on Saved when `activeId` set and live criteria ≠ collection payload |
| Applied label | Trigger may show truncated **collection name** when applied; else “Saved” |
| Savable | Save enabled only when criteria ≠ empty defaults (not scope:all alone with empty everything) |
| Payload in | scope, query, exotic, facet include/exclude (element/ammo/slot/class/archetype/synergies), sortKeys, groupBy |
| Payload out | item hash include/exclude, presentation chrome, nested group trees |
| Dialogs | Save (name), rename (prefill), delete confirm (danger), replace-by-name confirm when name collides |
| Signed-out | No list/save; honest empty / sign-in copy when no `userId` |
| Persist errors | Mono/soft field or status error — do not invent success |
| Desktop | Dropdown menu under Saved (`role=menu` / listbox rows) |
| Mobile | Bottom sheet; structure-first (not dual-gate Capture) |
| BR-CAT-006 | Unchanged include OR / across AND / exclude drop |

## State matrix (must demo / test)

empty · list · applied · dirty · save-dialog · rename-dialog · delete-confirm · at-cap · persist-error · narrow-band · no-user · soft-apply-only

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-desktop.html`
- `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-mobile.html`
- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (CatalogFilterCollections 004 — continue with workflow)
- Baseline filter band: existing `CatalogFilterBar` + 001 browse chrome mockups (do not reopen full weapons redesign)

## Implement notes

### `packages/ui_flutter` (presentation only)

- Add `CatalogFilterCollections` chrome (trigger + menu/sheet shell + dialogs) under `lib/src/catalog/`; export from package barrel
- Extend `CatalogFilterBar` action cluster so **Saved sits left of More/Reset**  
  - Note: existing `trailing` prop is not currently placed on the primary action row — fix placement or add an explicit pre-More slot rather than dumping Saved under More
- Props in only: list for current mode, activeId, dirty, signedIn/canPersist, callbacks (`onOpen`, `onApply`, `onSave`, `onRename`, `onDelete`, …) — **no Drift/IO/domain predicates in widgets**
- Dialogs: Neon-styled (radius 2px, accent/danger) matching mock; name max length aligned with system (~64 UI; validate via use case)
- Do not filter/sort catalog rows inside this chrome

### Host (`apps/windows_host` catalog)

- Wire list/create/save/rename/delete/apply via `packages/app` `catalog_filter_collection_use_cases.dart`
- On apply: set client filters from collection; also apply sortKeys/groupBy host state (collection stores them; `CatalogClientFilters` alone does not carry sort/group)
- Track `activeCollectionId` + dirty by comparing live host filters to applied snapshot
- Signed-out / no local user: disable save/list honesty
- Cap / validation errors surface as soft status (use-case / persist exceptions)

### Build

- Use `F:\d2w\filters` (junction → this worktree `flutter/`)

### Widgetbook

- Knobs: signedIn, collectionCount (0/3/20), activeId, dirty, browseMode, persistError
- Desktop dropdown + mobile sheet use cases

## Widget test inventory (minimum)

- Saved appears **before** More/Reset in the filter band action cluster
- Soft apply callback receives collection id; widget does not invent grid items
- Empty list shows Save CTA; list rows show name + summary
- Applied: trigger label / active row; dirty dot when criteria diverge
- At-cap: new name save disabled or blocked with cap hint; replace existing name still works
- Signed-out: no save/list mutations; honest copy
- Rename/delete dialogs fire correct callbacks; delete uses danger confirm
- Replace-by-name path confirmed (dialog or use-case round-trip via host test)
- A11y: Semantics for Saved expanded, list labels, live region on apply
- No ChoiceChip / Material-only product menu required

## Widgetbook backlog

- Catalog filter bar · Saved collections desktop — matrix scenarios
- Catalog filter bar · Saved collections mobile sheet 390
- Knobs: signedIn, count 0|3|20, dirty, active, persistError, mode weapons|armor
- Cap blocked new name vs replace existing
- Soft-apply status echo (criteria only)

## Nice-to-have (not gate)

- Keyboard: Esc closes menu/dialog; Enter submits save/rename
- Truncate long names on trigger with tooltip full name
- “Update active” one-click overwrite when dirty (if product wants later)
- Share/export collection JSON

## Acceptance

- [ ] Mockups dual-truth for Saved placement + soft-apply honesty
- [ ] Host can save/list/apply/rename/delete without inventing results
- [ ] Per-mode list + cap 20 + replace-by-name match system tests
- [ ] Structure: analyze + widget tests green; Capture must-rows for primary scenarios
- [ ] No BR-CAT-006 or domain algorithm changes

## Next workflow

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "catalog-filter-collections",
  "brief_path": "docs/ux-redesign/catalog/004-catalog-filter-collections-brief.md",
  "hosts": ["windows", "widgetbook"]
}
```

Build / analyze cwd: `F:\d2w\filters` (or worktree `flutter/`).
