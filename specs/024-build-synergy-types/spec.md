# Feature Specification: Build Synergy Types

**Feature Branch**: `024-build-synergy-types`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build Synergies are only the first part of a Synergy (Type). A Synergy is Type linked with an Object. Builds designate Types; library Synergies remain Type + Object; bridge matches for coverage/suggestions."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

**Refs**: DBR-SYN-001–004, DAC-P1-001–002

## Clarifications

- Builds designate **Synergy Types** (`type` + optional `subType`), not library synergy UUIDs.
- A **Synergy** library record is **Type linked with an Object** (evidence links).
- Bridge **unions** all matching library records per designation (equal weight).
- Coverage: **one row per designation** (aggregated links).
- Default build name uses Type labels (e.g. `Verb: Devour`), not library `— Object` names.
- Unmatched Types are valid; coverage reports missing / no library evidence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Designate Types on Create (Priority: P1)

User creates a build by selecting ≥1 Synergy Type (e.g. Verb: Devour, Melee: Base, Primary Weapon). No library synergy is required.

**Independent Test**: POST create with `synergyTypes: [{ type: "verb", subType: "Devour" }]`; build saves; empty array → `NO_SYNERGY`.

### User Story 2 - Bridge to Library Synergies (Priority: P1)

When library synergies exist for a designated Type, coverage and suggestions use the **union** of their evidence links.

**Independent Test**: Two library synergies with same `(type, subType)` and different links; designate that Type; coverage/suggestions see both links.

### User Story 3 - Identity on Type Change (Priority: P1)

Changing designated Types is an identity change (confirm or fork).

**Independent Test**: PATCH Types without `identityAction` → `IDENTITY_CONFIRM_REQUIRED`.

### User Story 4 - Unmatched Type Still Valid (Priority: P2)

Designate a Type with no matching library record; build saves; coverage reports missing/no evidence.

**Independent Test**: Create with Type that has zero library matches; detail returns designation + empty matched list.

## Requirements *(mandatory)*

- **FR-001**: Builds MUST store designations as `(type, subType)` rows (`build_synergy_types`), not `synergy_id` FKs.
- **FR-002**: Create/update MUST require ≥1 valid Synergy Type (`NO_SYNERGY` otherwise); subType rules match synergy create.
- **FR-003**: Read path MUST bridge designations → matching library synergies by `(userId, type, subType)` with **union** of links.
- **FR-004**: Coverage MUST emit one row per designation (aggregated matched links).
- **FR-005**: Default build names MUST use Type labels + optional subType.
- **FR-006**: Identity compare MUST use sorted `(type, subType)` tuples.
- **FR-007**: List filter MAY use `?type=&subType=` (replacing `?synergyId=`).
- **FR-008**: UI create/edit MUST pick Types (type + subType), not library UUIDs.

## Success Criteria *(mandatory)*

- **SC-001**: Build create with Types and zero library matches succeeds.
- **SC-002**: Empty Types rejected with `NO_SYNERGY`.
- **SC-003**: Bridge unions duplicate `(type, subType)` library records for coverage/suggestions.
- **SC-004**: Migrated builds from `build_synergies` retain distinct Types from former linked records.

## Out of Scope

- Requiring ≥1 Object on library Synergy create
- Production `/synergy` library UI polish
- LLM propose payload changes beyond Type-based build designation
