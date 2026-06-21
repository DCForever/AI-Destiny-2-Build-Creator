# Implementation Plan: Build Sets and Synergies

**Branch**: `001-build-sets-synergies` | **Date**: 2026-06-17 | **Spec**: specs/001-build-sets-synergies/spec.md

**Input**: Feature specification from `/specs/001-build-sets-synergies/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Primary requirement from spec (plus user clarification): Add support for user-created categorized Sets (weapon, armor, mod, pair, fashion), Synergies of multiple types, attaching Sets to Builds (with per-attachment choice of live reference or snapshot), automated + explicit suggestions for Sets/Synergies/Rolls, and easy creation of variant Builds using different Sets. 

Key enhancement: For weapons in Sets (SetItem), store full roll data (selected perks, barrels, masterwork, etc.). If a SetItem/weapon is later removed ("deleted") from the set, the previous roll configuration can still be displayed, and alternatives (weapons with matching/similar perks) can be offered in the set UI. Fashion Sets remain cosmetic only.

Technical approach: Extend the existing Next.js app's SQLite schema and lib services for sets/synergies/attachments (leveraging existing manifest entity stores and loadout/build models); add UI components integrated into build editor, sheets, and new or extended management views; use a hybrid of existing deterministic rules/meta + LLM pipeline (per clarifications and assumptions) for suggestions; ensure compliance with constitution via per-story increments, tests-first, and gate checkpoints. Use clarifications: deletion blocks with list, names unique per category/type, live default with per-Build snapshot option, suggestions = auto contextual + explicit, fashion excluded from functional logic.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod (schemas), drizzle-orm + better-sqlite3 (persistence), fuse.js (search/filter), existing: bungie-api-ts, @destinyitemmanager/dim-api-types, LLM clients (openai-compat for local/Grok/Ollama), iron-session, manifest extractors/entity stores in src/lib/manifest

**Storage**: SQLite (via Drizzle, file .cache/app.db) for sets, set_items, synergies, build_set_attachments + existing inventory/loadouts/users; filesystem .cache for Bungie manifest + derived stores; JSON files for user preferences

**Testing**: vitest (unit + integration, co-located *.test.ts); full gate = typecheck + lint + test + build (npm run gate)

**Target Platform**: Web browser (local dev server or production build); requires user-provided LLM endpoint; optional Bungie OAuth for inventory sync

**Project Type**: Full-stack web application (Next.js with API routes, server components, client UI)

**Performance Goals**: Sub-100ms response for set attach, suggestions, filters on 1000+ items; support 100+ sets and 50+ item sets without UI lag; responsive even with many variants

**Constraints**: Single-process local SQLite (no multi-writer); manifest must be refreshed first (BUNGIE_API_KEY); LLM required for intelligent suggestions (rules/meta fallback); offline capable for cached data only; existing build/loadout CRUD as foundation

**Scale/Scope**: Single user; 10-100s of sets/synergies per user; full Destiny manifest (thousands of weapons/armor); extends existing generator, analyzer, loadouts, build sheet features; 6 user stories as small testable increments (P1-P6)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Required checks against constitution (concrete assessment):**

- I. Small Testable Increments: **PASS**. Spec decomposes into 6 prioritized, independently testable user stories (P1: Set CRUD; P2: Filter weapons/armor; P3: Attach with live/snapshot + suggestions; P4: Synergy CRUD; P5: Roll suggestions; P6: Variant builds). Each has Independent Test and acceptance scenarios. No cross-story dependencies that break independence.

- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). All new behavior (set management, attachments, suggestions, synergies) will have failing tests written first per constitution and tasks template. Co-located vitest tests planned.

- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Checkpoints after each user story (e.g. after P1 sets complete, after P3 attach). Commits only after `npm run gate` (typecheck + lint + test + build) passes. Aligns with existing project gate.sh.

- IV-V. Co-Located Test Verification + Validation-First External Data: **PASS**. New code (lib/sets, lib/synergies, components for pickers/suggestions) will use co-located tests. All external data (manifest items, LLM suggestions, Bungie inventory) passes through existing zod schemas and validation layers before affecting sets/builds (per V and project practice).

No violations. All user stories map directly to constitution-mandated small increments. Complexity table not needed.

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
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
src/
├── app/ (extend build/loadouts)
├── components/
│   ├── sets/ (new)
│   └── sheet/ (extend)
├── lib/
│   ├── sets.ts, synergies.ts
│   ├── build/ (extend)
│   └── db/repositories + schema (extend)

tests/ co-located (following existing co-location pattern)








```

**Structure Decision**: Extend existing Next.js single project structure. New code in src/lib/ and src/components/ following current conventions for co-located tests, Drizzle/SQLite, manifest reuse. Integrates with existing build/loadout features. Simplest consistent extension.

## Complexity Tracking

No violations of constitution (see Constitution Check above). All 6 user stories provide small, independently testable increments. Implementation will follow test-first + gate checkpoints.

(If future design reveals unavoidable complexity, document here with justification per template.)
