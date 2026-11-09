# Implementation Plan: Lookup-Only Fields

**Branch**: `025-lookup-only-fields` | **Date**: 2026-07-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/025-lookup-only-fields/spec.md`

## Summary

Enforce a standing UI rule: Destiny game concepts are chosen only via lookups; free text is reserved for names, notes, and prose. Convert production create (subclass, exotic armor, pinned super), debug `SubclassStructuredForm` (abilities/aspects/fragments pick-only), and LLM `BuildForm` preferences (exotic, weapon, weapon types) to reuse existing catalog/manifest lookup patterns without schema migrations.

## Technical Context

**Language/Version**: TypeScript 5.x / Next.js (App Router)  
**Primary Dependencies**: React client components, existing `/api/manifest/search`, `SUBCLASSES_BY_CLASS`, `ExoticArmorLookup` / `ExoticWeaponLookup`  
**Storage**: No schema change — builds already store `exoticArmorHash`/`exoticArmorName`/`pinnedSuper` and subclass name strings; values must originate from lookups  
**Testing**: Vitest (co-located `*.test.ts`); prefer pure helpers / payload builders over heavy RTL (project pattern)  
**Target Platform**: Web app (production build UI + debug + generator)  
**Project Type**: Web application (single Next.js repo)  
**Performance Goals**: Lookup search remains on-demand; no new bulk loads beyond existing exotic/ability search  
**Constraints**: Pick-only primary path; debug hash/JSON escape hatches may remain secondary; no name→hash migration this iteration  
**Scale/Scope**: 3 form surfaces; shared small lookup helpers/components

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: Three user stories (P1 create, P1 subclass form, P2 generator) — each shippable alone.
- **II. Test-First**: Each story starts with failing tests for pick-only / vocabulary constraints before UI edits.
- **III. Green Commit Checkpoints**: Commit after each story when `npm run gate` is green.
- **IV. Co-Located Tests**: Helpers and payload mappers tested next to modules.
- **V. Validation-First External Data**: Manifest search results already validated by API; UI only commits selected result identities.

**Post-design re-check**: Pass — no new external data paths; reuse existing search contracts.

## Project Structure

### Documentation (this feature)

```text
specs/025-lookup-only-fields/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-lookups.md
└── tasks.md              # /speckit-tasks
```

### Source Code (repository root)

```text
src/
├── components/
│   ├── build/CreateBuildPanel.tsx      # US1: subclass select, exotic + super lookups
│   ├── build/BuildPage.tsx             # wire exoticArmorHash from create payload
│   ├── debug/SubclassStructuredForm.tsx # US2: pick-only abilities/aspects/fragments
│   ├── debug/ExoticArmorLookup.tsx     # reuse
│   ├── debug/ExoticWeaponLookup.tsx    # reuse for generator preferred weapon path if needed
│   └── BuildForm.tsx                   # US3: exotic/weapon lookups + weapon type multi-select
├── data/
│   ├── subclasses.ts                   # SUBCLASSES_BY_CLASS (reuse)
│   └── weaponTypes.ts                  # NEW: known weapon type vocabulary for generator
├── lib/
│   ├── debug/subclassScope.ts          # clear incompatible on subclass change (reuse/extend)
│   └── build/ or lib/ui/               # small helpers: default subclass for class, pick-only assign
```

**Structure Decision**: Single Next.js app; UI-first feature with shared data vocabularies and existing manifest search — no new API routes required unless a thin weapon-types list endpoint is preferred over a static data module (research chooses static list for generator).

## Complexity Tracking

> No constitution violations.
