# Implementation Plan: Bungie Equip

**Branch**: `020-bungie-equip` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/020-bungie-equip/spec.md` (domain slice 6)

## Summary

Add **live Bungie equip** for equip-ready variants: class-matching character pick, sync-on-equip (~1/min reuse), transfer then equip combat pins, apply artifact/fashion when resolved, return **best-effort partial** status (no rollback). Reuse 016 gates and 018 resolved artifact/fashion. Debug/API-first with injectable write client for tests.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: `assertEquipReady`, `getResolvedVariant`, inventory sync/`lastFullSyncAt`, characters API, new `BungieWriteClient`  
**Storage**: No new tables; uses inventory + resolved  
**Testing**: vitest with mock write client; `npm run gate`  
**Target Platform**: Local Next.js; signed-in Bungie OAuth  
**Project Type**: Full-stack Next.js — debug/API-first  
**Performance Goals**: Equip orchestration within Bungie rate limits  
**Constraints**: Gate before writes; partial status; no hard rollback; fashion omit = leave-as-is  
**Scale/Scope**: 4 user stories; write client + planner + orchestrator + equip route + debug UI

## Constitution Check

- I. Small Testable Increments: **PASS** — gate+character → sync/transfer/equip → partial status → debug  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS** — Bungie responses validated; failures explicit  

**Post-design**: **PASS**

## Project Structure

```text
specs/020-bungie-equip/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/equip-contract.md, equip-status-contract.md
└── tasks.md

src/lib/bungie/writeClient.ts          # interface + HTTP + mock
src/lib/bungie/syncFreshness.ts        # ~1/min reuse
src/lib/builds/equipPlan.ts            # plan steps from resolved + inventory
src/lib/builds/equipOrchestrator.ts    # run steps → EquipStatus
src/app/api/user/builds/.../equip/route.ts
src/app/debug/builds/BuildsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Gate + character | assertEquipReady + class filter |
| US2 Sync/transfer/apply | writeClient + planner + orchestrator |
| US3 Partial status | EquipStatus contract |
| US4 Debug | character picker + Equip button |
| Validation | quickstart; mocked mid-fail test |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Injectable write client | Live Bungie flaky in CI | Real-only calls break gate |
