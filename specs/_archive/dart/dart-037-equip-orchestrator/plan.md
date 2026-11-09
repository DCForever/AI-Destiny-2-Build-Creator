# Implementation Plan: DART-037 Equip Orchestrator

**Branch**: `dart-037-equip-orchestrator` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-037-equip-orchestrator/spec.md`

## Summary

Port product equip planning + best-effort write orchestration into pure Dart:

1. **`packages/domain`**: pure `planEquipSteps` + plan DTOs (mirrors `equipPlan.ts`).
2. **`packages/bungie`**: `BungieWriteClient` (HTTP + mock) and `executeEquipPlan` partial status (mirrors `writeClient.ts` + `equipOrchestrator.ts`).

Exit criteria: best-effort partial equip; no full rollback; unit tests with mocked write API.

## Technical Context

**Language/Version**: Dart SDK ^3.5.0  

**Primary Dependencies**: `destiny2_domain` (pure plan), `destiny2_bungie` (HTTP client already present; add write surface). No Flutter/Jaspr required for this slice.

**Storage**: N/A (no Drift writes for equip execute; inventory is plan input only)

**Testing**: `dart test` in `packages/domain` and `packages/bungie` (mock transport / mock write client)

**Target Platform**: Shared pure packages (Windows Flutter host consumes later in DART-038)

**Project Type**: Library packages in Melos monorepo

**Performance Goals**: Sequential step execution; no parallelism requirement (Bungie write order matters)

**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft guidance never auto-applies; hard NOT_EQUIP_READY when combat instance missing from plan inventory

**Scale/Scope**: ~3 source files domain/bungie + 2 test files; parity with existing TS fixtures

## Constitution Check

- I. Small Testable Increments: Single slice — plan, write client, execute partial.
- II. Test-First discipline: Plan/execute tests mirror TS goldens before/with implementation.
- III. Green Commit Checkpoints: Domain tests green, then bungie tests green, then finish merge.
- IV–V. Co-located package tests; validation-first on plan missing instance.

No constitution violations requiring complexity tracking.

## Project Structure

### Documentation (this feature)

```text
specs/dart-037-equip-orchestrator/
├── spec.md
├── plan.md
├── research.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/domain/lib/src/evaluators/equip_plan.dart   # pure planner + DTOs
packages/domain/lib/destiny2_domain.dart             # export equip_plan
packages/domain/test/equip_plan_test.dart

packages/bungie/lib/src/write/write_client.dart      # interface, HTTP, mock
packages/bungie/lib/src/write/equip_orchestrator.dart
packages/bungie/lib/destiny2_bungie.dart             # exports
packages/bungie/pubspec.yaml                         # + destiny2_domain
packages/bungie/test/write_client_test.dart
packages/bungie/test/equip_orchestrator_test.dart
```

## Implementation approach

### Pure plan (domain)

- DTOs: `EquipStepKind`, `PlannedEquipStep`, `EquipInventoryItem`, `EquipPlanArtifact`, `EquipPlanFashion` / piece, `EquipPlanInput`.
- Reuse `EquipmentSlot.combatSlots`, `SlotClaim`, `EquipReadyException` / `DomainFailureCodes.notEquipReady` for missing combat instance.
- Fashion: `Map<String, EquipPlanFashionPiece>` (wire slot keys) so step ids stay `fashion-{slot}`.
- Locations: `vault` | `character` | `equipped` string parity.

### Write client (bungie)

- Abstract `BungieWriteClient` + `WriteClientContext`.
- `HttpBungieWriteClient` uses `BungieHttpClient.postJson` for TransferItem / EquipItem.
- `applyArtifactConfig`: throw clear “not fully wired” (TS parity).
- `applyFashionSlot`: equip by instanceId when present; throw if missing.
- `createMockWriteClient` / class with optional overrides; default no-op success.

### Orchestrator (bungie)

- `executeEquipPlan(client, ctx, characterId, plan) → EquipStatus`.
- Per-step try/catch → `EquipStepResult`; always continue; summarize completed/failed.
- No compensating reverse transfers.

## Dependencies

| Package | Change |
| ------- | ------ |
| destiny2_domain | +equip_plan evaluator |
| destiny2_bungie | +destiny2_domain dep; write + orchestrator |

## Risks / non-goals

- Does not gate on full `computeEquipReady` inside planner (caller/UI does that in DART-038); planner only fails when building a step for a missing combat instance.
- Artifact apply remains stub on HTTP path.
- No Flutter character picker or post-sync UI.

## Test plan

1. `cd packages/domain && dart test test/equip_plan_test.dart`
2. `cd packages/bungie && dart test test/write_client_test.dart test/equip_orchestrator_test.dart`
