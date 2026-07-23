# Implementation Plan: Catalog Universal Search

**Branch**: `027-catalog-universal-search` | **Date**: 2026-07-23 | **Spec**: [specs/027-catalog-universal-search/spec.md](./spec.md)

**Input**: Feature specification from `/specs/027-catalog-universal-search/spec.md`

## Summary

Add a **Catalog-home universal search** that returns **mixed composition-relevant kinds** (weapons, armor, mods, perks, origin traits, artifact perks, set bonuses, subclass kit pieces, etc.) by **name + description**, with a **detail pane** and **create/add Set** and **create/add Synergy** actions that reuse existing set-item and synergy-link services. Prefer a **new composed search service + thin API** over forcing users through category-scoped `/api/manifest/search` alone; Catalog UI gains a universal mode without rewriting specialized weapon/armor facet browse.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16 App Router, React 19

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, fuse.js / `ItemResolver.search` + `descriptionMatch`, iron-session auth, entity cache stores (`weapons`, `exotic-weapons`, `exotic-armor`, `weapon-perks`, `origin-traits`, `mods`, `set-bonuses`, `artifacts`, `aspects`, `fragments`, `abilities`), existing set/synergy services

**Storage**: No new tables for v1. Reuse `sets` / `set_items` / `synergies` / `synergy_links` and inventory for ownership. Search is ephemeral over entity cache (+ optional owned hash set).

**Testing**: vitest co-located `*.test.ts`; contract tests on new route; `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Local web app (`npm run dev`); signed-in optional for browse, required for mutations

**Project Type**: Full-stack Next.js (production Catalog + library Sets/Synergies)

**Performance Goals**: SC-004 — usable results within **5s** for typical manifest + short query; target in-memory search p95 under **500ms** after entity cache warm

**Constraints**: Reuse Set/Synergy hard rules (slot, exotic exclusivity, energy, link kinds, dedupe); zod at route boundary; no silent empty when manifest missing; unsigned browse OK; fashion-only out of default scope; do not break existing weapon/armor Catalog facets

**Scale/Scope**: 5 user stories (P1 search+detail+set, P2 synergy, P3 kind filters); ~15–25 files across `src/lib/catalog/`, `src/app/api/catalog/`, `src/components/catalog/`, thin set/synergy action wiring

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 universal search API/UI → US2 detail → US3 Set create/add → US4 Synergy create/add → US5 kind filters. Each slice independently testable.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Failing tests for `searchCompositionCatalog`, kind mapping, action eligibility, and route contracts before UI polish.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate after each user-story checkpoint in tasks.
- IV. Co-Located Tests: **PASS**. New domain under `src/lib/catalog/` (and thin helpers) with adjacent `*.test.ts`.
- V. Validation-First External Data: **PASS**. Entity cache already extracted; zod on query/body; invalid kinds/hashes rejected; manifest-not-ready explicit error.

**Post-design re-check (Phase 1)**: **PASS**. Contracts compose existing mutation APIs; data model is DTO-only; no unjustified complexity.

## Project Structure

### Documentation (this feature)

```text
specs/027-catalog-universal-search/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── universal-search-contract.md
│   └── composition-actions-contract.md
└── tasks.md             # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
src/
├── app/api/
│   ├── catalog/
│   │   ├── weapons/route.ts              # unchanged specialized browse
│   │   ├── armor/route.ts
│   │   ├── synergy-pickers/...           # reuse for kind-scoped parity tests
│   │   └── universal-search/route.ts     # NEW: mixed-kind search
│   ├── manifest/search/route.ts          # keep category-scoped pickers
│   └── user/
│       ├── sets/route.ts                 # create set (existing)
│       ├── sets/[id]/items/...           # upsert item (existing)
│       └── synergies/...                 # create + link (existing)
├── components/catalog/
│   ├── CatalogScreen.tsx                 # universal mode entry + detail actions
│   ├── CatalogPage.tsx
│   └── UniversalSearch*.tsx              # optional extract if CatalogScreen grows
├── lib/
│   ├── catalog/
│   │   ├── universalSearch.ts            # NEW: multi-store search + rank
│   │   ├── compositionKinds.ts           # NEW: kind enum + action eligibility
│   │   └── ...
│   ├── search/descriptionMatch.ts        # reuse
│   ├── sets/setService.ts / setItemService.ts
│   └── synergies/synergyService.ts / schemas
```

**Structure Decision**: Single Next.js app. New **composed search domain** under `src/lib/catalog/` + one Catalog API route. Mutations call **existing** user Sets/Synergies routes/services. Catalog UI extends `CatalogScreen` (or thin child components) rather than a separate product surface.

## Delivery Mapping

| User Story | Backend | UI | Notes |
|------------|---------|-----|-------|
| US1 Universal search (P1) | `GET /api/catalog/universal-search` | Catalog universal query + mixed results | Multi-store + descriptionMatch |
| US2 Detail (P1) | same response fields + optional detail fetch | Detail pane from hit | Preserve query on back |
| US3 Set create/add (P1) | existing sets POST + item upsert | Actions on detail | Slot/type mapping + constraints |
| US4 Synergy create/add (P2) | existing synergies APIs | Actions on detail | Link-kind eligibility |
| US5 Kind filters (P3) | `kinds` query param | Filter chips | Client and/or server filter |

## Complexity Tracking

> No constitution violations requiring justification.
