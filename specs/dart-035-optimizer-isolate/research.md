# Research: DART-035 Optimizer Isolate

**Date**: 2026-07-24

## Product TS sources

| Area | Source |
| ---- | ------ |
| Pipeline | `src/lib/optimizer/optimizeArmor.ts` — prune → enumerate → buildCombination → filter → sort → maxResults |
| Combination | `src/lib/optimizer/buildCombination.ts`, `combinationDto.ts` |
| Empty reasons | `src/lib/optimizer/explainEmpty.ts` |
| Materialize | `src/lib/sets/materializeCombination.ts` (US5 new set) |
| Apply in place | `src/lib/sets/applyCombinationInPlace.ts` (US5b) |
| Confirm-only | Debug UI + improvement suggestions: suggest then confirm via materialize/apply APIs |

## Isolate pattern (this monorepo)

DART-018 `packages/manifest/lib/src/isolate_rebuild.dart` uses `Isolate.run` with primitive path args. DART-035 mirrors that: pure work function + isolate wrapper that transfers maps/primitives.

## Decisions

| Topic | Decision |
| ----- | -------- |
| Where is isolate | `destiny2_app` (not domain) |
| Candidates load | Injected only (A1) |
| Auto mods | Deferred; empty assumedMods (A2) |
| Attach on materialize | Default off; host can call `replaceAttachmentByType` separately (keeps confirm-only surface small) |
| Soft thresholds | Score/filter only when requireThresholds; never auto-apply |

## Risks

- Large boards: rely on prune K + maxCombinations (DART-008) + maxResults.
- Isolate cold start: acceptable for optimize button; UI progress is DART-036.
