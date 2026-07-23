# Implementation Plan: Armor Set Optimizer

**Branch**: `026-armor-set-optimizer` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/026-armor-set-optimizer/spec.md`

## Summary

Deliver (1) **create Sets from a Build and attach immediately** (replace-by-type, auto-unique names, **seed exotic + soft-stat optimizer constraints** on Armor Sets), and (2) a **DIM-inspired armor combination searcher** that returns ranked complete kits under exotic, set-bonus coverage, and EoF stat-priority constraints, with optional **auto stat-mod estimates**, **cross-Set reuse annotations**, and optional **prefer-reuse** soft tie-break. **Persist search constraints on the Armor Set** (JSON); first materialize **creates** a new Set; later **refresh applies better kits in place**. After inventory sync (and on open of unattached constrained Sets), surface **soft suggestions** (suggest-then-confirm — never silent auto-apply). Approach: clean-room optimizer in `src/lib/optimizer/` + thin authenticated APIs + debug UI; reuse Sets CRUD, inventory stats, set-bonus identity, soft-stat targets, and energy helpers — **no** vendored DIM LO. **Production-facing optimizer UX is deferred** — see [spec.md § Future UX](./spec.md#future-ux-deferred).

## Technical Context

**Language/Version**: TypeScript 5.x / Next.js 16 (App Router, Node runtime on API routes)  
**Primary Dependencies**: Zod 4 (request validation), Drizzle/SQLite (existing Sets/inventory), Vitest 4; reuse inventory projection, `setService` / `setItemService` / `attachmentService`, `softStatTargets`, mod energy helpers  
**Storage**: No **new** tables — add nullable JSON columns on existing `sets` (`optimizer_constraints`, optional `linked_mod_set_id`); ephemeral optimize requests; durable kits via existing set items / variant attachments  
**Testing**: Vitest co-located `*.test.ts` (pure optimizer + route contract tests with fixtures); `npm run gate`  
**Target Platform**: Web app (debug/API-first verification)  
**Project Type**: Single Next.js application  
**Performance Goals**: First ranked slice for constrained owned inventory within ~5s on typical fixture (SC-007); hard caps on prune/enumeration  
**Constraints**: Owned inventory only; complete five-slot kits only; ≤1 exotic armor; energy-legal mods; suggest-then-confirm refresh; debug/API-first; DIM-like quality without DIM LO dependency  
**Scale/Scope**: Optimize + materialize + create-from-build + refresh/apply + improvement-suggestions APIs + optimizer core + two debug surfaces; US1–US7 (incl. US5b); Future UX polish deferred.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: US1 (create-from-build) → US2 (constrained search) → US3 (result shape) → US4 (mod estimates) → US5 (materialize + persist constraints) → US5b (refresh / soft suggestions) → US7 (prefer-reuse) → US6 (Sets entry). Each independently demoable.
- **II. Test-First**: Failing unit/contract tests for uniqueness/attach-replace, hard-constraint fixtures, ranking/mod/reuse fixtures, materialize + in-place apply — before implementation.
- **III. Green Commit Checkpoints**: Commit after each story when `npm run gate` is green.
- **IV. Co-Located Tests**: Optimizer pure functions + route tests beside modules.
- **V. Validation-First External Data**: Inventory/manifest-derived stats and set-bonus maps already validated at sync/catalog boundaries; optimizer consumes typed projections and Zod-validated requests only.

**Post-design re-check**: Pass — no unjustified complexity; DIM port rejected in research (R1).

## Project Structure

### Documentation (this feature)

```text
specs/026-armor-set-optimizer/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── create-sets-from-build-contract.md
│   ├── armor-optimize-contract.md
│   ├── materialize-combination-contract.md
│   ├── refresh-constrained-set-contract.md
│   └── improvement-suggestions-contract.md
└── tasks.md              # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
src/
├── lib/
│   ├── optimizer/
│   │   ├── types.ts                 # request/result + ArmorSetOptimizerConstraints
│   │   ├── constraints.ts           # exotic + set-bonus goal checks
│   │   ├── constraintsSchema.ts     # Zod normalize/clear
│   │   ├── prune.ts                 # per-slot top-K / Pareto
│   │   ├── enumerate.ts             # bounded kit search
│   │   ├── score.ts                 # lexicographic priority + preferReuse tie-break
│   │   ├── autoStatMods.ts          # greedy mod assignment + energy
│   │   ├── estimate.ts              # kit totals (± mods)
│   │   ├── explainEmpty.ts          # unmet hard constraints
│   │   ├── detectImprovement.ts     # better-than-current kit
│   │   ├── seedConstraintsFromBuild.ts
│   │   └── optimizeArmor.ts         # orchestrator
│   ├── builds/
│   │   ├── createSetsFromBuild.ts   # US1 service
│   │   ├── replaceAttachmentByType.ts
│   │   ├── softStatTargets.ts       # seed priorities (reuse)
│   │   └── statEstimate.ts          # extend/share helpers if needed
│   ├── sets/
│   │   ├── setService.ts            # reuse create + constraints columns
│   │   ├── setItemService.ts        # reuse upsert / in-place replace
│   │   ├── uniqueSetName.ts
│   │   ├── materializeCombination.ts
│   │   └── refreshConstrainedSet.ts
│   └── inventory/                   # list/project armor (reuse)
├── app/api/user/
│   ├── builds/[id]/create-sets/route.ts
│   ├── armor/optimize/
│   │   ├── route.ts                 # POST search
│   │   └── materialize/route.ts     # POST first-time materialize
│   ├── armor/improvement-suggestions/route.ts
│   └── sets/[id]/
│       ├── optimize/route.ts        # refresh search from stored constraints
│       └── apply-combination/route.ts
└── app/debug/ + components/debug/
    ├── builds/                      # create-sets + seed optimize + soft suggestions
    └── sets/                        # standalone optimize + constraints + refresh
```

**Structure Decision**: Single Next.js app; new pure optimizer library + thin routes; materialize/create-from-build/refresh as services composing existing Sets/attach APIs.

## Complexity Tracking

> No constitution violations.
