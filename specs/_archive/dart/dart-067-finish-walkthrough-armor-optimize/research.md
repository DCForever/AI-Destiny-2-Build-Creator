# Research: DART-067 Finish Walkthrough / Armor Optimize / Post-Sync

**Date**: 2026-07-25  
**Branch**: `dart-067-finish-walkthrough-armor-optimize`

## R1 — Reuse domain finish helpers

**Decision**: Keep pure `evaluateFinishGaps`, `resolvePostMutationStep`, `showFinishCreateActions`, `shouldOpenArmorOptimize`, `firstEmptyRequiredSlot` in `destiny2_domain` (DART-007). Hosts own UI state (step, skippedKeys, fillSlot) and call use cases for mutations.

**Rationale**: Parity already golden-tested; host residual is action chrome only.

## R2 — createSetAndAttach / capture as app use cases

**Decision**: Port `createSetAndAttach` and `createSetsFromBuild` (capture) into `packages/app` using existing `createUserSet`, `replaceAttachmentByType`, `upsertUserSetItem`.

**Rationale**: Product Finish POSTs these APIs; Dart shells call in-process use cases (no HTTP).

## R3 — Armor improve = bind existing OptimizerController

**Decision**: Embed `OptimizerWorkspace` in Windows Finish when step is armor_optimize; bind covering set id. Do not reimplement isolate pipeline.

**Rationale**: DART-036 already confirm-only; GAP-UI-BUILD-04 is wiring into Build path.

## R4 — Post-sync suggestions without auto-apply

**Decision**: After `InventorySyncController.syncNow` success, host optionally runs improvement scan (constrained armor sets attached to builds). Banner Confirm → `applyArmorCombinationInPlace`; Dismiss → local list remove only.

**Rationale**: BR-OPT-004 / Next InventorySyncCard parity; soft best-effort.

## R5 — Web optimizer deferred

**Decision**: Jaspr gets Create/Capture/fill only. No Find kits / post-sync banner on web in this slice.

**Rationale**: GAP-FEAT-01 deferred; SETTINGS-04 shells = windows; BUILD-04 web may stay deferred.

## R6 — Constraints JSON

**Decision**: Minimal `parseOptimizerConstraints` / `serializeOptimizerConstraints` in app package for eligibility + preferReuse/thresholds/locked exotic used by suggestions and optional seed on armor capture.

**Rationale**: Sets store opaque JSON today; post-sync eligibility needs non-null parseable payload.
