# Implementation Plan: Instance Disambiguation Picker

**Branch**: `010-instance-disambiguation` | **Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-instance-disambiguation/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Add a **disambiguation picker** that, after the user selects a single owned weapon or armor item, shows **all owned copies of that item in a carousel** with kind-aware per-card detail: for weapons, the copy's equipped perks (already in the instance DTO) plus—at the selection step—the **available plug options per socket**; for armor, the copy's six **Armor 3.0 stats** (already in the DTO) plus its **Tier** and **Set Bonus (2-piece & 4-piece)**. Users **remove candidates** (ephemeral React session state), **pick exactly one** copy, and attach it to a **set** slot recording the **specific `instanceId`** and selected perks.

Technical approach composes existing infrastructure (owned-instances list/detail API + `OwnedInstanceDetail` DTO, `CatalogItem.ownedCount`/`instancesHref`, set-item `PUT` with `selectedPerks`, the debug Sets picker) and adds four small, testable pieces: (1) surface **armor Tier** from the Bungie **`gearTier`** field (instance component 300, already fetched — captured into a new nullable `inventory_items.gear_tier` column during sync), with a curated stat-band heuristic as a fallback for legacy copies and graceful "unavailable"; (2) resolve **armor Set Bonus by itemHash** by inverting existing `SetBonusRecord.itemHashes` and surface it (+`tier`) on the armor instance projection; (3) a read-only **weapon perk-options** endpoint over the existing `WeaponRecord.perkColumns`; (4) add a nullable **`instanceId`** to `set_items` + `setItemInputSchema` + `upsertSetItem`. UI work is confined to the debug Sets surface.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: `better-sqlite3` + `drizzle-orm` (app DB), manifest entity cache (`weapons`, `weapon-perks`, `origin-traits`, `mods`, `set-bonuses` stores), zod route validation, existing owned-inventory instance pipeline (003) and set item lookup/attachment (008)

**Storage**: SQLite via drizzle. **Two additive nullable migrations** (idempotent `ensure*Column` pattern in `src/lib/db/client.ts`): `set_items.instance_id` and `inventory_items.gear_tier` (captures the Bungie `gearTier` from component 300 during sync; requires a one-time re-sync to backfill). Available weapon perk options are resolved from the manifest, not synced.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Local dev (`npm run dev`); signed-in + synced inventory; debug routes only (non-production)

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/sets`, reusing `/debug/catalog` patterns)

**Performance Goals**: Carousel renders all owned copies of one item (typical < 30) from a single instances fetch; perk-options fetched lazily only at the weapon selection step; user can pick the correct copy in < 60s (SC-001)

**Constraints**: Carousel scoped to copies of **one selected item** (FR-001); **no cap / no pagination** (FR-021); candidate removal is **session-only, never mutates inventory** (FR-016); attachment targets **sets only**, build attachment deferred (FR-022); Tier is **exact from the API `gearTier`** when present, with a stat-band heuristic fallback for legacy (`gearTier: null`) copies and "unavailable" when neither applies (FR-005/FR-009); weapon perk options degrade to equipped-only when `perkColumns` are unavailable

**Scale/Scope**: 5 user stories; ~20–24 source files across `src/data/rules/`, `src/lib/bungie/` (sync `gearTier` capture), `src/lib/inventory/instances/`, `src/lib/catalog/`, `src/lib/sets/`, `src/lib/db/`, one new API route, and the debug Sets page; plus `DEBUG.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: **PASS**. Vertical slices: US1 (carousel over existing instances) → US2 (armor Tier + Set Bonus on projection) → US3 (`instanceId` attach) → US4 (weapon perk-options selection) → US5 (candidate removal session state). Each independently testable and demoable on debug Sets.
- **II. Test-First (NON-NEGOTIABLE)**: **PASS** (plan). Failing tests precede: `resolveArmorTier` (gearTier + fallback), `gearTier` sync capture, `armorSetBonus` map/lookup, extended `projectInstance`, `resolveWeaponPerkOptions`, perk-options route, `set_items` + `inventory_items.gear_tier` migration smoke, `setItemInputSchema`, `upsertSetItem` with `instanceId`, and the pure candidate-session reducer.
- **III. Green Commit Checkpoints (NON-NEGOTIABLE)**: **PASS** (plan). Gate at each user-story checkpoint after `/speckit-tasks`.
- **IV. Co-Located Tests**: **PASS**. New `*.test.ts` beside each new module; extend existing instance/set tests.
- **V. Validation-First External Data**: **PASS**. Tier's primary source is the Bungie **`gearTier`** instance field, range-guarded by `resolveArmorTier` (only integers 1–5 accepted; otherwise a curated stat-band estimate or explicit "unavailable"); perk options come from validated manifest stores; new `instanceId` is zod-validated at the route boundary. No unvalidated external data enters resolution.

**Post-design re-check (Phase 1)**: **PASS**. Contracts fix DTO/endpoint shapes and degradation rules; data model defines the session lifecycle and field maps; the two additive nullable columns (`set_items.instance_id`, `inventory_items.gear_tier`) are backward compatible; no constitution violations. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/010-instance-disambiguation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── instance-card-detail-contract.md
│   ├── weapon-perk-options-contract.md
│   └── set-item-instance-attach-contract.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/
│   │   ├── catalog/weapons/perk-options/route.ts   # NEW GET perk options by itemHash
│   │   └── user/
│   │       ├── inventory/instances/route.ts        # (unchanged) list powers the carousel
│   │       └── sets/[id]/items/route.ts            # (unchanged handler) accepts instanceId via schema
│   └── debug/
│       └── sets/
│           ├── SetsDebugPage.tsx                   # carousel + per-card detail + remove/reset + select + perk step
│           └── InstanceCarousel.tsx                # NEW presentational carousel/card (debug-scoped)
├── data/rules/
│   ├── armorTiers.ts                               # NEW resolveArmorTier() (gearTier primary; stat-band fallback, source-cited)
│   └── armorTiers.test.ts                          # NEW
├── lib/
│   ├── bungie/
│   │   └── profile.ts                              # + parseGearTier(instance) from component 300
│   ├── inventory/instances/
│   │   ├── types.ts                                # + tier?, setBonus? on OwnedInstanceDetail
│   │   ├── armorSetBonus.ts                        # NEW invert SetBonusRecord.itemHashes → Map + lookup
│   │   ├── loadInstanceContext.ts                  # + build itemHash→SetBonusRecord context
│   │   ├── projectInstance.ts                      # + compute tier (gearTier) + setBonus for armor
│   │   ├── candidateSession.ts                     # NEW pure reducer: remove / reset candidates
│   │   └── *.test.ts                               # extend + new co-located tests
│   ├── catalog/
│   │   ├── weaponPerkOptions.ts                    # NEW resolveWeaponPerkOptions(itemHash)
│   │   └── weaponPerkOptions.test.ts              # NEW
│   ├── sets/
│   │   ├── schemas.ts                              # + instanceId in setItemInputSchema
│   │   ├── setItemService.ts                       # persist instanceId; SetItemRecord + upsertSetItem
│   │   └── *.test.ts                               # extend
│   └── db/
│       ├── schema.ts                               # + setItems.instanceId, inventoryItems.gearTier
│       ├── types.ts                                # + UserInventoryItem.gearTier
│       ├── client.ts                               # + ensureSetItemInstanceIdColumn, ensureGearTierColumn
│       └── schema.test.ts                          # migration smoke update (both columns)
└── ...
DEBUG.md                                            # update per debug-docs rule (carousel flow, perk-options, re-sync note)
```

**Structure Decision**: Single Next.js project. **Compose over existing modules**: the carousel is fed by the current instances list API; the armor projection gains `tier` (from the captured `gearTier`, heuristic fallback) and `setBonus`, one small read-only weapon perk-options route is added, and nullable `set_items.instance_id` / `inventory_items.gear_tier` columns enable instance-specific attachment and exact tier. UI changes are limited to the debug Sets page plus one presentational carousel component. Candidate-session logic (remove/reset) is extracted to a pure reducer so it is unit-testable without the DOM.

## Delivery Mapping

| User Story | Domain / data work | API / surface | UI |
|------------|--------------------|---------------|-----|
| US1 Carousel of copies (P1) | `candidateSession` reducer; gate on `CatalogItem.ownedCount` | existing `GET /inventory/instances?itemHash&kind&sortBy` via `instancesHref` | `InstanceCarousel` over instance rows |
| US2 Full detail per card (P1) | capture `gearTier` in sync (`profile.ts` + `gear_tier` column), `resolveArmorTier` (`armorTiers.ts`), `armorSetBonus` map, `projectInstance` + `loadInstanceContext` | instances list DTO gains `tier`, `setBonus` (armor) | weapon perks (existing) / armor Tier+stats+set bonus card |
| US3 Pick one + attach (P1) | `set_items.instance_id` migration, `setItemInputSchema`, `upsertSetItem`, `SetItemRecord` | `PUT /user/sets/:id/items` accepts `instanceId` | single-select + attach (replace confirm preserved) |
| US4 Weapon perk selection (P2) | `resolveWeaponPerkOptions` over `WeaponRecord.perkColumns` + `weapon-perks` names | `GET /catalog/weapons/perk-options?itemHash` | per-socket option picker; equipped marked from instance plugs; defaults to equipped |
| US5 Remove candidates (P2) | `candidateSession` reducer (remove/reset) | none (client state only) | remove control per card + reset/empty state |

### Instance card → data sources

| Card element | Source | Availability / degradation |
|--------------|--------|----------------------------|
| Copy identity (id, power, location, character) | `OwnedInstanceDetail` (003) | always |
| Weapon equipped perks | `OwnedInstanceDetail.plugs` (003) | unresolved plug shown by hash (FR-004) |
| Weapon available perk options (selection step) | `GET perk-options` ← `weapons` store `perkColumns` + `weapon-perks` names | missing weapon/columns → equipped-only fallback |
| Armor six stats + total + incomplete | `OwnedInstanceDetail.statValues/totalStats/statsIncomplete` (008) | `statsIncomplete` flagged (FR-008) |
| Armor Tier | `resolveArmorTier({gearTier, totalStats, isExotic, statsComplete})` — `gearTier` from component 300 (synced to `gear_tier`) | exact when `gearTier` present; legacy `null` → stat-band estimate; else "unavailable" (FR-009); exotic → "Exotic" |
| Armor Set Bonus (2pc/4pc) | `armorSetBonus` map from `set-bonuses` store, via projection context | no set membership → `setBonus: null` → "no set bonus" (FR-009) |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | — | — |
