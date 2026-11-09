# Implementation Plan: Soft Stat Targets

**Branch**: `019-soft-stat-targets` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/019-soft-stat-targets/spec.md` (domain slice 5)

## Summary

Add **build-level optional soft stat targets** for the EoF six (Health, Melee, Grenade, Super, Class, Weapons), estimate variant loadout totals, and emit **below-target soft warnings** via coverage (or sibling fields). Synergy **nudges** are opt-in. Soft-only — never hard-block non-default save. Extends 017 coverage; no hard element lock.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: `builds` schema, `ArmorStatName` / `STAT_MAX`, inventory `stat_values`, `coverage.ts` / `coverageService`, BuildsDebugPage  
**Storage**: JSON TEXT column `soft_stat_targets` on `builds` (`Partial<Record<ArmorStatName, number>>`)  
**Testing**: vitest co-located; `npm run gate`  
**Target Platform**: Local Next.js; signed-in debug  
**Project Type**: Full-stack Next.js — debug/API-first  
**Performance Goals**: Coverage + estimate interactive  
**Constraints**: Soft-only; targets 1–200; best-effort estimate when loadout incomplete; nudges opt-in  
**Scale/Scope**: 4 user stories; schema + estimate + coverage softStats + nudge API + debug UI

## Constitution Check

- I. Small Testable Increments: **PASS** — US1 targets → US2 warnings → US3 nudges → US4 soft coexistence  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS** — target range validated; estimate from known inventory/manifest inputs  

**Post-design**: **PASS**

## Project Structure

```text
specs/019-soft-stat-targets/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/soft-stat-targets-contract.md, soft-stat-warnings-contract.md, soft-stat-nudges-contract.md
└── tasks.md

src/lib/db/schema.ts / client.ts          # soft_stat_targets column
src/lib/builds/softStatTargets.ts         # parse/validate
src/lib/builds/statEstimate.ts            # loadout estimate
src/lib/builds/coverage.ts                # softStats rows
src/lib/builds/coverageService.ts
src/lib/builds/statNudges.ts              # synergy → suggested targets
src/app/debug/builds/BuildsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Targets | builds column, PATCH build, soft-stat-targets-contract |
| US2 Warnings | statEstimate + coverage.softStats |
| US3 Nudges | suggest endpoint / accept PATCH |
| US4 Soft coexistence | regression with element soft + save |
| Validation | quickstart; Fetch Coverage shows softStats |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Best-effort estimate | Full fragment/mod graph incomplete | Blocking on perfect estimate delays soft warnings |
