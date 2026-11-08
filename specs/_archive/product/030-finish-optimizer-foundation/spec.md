# Feature Specification: Finish Optimizer Foundation

**Feature Branch**: `030-finish-optimizer-foundation`
**Created**: 2026-07-23
**Status**: Draft
**Input**: Optional classType for empty-set optimize; synergy-first set-bonus ranking; constraints compose helpers; tests only (no Finish UI).

**Prior**: [026](../026-armor-set-optimizer/spec.md), [028](../028-build-inline-sets/spec.md), [029](../029-finish-slot-first/spec.md)

## Iteration Scope
**In**: (1) explicit class on optimize when set empty; (2) rank set bonuses with designated-synergy armor_set_bonus links first; (3) compose constraints from build seed + user edits. Pure helpers + API + tests.
**Out**: Finish UI (031); DIM LO; inventory sync redesign; auto-apply kits.

## User Stories
### US1 - Empty set optimize with class (P1)
**Test**: Empty armor set + constraints + classType Warlock does not fail class resolution.
1. Given empty armor set with constraints, When optimize with classType, Then proceeds past class resolve.
2. Given empty set without classType, When optimize, Then clear class failure.
3. Given pieces imply class, When class omitted, Then piece resolution still works.

### US2 - Synergy-linked bonuses first (P1)
**Test**: Linked bonuses group before unlinked with synergy labels.
1. Given armor_set_bonus links on designated synergies, When rank, Then linked group first.
2. Given unlinked bonus, When rank, Then only in all group.
3. Given no links, When rank, Then linked empty.

### US3 - Compose constraints (P1)
**Test**: seed + goals + toggles yields valid schema.
1. Seed exotic + soft targets match seedConstraintsFromBuild.
2. User goals become setBonusGoals 2 or 4.
3. Toggles default mods on / reuse off.

## Requirements
- **FR-001**: Optimize accepts optional explicit Destiny class.
- **FR-002**: Explicit class used when provided for candidate load.
- **FR-003**: Omitted class keeps piece-based resolution.
- **FR-004**: Pure rank helper: linked vs all via designated/bridged armor_set_bonus links.
- **FR-005**: Linked rows expose setBonusKey/hash/name + suggested minPieces.
- **FR-006**: Pure compose helper: seed + edits to ArmorSetOptimizerConstraints.
- **FR-007**: Output validates against existing constraints schema.
- **FR-008**: Tests for empty+class, ranking, compose.
- **FR-009**: No Finish UI in this feature.

## Success Criteria
- **SC-001**: Empty+classType cases avoid class failure.
- **SC-002**: Ranking places linked before unlinked.
- **SC-003**: Compose tests pass schema.
- **SC-004**: Existing optimizeFromSet tests green.

## Assumptions
setBonusKey matches 026; bridge = resolveDesignatedSynergies; clients pass build.className; goals dedupe by setBonusKey last-wins.

## Dependencies
026 optimizeFromSet; synergy armor_set_bonus links; build.className.
