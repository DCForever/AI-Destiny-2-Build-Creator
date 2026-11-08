# Research: Hard-gate characterization tests

## Decision 1: Direct assert tests over validateVariantSave
**Decision**: Cover the four assert modules directly; skip optional `validateVariantSave` wiring tests.  
**Rationale**: Improve prompt R6 marks orchestration tests optional; assert units are cheaper and isolate domain gates.  
**Alternatives considered**: Full `createTestDb` service tests — higher fixture cost, weaker failure localization.

## Decision 2: Mock getServices entity cache
**Decision**: `vi.mock("@/lib/services")` with `entityCache.getStore` keyed by store name.  
**Rationale**: Matches existing offline patterns (`collectVariantMods.test.ts`, catalog route tests); avoid manifest download.  
**Alternatives considered**: Real entity cache — flaky/offline-hostile.

## Decision 3: Mock exotic ability requirements module
**Decision**: Mock `@/data/exoticAbilityRequirements` because `EXOTIC_ABILITY_REQUIREMENTS` seed is empty in-repo.  
**Rationale**: Characterization must not depend on uncommenting production seed data.  
**Alternatives considered**: Temporarily patch seed array — mutates shared module state and risks cross-test bleed.

## Decision 4: Prefer assertModEnergyForConfigs
**Decision**: Primary mod coverage via `assertModEnergyForConfigs`; attachments loader path optional.  
**Rationale**: Energy + illegal category logic lives there; attachments only aggregate configs.

## Decision 5: No production behavior changes
**Decision**: Characterization-first; only fix clear test-only bugs if asserts are untestable.  
**Rationale**: Improve R7 / acceptance; progressive create empty defaults must stay allowed.

## Decision 6: Skip clarify; document assumptions in spec
**Decision**: Non-interactive Spec Kit path.  
**Rationale**: Orchestrator hard rule for this improve run.
