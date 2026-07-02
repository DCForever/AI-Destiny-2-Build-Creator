# Implementation Plan: Description Search for Pickers

**Branch**: `009-description-search` | **Date**: 2026-06-29 | **Spec**: [specs/009-description-search/spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-description-search/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Extend **all existing search surfaces** (synergy pickers, catalog filters, catalog browse `q`, manifest search) to match keywords against **name and description** text—entity-scoped per picker/filter—with **name matches ranked before description-only matches**. Introduce a shared **`descriptionMatch`** domain module; wire it into `synergyPickerLinks`, `subTypeVocabularies`, `perkTraitFilters`, `setBonusFilter`, `filterItems` (Fuse keys for exotic intrinsics), and `itemResolver` (store-specific searchable projections). Update debug picker UIs to show descriptions **in result lists**, not only after selection.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: fuse.js (catalog + manifest fuzzy search), manifest entity cache (`weapon-perks`, `origin-traits`, `set-bonuses`, `abilities`, `exotic-weapons`, `exotic-armor`, `mods`, `aspects`, `fragments`, `artifacts`), zod route validation, existing synergy/catalog picker routes from specs 006 and 008

**Storage**: No schema changes — read-only search over in-memory manifest stores

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local dev (`npm run dev`); manifest loaded

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/synergies`, `/debug/catalog`, `/debug/sets`, `WeaponPicker`)

**Performance Goals**: First results within 2s (SC-003); linear scan acceptable at manifest scale with early exit + limit caps (existing picker `limit` 50 when `q` set)

**Constraints**: Entity-scoped pickers (FR-018); no cross-entity joins in catalog `q` (FR-019); substring case-insensitive match only; preserve hash resolution paths; descriptions returned in DTOs where already present—extend UI to render in lists

**Scale/Scope**: 5 user stories; ~15–20 source files across `src/lib/search/` (new), `src/lib/synergies/`, `src/lib/catalog/`, `src/lib/manifest/`, debug pages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (shared matcher + perk/trait pickers + filter resolvers) → US2 (subtype pickers) → US5 (set bonus + exotics + manifest) → US3 (catalog filter parity) → US4 (UI descriptions in lists). Each slice independently testable.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Tests for `descriptionMatch`, extended `resolvePerkFilter`/`resolveSetBonusFilter`, picker search, Fuse key projection before route/UI wiring.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint after `/speckit-tasks`.
- IV. Co-Located Tests: **PASS**. New `src/lib/search/descriptionMatch.test.ts`; extend existing `*.test.ts` adjacent to modified modules.
- V. Validation-First External Data: **PASS**. No new external inputs; manifest records already validated at extract; empty/unresolved filter messages unchanged.

**Post-design re-check (Phase 1)**: **PASS**. Contracts document match rules + DTO fields; data model defines entity scopes and searchable field maps; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-description-search/
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
│   │   │   ├── weapons/route.ts
│   │   │   ├── armor/route.ts
│   │   │   └── synergy-pickers/
│   │   │       ├── links/route.ts
│   │   │       └── subtypes/route.ts
│   │   └── manifest/search/route.ts
│   └── debug/
│       ├── synergies/SynergiesDebugPage.tsx   # descriptions in picker lists
│       ├── catalog/CatalogDebugPage.tsx       # optional description column
│       └── sets/SetsDebugPage.tsx             # inherits catalog filter behavior
├── components/sheet/WeaponPicker.tsx          # manifest search consumer
└── lib/
    ├── search/
    │   └── descriptionMatch.ts                # NEW shared matcher + rank
    ├── synergies/
    │   ├── synergyPickerLinks.ts              # + description in filter
    │   └── subTypeVocabularies.ts             # + description in filter
    ├── catalog/
    │   ├── perkTraitFilters.ts                # matchByName → name+description
    │   ├── setBonusFilter.ts                  # + tier perk descriptions
    │   └── filterItems.ts                     # Fuse keys: intrinsic desc, etc.
    └── manifest/
        └── itemResolver.ts                    # per-store searchable projections
```

**Structure Decision**: Single Next.js project. **Centralize** match/rank logic in `src/lib/search/descriptionMatch.ts`; **compose** into existing picker and catalog modules rather than new API routes. UI changes limited to debug pickers and result list rendering.

## Delivery Mapping

| User Story | Domain module | API / surface | UI |
|------------|---------------|---------------|-----|
| US1 Perk/trait by keyword (P1) | `descriptionMatch`, `perkTraitFilters`, `synergyPickerLinks` | `/synergy-pickers/links`, `/catalog/weapons` perk/originTrait | synergies link picker |
| US2 Sub-types by description (P1) | `subTypeVocabularies` | `/synergy-pickers/subtypes` | synergies subtype picker |
| US5 Set bonus / exotics (P1) | `setBonusFilter`, `synergyPickerLinks`, `filterItems`, `itemResolver` | links, `/catalog/*` q, `/manifest/search` | catalog, WeaponPicker |
| US3 Catalog filter parity (P2) | `perkTraitFilters`, `setBonusFilter` | `/catalog/weapons`, `/catalog/armor` | sets, catalog debug |
| US4 Descriptions in lists (P2) | — | DTOs already carry `description` | synergies + catalog debug result rows |

### Entity scope → searchable fields

| Scope | Surfaces | Searchable fields |
|-------|----------|-------------------|
| `weapon_perk` | links picker, `perk` filter | `name`, `searchName`, `description` |
| `origin_trait` | links picker, `originTrait` filter | `name`, `searchName`, `description` |
| `armor_set_bonus` | links picker, `setBonus` filter | set `name`, tier perk `name`, tier perk `description` |
| `ability` / subtype | subtypes picker | `name`, `description` |
| `catalog_weapon` | catalog `q` | `name`, `searchName`, `itemTypeName`, `frame`, exotic `intrinsic.name`, `intrinsic.description` |
| `catalog_armor` | catalog `q` | `name`, `searchName`, exotic `intrinsic.*`, legendary `setBonusName` (name only for q) |
| `manifest_*` | `/manifest/search` | store-specific: name + description (+ intrinsic for exotics) |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | — | — |
