# Implementation Plan: Build Inline Sets

**Branch**: `028-build-inline-sets` | **Date**: 2026-07-23 | **Spec**: [specs/028-build-inline-sets/spec.md](./spec.md)

**Input**: Feature specification from `/specs/028-build-inline-sets/spec.md`

## Summary

Ship a **production Builds guided finish walkthrough** that detects combat loadout gaps on the active variant and steps **Armor → Weapons → Mods**. At each unsatisfied category the user can **create an empty Set**, **link an existing Set**, or (when resolved gear exists) **prefer Capture current gear into a Set** via existing `POST .../create-sets`. After a covering Set is attached, the walkthrough guides **slot fill** reusing Sets fill rules (`SlotFillPanel` / set item upsert). **Skip for now** defers gaps without marking them satisfied. No new durable tables; compose pure gap evaluation + thin create-and-attach helper on existing Sets/variant APIs; primary UI on `BuildPage` / `VariantEditPanel`.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16 App Router, React 19

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, iron-session auth; existing `createSetsFromBuild`, `replaceAttachmentByType`, `resolveVariantEquipment`, set create + `upsertSetItem`, `SetAttachPicker`, `SlotFillPanel`, variant PATCH attachments

**Storage**: No new tables. Reuse `sets`, `set_items`, variant attachments. Walkthrough progress is **derived** from attachments + resolved equipment (optional ephemeral client session only).

**Testing**: vitest co-located `*.test.ts`; route/contract tests where new endpoints appear; `npm run gate`

**Target Platform**: Local web app; signed-in required for mutations

**Project Type**: Full-stack Next.js (production Builds)

**Performance Goals**: Gap evaluation after warm resolve <100ms class (same as attach checks); walkthrough step transitions feel immediate; SC-001 finish path under 10 minutes human time

**Constraints**: DBR-CMP-001 Sets-as-normal path; DBR-CMPL-001 default full combat loadout; live attach default; snapshot semantics preserved; BR-OPT-001 replace-by-type; BR-UI-001 hard constraints; Fashion out of primary CTAs; mod create-from-build may still skip until claims exist — UI must not over-promise

**Scale/Scope**: 5 stories (P1 create/fill/capture/walkthrough, P3 Pair); ~15–25 files under `src/lib/builds/`, `src/components/build/`, thin API glue

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. Slices: gap model → create+attach → fill-from-builds → create-from-build production CTA → guided walkthrough shell → Pair polish.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Failing tests for `evaluateFinishGaps`, create-and-attach, walkthrough step transitions before UI chrome.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate after each story checkpoint in tasks.
- IV. Co-Located Tests: **PASS**. Domain under `src/lib/builds/` with adjacent `*.test.ts`.
- V. Validation-First External Data: **PASS**. Reuse zod routes and set item validation; no new external unvalidated sources.

**Post-design re-check (Phase 1)**: **PASS**. Contracts compose existing mutation APIs; data model is DTO/session-only; no unjustified complexity.

## Project Structure

### Documentation (this feature)

```text
specs/028-build-inline-sets/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── finish-gaps-contract.md
│   ├── create-set-attach-contract.md
│   └── guided-walkthrough-ui-contract.md
└── tasks.md             # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
src/
├── app/api/user/
│   ├── builds/[id]/create-sets/route.ts     # existing capture; production UI calls it
│   ├── builds/[id]/variants/...             # existing attachment PATCH
│   └── sets/route.ts                        # existing create set
│   └── sets/[id]/items/...                  # existing slot upsert
├── components/build/
│   ├── BuildPage.tsx / BuildDetail*.tsx     # Finish build entry
│   ├── VariantEditPanel.tsx                 # discrete Sets tab + walkthrough host
│   ├── FinishBuildWalkthrough.tsx           # NEW guided shell
│   ├── CreateSetAttachForm.tsx              # NEW or extract
│   └── ...
├── components/sets/SlotFillPanel.tsx        # reuse for fill steps
├── components/lookups/SetAttachPicker.tsx   # reuse link-existing
└── lib/builds/
    ├── finishGaps.ts                        # NEW pure gap evaluation
    ├── createSetAndAttach.ts                # NEW create empty + live attach
    ├── createSetsFromBuild.ts               # existing capture
    ├── replaceAttachmentByType.ts
    └── resolveVariant.ts
```

**Structure Decision**: Single Next.js app. New **pure finish-gap domain** + small create-and-attach helper. UI walkthrough on Builds only. Mutations via existing user APIs (sets POST, items upsert, variant attachments, create-sets).

## Delivery Mapping

| User Story | Backend / domain | UI | Notes |
|------------|------------------|-----|-------|
| US1 Create+attach (P1) | `createSetAndAttach` + sets POST + variant attach | Create Set in walkthrough + Sets tab | Live attach default; name auto-suffix |
| US2 Fill slots (P1) | existing set item upsert | Embed/reuse `SlotFillPanel` from Builds | Live only for library mutation; snapshot guard |
| US3 Capture from gear (P1) | existing `create-sets` | Preferred action when resolved gear w/o Set | Per-category call from walkthrough |
| US4 Guided walkthrough (P1) | `evaluateFinishGaps` | `FinishBuildWalkthrough` | Order Armor→Weapons→Mods; Skip for now |
| US5 Pair (P3) | same create+attach with type pair | Optional type in create | Fashion excluded from primary CTAs |

## Complexity Tracking

> No constitution violations requiring justification.

## Delivery status

**028 implementation complete** on branch `028-build-inline-sets` (tasks T001–T029). This plan describes the shipped v1 walkthrough only.

## Follow-on delivery (not this feature)

Product source: Warp plan `1ee4d5e0-4c18-436d-8c1d-81be268c9ae3` (slot-first Finish + Armor optimizer).

UI mocks: `docs/ui-mocks/finish-build-slot-first.html` (canonical V2+V5 / V6), `docs/ui-mocks/armor-picking-variants.html` (exploration archive).

| Slice | Feature (planned id) | Owns |
|-------|----------------------|------|
| A | 029-finish-slot-first (name TBD at specify) | Finish chrome: one-tap create/capture, no link/tags in Finish, weapons/mods slot-first loop, inherit names |
| B | 030-finish-optimizer-foundation | `classType` on empty-set optimize; synergy→setBonus ranking helper; seed/constraints payload helpers; tests |
| C | 031-finish-armor-optimize-ui | Armor workspace UI V2+V5 / V6; PATCH constraints; optimize; top-3 compare; apply-combination; wire Finish after Armor create |

Create 029–031 via `/speckit.specify`; do not reopen 028 tasks for this work.
