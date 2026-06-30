# Implementation Plan: Sets Catalog-Style Item Lookup

**Branch**: `008-sets-catalog-lookup` | **Date**: 2026-06-29 | **Spec**: [specs/008-sets-catalog-lookup/spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-sets-catalog-lookup/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Bring **Catalog-parity item discovery** to Sets: extend **`GET /api/catalog/weapons`** with **perk** and **origin trait** filters (via `perkWeaponIndex` + `WeaponRecord.originTraitHashes`); extend **`GET /api/catalog/armor`** with **legendary armor rows** from `set-bonuses` and a **set bonus** filter; extend **inventory sync + instance API** to capture **Armor 3.0 stat values** and **sort owned armor copies** by stat dimension or total. Replace manual hash entry on **`/debug/sets`** with the same browse → select → instance drill-down flow as **`/debug/catalog`**.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, fuse.js (catalog search), manifest entity cache (`weapons`, `exotic-weapons`, `exotic-armor`, `weapon-perks`, `origin-traits`, `set-bonuses`, `stats`), `perkWeaponIndex` derived artifact, iron-session auth

**Storage**: SQLite — add nullable `stat_values` JSON column on `inventory_items` (six Armor 3.0 stats per armor instance). No change to `set_items` schema v1 (still `itemHash` + `selectedPerks`; instance pick populates those fields).

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local dev (`npm run dev`); signed-in user with manifest + inventory sync

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/sets`, `/debug/catalog` patterns)

**Performance Goals**: Filtered catalog responses &lt;5s (FR-013 / SC-005); instance stat sort in-memory after DB read

**Constraints**: Extend existing catalog/instance APIs (no parallel picker service); zod validation at route boundary; slot context from set type must map to catalog bucket enums; occupied-slot replace confirmation unchanged (FR-012); manual hash fields remain as debug fallback only (FR-008)

**Scale/Scope**: 4 user stories; ~20–25 source files across `src/lib/catalog/`, `src/lib/inventory/`, `src/lib/bungie/`, catalog API routes, `SetsDebugPage.tsx`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (weapon perk/trait catalog filters + instance `q`) → US2 (legendary armor catalog + set bonus filter) → US3 (sync stats + instance sort) → US4 (debug Sets picker UI). Each slice independently testable.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Tests for `filterWeaponsByPerk`, `filterWeaponsByOriginTrait`, `filterArmorBySetBonus`, `parseArmorStatValues`, `sortInstancesByStat` before route/UI wiring.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint after `/speckit-tasks`.
- IV. Co-Located Tests: **PASS**. New logic under `src/lib/catalog/` and `src/lib/inventory/instances/` with adjacent `*.test.ts`.
- V. Validation-First External Data: **PASS**. zod query schemas for new params; stat JSON validated against `ArmorStatName` keys; unresolved set bonus / perk names → empty results with message, not 500.

**Post-design re-check (Phase 1)**: **PASS**. Contracts document catalog + instance API deltas; data model adds `stat_values` projection only; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/008-sets-catalog-lookup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/
│   │   ├── catalog/
│   │   │   ├── weapons/route.ts          # + perk, originTrait query params
│   │   │   └── armor/route.ts            # + setBonus; legendary armor source
│   │   └── user/inventory/instances/
│   │       └── route.ts                  # + sortBy for armor instances
│   └── debug/
│       ├── catalog/CatalogDebugPage.tsx  # reference UX (minimal/no change)
│       └── sets/SetsDebugPage.tsx        # catalog-style picker panel
├── data/rules/statBenefits.ts            # ArmorStatName enum (reuse)
├── lib/
│   ├── bungie/
│   │   ├── profile.ts                    # parse instance stats from itemComponents
│   │   └── syncInventory.ts              # persist stat_values on armor rows
│   ├── catalog/
│   │   ├── filterItems.ts                # extend weapon/armor filters
│   │   ├── legendaryArmor.ts             # project rows from set-bonuses itemHashes
│   │   ├── perkTraitFilters.ts           # perk + origin trait resolution
│   │   └── types.ts                      # optional setBonus on CatalogItem
│   ├── db/
│   │   ├── schema.ts                     # inventory_items.stat_values
│   │   └── types.ts
│   └── inventory/instances/
│       ├── types.ts                      # statValues on DTO; sortBy criteria
│       ├── parseArmorStats.ts
│       ├── sortInstances.ts              # + sortInstancesByStat
│       └── listUserInstances.ts
```

**Structure Decision**: Single Next.js project. **Compose** existing catalog and instance APIs rather than a dedicated `/api/sets/lookup` route. Domain extensions live in `src/lib/catalog/` and `src/lib/inventory/instances/`. Debug Sets page embeds picker UI reusing Catalog fetch patterns.

## Delivery Mapping

| User Story | Catalog API | Instance API | Sync / DB | Debug UI |
|------------|-------------|--------------|-----------|----------|
| US1 Weapon perk/trait (P1) | `perk`, `originTrait` on `/catalog/weapons` | existing `q` on `/instances` after row select | — | perk/trait inputs + catalog results |
| US2 Armor set bonus (P1) | `setBonus` on `/catalog/armor`; legendary rows | — | — | set bonus filter + slot lock |
| US3 Stat ranking (P2) | — | `sortBy` on `/instances` (armor) | `stat_values` column + parse at sync | stat sort select on instance list |
| US4 Unified picker (P2) | compose above | auto-fetch on select | — | replace hash inputs with picker panel |

### Set slot → catalog bucket mapping

| Set slot | Catalog `slot` param |
|----------|----------------------|
| `primary` | `Kinetic` |
| `special` | `Energy` |
| `heavy` | `Power` |
| `helmet` | `Helmet` |
| `arms` | `Gauntlets` |
| `chest` | `Chest` |
| `legs` | `Legs` |
| `class_item` | `ClassItem` |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Inventory schema migration (`stat_values`) | FR-007 requires ranking owned armor by stat; stats not stored today | Live Bungie fetch per instance list — latency, rate limits, violates 003 FR-013 pattern |
| Legendary armor catalog projection | Armor catalog is exotic-only; set bonus filter needs legendary set pieces | Filter inventory only — fails FR-005 manifest browse / unowned discovery |
