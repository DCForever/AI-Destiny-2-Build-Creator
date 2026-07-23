# Implementation Plan: Create Build Search Pickers

**Branch**: `042-create-build-pickers` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/042-create-build-pickers/spec.md`

## Summary

Improve Create/Edit Build single-select lookups: collapse search chrome after pick; scope super search with class+subclass (debug parity); group exotic armor results by slot sorted by name; show library synergy chips on exotic rows via batch reverse-lookup.

## Technical Context

**Language/Version**: TypeScript 5.x / Next.js (App Router)

**Primary Dependencies**: React client components, existing `/api/manifest/search`, `/api/user/synergies/by-target`, entity cache

**Storage**: Existing SQLite user synergies (read-only reverse lookup); no schema changes

**Testing**: Vitest co-located unit/route tests; `npm run gate`

**Target Platform**: Web (Windows dev)

**Project Type**: Full-stack Next.js app

**Performance Goals**: One batch synergy request per exotic result set (≤50 hashes); non-blocking chips

**Constraints**: Soft-fail synergies; multi-select chrome unchanged; no create-payload/identity changes

**Scale/Scope**: CreateBuildPanel + BuildEditPanel + ManifestSearchPicker + small lib/API helpers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: Three P1 stories (collapse, scope, exotic groups+synergies) are independently testable.
- II. Test-First: Unit tests for exotic grouping; route tests for batch by-target; scope wiring covered by existing/search param tests where applicable.
- III. Green Commit Checkpoints: Commit after stories only when `npm run gate` is green.
- IV-V. Co-located tests; external synergy data already schema-validated at write time — read path reuses service.

Post-design: still compliant; no Complexity Tracking rows.

## Project Structure

### Documentation (this feature)

```text
specs/042-create-build-pickers/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── create-build-pickers-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
src/components/lookups/ManifestSearchPicker.tsx
src/components/build/CreateBuildPanel.tsx
src/components/build/BuildEditPanel.tsx
src/lib/manifest/exoticArmorSearchGroups.ts
src/lib/manifest/exoticArmorSearchGroups.test.ts
src/lib/debug/subclassSearchParams.ts          # reuse for super scope
src/lib/synergies/synergyService.ts            # batch reverse lookup helper
src/lib/db/repositories/synergyRepository.ts   # optional batch query
src/app/api/user/synergies/by-target/route.ts  # extend for itemHashes
docs/ui-mocks/create-build-search-pickers.html
```

**Structure Decision**: Extend existing Next.js app paths; no new packages.

## Complexity Tracking

> None
