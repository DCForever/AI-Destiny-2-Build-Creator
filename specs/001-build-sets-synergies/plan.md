# Implementation Plan: Build Sets and Synergies

**Branch**: `001-build-sets-synergies` | **Date**: 2026-06-28 | **Spec**: [specs/001-build-sets-synergies/spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-build-sets-synergies/spec.md` (includes Session 2026-06-22 clarifications on set slot rules, build/variant model, hybrid exotics, synergy weighting, Pair Set behavior; Session 2026-06-28 on controlled concept tags with AND-filter discovery).

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add user-created **Sets** (Weapon, Armor, Mod, Pair, Fashion) with per-type slot cardinality (0–1 per applicable slot), **concept tags** from a controlled vocabulary (`src/data/conceptTags.ts`), **Synergies**, and **Builds** composed of a **default variant** plus optional additional **variants**. Build-level fields (subclass, aspects, exotic armor, designated synergies, tags) are shared; variants differ in attached sets and exotic weapon. Attachments support live reference (default) or snapshot per variant. Users filter sets/builds by tag combination (AND semantics) when attaching sets to builds. Suggestions combine deterministic rules/meta with the existing LLM pipeline; all designated synergies contribute equally.

Weapon SetItems store full roll data; removed entries retain roll history for display and alternative matching. Pair Sets must match build exotic armor and primarily supply the variant exotic weapon. Variant and build save require ≥1 equipment slot filled via attached sets and ≥1 designated synergy.

Technical approach: extend SQLite/Drizzle schema (`sets`, `set_items`, `set_tags`, `synergies`, `builds`, `build_tags`, `build_variants`, `variant_set_attachments`, `build_synergies`); add `src/lib/sets`, `src/lib/synergies`, `src/lib/builds` services with slot-resolution, tag validation, and conflict validation; shared `ConceptTagPicker` / `TagFilterBar` UI; reuse manifest entity stores, fuse.js filtering, and existing `GeneratedBuild`/`ResolvedBuildSheet` resolution where builds overlap with today's loadout generator.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, fuse.js, bungie-api-ts, @destinyitemmanager/dim-api-types, LLM clients (openai-compat), iron-session, manifest extractors/entity stores (`src/lib/manifest`)

**Storage**: SQLite (`.cache/app.db`) — new tables for sets, synergies, builds, variants, attachments; existing `loadouts`/`inventory_items`/`users` unchanged initially (builds may later link to or supersede loadout saves). Filesystem `.cache` for Bungie manifest.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Web browser (local dev / production); optional Bungie OAuth; LLM endpoint for explicit suggestions

**Project Type**: Full-stack Next.js web app (API routes + server/client components)

**Performance Goals**: Sub-100ms set attach and slot-conflict checks; sub-5s filter/search on catalogs (SC-002); 30+ sets / 20+ synergies without UI lag (SC-007)

**Constraints**: Single-process SQLite; manifest refresh required; fashion sets excluded from functional resolution; Pair Set armor must match build exotic armor (FR-028); cross-set slot conflicts block variant save (FR-026)

**Scale/Scope**: Single user; 6 user stories (P1–P6); extends generator, analyzer, loadouts, build sheet

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. Six prioritized user stories remain independently testable. P1 (Sets CRUD + slot rules) is a viable MVP without builds.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Slot validation, attachment modes, variant save guards, and Pair Set matching will have failing tests before implementation.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Checkpoint after each user story; commit only when `npm run gate` passes.
- IV–V. Co-Located Tests + Validation-First External Data: **PASS**. Manifest item hashes, roll perks, and LLM suggestion payloads validated via zod before persistence or display.

**Post-design re-check (Phase 1)**: **PASS**. Data model decomposes build vs variant vs attachment cleanly; contracts define validation boundaries; no constitution violations introduced.

## Project Structure

### Documentation (this feature)

```text
specs/001-build-sets-synergies/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 (by /speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/user/sets/          # new CRUD
│   ├── api/user/synergies/     # new CRUD
│   ├── api/user/builds/        # new CRUD + variants
│   └── (extend loadouts/build pages)
├── components/
│   ├── sets/                   # Set editor, slot pickers, replace confirm
│   ├── builds/                 # Build editor, variant tabs, compare
│   ├── synergies/              # Synergy catalog
│   └── sheet/                  # extend resolved sheet with set composition
├── lib/
│   ├── sets/                   # set CRUD, slot rules, roll storage
│   ├── synergies/              # synergy CRUD
│   ├── builds/                 # build/variant, slot resolution, conflicts
│   ├── suggestions/            # rules + LLM orchestration
│   ├── db/schema.ts            # extend drizzle tables
│   └── db/repositories/        # new repos + tests co-located
```

**Structure Decision**: Extend the existing single Next.js project. New domain modules under `src/lib/{sets,synergies,builds}` with co-located tests. Builds are first-class entities separate from ephemeral `GeneratedBuild` JSON in loadouts, but may import/export via existing sheet resolution.

## Complexity Tracking

No constitution violations. Build/variant split and per-type slot domains add modeling complexity but are required by spec clarifications (Session 2026-06-22).
