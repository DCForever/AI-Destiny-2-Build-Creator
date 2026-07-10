# Implementation Plan: Class-Item Intent Lock

**Branch**: `022-class-item-intent` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/022-class-item-intent/spec.md` (domain slice 8)

## Summary

Distinguish **exotic class items** (ClassItem slot) from **classic exotic armor**. Classic stays item-hash identity (015). Class-item mode is **intent/synergy-locked**: variants may use different class items/perk configs without identity confirm/fork; fitness is soft coverage (017). Store full perk config on class_item set attachments. Switching classic ↔ intent requires confirm/fork.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js App Router  
**Primary Dependencies**: exotic-armor catalog `slot`, `identityFieldsChanged`, `resolveVariantEquipment`, coverage (017), set `selectedPerks`  
**Storage**: No new tables preferred — reuse attachment snapshot/live `selectedPerks` on `class_item`  
**Testing**: vitest; `npm run gate`  
**Target Platform**: Local Next.js; debug/API-first  
**Constraints**: Soft-only intent mismatch; hard exotic limits unchanged (DBR-CMP-007)  
**Scale/Scope**: Detection helper + identity gating + resolve/pair/coverage fixes + debug

## Constitution Check

- I. Small Testable Increments: **PASS** — detect → identity gate → resolve/config → debug  
- II. Test-First: **PASS** (plan)  
- III. Green Commit Checkpoints: **PASS** (plan)  
- IV. Co-Located Tests: **PASS**  
- V. Validation-First: **PASS**

**Post-design**: **PASS**

## Project Structure

```text
specs/022-class-item-intent/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/class-item-intent-contract.md
└── tasks.md

src/lib/builds/exoticArmorIntent.ts   # detect mode + identity change rules
src/lib/builds/buildService.ts        # identityFieldsChanged gating
src/lib/builds/resolveVariant.ts      # intent resolve + pair match
src/lib/builds/coverageService.ts     # real exotic slot lookup
src/app/debug/builds/BuildsDebugPage.tsx
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Detect | exoticArmorIntent + catalog slot |
| US2 Variant swaps | identity gate skip; pair-match relax |
| US3 Perk config | class_item selectedPerks on attachments → SlotClaim |
| US4 Debug | edit exotic armor; show mode |
| Validation | quickstart; classic vs intent tests |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Shared lookup module | Dedupe buildService/compareVariants/coverage | Leaving chest fallback breaks class_item coverage |
