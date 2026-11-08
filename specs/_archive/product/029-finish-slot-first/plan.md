# Implementation Plan: Finish Slot-First Chrome

**Branch**: `029-finish-slot-first` | **Date**: 2026-07-23 | **Spec**: [specs/029-finish-slot-first/spec.md](./spec.md)

**Input**: Feature specification from `/specs/029-finish-slot-first/spec.md`

## Summary

Reshape the **production Finish build walkthrough** so category steps no longer mount multi-field create or link-existing chrome. One-tap **Create** (type fixed to category; name inherited server-side) or preferred **Capture** live-attaches a covering Set, then the walkthrough **auto-enters the first empty required slot** and advances slot-by-slot until the category is satisfied or skipped. Variant **Sets tab** retains full CreateSetAttachForm + SetAttachPicker. No new tables; compose existing `create-set-attach`, create-sets capture, `evaluateFinishGaps`, and `BuildSlotFillHost`. Armor uses the same path as manual interim until 031.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16 App Router, React 19

**Primary Dependencies**: Existing `FinishBuildWalkthrough`, `CreateSetAttachForm`, `CaptureSetsFromBuild`, `BuildSlotFillHost`, `createSetAndAttach` / `POST .../create-set-attach`, `evaluateFinishGaps` / `finishGapsFromDetail`, variant attachment PATCH, create-sets capture API

**Storage**: No new tables. Reuse sets, set_items, variant attachments. Walkthrough skip keys remain client-only.

**Testing**: vitest co-located `*.test.ts` for pure next-slot / finish-step helpers; component behavior covered by pure helpers + existing API tests; `npm run gate`

**Target Platform**: Local web app; signed-in mutations

**Project Type**: Full-stack Next.js (production Builds Finish UI)

**Performance Goals**: Step transitions after create/fill feel immediate; gap re-eval after warm resolve same class as 028

**Constraints**: Preserve Armor→Weapons→Mods order; satisfaction = covering Set + required fills; Skip for now does not satisfy; Capture preferred when `canCapture`; live attach + replace-by-type; snapshot fill guard; no optimizer UI (031); no Finish link/tags/name/type fields

**Scale/Scope**: ~5–10 files under `src/components/build/` and `src/lib/builds/`; 5 user stories (P1 create/fill/capture, P2 Sets-tab retain + Armor interim)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. Slices: pure next-empty-slot helper → Finish one-tap create → auto fill entry + loop → Capture presentation → strip link from Finish / verify Sets tab → Armor parity copy.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Failing tests for next empty slot order and post-create step selection before UI edits.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate after helper + after walkthrough UI.
- IV. Co-Located Tests: **PASS**. Helpers under `src/lib/builds/*.test.ts`.
- V. Validation-First External Data: **PASS**. No new external sources; reuse existing zod routes.

**Post-design re-check (Phase 1)**: **PASS**. Contracts are UI/composition only; no new durable model; no unjustified complexity.

## Project Structure

### Documentation (this feature)

```text
specs/029-finish-slot-first/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── finish-one-tap-create-contract.md
│   └── finish-slot-first-ui-contract.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
src/
├── components/build/
│   ├── FinishBuildWalkthrough.tsx   # PRIMARY: strip create form + link; one-tap; auto fill loop
│   ├── CreateSetAttachForm.tsx      # KEEP on Sets tab; optional finishMode later or leave unused in Finish
│   ├── CaptureSetsFromBuild.tsx     # KEEP; Finish uses category-scoped capture as preferred CTA
│   ├── BuildSlotFillHost.tsx        # REUSE fill
│   └── VariantEditPanel.tsx         # Sets tab still hosts form + attach picker
├── lib/builds/
│   ├── finishGaps.ts                # existing statuses/emptySlots
│   ├── finishNextSlot.ts            # NEW pure: first/next empty required slot + post-mutation step
│   ├── createSetAndAttach.ts        # existing inherit name when name omitted
│   └── finishGapsFromDetail.ts
└── app/api/user/builds/[id]/create-set-attach/  # existing; Finish posts type + variantId only
```

**Structure Decision**: Single Next.js app. UI-first change on Finish walkthrough; small pure helper for slot cursor; no API schema change required (`createSetAndAttach` already defaults name from build + type).

## Delivery Mapping

| User Story | Domain / API | UI | Notes |
|------------|--------------|-----|-------|
| US1 One-tap create → fill (P1) | `POST create-set-attach` type only | Finish category: single Create button | No name/type chips/tags in Finish |
| US2 Slot-first loop (P1) | `emptySlots` from gaps + fill host | After create/fill, open next empty | Stable slot order from `REQUIRED_SLOTS` |
| US3 Capture preferred (P1) | existing create-sets | Capture CTA first when `canCapture` | Then fill remaining or satisfy |
| US4 Sets tab advanced (P2) | unchanged attach/create | VariantEditPanel keeps form + picker | Finish omits SetAttachPicker |
| US5 Armor interim (P2) | same as weapons path | Same chrome; no optimizer | 031 replaces post-create later |

## Complexity Tracking

> No constitution violations requiring justification.
