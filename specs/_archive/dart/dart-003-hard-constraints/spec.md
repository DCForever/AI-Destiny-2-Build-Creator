# Feature Specification: DART-003 Hard Constraints

**Feature Branch**: `dart-003-hard-constraints`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port pure hard evaluators: exotic limits, mod energy, subclass kit, exotic ability match. Golden tests vs TS fixtures; hard-block codes stable; capacityResolved semantics documented."

**Program ID**: DART-003  
**Phase**: P0  
**Depends**: DART-002  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure hard-block evaluators in `packages/domain` that mirror TypeScript `src/lib/builds/destinyBuildConstraints.ts`:

- `evaluateExoticLimits` (DBR-CMP-007 / DAC-DST-001)
- `evaluateModEnergy` (DBR-MOD-001–002 / DAC-DST-002)
- `evaluateSubclassKit` including `capacityResolved` semantics (DBR-SUB-004 / DAC-DST-003)
- `evaluateExoticAbilityMatch` (DBR-SUB-005 / DAC-DST-004)
- `evaluateSynergyRequirement` (DBR-SYN-003) — pure hard gate co-located with the same TS module
- `mergeConstraintEvaluations` helper
- Golden unit tests parity with `destinyBuildConstraints.test.ts`
- Documented `capacityResolved` semantics (spec + API docs)

**Out of scope (later slices):** soft coverage (DART-004), resolveVariant (DART-005), equipReady (DART-006), finishGaps (DART-007), optimizer (DART-008), static sandbox tables / exotic ability requirement tables (DART-009 — this slice only matches already-resolved ability requirements), entity/manifest adapters, save-pipeline orchestration, Flutter/Jaspr, Drift/IO, Node sidecar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exotic limits and mod energy hard blocks (Priority: P1)

As a multiplatform domain engineer, I can call pure functions that emit stable `TOO_MANY_EXOTICS` and `MOD_ENERGY_EXCEEDED` hard blocks matching TypeScript behavior so later save pipelines share one gate language.

**Why this priority**: Composition and mod capacity are the most common hard save failures; golden parity must land first.

**Independent Test**: Unit tests feed exotic hash lists and mod energy pieces; assert codes, messages, and empty soft-warning lists match TS fixtures.

**Acceptance Scenarios**:

1. **Given** one exotic weapon hash and one exotic armor hash, **When** `evaluateExoticLimits` runs, **Then** hard blocks are empty.
2. **Given** two distinct exotic weapon hashes (or two armor), **When** evaluated, **Then** one `TOO_MANY_EXOTICS` block per over-limit kind with message matching the weapon/armor wording.
3. **Given** duplicate hashes for the same exotic, **When** evaluated, **Then** dedupe allows a single unique hash without block; zero/negative hashes are ignored.
4. **Given** a mod piece with `energyUsed` greater than `energyCapacity`, **When** `evaluateModEnergy` runs, **Then** `MOD_ENERGY_EXCEEDED` includes the slot label; under/at capacity yields no blocks.

---

### User Story 2 - Subclass kit and capacityResolved (Priority: P1)

As an engineer, I can evaluate aspect/fragment legality with explicit `capacityResolved` so unresolved aspect stores do not false-hard-block fragment counts.

**Why this priority**: `capacityResolved` is an explicit port decision surface and exit criterion; wrong default breaks parity with server assert paths.

**Independent Test**: Fixture matrix for aspect over max, fragments over capacity, at capacity, and `capacityResolved: false` with high fragment count.

**Acceptance Scenarios**:

1. **Given** `aspectCount` > max (default 2), **When** evaluated, **Then** `ILLEGAL_SUBCLASS_KIT` with aspects message.
2. **Given** `capacityResolved` true (default) and `fragmentCount` > `fragmentCapacity`, **When** evaluated, **Then** `ILLEGAL_SUBCLASS_KIT` with fragments message.
3. **Given** fragments equal capacity, **When** evaluated, **Then** no hard blocks from fragments.
4. **Given** `capacityResolved: false` and a high fragment count, **When** evaluated, **Then** fragment over-capacity does **not** emit a hard block (aspect over-max still can).

---

### User Story 3 - Exotic ability match and synergy requirement (Priority: P2)

As an engineer, I can match exotic-required abilities to kit/pins and require ≥1 synergy designation using pure evaluators with stable codes.

**Why this priority**: Completes the pure hard surface of the TS constraints module for DART-003 exit criteria.

**Independent Test**: Mismatched super → `EXOTIC_ABILITY_MISMATCH` + soft `EXOTIC_ABILITY_PIN_PROPOSED`; pinned super overrides kit; empty synergy list → `NO_SYNERGY`; merge concatenates blocks.

**Acceptance Scenarios**:

1. **Given** required Super `Thundercrash` and kit Super `Hammer of Sol` with null pin, **When** `evaluateExoticAbilityMatch` runs, **Then** hard `EXOTIC_ABILITY_MISMATCH` and soft `EXOTIC_ABILITY_PIN_PROPOSED`.
2. **Given** the same required Super and `pinnedSuper: Thundercrash`, **When** evaluated, **Then** no hard blocks.
3. **Given** empty required abilities, **When** evaluated, **Then** no hard blocks (no-op).
4. **Given** empty synergy types, **When** `evaluateSynergyRequirement` runs, **Then** `NO_SYNERGY`; non-empty list allows.
5. **Given** multiple evaluation parts, **When** `mergeConstraintEvaluations` runs, **Then** hard and soft lists are concatenated in order.

---

### Edge Cases

- Hash dedupe is by unique positive values (`h > 0`); `0` and negatives do not count toward exotic limits.
- Name matching for abilities is case-insensitive after trim (TS `namesMatch`).
- Super effective value prefers non-empty trimmed `pinnedSuper` over kit super.
- Soft warning `EXOTIC_ABILITY_PIN_PROPOSED` appears only when there is at least one requirement **and** at least one hard mismatch; it never hard-blocks alone.
- `capacityResolved` defaults to **true** when omitted (TS: `input.capacityResolved !== false`).
- Soft guidance must never auto-apply; these evaluators only return result envelopes.
- Domain package remains zero IO/UI runtime dependencies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure `evaluateExoticLimits` with code `TOO_MANY_EXOTICS` for >1 unique exotic weapon and/or >1 unique exotic armor hashes (DBR-CMP-007).
- **FR-002**: Domain MUST export pure `evaluateModEnergy` that emits `MOD_ENERGY_EXCEEDED` per piece where used energy exceeds capacity (DBR-MOD-001–002).
- **FR-003**: Domain MUST export pure `evaluateSubclassKit` that enforces max aspects (default 2) and, when `capacityResolved` is true, fragment count ≤ fragment capacity (DBR-SUB-004).
- **FR-004**: Domain MUST document and implement `capacityResolved` semantics: **false** skips fragment-capacity hard enforcement; **omitted/true** enforces it. Callers that cannot resolve aspect capacities must pass `false`.
- **FR-005**: Domain MUST export pure `evaluateExoticAbilityMatch` with hard `EXOTIC_ABILITY_MISMATCH` and soft `EXOTIC_ABILITY_PIN_PROPOSED` per TS rules (DBR-SUB-005).
- **FR-006**: Domain MUST export pure `evaluateSynergyRequirement` emitting `NO_SYNERGY` for empty designations (DBR-SYN-003).
- **FR-007**: Domain MUST export `mergeConstraintEvaluations` that flattens hard blocks and soft warnings.
- **FR-008**: Hard-block `code` strings MUST remain stable and identical to TypeScript: `TOO_MANY_EXOTICS`, `ILLEGAL_SUBCLASS_KIT`, `MOD_ENERGY_EXCEEDED`, `EXOTIC_ABILITY_MISMATCH`, `NO_SYNERGY` (plus soft `EXOTIC_ABILITY_PIN_PROPOSED`).
- **FR-009**: Golden unit tests MUST cover the scenarios in `destinyBuildConstraints.test.ts` (and documented capacityResolved edge).
- **FR-010**: Evaluators MUST NOT perform IO, read manifest stores, or auto-apply kit/pin mutations; inputs are pre-resolved pure values.
- **FR-011**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **ExoticComposition**: weapon/armor exotic hash lists (model from DART-002).
- **ModEnergyPiece**: slot + used + capacity (model from DART-002).
- **SubclassKitEvalInput**: counts + capacity + `capacityResolved` (model from DART-002).
- **AbilityKit**: super/melee/grenade/class ability names (model from DART-002).
- **ConstraintEvaluation / HardBlock / SoftWarning**: result envelope (model from DART-002).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All golden hard-constraint tests pass under `dart test packages/domain`.
- **SC-002**: Every hard-block code used by these evaluators matches the TypeScript string constants exactly.
- **SC-003**: `capacityResolved: false` never produces a fragment over-capacity hard block in tests; documentation states the default and skip rule.
- **SC-004**: Soft `EXOTIC_ABILITY_PIN_PROPOSED` never appears without a corresponding hard mismatch path covered by tests.
- **SC-005**: Domain package analyze clean; no new IO/UI dependencies.

## Assumptions

- Port source of truth is `src/lib/builds/destinyBuildConstraints.ts` (+ its vitest) as of this slice; server assert wrappers that resolve hashes/names stay out of scope.
- `evaluateSynergyRequirement` is included because it is pure, co-located, and uses a DART-002 hard-gate code; it is not deferred to soft-coverage.
- Ability requirement tables (`exoticAbilityRequirements`) remain data for DART-009; this slice only matches already-supplied `required` fields.
- Message text aims for TS parity (not only codes) so golden message regexes port cleanly.
- No NEEDS CLARIFICATION retained: `capacityResolved` default true matches TS.
