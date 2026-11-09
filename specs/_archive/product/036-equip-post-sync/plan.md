# Implementation Plan: Equip Post-Sync Reassert

**Branch**: `036-equip-post-sync` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/036-equip-post-sync/spec.md`

## Summary

After `syncIfStale` on the equip route, recompute equip readiness from post-sync inventory and hard-fail with `NOT_EQUIP_READY` (409) when pins are stale/missing. Harden `planEquipSteps` so combat claims with `instanceId` never silently skip missing inventory rows. Add unit tests for post-sync stale path and planner missing-instance behavior; keep happy-path planning coverage.

## Technical Context

**Language/Version**: TypeScript 5 / Node.js (Next.js 16 app router)

**Primary Dependencies**: Next.js 16, Vitest, existing equip/readiness libs

**Storage**: SQLite inventory via `listInventoryItems` (unchanged)

**Testing**: Vitest (`npm run test`)

**Target Platform**: Web API (nodejs runtime route)

**Project Type**: Web application (Next.js)

**Performance Goals**: Negligible — one extra O(n) readiness pass over combat slots

**Constraints**: Preserve gap equip (empty claims omit); fashion behavior unchanged; no invent full gear rollback

**Scale/Scope**: Small bugfix — 2–3 source files + tests

## Constitution Check

- I. Small Testable Increments: Two user stories (route reassert; planner hard-error); each independently testable.
- II. Test-First: Add/adjust failing tests before implementation.
- III. Green Commit Checkpoints: Commit after specify, plan/tasks, and green implement gate.
- IV-V. Co-located tests (`equipPlan.test.ts`, `equipReady.test.ts`); validation via existing `assertEquipReady`.

No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/036-equip-post-sync/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
├── checklists/
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
src/app/api/user/builds/[id]/variants/[variantId]/equip/route.ts
src/lib/builds/equipPlan.ts
src/lib/builds/equipPlan.test.ts
src/lib/builds/equipReady.ts          # reuse only unless tiny helper needed
src/lib/builds/equipReady.test.ts
```

**Structure Decision**: Single Next.js project; change equip route + planner + unit tests only.

## Implementation Approach

1. **Tests first**
   - Post-sync style unit test: inventory missing claimed instance → `computeEquipReady` false → `assertEquipReady` throws `NOT_EQUIP_READY` (document as post-sync reassert contract; may live in `equipReady.test.ts`).
   - Optional pure helper test if route logic is extracted; otherwise route order verified by code review + readiness unit coverage.
   - Planner: missing instance with `instanceId` throws; multi-slot happy path still plans all combat equips.

2. **Route** (`equip/route.ts`)
   - Import `computeEquipReady`, `buildInventoryPinIndex` (and keep `assertEquipReady`).
   - After `listInventoryItems`, recompute and assert before `planEquipSteps`.
   - Order: pre-assert → character/manifest → `syncIfStale` → inventory → **recompute assert** → plan → execute.

3. **Planner** (`equipPlan.ts`)
   - When `claim.instanceId` set and `byInstance.get` misses: throw `ApiError(NOT_EQUIP_READY, ..., 409)` with slot/instance detail.
   - Do not change fashion or empty-claim omission.

4. **Verify**: `npm run test`, `typecheck`, `lint`.

## Complexity Tracking

None.
