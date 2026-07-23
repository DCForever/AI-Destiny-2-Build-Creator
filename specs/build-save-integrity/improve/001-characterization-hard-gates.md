---
status: DONE
priority: P1
effort: M
risk: LOW
category: tests
depends: []
planned_at: 799a9d6
issue: ""
---

# Add characterization tests for Destiny hard save gates

## Objective

Hard composition rules (dual exotic, illegal subclass kit, mod energy, exotic ability pins) are enforced in pure/assert modules wired from `validateVariantSave`, but those assert modules have **no dedicated unit tests**. Regressions only surface via manual compose or coarse service tests. After this lands, each gate has table-driven tests aligned with domain DBR/DAC so later transactional-save work can refactor safely.

## Current context

- Assert modules (no sibling `*.test.ts` today):
  - `src/lib/builds/assertExoticLimits.ts`
  - `src/lib/builds/assertSubclassKit.ts`
  - `src/lib/builds/assertModEnergy.ts`
  - `src/lib/builds/assertExoticAbilityPins.ts`
- Orchestration: `src/lib/builds/buildService.ts` `validateVariantSave` (approx. lines 631–666) calls slot conflicts, exotic limits, mod energy, and default full loadout.
- Shared evaluation helpers live under `src/lib/builds/destinyBuildConstraints` (used by exotic limits).
- Domain refs: `specs/domain-business-rules.md` DBR-CMP-007, DBR-SUB-004, DBR-MOD-001, DBR-EXO / exotic ability pins; `specs/domain-acceptance-criteria.md` DAC-P1-003.
- Test style: vitest; many pure tests under `src/lib/builds/*.test.ts` with fixtures (see `equipReady.test.ts`, `destinyBuildConstraints` tests if present).
- Verification: `npm run test`, `npm run typecheck`, `npm run lint`.

```ts
// assertExoticLimits.ts:45-58
export async function assertExoticLimits(claims: SlotClaim[]): Promise<void> {
  const composition = await collectExoticComposition(claims);
  const { hardBlocks } = evaluateExoticLimits(composition);
  if (hardBlocks.length === 0) return;
  throw new ApiError(API_ERROR_CODES.TOO_MANY_EXOTICS, /* ... */, 400);
}
```

```ts
// buildService.ts:649-666
assertNoSlotConflicts(resolved);
await assertExoticLimits(exoticClaims);
await assertModEnergyForAttachments(/* ... */);
if (variant.isDefault) {
  const hasMods = await variantHasMods(db, userId, attachments);
  assertFullCombatLoadout(resolved, build, { hasMods });
}
```

**Product note:** Empty default variants without attachments are allowed during progressive Finish (028/029). Do **not** add tests that require full loadout on bare create; focus on assert modules and optional thin `validateVariantSave` cases with attachments present.

## Detailed instructions

### Requirements

- R1: Add vitest coverage for `assertExoticLimits` / composition: legal single exotic weapon + armor; illegal two exotic weapons; illegal two exotic armors; empty claims OK.
- R2: Add coverage for subclass kit legality (`assertSubclassKit` / related): at least one legal kit and one illegal over-capacity or invalid combination that throws the existing API error code.
- R3: Add coverage for mod energy / capacity (`assertModEnergy`): over-capacity blocked; legal under-capacity allowed (use fixtures or mocked listActiveSetItems).
- R4: Add coverage for `assertExoticAbilityPins`: mismatch between exotic-required ability and pinned super/subclass fields throws; matching config passes.
- R5: Prefer mocking `getServices` / entity stores where exotic hash sets are needed rather than full manifest download.
- R6: Optional thin tests for `validateVariantSave` only if cheap with `createTestDb` fixtures already used elsewhere — not required to expand into full HTTP route tests.
- R7: Do not change production assert behavior except fixing clear test-only bugs discovered; this prompt is characterization-first.

### Acceptance criteria

- [ ] New test files exist beside the assert modules (or a clear `assertGates.test.ts` that imports all four)
- [ ] `npm run test` passes and exercises legal + illegal cases for each of the four gate areas
- [ ] `npm run typecheck` passes
- [ ] No production route or UI files required to change for green CI

### Scope boundaries

**In scope**

- `src/lib/builds/assertExoticLimits.ts` (+ test)
- `src/lib/builds/assertSubclassKit.ts` (+ test)
- `src/lib/builds/assertModEnergy.ts` (+ test)
- `src/lib/builds/assertExoticAbilityPins.ts` (+ test)
- Shared test fixtures under `src/lib/builds/` as needed
- Optional small `validateVariantSave` tests in `buildService` tests

**Out of scope**

- Transactional save refactor (sibling prompt)
- Equip planner changes
- UI Finish walkthrough tests
- Expanding full combat loadout enforcement on create without attachments

### Risks and notes

- Exotic composition depends on entity cache exotic stores — mock carefully so tests stay offline.
- Keep error codes stable (`TOO_MANY_EXOTICS`, etc.); tests should assert codes, not only message strings.
- Reviewer: confirm progressive-create incomplete defaults remain allowed.