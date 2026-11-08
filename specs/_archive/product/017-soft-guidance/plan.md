# Implementation Plan: Soft Guidance & Coverage Indicators

**Branch**: `017-soft-guidance` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/017-soft-guidance/spec.md` (domain slice 3; clarify Q1=A, Q2=C, Q3=C)

## Summary

Add evaluate-on-read **soft coverage** over resolved variant loadouts: per designated synergy tiers (`supported` / `weak` / `missing` = all / some / none evidence links), plus breakdown rows for armor **set-bonus soft coverage** and **element/subclass soft mismatches** with hints. Expose via dedicated coverage API and Builds debug. Bias `suggestSets` toward closing coverage gaps. Soft guidance never hard-blocks save. No soft-stat UI (slice 5).

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: `resolveVariant`, synergies/links, suggestions, set-bonus / weapon manifest stores, BuildsDebugPage  
**Storage**: No new tables; evaluate-on-read  
**Testing**: vitest co-located; `npm run gate`  
**Target Platform**: Local Next.js; signed-in debug  
**Project Type**: Full-stack Next.js — debug/API-first  
**Performance Goals**: Coverage evaluate interactive (&lt;150ms typical single variant)  
**Constraints**: Soft-only; no soft-stat rows; fashion excluded from scoring; save paths unchanged  
**Scale/Scope**: 4 user stories; `coverage.ts`, coverage route, suggestSets bias, debug UI, contracts/tests

## Constitution Check

- I. Small Testable Increments: **PASS** — US1 tiers → US2 breakdown → US3 suggest bias → US4 soft-save regression  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS** — coverage is advisory; no new untrusted writers  

**Post-design**: **PASS**

## Project Structure

```text
specs/017-soft-guidance/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/coverage-contract.md, suggest-gap-bias-contract.md
└── tasks.md

src/lib/builds/coverage.ts          # NEW
src/lib/suggestions/suggestSets.ts  # gap bonus
src/app/api/user/builds/[id]/variants/[variantId]/coverage/route.ts  # NEW
src/app/debug/builds/BuildsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Tiers | coverage.ts, coverage-contract |
| US2 Breakdown | coverage.ts set-bonus + element rows |
| US3 Suggest bias | suggest-gap-bias-contract, suggestSets |
| US4 Soft save | regression tests; no save-path hooks |
| Validation | quickstart.md |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
