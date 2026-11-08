# Implementation Plan: Build Pipeline Consistency

**Branch**: `012-build-pipeline-consistency` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-build-pipeline-consistency/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Close end-to-end gaps in the **build composition pipeline** and align **debug lookup patterns** so Creates → synergy designation → variant selection → set attach/detach → resolve/compare can be verified without typing raw hashes or opaque IDs. Build/variant/set/synergy **REST APIs already exist** (001); this iteration is primarily **debug UX + shared pickers**, plus small API/behavior fixes: stop silent synergy auto-seed on create, expose abilities in manifest search for structured subclass picking, and make attach UX additive over replace-all attachment semantics.

Technical approach: extract reusable debug pickers (exotic armor/weapon catalog search, synergy multi-select, set attach with type+tag AND filters + detach, variant `<select>`); rework `BuildsDebugPage` to drive the full pipeline; extend `GET /api/manifest/search` with `abilities`; require explicit `synergyIds` on build create (no invisible first-synergy seed; block + link to Synergies debug when none exist); allow empty default variant at create; keep advanced hash/ID fields optional only.

**Clarifications (2026-07-08)**: empty create allowed; attach additive; detach in scope; per-variant exotic weapon picker; no-synergies → block create with link to `/debug/synergies`.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Existing build/set/synergy services (`src/lib/builds/*`, `src/lib/sets/*`, `src/lib/synergies/*`), catalog + manifest search APIs, entity cache (`exotic-armor`, `aspects`, `fragments`, `abilities`), zod schemas in `src/lib/builds/schemas.ts`, concept tags (`src/data/conceptTags.ts`, `src/data/subclasses.ts`)

**Storage**: No new tables. Reuses `builds`, `build_variants`, `build_set_attachments`, `build_synergies`, user sets/synergies. Optional: none.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Local dev (`npm run dev`); signed-in debug surfaces only (non-production)

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/builds` primary; parity touch-ups on Sets/Synergies/Catalog/Suggestions as needed)

**Performance Goals**: Picker searches reuse existing catalog/manifest limits; full pipeline completable in < 5 minutes (SC-001); no new bulk list pagination

**Constraints**: MUST NOT weaken Pair/exotic, live/snapshot, or slot rules (FR-007); happy path MUST NOT require raw hashes/IDs (FR-011); attachment PATCH remains **replace-all** — UI must send full attachment list; production chrome out of scope

**Scale/Scope**: 5 user stories; ~12–18 source files (shared pickers, Builds debug rewrite, small API tweaks, tests, DEBUG.md); contracts for debug lookup parity + build create/synergy designation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: **PASS**. Vertical slices: US1 (create pickers + explicit synergies + subclass form) → US3 (variant accounting) → US2 (set attach picker + replace-all-safe attach) → US4 (post-create synergy edit) → US5 (cross-surface parity checklist + shared components). Each independently demonstrable on `/debug/builds`.
- **II. Test-First (NON-NEGOTIABLE)**: **PASS** (plan). Failing tests precede: create rejects empty `synergyIds` (no auto-seed), abilities manifest search category, exotic/synergy/set picker helpers (pure filter/map), Builds debug integration smoke where practical, attachment merge helper for replace-all PATCH.
- **III. Green Commit Checkpoints (NON-NEGOTIABLE)**: **PASS** (plan). Gate after each user-story checkpoint in `/speckit-tasks`.
- **IV. Co-Located Tests**: **PASS**. New `*.test.ts` beside changed modules (`buildService`, manifest search route, picker helpers).
- **V. Validation-First External Data**: **PASS**. Catalog/manifest results already schema-validated at route boundaries; exotic selection still persists hash + name from catalog row; subclass fields still validated by `createBuildSchema` / `generatedBuildSchema.shape.subclass`.

**Post-design re-check (Phase 1)**: **PASS**. Contracts document picker DTOs and create/synergy behavior change; data model clarifies designation + attachment client state; no new persistence entities; Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/012-build-pipeline-consistency/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── debug-lookup-parity-contract.md
│   └── build-create-designation-contract.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/
│   │   └── manifest/search/route.ts          # + category=abilities (+ optional kind filter)
│   └── debug/
│       ├── builds/BuildsDebugPage.tsx        # pipeline UX rewrite
│       ├── sets/SetsDebugPage.tsx            # parity: reuse shared set/tag filters if drifted
│       ├── synergies/SynergiesDebugPage.tsx  # parity: listing fields for designation reuse
│       └── catalog/CatalogDebugPage.tsx      # parity reference for exotic armor lookup
├── components/
│   └── debug/                                # NEW shared debug pickers
│       ├── ExoticArmorLookup.tsx             # catalog/manifest exotic armor search → select
│       ├── ExoticWeaponLookup.tsx            # catalog/manifest exotic weapon search → set/clear
│       ├── SynergyMultiSelect.tsx            # list/filter user synergies → multi-select
│       ├── SetAttachPicker.tsx               # type + tag AND + set select + live/snapshot + detach
│       ├── VariantSelect.tsx                 # variants of selected build
│       └── SubclassStructuredForm.tsx       # class → subclass → ability/aspect/fragment fields
├── lib/
│   ├── builds/
│   │   ├── buildService.ts                   # require explicit synergyIds (no silent seed)
│   │   ├── buildService.test.ts
│   │   └── attachmentMerge.ts                # NEW: add/update/remove helpers for full-list PATCH
│   └── debug/
│       └── lookupParity.ts                   # NEW: shared result-field helpers / empty-state copy
└── ...
DEBUG.md                                      # update pipeline verification steps
```

**Structure Decision**: Single Next.js app. Prefer **shared debug components** under `src/components/debug/` over copy-paste between pages. Domain APIs stay in place; only create-synergy seeding and abilities search are server changes.

## Delivery Mapping

| User Story | Domain / data work | API / surface | UI |
|------------|--------------------|---------------|-----|
| US1 Create without hashes (P1) | Stop silent synergy seed; empty default variant OK; subclass still `GeneratedBuild.subclass` | `POST /api/user/builds` (explicit `synergyIds`); `GET /api/manifest/search?category=exotic-armor\|abilities\|aspects\|fragments` | ExoticArmorLookup, SynergyMultiSelect (empty → block + link), SubclassStructuredForm on Builds create |
| US3 Variant accounting (P1) | Optional exotic weapon on variant | Existing variant PATCH; load detail → list variants | VariantSelect; block scoped actions when empty; ExoticWeaponLookup set/clear |
| US2 Attach/detach sets (P1) | Client merge/remove for replace-all attachments | `GET /api/user/sets?type=&tags=`; `PATCH .../variants/:id` with full `attachments[]` | SetAttachPicker; list + detach one; confirm target variant name |
| US4 Synergy edit (P2) | None | `PATCH /api/user/builds/:id` `{ synergyIds }` | SynergyMultiSelect on selected build + save designations |
| US5 Lookup parity (P2) | Shared helpers | Reuse catalog/synergy/set list endpoints | Adopt shared pickers on any debug page still using raw IDs for those entities; optional advanced hash fields labeled |

### Pipeline → existing endpoints

| Step | Endpoint | Notes |
|------|----------|-------|
| List synergies | `GET /api/user/synergies` | Feed SynergyMultiSelect |
| Create build | `POST /api/user/builds` | Must include `synergyIds` (≥1); exotic from picker |
| Load build | `GET /api/user/builds/:id` | Variants + designations for selects |
| Update designations | `PATCH /api/user/builds/:id` | `{ synergyIds }` replace junction |
| List sets (attach) | `GET /api/user/sets?type=&tags=` | AND tags already implemented |
| Attach / update attachments | `PATCH .../variants/:variantId` | **Replace-all** — send complete list |
| Resolve / compare / suggest | Existing GET/POST routes | Always use selected `variantId` |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | — | — |
