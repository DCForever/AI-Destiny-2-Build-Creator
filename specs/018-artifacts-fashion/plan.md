# Implementation Plan: Artifacts & Fashion (Per Variant)

**Branch**: `018-artifacts-fashion` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/018-artifacts-fashion/spec.md` (domain slice 4)

## Summary

Store **per-variant artifact selection + unlock config** and complete **fashion set** cosmetic-slot validation/attachment so variants can carry fashion for later equip. Expose both on **resolved** debug/API payloads. Fashion stays non-identity and out of combat resolve / suggestions. **No** Bungie apply or DIM fashion/artifact export in this slice.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: Drizzle/SQLite `build_variants`, `sets`/`set_items`/`variant_set_attachments`, `resolveVariant`, manifest `artifacts` store, Builds/Sets debug pages  
**Storage**: New nullable columns on `build_variants` for artifact hash/name/config JSON; fashion via existing set type + attachments once cosmetic slots validate  
**Testing**: vitest co-located; `npm run gate`  
**Target Platform**: Local Next.js; signed-in debug  
**Project Type**: Full-stack Next.js — debug/API-first  
**Performance Goals**: Variant update + resolve interactive  
**Constraints**: No Bungie equip/DIM apply; fashion ≠ identity/synergies/stats; emotes/consumables rejected; ≤1 fashion attachment per variant  
**Scale/Scope**: 4 user stories; schema + set fashion slots + resolve exposure + debug UI + contracts/tests

## Constitution Check

- I. Small Testable Increments: **PASS** — US1 artifact → US2 fashion slots/attach → US3 resolved exposure → US4 soft completeness / non-identity  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS** — artifact hashes validated against manifest store; fashion slots/kinds validated before write  

**Post-design**: **PASS**

## Project Structure

```text
specs/018-artifacts-fashion/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/artifact-contract.md, fashion-contract.md, resolved-artifact-fashion-contract.md
└── tasks.md

src/lib/db/schema.ts
src/lib/sets/schemas.ts
src/lib/sets/setItemService.ts
src/lib/builds/schemas.ts
src/lib/builds/variantService.ts / buildService.ts
src/lib/builds/resolveVariant.ts
src/app/api/user/builds/.../variants/...
src/app/debug/builds/BuildsDebugPage.tsx
src/app/debug/sets/SetsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Artifact | schema columns, variant PATCH, artifact-contract |
| US2 Fashion | FASHION_SLOTS, set item upsert, ≤1 attach, fashion-contract |
| US3 Resolved | getResolvedVariant + resolved-artifact-fashion-contract |
| US4 Soft / non-identity | regression: fashion omit OK; identityAction not required |
| Validation | quickstart.md; Builds + Sets debug |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
