# Feature Specification: Class-Item Intent Lock

**Feature Branch**: `022-class-item-intent`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Exotic class-item intent-lock across variants (deferred from 015). When the exotic armor slot is an exotic class item, identity is synergy/intent-locked (not item-hash-locked). Variants may use different class items/perk configs that still fit designated synergies (soft-checked). Store full class-item perk config per variant. Classic non–class-item exotic armor remains item-hash identity."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

**Prior slices**: [015-build-identity](../015-build-identity/spec.md) (deferred this), [017-soft-guidance](../017-soft-guidance/spec.md) (soft coverage)

## Clarifications

None yet — defaults from DBR-ID-005, DBR-ROLL-009, DAC-VAR-005.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Detect Exotic Class Item vs Classic Exotic (Priority: P1)

The system distinguishes **exotic class items** (ClassItem bucket) from **classic exotic armor**. Classic pieces stay item-hash identity (015). Class items use intent/synergy lock.

**Why this priority**: Gate for all other behavior; wrong classification breaks identity rules.

**Independent Test**: Fixture classic exotic (e.g. Felwinter’s) vs exotic class item hash; identity/confirm paths differ.

**Acceptance Scenarios**:

1. **Given** build exotic armor is a classic exotic, **When** identity is evaluated, **Then** item-hash lock applies (unchanged from 015).
2. **Given** build exotic armor is an exotic class item (or unset with class-item-only variants), **When** identity is evaluated, **Then** class-item intent mode applies (not hash-lock across variants).

### User Story 2 - Variants May Differ Within Intent (Priority: P1)

When in class-item intent mode, variants may select **different exotic class items and/or perk configs** without triggering identity confirm/fork, as long as soft synergy coverage still fits designated synergies.

**Why this priority**: DAC-VAR-005 / DBR-ID-005 core deliverable.

**Independent Test**: Two variants with different class-item hashes/configs on same build; save succeeds; no identity confirm required for the swap.

**Acceptance Scenarios**:

1. **Given** a class-item-intent build, **When** variant A uses class item X and variant B uses class item Y (both soft-fit synergies), **Then** both save without identity confirm/fork.
2. **Given** a class-item swap that weakens synergy coverage, **When** saved, **Then** soft coverage warnings apply (017); save is not hard-blocked solely for intent mismatch.
3. **Given** a classic exotic-armor identity build, **When** a variant tries a different exotic armor hash, **Then** identity confirm/fork still required (015 unchanged).

### User Story 3 - Full Perk Config Storage (Priority: P1)

Each variant stores the **full selected perk config** for its exotic class item (owned instance or wishlist desired plugs) per DBR-ROLL-009.

**Why this priority**: Required for resolve/equip/DIM fidelity.

**Independent Test**: PATCH variant with class-item hash + perk config; resolved/debug shows config; reload persists.

**Acceptance Scenarios**:

1. **Given** a variant class-item selection with perk hashes, **When** saved and reloaded, **Then** full config is retained.
2. **Given** wishlist (no instance) class-item config, **When** saved, **Then** desired plugs persist like other wishlist rolls.

### User Story 4 - Debug Verification (Priority: P2)

Builds debug can set/clear class-item intent mode signals, edit per-variant class-item + config, and show soft coverage / identity confirm behavior.

**Independent Test**: Tester completes classic vs class-item paths via debug only.

## Edge Cases

- Build exoticArmorHash unset but a variant attaches exotic class item in class_item slot: treat as class-item intent for that variant’s exotic armor claim.
- Switching build from classic exotic identity to class-item intent (or reverse) is an identity change → confirm/fork.
- Pair-set exotic armor that is a class item follows class-item rules.
- Soft coverage only; no hard block for “intent mismatch” beyond existing hard exotic limits (DBR-CMP-007).

## Requirements *(mandatory)*

- **FR-001**: System MUST detect exotic class items (ClassItem exotic armor) vs classic exotic armor.
- **FR-002**: Classic exotic armor identity MUST remain item-hash locked (015).
- **FR-003**: Class-item mode MUST allow different class items/configs across variants without identity confirm when only class-item selection changes.
- **FR-004**: Class-item fitness vs designated synergies MUST use soft coverage (017), not hard save block.
- **FR-005**: Variants MUST store full class-item perk config (DBR-ROLL-009).
- **FR-006**: Switching between classic exotic identity and class-item intent MUST require identity confirm/fork.
- **FR-007**: Debug/API verification without production polish UI.

## Success Criteria *(mandatory)*

- **SC-001**: Automated tests distinguish classic vs class-item identity behavior.
- **SC-002**: Cross-variant class-item swaps save without identity confirm in intent mode.
- **SC-003**: Perk config round-trips on variant save/load.
- **SC-004**: Gate green with new tests.
- **SC-005**: Debug path covers classic lock vs intent lock.

## Assumptions

- Manifest/exotic-armor catalog exposes slot (ClassItem) for detection.
- Soft coverage from 017 is the soft-check mechanism.
- Equip/DIM already consume resolved class_item claims; this slice focuses on identity + storage rules.

## Out of Scope

- Changing soft-coverage algorithm beyond class-item awareness
- LLM propose, production UI polish
- Hard-blocking saves for soft intent mismatch
