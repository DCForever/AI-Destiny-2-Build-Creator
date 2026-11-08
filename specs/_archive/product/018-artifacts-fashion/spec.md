# Feature Specification: Artifacts & Fashion (Per Variant)

**Feature Branch**: `018-artifacts-fashion`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement per-variant seasonal artifact selection (exactly one of six fixed artifacts with full unlock config) and fashion set attachment (shaders/ornaments, ghost, sparrow, ship, emblem, finisher). Fashion is not identity and does not drive synergies/suggestions/stats. Omitted fashion slots leave cosmetics as-is on later equip. Emotes and consumables out of scope. Storage and debug/API verification in this slice; Bungie equip apply deferred to bungie-equip slice."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [domain-slice-roadmap.md](../domain-slice-roadmap.md)

**Prior slices**: [015-build-identity](../015-build-identity/spec.md), [016-wishlist-equip-ready](../016-wishlist-equip-ready/spec.md), [017-soft-guidance](../017-soft-guidance/spec.md)

## Clarifications

None yet — defaults taken from DBR-ART-*, DBR-FASH-*, DAC-VAR-002–003, and roadmap note that this slice stores configs for later equip.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Per-Variant Artifact Selection & Config (Priority: P1)

A builder assigns **exactly one** of the **six fixed seasonal artifacts** to a variant and stores a **full artifact unlock/mod config** for that choice. Different variants of the same build may choose different artifacts and configs. Verification is debug/API-first.

**Why this priority**: Artifact choice is required for complete variant readiness (DBR-ART-001–003, DAC-VAR-002) and must exist before equip/DIM slices can apply it.

**Independent Test**: Via debug/API, set artifact A + config on variant 1 and artifact B + config on variant 2 of the same build; reload both; confirm each stores exactly one artifact identity and its full config independently.

**Acceptance Scenarios**:

1. **Given** a variant with no artifact yet, **When** the user selects one of the six fixed artifacts and a valid unlock config, **Then** the variant stores that artifact and config.
2. **Given** a variant already configured with an artifact, **When** the user switches to a different one of the six and a new config, **Then** the prior choice is replaced (still exactly one artifact).
3. **Given** two variants of the same build, **When** each selects a different artifact and config, **Then** each retains its own selection independently.
4. **Given** an attempt to assign an artifact outside the fixed set of six, **When** save/update runs, **Then** the request is rejected with a clear validation error.
5. **Given** stored artifact config on a variant, **When** a tester inspects debug/API output, **Then** artifact identity and unlock selections are visible without requiring Bungie equip or DIM export.

---

### User Story 2 - Fashion Sets Attach Per Variant (Priority: P1)

A builder attaches **fashion/cosmetic sets** to a variant covering allowed fashion slots: shaders/ornaments, ghost, sparrow, ship, emblem, and finisher. Fashion remains **non-identity** and does **not** drive synergies, suggestions, or soft-stat scoring. Emotes and consumables/temporary buffs are out of scope.

**Why this priority**: Fashion is part of full equip/DIM payloads later (DBR-FASH-001–005, DAC-VAR-003) and must be storable per variant now.

**Independent Test**: Create a fashion set with a subset of allowed cosmetic slots; attach it to a variant; confirm attachment and items persist via debug/API; confirm combat resolve/coverage/suggest flows ignore fashion contents.

**Acceptance Scenarios**:

1. **Given** a fashion set with one or more allowed cosmetic slots filled, **When** it is attached to a variant, **Then** the attachment is stored and listed with the variant.
2. **Given** a fashion set attached to a variant, **When** combat resolve / coverage / suggest-sets run, **Then** fashion items do not claim combat slots, do not change coverage tiers, and do not drive suggestion scoring.
3. **Given** fashion slots left empty on the attached set, **When** the variant is inspected, **Then** those slots are recorded as omitted (for later equip leave-as-is behavior).
4. **Given** an attempt to put emotes or consumables into fashion, **When** validation runs, **Then** those item kinds are rejected.
5. **Given** debug/API tools only, **When** a tester reviews fashion attachment output, **Then** they can verify per-variant fashion without production polish UI or live Bungie apply.

---

### User Story 3 - Resolved Variant Exposes Artifact + Fashion for Later Equip (Priority: P2)

Resolved variant payloads (debug/API) include the selected **artifact + config** and **fashion layer** (specified slots only) so later `bungie-equip` / `dim-export` slices can consume them. This slice does **not** call Bungie equip or produce DIM share files for fashion/artifact apply.

**Why this priority**: Downstream slices need a stable contract; exposing resolved fields now prevents rework.

**Independent Test**: Resolve a variant that has both artifact config and fashion attachment; confirm response includes both; confirm no equip/DIM apply side effects occur.

**Acceptance Scenarios**:

1. **Given** a variant with artifact config and fashion attachment, **When** resolved is fetched, **Then** the payload includes artifact identity/config and fashion specified slots.
2. **Given** a variant with artifact but no fashion (or fashion with only some slots), **When** resolved is fetched, **Then** omitted fashion slots are absent or explicitly unmarked—not invented.
3. **Given** resolved output in this slice, **When** inspected, **Then** there is no Bungie equip transfer/apply and no DIM export of fashion/artifact beyond existing equip-ready gates for combat gear.

---

### User Story 4 - Artifact Required for Default Completeness Softness (Priority: P2)

Default-variant completeness rules may **soft-warn** when artifact is missing, but this slice does **not** newly hard-block non-default saves solely for missing fashion. Fashion remains optional. Exact hard-gate for missing artifact on default (if any) follows existing completeness patterns without inventing new identity rules.

**Why this priority**: Keeps artifact/fashion aligned with soft-vs-hard guidance already established (DBR-GUID / completeness) without blocking builders mid-composition.

**Independent Test**: Save a non-default variant without fashion and with/without artifact per product rules; confirm fashion omission never hard-blocks; document artifact completeness behavior in tests.

**Acceptance Scenarios**:

1. **Given** a non-default variant with no fashion attached, **When** the user saves, **Then** save succeeds.
2. **Given** a non-default variant missing artifact config, **When** the user saves, **Then** save is not newly hard-blocked solely by fashion rules; artifact completeness follows the documented completeness policy for this slice.
3. **Given** identity fields unchanged, **When** only artifact or fashion on a variant changes, **Then** no identity confirm/fork is required.

---

### Edge Cases

- Switching artifacts clears or replaces unlock config so stale unlocks from the previous artifact are not retained.
- Fashion set attached alongside combat sets: combat resolution ignores fashion; no slot conflicts between fashion cosmetics and armor/weapon slots.
- Duplicate fashion attachments: at most one active fashion attachment per variant (or last-write-wins with clear API behavior)—document chosen rule in plan.
- Manifest/catalog missing one of the six artifacts: validation fails closed with a clear error rather than inventing a seventh.
- Ornament/shader on a slot with no underlying armor item in the fashion set: allowed as fashion-only data for later equip leave-as-is semantics.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow each variant to select exactly one of the six fixed artifacts and store a full unlock/mod config for that artifact.
- **FR-002**: System MUST reject artifact identities outside the fixed set of six.
- **FR-003**: System MUST allow fashion sets (type `fashion`) to attach per variant with allowed cosmetic slots: shaders/ornaments, ghost, sparrow, ship, emblem, finisher.
- **FR-004**: System MUST exclude emotes and consumables/temporary buffs from fashion.
- **FR-005**: Fashion MUST NOT be treated as build identity and MUST NOT drive synergies, suggestions, or soft-stat scoring.
- **FR-006**: Combat resolve MUST ignore fashion items for equipment slot claims and conflicts.
- **FR-007**: Resolved variant (debug/API) MUST expose artifact selection/config and fashion specified slots for later equip/DIM consumers.
- **FR-008**: This slice MUST NOT implement Bungie equip apply or DIM export of artifact/fashion (deferred).
- **FR-009**: Changing only variant artifact or fashion MUST NOT trigger identity confirm/fork.
- **FR-010**: Omitted fashion slots MUST be representable so later equip can leave character cosmetics as-is.

### Key Entities

- **ArtifactSelection**: Per-variant choice of one of six artifacts plus unlock/mod config payload.
- **FashionSet**: Set of type `fashion` holding allowed cosmetic slot items.
- **FashionAttachment**: Link from variant to a fashion set.
- **ResolvedFashionLayer**: Specified cosmetic slots only, suitable for later equip/DIM.
- **ResolvedArtifact**: Artifact identity + unlock config on resolved variant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Testers can configure two variants with different artifacts/configs and reload both correctly via debug/API in under 2 minutes.
- **SC-002**: 100% of fashion-attached variants show fashion excluded from combat resolve conflicts and suggestion gap scoring in automated tests.
- **SC-003**: Resolved payload always includes artifact and fashion fields (nullable/empty when unset) so bungie-equip/dim-export can consume without schema churn.
- **SC-004**: Gate (`npm run gate`) remains green with new artifact/fashion tests.
- **SC-005**: No identity confirm/fork prompts appear when only artifact or fashion changes.

## Assumptions

- The six artifacts are the current seasonal/catalog fixed set exposed by the manifest entity store (not user-defined).
- Fashion set type already exists in the set model; this slice completes cosmetic slot validation, attachment semantics, and resolved exposure.
- Bungie apply and DIM fashion/artifact export land in later slices; this slice only stores and exposes data.
- Soft-stat targets remain out of scope (slice 5).

## Out of Scope

- Live Bungie equip/transfer/apply of artifact or fashion
- DIM share/export of fashion/artifact (beyond preparing resolved fields)
- Emotes, consumables, temporary buffs
- Soft-stat UI, LLM propose, class-item intent-lock
- Changing the count of artifacts beyond the fixed six
