# Implementation Plan: Item Filter Enrichment

**Branch**: `013-item-filter-enrichment` | **Date**: 2026-07-08 | **Spec**: [specs/013-item-filter-enrichment/spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-item-filter-enrichment/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Enrich curated **abilities** with structured **subclass affinities** and **effect verbs** (class and element already exist), then expose AND-combined filters on `GET /api/manifest/search` (`category=abilities`) so lookups like “Warlock + Cure + Dawnblade/Prismatic” and “Stormcaller Arc Super + Jolt” find Phoenix Dive and Chaos Reach without exact names. Derivation uses plug-category → `SUBCLASS_METADATA`, plug-set membership (with curated overrides for Prismatic dual-affinity), and whitelist word-boundary verb tagging against `synergyVerbs.ts`.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js (App Router)

**Primary Dependencies**: Existing manifest extractors + entity cache, `SUBCLASS_METADATA` (`src/data/subclasses.meta.ts`), `SYNERGY_VERBS` (`src/data/synergyVerbs.ts`), fuse/resolver search, zod route validation

**Storage**: Derived entity store for `abilities` (`.cache/entities/...`); no SQLite schema change

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local Next.js dev; debug/manifest search verification

**Project Type**: Full-stack Next.js — debug/search-first delivery

**Performance Goals**: Ability catalog is small; linear post-filter after search/over-fetch is acceptable; first results within interactive latency for SC-002

**Constraints**: FR-008 forbids description-substring-only verb tags; FR-009 forbids inventing affinities; abilities-only in v1; preserve existing name/description `q` behavior

**Scale/Scope**: 3 user stories; primary touchpoints: `AbilityRecord`, `abilities.ts` extractor (+ helpers), fixtures/tests, `itemResolver` ability indexing, `/api/manifest/search`, optional debug picker display of enrichment fields

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (record enrichment + extractor tests) → US2 (search filters + discovery queries) → US3 (shared vs exclusive affinity correctness). Each slice independently testable.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Failing extractor/route tests for Phoenix Dive / Chaos Reach and filter AND semantics before implementation.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate after each user-story checkpoint in `/speckit-tasks`.
- IV. Co-Located Tests: **PASS**. Extend `extractors2.test.ts`, `route.test.ts`; new helper tests adjacent to derivation/verb modules.
- V. Validation-First External Data: **PASS**. Verb tags validated against curated vocabulary; subclass names constrained to `SUBCLASS_METADATA`; empty when unknown.

**Post-design re-check (Phase 1)**: **PASS**. Contracts define filter AND semantics and DTO fields; data model extends `AbilityRecord` without inventing values; research resolves Prismatic dual-affinity via plug sets + curated override. No constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/013-item-filter-enrichment/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── ability-enrichment-search-contract.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/api/manifest/search/
│   ├── route.ts                 # + abilities category, structured filters, enriched DTO
│   └── route.test.ts
├── data/
│   ├── subclasses.meta.ts       # affinity join source (read)
│   ├── synergyVerbs.ts          # verb whitelist (read)
│   └── abilityEnrichmentOverrides.ts  # NEW optional hash→affinities/verbs anchors
└── lib/manifest/
    ├── types/records.ts         # AbilityRecord + subclassAffinities, verbs
    ├── itemResolver.ts          # abilities searchable projection (description/verbs)
    ├── __fixtures__/rawTables.ts
    └── extractors/
        ├── abilities.ts         # wire enrichment
        ├── abilityEnrichment.ts # NEW derive affinities + verbs
        ├── common.ts            # plug-set helpers (reuse)
        └── extractors2.test.ts
```

**Structure Decision**: Single Next.js project. Keep enrichment derivation in a dedicated extractor helper; surface filters on existing manifest search rather than a new catalog route. Overrides file is small and explicit for FR-006/FR-007 anchors.

## Delivery Mapping

| User Story | Domain module | API / surface | Verification |
|------------|---------------|---------------|--------------|
| US1 Filter by enrichment (P1) | `abilityEnrichment`, `abilities` extractor, `AbilityRecord` | Entity store + search DTO fields | Extractor tests; Phoenix Dive / Chaos Reach fields |
| US2 Discover without names (P1) | Search post-filters | `/api/manifest/search?category=abilities&…` | Contract examples without `q` name |
| US3 Shared vs exclusive (P2) | Affinity derivation tiers | Same search filters | Negative class/subclass/element cases |

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
