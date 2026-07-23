# Implementation Plan: Finish Optimizer Foundation
**Branch**: `030-finish-optimizer-foundation` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

## Summary
Extend optimize body/route with optional classType; add rankSetBonusesForBuild and composeOptimizerConstraints pure helpers; tests. No Finish UI.

## Technical Context
TS/Next 16; vitest; existing optimizeFromSet, seedConstraintsFromBuild, resolveDesignatedSynergies.

## Constitution Check
PASS: small increments; test-first helpers; gate; co-located tests.

## Project Structure
src/lib/optimizer/optimizeFromSet.ts
src/app/api/user/sets/[id]/optimize/route.ts
src/lib/optimizer/rankSetBonusesForBuild.ts
src/lib/optimizer/composeOptimizerConstraints.ts

## Delivery Mapping
US1 schema+route+empty-set test; US2 ranking helper; US3 compose helper.

## Complexity Tracking
None.
