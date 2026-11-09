# Implementation Plan: Hard-gate characterization tests

**Branch**: `035-hard-gate-tests` | **Date**: 2026-07-23 | **Spec**: `specs/035-hard-gate-tests/spec.md`
**Input**: Feature specification from `/specs/035-hard-gate-tests/spec.md`

## Summary
Add offline vitest characterization tests for the four hard save-gate assert modules used by `validateVariantSave`. Mock `getServices` entity cache (and exotic ability lookup) so tests never hit the network. Do not change production behavior; do not expand full combat loadout rules on bare create.

## Technical Context
**Language/Version**: TypeScript (strict), Next.js 16 app codebase  
**Primary Dependencies**: vitest, existing `@/lib/api/errors`, `@/lib/builds/*`  
**Storage**: N/A (unit tests; no DB required for assert modules)  
**Testing**: `npm run test` (vitest run); `npm run typecheck`; `npm run lint`  
**Target Platform**: Node test runner in repo CI  
**Project Type**: Web application (lib unit tests only)  
**Performance Goals**: Suite completes in seconds; pure mocks  
**Constraints**: Offline mocks only; stable error codes; no UI/route edits  
**Scale/Scope**: Four assert modules + sibling `*.test.ts` files

## Constitution Check
- *Small, testable increments*: One feature = characterization tests only. PASS
- *Test-first / co-located verification*: New tests beside production asserts. PASS
- *Green commit checkpoints*: Commit after specify, plan, tasks, implement; run typecheck/lint/test before final. PASS
- *Validation-first external data*: Entity stores mocked; no live manifest. PASS

## Project Structure

### Documentation (this feature)
```text
specs/035-hard-gate-tests/
├── plan.md
├── research.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)
```text
src/lib/builds/
├── assertExoticLimits.ts
├── assertExoticLimits.test.ts          # NEW
├── assertSubclassKit.ts
├── assertSubclassKit.test.ts           # NEW
├── assertModEnergy.ts
├── assertModEnergy.test.ts             # NEW
├── assertExoticAbilityPins.ts
└── assertExoticAbilityPins.test.ts     # NEW
```

**Structure Decision**: Co-locate one test file per assert module (matches improve acceptance and constitution co-location).

## Implementation approach

### Mock harness
- `vi.mock("@/lib/services", ...)` returning `{ entityCache: { getStore: vi.fn(...) } }`.
- `getStore` switches on store id: `exotic-weapons`, `exotic-armor`, `aspects`, `mods`.
- Per-test `mockResolvedValue` / implementation overrides as needed.
- Exotic ability: `vi.mock("@/data/exoticAbilityRequirements", ...)` with controllable `lookupExoticAbilityRequirements` / `hasAbilityRequirements` OR spy real helpers after seeding via mock factory returning fixed requirements for a test hash/name.

### Case tables (minimum)

| Module | Legal | Illegal |
|--------|-------|---------|
| exotic limits | `[]`; 1 weapon + 1 armor | 2 weapons; 2 armors |
| subclass kit | 2 aspects capacity 5, ≤5 fragments | fragments > capacity; aspectCount > MAX |
| mod energy | sum cost ≤10 (or empty) | sum > capacity; wrong slot category |
| ability pins | no req; matching super | mismatched super |

### Error assertions
```ts
await expect(fn()).rejects.toMatchObject({
  code: API_ERROR_CODES.TOO_MANY_EXOTICS,
  status: 400,
});
```
(or `instanceof ApiError` + `.code` depending on existing patterns).

### Out of scope
- Transactional save refactor
- `assertFullCombatLoadout` / bare-create full loadout
- UI, routes, equip planner
- Domain doc edits (no product rule change)

## Complexity Tracking
N/A — no constitution violations.
