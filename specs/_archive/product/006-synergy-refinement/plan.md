# Implementation Plan: Synergy Refinement

**Branch**: `006-synergy-refinement` | **Date**: 2026-06-29 | **Spec**: [specs/006-synergy-refinement/spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-synergy-refinement/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Refine synergy definition and verification: **auto-generated names** from category + sub-type + link; **expanded category model** (add `element`, rename `damage`→`dps`, remove creatable `kinetic_weapon`); **sub-type field** for Verb/Melee/Grenade/Super/Element (including **Base** for Melee/Grenade/Super and **Kinetic** under Element); **catalog-backed link pickers** with **description preview** on `/debug/synergies`; reinforce **many-to-many** associations (already in DB/service—verify UI + catalog badges). No production synergy editor; debug-first delivery per 001.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, manifest entity cache (`abilities`, `origin-traits`, `weapon-perks`, `set-bonuses`, `weapons`), iron-session auth

**Storage**: SQLite — add nullable `sub_type` column on `synergies`; no change to `synergy_links` (many-to-many already supported)

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local dev (`npm run dev`); signed-in user; manifest refreshed for catalog pickers

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/synergies`, `/debug/catalog`)

**Performance Goals**: Picker search &lt;2s with manifest loaded; sub-type vocabularies served from in-memory curated/manifest data (no per-row DB joins)

**Constraints**: Strict zod validation (constitution V); legacy `kinetic_weapon`/`damage` readable; re-save migrates types; free-text link fields removed from debug UI; auto-name max 120 chars (truncate link portion per spec edge case)

**Scale/Scope**: 5 user stories; ~15–20 source files touched across `src/lib/synergies/`, catalog picker routes, debug page, drizzle migration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (schema + auto-name + sub-types) → US2 (category enum + legacy migration) → US3 (multi-synergy verification) → US4 (picker APIs + debug UI) → US5 (description preview). Each independently testable.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Tests for `generateSynergyName`, `subTypeVocabularies`, schema validation, legacy migration, picker route filters before UI wiring.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint after `/speckit-tasks`.
- IV. Co-Located Tests: **PASS**. New modules under `src/lib/synergies/` with adjacent `*.test.ts`.
- V. Validation-First External Data: **PASS**. Link validation unchanged (`validateSynergyLink`); picker APIs return manifest-backed records only; sub-types from curated vocabularies.

**Post-design re-check (Phase 1)**: **PASS**. Contract documents API/schema deltas; data model adds `subType` only; picker endpoints read-only; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/006-synergy-refinement/
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
│   │   │   ├── weapons/route.ts              # reuse for weapon link picker (q param)
│   │   │   └── synergy-pickers/
│   │   │       ├── subtypes/route.ts         # verbs, abilities, elements
│   │   │       └── links/route.ts            # origin traits, perks, set bonuses
│   │   └── user/synergies/                   # extend create/update for subType + auto-name
│   └── debug/synergies/
│       ├── SynergiesDebugPage.tsx            # catalog pickers, auto-name, description panel
│       └── components/                       # optional: SynergyForm, LinkPicker, DescriptionPanel
├── data/
│   └── synergyElements.ts                    # Kinetic + damage elements enum
├── lib/
│   ├── db/
│   │   ├── schema.ts                         # synergies.subType
│   │   └── repositories/synergyRepository.ts
│   └── synergies/
│       ├── schemas.ts                        # SYNERGY_TYPES, subType on create/update
│       ├── generateSynergyName.ts
│       ├── subTypeVocabularies.ts            # verbs, abilities by kind, elements
│       ├── legacySynergyTypes.ts             # kinetic_weapon/damage migration
│       ├── synergyService.ts
│       └── validateSynergyLink.ts            # unchanged link kinds
└── data/subclasses.meta.ts                   # verb source (dedupe via subTypeVocabularies)
```

**Structure Decision**: Single Next.js project. Domain logic in `src/lib/synergies/`; thin read-only picker routes under `/api/catalog/synergy-pickers/`; debug UI consumes existing weapons catalog + new picker endpoints.

## Delivery Mapping

| User Story | Domain | API | Debug |
|------------|--------|-----|-------|
| US1 Auto-generated names (P1) | `generateSynergyName`, live preview | POST auto-fills name (server authoritative) | read-only name field updates on change |
| US2 Sub-types + categories (P1) | `subTypeVocabularies`, schema, migration | `subtypes` picker route; zod rejects missing subType | category + sub-type `<select>` |
| US3 Multi-synergy per target (P1) | existing `findSynergiesByTarget` | `by-target` unchanged | reverse lookup + catalog badges show all |
| US4 Catalog link pickers (P2) | picker routes + manifest stores | `/api/catalog/weapons`, `/synergy-pickers/links` | searchable selects, no text/hash inputs |
| US5 Description preview (P2) | description on picker DTOs | included in picker + weapons catalog item | read-only panel below link picker |

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
