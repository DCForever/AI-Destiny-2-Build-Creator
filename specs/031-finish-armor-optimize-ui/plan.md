# Plan: 031 Finish Armor Optimize UI
## Summary
Add FinishArmorOptimizeWorkspace + armor-optimize-context API; wire FinishBuildWalkthrough armor branch to workspace after covering set; use 030 compose/rank/classType and apply-combination.

## Tech
React client panel; GET context API; PATCH set; POST optimize; POST apply-combination.

## Files
src/app/api/user/builds/[id]/armor-optimize-context/route.ts
src/components/build/FinishArmorOptimizeWorkspace.tsx
src/components/build/FinishBuildWalkthrough.tsx
src/lib/builds/finishNextSlot.ts (armor_optimize step optional)

## Constitution
PASS — UI slice over existing APIs; manual smoke + gate.
