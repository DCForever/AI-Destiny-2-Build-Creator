# Implementation Plan: DIM Export

**Branch**: `021-dim-export` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/021-dim-export/spec.md` (domain slice 7)

## Summary

Add **variant-based DIM export** for equip-ready builds: reuse 016 `assertEquipReady` / dim-export-gate, map resolved variant (gear pins, mods, fashion, artifact) + optional soft-stat targets into `DimLoadout`, share via existing `DimSyncClient` when configured. Keep generator-sheet `/api/dim/share`. Debug/API-first with `jsonOnly` escape hatch.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: `assertEquipReady`, `getResolvedVariant`, `DimSyncClient`, `DimLoadout` types, soft-stat targets (019)  
**Storage**: No new tables  
**Testing**: vitest with mocked DimSync; `npm run gate`  
**Target Platform**: Local Next.js; Bungie OAuth + optional `DIM_API_KEY`  
**Project Type**: Full-stack Next.js — debug/API-first  
**Performance Goals**: Single resolve + share round-trip  
**Constraints**: Gate before share; fashion omit empty; keep `/api/dim/share`  
**Scale/Scope**: 4 user stories; builder + route + debug button

## Constitution Check

- I. Small Testable Increments: **PASS** — gate → payload → share → debug  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS** — explicit 409/503/401  

**Post-design**: **PASS**

## Project Structure

```text
specs/021-dim-export/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/dim-export-contract.md
└── tasks.md

src/lib/dim/buildVariantDimLoadout.ts   # resolved → DimLoadout
src/lib/dim/collectVariantMods.ts       # mod hashes from attachments
src/app/api/user/builds/.../dim-export/route.ts
src/app/debug/builds/BuildsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Gate | assertEquipReady on dim-export route |
| US2 Payload | buildVariantDimLoadout + collectVariantMods |
| US3 Share | DimSyncClient; 503 default / jsonOnly 200 |
| US4 Debug | Export to DIM button |
| Validation | quickstart; mocked share tests |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| jsonOnly flag | CI/debug without DIM_API_KEY | Share-only would block gate |
| Separate builder from sheet path | Variant shape ≠ ResolvedBuildSheet | Forcing sheet adapter loses pins/fashion |
