# Feature Specification: Hard-gate characterization tests
**Branch**: `035-hard-gate-tests` | **Created**: 2026-07-23 | **Status**: Draft
**Input**: Improve prompt `specs/build-save-integrity/improve/001-characterization-hard-gates.md` — add vitest characterization coverage for Destiny hard save gates (`assertExoticLimits`, `assertSubclassKit`, `assertModEnergy`, `assertExoticAbilityPins`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exotic composition gate (Priority: P1)
As a maintainer refactoring variant save, I need offline unit tests that prove one exotic weapon + one exotic armor is allowed and dual exotic weapons/armors hard-block with `TOO_MANY_EXOTICS`, so I can change orchestration without guessing composition rules.

**Why this priority**: Dual-exotic is the highest-risk silent regression in equipment resolve.

**Independent Test**: Run `assertExoticLimits` tests with mocked exotic stores; legal/illegal/empty cases pass without network or DB.

**Acceptance Scenarios**:
1. **Given** empty claims, **When** `assertExoticLimits` runs, **Then** it resolves without throw.
2. **Given** one exotic weapon hash and one exotic armor hash, **When** assert runs, **Then** it resolves without throw.
3. **Given** two distinct exotic weapon hashes, **When** assert runs, **Then** it throws `ApiError` with `TOO_MANY_EXOTICS`.
4. **Given** two distinct exotic armor hashes, **When** assert runs, **Then** it throws `ApiError` with `TOO_MANY_EXOTICS`.

---

### User Story 2 - Subclass kit gate (Priority: P1)
As a maintainer, I need tests that a legal aspect/fragment kit saves and an over-capacity or over-aspect kit throws `ILLEGAL_SUBCLASS_KIT`.

**Why this priority**: Fragment capacity depends on aspect store resolution; regressions are easy when mocks drift.

**Independent Test**: Mock `aspects` store fragment capacities; assert legal kit OK and illegal kit throws code.

**Acceptance Scenarios**:
1. **Given** two aspects totaling fragment capacity ≥ fragment count, **When** `assertSubclassKitLegal` runs, **Then** it resolves.
2. **Given** more fragments than resolved capacity, **When** assert runs, **Then** it throws `ILLEGAL_SUBCLASS_KIT`.
3. **Given** more than `MAX_SUBCLASS_ASPECTS` aspects, **When** assert runs, **Then** it throws `ILLEGAL_SUBCLASS_KIT`.

---

### User Story 3 - Mod energy gate (Priority: P1)
As a maintainer, I need tests that under-capacity mod loadouts pass and over-capacity or illegal slot-category mods throw `MOD_ENERGY_EXCEEDED`.

**Why this priority**: Energy math and slot legality both gate saves; pure `assertModEnergyForConfigs` is enough without attachments.

**Independent Test**: Mock `mods` store; call `assertModEnergyForConfigs` with legal/illegal configs.

**Acceptance Scenarios**:
1. **Given** mods whose energy sum ≤ capacity for the piece, **When** assert runs, **Then** it resolves.
2. **Given** mods whose energy sum exceeds capacity, **When** assert runs, **Then** it throws `MOD_ENERGY_EXCEEDED`.
3. **Given** a slot-locked mod on the wrong armor piece, **When** assert runs, **Then** it throws `MOD_ENERGY_EXCEEDED` (illegal piece path).
4. **Given** empty configs, **When** assert runs, **Then** it resolves (progressive create / no mods).

---

### User Story 4 - Exotic ability pin gate (Priority: P1)
As a maintainer, I need tests that matching kit/pinned super passes and mismatched required abilities throw `EXOTIC_ABILITY_MISMATCH`.

**Why this priority**: Seed table may be empty in repo; tests must inject requirements via module mock so coverage does not depend on live seed data.

**Independent Test**: Mock `lookupExoticAbilityRequirements` / `hasAbilityRequirements`; assert match vs mismatch.

**Acceptance Scenarios**:
1. **Given** no ability requirements for the exotic, **When** `assertExoticAbilityPins` runs, **Then** it returns without throw.
2. **Given** required super matches subclass super (or pinnedSuper), **When** assert runs, **Then** it returns without throw.
3. **Given** required super differs from kit and pin, **When** assert runs, **Then** it throws `EXOTIC_ABILITY_MISMATCH`.

---

### Edge Cases
- Empty claims / empty mod configs / empty aspect lists must remain allowed (progressive Finish create).
- Unknown mod hashes in configs are skipped for cost (current production behavior) — characterize, do not change.
- Unresolved aspect names set `capacityResolved: false` and skip fragment over-cap hard block — characterize if covered cheaply.
- Do **not** require full combat loadout on bare create; no `assertFullCombatLoadout` expansion in this feature.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST provide vitest coverage for `assertExoticLimits` legal single exotic weapon+armor, illegal dual weapons, illegal dual armor, empty claims.
- **FR-002**: System MUST provide vitest coverage for `assertSubclassKitLegal` with at least one legal kit and one illegal over-capacity or over-aspect kit throwing existing API error code.
- **FR-003**: System MUST provide vitest coverage for `assertModEnergyForConfigs` over-capacity blocked and under-capacity allowed; illegal slot category blocked.
- **FR-004**: System MUST provide vitest coverage for `assertExoticAbilityPins` mismatch throws and matching config passes.
- **FR-005**: Tests MUST mock `getServices` / entity cache stores (and exotic ability lookup as needed) so suites run offline without manifest download.
- **FR-006**: Tests MUST assert stable `API_ERROR_CODES` values, not only message strings.
- **FR-007**: Production assert behavior MUST NOT change except clear test-only bugs discovered during characterization.
- **FR-008**: Optional thin `validateVariantSave` tests are out of required scope; prefer direct assert module tests.
- **FR-009**: Progressive-create incomplete defaults without attachments MUST remain allowed (no new full-loadout-on-create requirements).

### Key Entities
- **SlotClaim**: Equipment claim with `slot`, `itemHash`, `itemName`, `source`.
- **SubclassKitInput**: Aspects/fragments/ability name fields on variant subclass.
- **ModEnergyConfig**: Armor slot + mod hashes + optional tier.
- **ApiError**: Structured 400 with `API_ERROR_CODES.*` for hard gates.

## Success Criteria *(mandatory)*

### Measurable Outcomes
- **SC-001**: New `*.test.ts` files exist beside the four assert modules (or one clear multi-import suite under `src/lib/builds/`).
- **SC-002**: `npm run test` exercises legal + illegal cases for all four gate areas and passes.
- **SC-003**: `npm run typecheck` and `npm run lint` pass for touched files / project.
- **SC-004**: No production route or UI file changes required for green CI.
- **SC-005**: Spec Kit artifacts live under `specs/035-hard-gate-tests/` with commits after specify, plan, tasks, and implement phases.

## Assumptions
- Improve prompt is source of truth; interactive clarify skipped.
- Domain DBR/DAC already define gate semantics; this feature only characterises existing assert wrappers — no domain doc edits unless a product rule change is discovered (none expected).
- Mocking `@/lib/services` `getServices` → `entityCache.getStore` is the preferred isolation pattern (see existing dim/catalog tests).
- For exotic ability pins, mocking `@/data/exoticAbilityRequirements` is acceptable because the production seed array may be empty.
- `assertModEnergyForAttachments` orchestration can stay lightly covered or uncovered if `assertModEnergyForConfigs` fully covers energy/illegality rules.
- Worktree-only; do not touch `F:\Destiny2BuildCreator` main checkout.
