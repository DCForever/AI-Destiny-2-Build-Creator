# Feature Specification: Build Identity & Default Completeness

**Feature Branch**: `015-build-identity`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Implement build identity and default-variant completeness per specs/domain-business-rules.md and DAC-P1-001..004 / DAC-VAR-004 / DAC-NME-*. Scope: designated synergies as primary identity; optional exotic armor item identity; build-shared exotic weapon; optional build-pinned Super; tags filter-only; default variant full combat loadout; confirm/fork on identity edit; default naming unique per class. Out of scope: Bungie equip, DIM export, LLM pass, artifacts, wishlist instance pins, fashion equip, soft stats UI, exotic class-item intent-lock (later slice)."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Establish Build Identity on Save (Priority: P1)

A builder creates or updates a Build whose **identity** is defined by **designated synergies** (at least one required), with **optional exotic armor** (when set, identity by item/manifest hash, not inventory instance), an **optional exotic weapon** that is either **build-shared** (identity) or **variant-level** (not identity), and an **optional build-pinned Super** (identity when pinned). **Concept tags** may be attached for filtering but are **not** part of identity. Acceptance is verified through internal/debug tools (same pattern as feature 001).

**Why this priority**: Without a clear, enforceable identity model, variants cannot be distinguished from separate builds, and later completeness, naming, and edit/fork flows have no stable foundation.

**Independent Test**: Via debug/verification surfaces, create a build with ≥1 designated synergy, optional exotic armor, and either a build-shared or variant-level exotic weapon; confirm save succeeds; confirm a build with zero synergies is rejected; confirm changing only concept tags does not treat the build as a new identity.

**Acceptance Scenarios**:

1. **Given** a signed-in user composing a build, **When** they designate one or more synergies and save, **Then** the build is persisted with those synergies as primary identity.
2. **Given** a build with no designated synergies, **When** the user attempts to save, **Then** save is blocked with a clear message that at least one designated synergy is required (`NO_SYNERGY`).
3. **Given** the user sets exotic armor on the build, **When** they save, **Then** identity includes that exotic armor **item** (hash/catalog identity); different owned instances of the same item do not create a different build identity.
4. **Given** exotic armor is left unset, **When** the user saves an otherwise-valid build, **Then** save succeeds and identity does not include an exotic armor item.
5. **Given** the user marks an exotic weapon as **build-shared**, **When** they save, **Then** that exotic weapon is part of build identity and is shared across variants.
6. **Given** the user sets an exotic weapon at **variant level** only, **When** they save, **Then** variants may differ by exotic weapon without changing build identity.
7. **Given** the user pins Super at build level, **When** they save, **Then** Super is part of build identity and shared across variants.
8. **Given** a saved build, **When** the user adds, removes, or changes **concept tags** only, **Then** the build remains the same identity (no fork required) and tags remain available as filter metadata.

---

### User Story 2 - Require a Full Default Combat Loadout (Priority: P1)

A builder’s **default variant** must be a **full combat loadout** before the build (or that default variant) can be saved as complete: guardian class, subclass tree/kit, all weapon slots, all armor slots, and mods as part of the build composition. Non-default variants may leave combat slots empty in this slice. This slice does **not** include equip/DIM export, artifact configs, wishlist instance pins, or LLM-assisted discovery.

**Why this priority**: Domain completeness for the default kit is the other half of “a build is a fully equippable loadout”; identity alone must not allow an incomplete default to be treated as ready.

**Independent Test**: Compose a build with valid identity (≥1 synergy) but an incomplete default variant and confirm save is blocked with named gaps; fill all required combat slots (including mods as part of the build) and confirm save succeeds; create a non-default variant with empty slots and confirm it can save while the default remains complete.

**Acceptance Scenarios**:

1. **Given** a build with valid identity but a default variant missing one or more required combat slots (weapon, armor, subclass kit, or mods-as-part-of-build), **When** the user attempts to save the default as complete, **Then** save is blocked and the missing completeness requirements are named clearly.
2. **Given** a default variant with class, subclass kit, all weapon slots, all armor slots, and mods filled as part of the build, **When** the user saves, **Then** the default variant is accepted as a full combat loadout.
3. **Given** a build whose default variant is already a full combat loadout, **When** the user creates or edits a **non-default** variant with one or more empty combat slots, **Then** that non-default variant may be saved without requiring full combat completeness.
4. **Given** completeness validation for the default variant, **When** the user inspects the blocked or successful outcome in debug/verification tools, **Then** they can confirm which slots/kit pieces satisfied or failed the full-loadout rule without needing production UI, equip, DIM, artifacts, wishlist pins, or LLM features.

---

### User Story 3 - Confirm In-Place or Fork When Editing Identity (Priority: P2)

When a builder changes an **identity field** (designated synergies; exotic armor item when set; build-shared exotic weapon when set; build-pinned Super when set), the system requires an explicit choice: **confirm in-place** (update identity for the existing build and all its variants) or **fork** into a new Build that preserves the prior identity on the original. Changing non-identity fields (including concept tags and variant-only gear) does not trigger this choice.

**Why this priority**: Identity edits without confirm/fork silently rewrite every variant’s meaning or accidentally split builds; this protects multi-variant kits once identity and completeness exist.

**Independent Test**: On a build with two variants, change designated synergies (or set exotic armor / build-shared exotic weapon / build-pinned Super) and complete both paths—confirm in-place and fork—verifying variant membership and identity fields afterward; change only tags or a variant-level exotic weapon and confirm no confirm/fork prompt.

**Acceptance Scenarios**:

1. **Given** an existing build with one or more variants, **When** the user changes designated synergies, **Then** they must choose confirm in-place or fork before the change is applied.
2. **Given** the user chooses **confirm in-place**, **When** the identity change is applied, **Then** the same build id retains the new identity and all existing variants remain under that build.
3. **Given** the user chooses **fork**, **When** the identity change is applied, **Then** a new Build is created with the new identity (and appropriate variant copy behavior for continuing work), while the original build keeps its previous identity.
4. **Given** exotic armor is set, a build-shared exotic weapon is set, or Super is build-pinned, **When** the user changes that identity field, **Then** the same confirm in-place or fork choice is required.
5. **Given** the user changes only concept tags, variant-level exotic weapon, or other non-identity composition, **When** they save, **Then** no identity confirm/fork step is required.
6. **Given** the user clears previously set exotic armor or clears a build-shared exotic weapon or unpins Super, **When** they save, **Then** confirm in-place or fork is required (clearing identity fields is an identity edit).

---

### User Story 4 - Default Build Names and Per-Class Rename Uniqueness (Priority: P2)

A newly saved build receives a **default name** derived from available segments among **Class, Element, Super, Exotic Armor, Exotic Weapon, and Synergies**, omitting any missing optional segments (no “None” placeholders). Super in the default name comes from the **default variant** when Super is not build-pinned. The user may rename; renamed names must be **unique per class** for that user.

**Why this priority**: Readable, collision-safe names make identity tangible in lists and debug verification once identity and default completeness are enforceable.

**Independent Test**: Create builds with different combinations of present/absent name segments and confirm omitted segments; rename two Warlock builds to the same name and confirm rejection; create the same display name on Titan and Warlock and confirm both are allowed.

**Acceptance Scenarios**:

1. **Given** a build with class, element, default-variant Super, exotic armor, exotic weapon, and designated synergies all present, **When** the default name is generated, **Then** it includes segments reflecting Class, Element, Super, Exotic Armor, Exotic Weapon, and Synergies.
2. **Given** one or more of exotic armor, exotic weapon, or Super are unset/unavailable, **When** the default name is generated, **Then** those segments are omitted entirely (no placeholder text for missing parts).
3. **Given** a user renames a build, **When** the new name is unique among that user’s builds of the same class, **Then** the rename succeeds.
4. **Given** the user already has a build of class Warlock named `Ionic Trace Kit`, **When** they rename another Warlock build to `Ionic Trace Kit`, **Then** the rename is rejected with a clear uniqueness error.
5. **Given** a Titan build named `Ionic Trace Kit`, **When** the user names a Warlock build `Ionic Trace Kit`, **Then** both names are allowed (uniqueness is per class, not global across classes).

---

### Edge Cases

- Saving with zero designated synergies is always rejected, even if exotic armor, exotic weapon, tags, and a full default loadout are present.
- Changing concept tags never triggers confirm-in-place or fork; tags remain filter-only metadata.
- Clearing previously set exotic armor (or clearing a build-shared exotic weapon, or unpinning Super) is an identity change and requires confirm in-place or fork.
- Moving an exotic weapon from build-shared to variant-level (or the reverse) is an identity boundary change and requires confirm in-place or fork.
- Non-default variants may save with empty combat slots; soft guidance / coverage warnings for those variants are out of scope for this slice.
- Default-name generation omits missing segments and must not invent filler words.
- Rename uniqueness is scoped per user and per guardian class; identical names on different classes do not conflict.
- Equip/DIM export, artifact loadouts, wishlist/instance pins, and LLM proposal flows are out of scope; completeness here means composition completeness of the default combat loadout, not equippability of pinned instances.
- Exotic class-item intent-lock (variants may swap class items within synergies) is deferred; this slice treats set exotic armor as item-hash identity for classic exotic armor pieces.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A Build MUST designate ≥1 synergy; save with zero designated synergies MUST fail with a clear `NO_SYNERGY` outcome.
- **FR-002**: Designated synergies MUST be primary build identity; changing them MUST be treated as an identity edit (FR-008).
- **FR-003**: Concept tags MUST be optional filter metadata only; assigning or changing tags MUST NOT be treated as an identity edit and MUST NOT require confirm/fork.
- **FR-004**: Exotic armor (non–class-item), when set, MUST be identity by item (not inventory instance); variants MAY use different owned instances of that item without changing identity.
- **FR-005**: Exotic armor MUST be optional; when unset, identity MUST NOT include an exotic armor item.
- **FR-006**: Exotic weapon MAY be variant-level or build-shared; when build-shared, it MUST be identity and shared across variants.
- **FR-007**: Super MUST be variant-level by default and MAY be build-pinned; when pinned, it MUST be identity and shared across variants.
- **FR-008**: Changing any identity field (designated synergies; set exotic armor item; build-shared exotic weapon; build-pinned Super)—including clearing those fields—MUST warn and require either confirm in-place (applies to all variants) or fork to a new Build.
- **FR-009**: Gear, mods, non-pinned abilities/aspects/fragments, fashion, and artifact config MUST NOT be identity in this slice.
- **FR-010**: Each Build MUST have exactly one default variant; that default MUST be a full combat loadout (class, subclass tree, subclass kit, all weapon slots, all armor slots, and mods as part of the build) before it can be marked complete / saved as default.
- **FR-011**: Non-default variants MAY leave some combat slots empty; empty-slot rules for those variants MUST NOT weaken the default full-loadout requirement.
- **FR-012**: If the user does not supply a custom name, the system MUST derive a default Build name from Class, Element, Super, Exotic Armor, Exotic Weapon, and Synergies, omitting missing optional segments (no “None” placeholders); when Super is not build-pinned, the default variant’s Super MUST be used.
- **FR-013**: User-renamed Build names MUST be unique per class for that user; duplicate rename/create MUST be rejected clearly.
- **FR-014**: Builds MUST remain class-bound (Titan / Hunter / Warlock); subclass element/tree MUST be shared across variants for naming and composition consistency in this slice.

### Key Entities

- **Build**: Class-bound identity container; holds designated synergies, optional exotic armor item, optional build-shared exotic weapon, optional build-pinned Super, filter-only concept tags, derived or user name.
- **Build Variant**: Named loadout under a Build; exactly one default; default must be full combat loadout; may hold variant-level exotic weapon and incomplete slots when non-default.
- **Designated Synergy**: Curated play-pattern linked to the Build as primary identity (≥1 required).
- **Concept Tag**: Controlled-vocabulary filter label on a Build; not identity.
- **Identity Edit Decision**: User choice of confirm in-place vs fork when identity fields change.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In verification, 100% of save attempts with zero designated synergies are blocked with a message that names the synergy requirement.
- **SC-002**: In a scripted checklist, a tester can create one build with build-shared exotic weapon identity and one with variant-only exotic weapon difference, and correctly identify which field is shared identity vs variant-only in under 5 minutes using debug/verification tools only.
- **SC-003**: 100% of attempts to save a default variant missing any required full-combat slot (weapons, armor, subclass kit, or mods-as-part-of-build) are blocked with the missing gaps identifiable; 100% of complete default variants in the same checklist save successfully.
- **SC-004**: For identity-field edits on a multi-variant build, 100% of test runs require an explicit confirm-in-place or fork choice; tag-only and variant-only exotic weapon edits complete without that choice in 100% of parallel control cases.
- **SC-005**: Default names for at least 5 fixture combinations omit every missing optional segment (zero “None”/placeholder segments) and include every present Class/Element/Super/Exotic Armor/Exotic Weapon/Synergies segment expected by the fixture.
- **SC-006**: Rename uniqueness checks reject duplicate names within the same class in 100% of conflict fixtures and allow the same name across different classes in 100% of cross-class fixtures.

## Assumptions

- Domain rules in `specs/domain-business-rules.md` and ACs in `specs/domain-acceptance-criteria.md` are canonical when they conflict with older feature-001 BRs (especially ≥1-slot save, always-required exotic armor, tags-as-shared-sameness).
- Verification uses signed-in internal/debug tools; polished production UI is out of scope for this feature (same delivery pattern as 001).
- Existing Build/Variant/Synergy/Tag services and schemas are the starting point; this feature evolves them rather than inventing a parallel model.
- “Full combat loadout” means composition completeness (slots filled via sets and/or overrides), not owned-instance pins or in-game equip readiness (later slices).
- Exotic class-item intent-lock and ability auto-pin from exotic requirements are deferred to a later slice; classic exotic armor uses item-hash identity when set.
- Soft guidance / coverage UI, artifacts, fashion equip, LLM discovery, Bungie equip, and DIM export are out of scope.
- Fork copies enough variant structure for the user to continue editing the new build; exact copy depth (attachments live vs snapshot) may be refined in planning without changing the confirm/fork product rule.

## Out of Scope

- Bungie API equip, transfers, inventory sync
- DIM export
- LLM synergy discovery
- Artifact selection/config
- Wishlist desired rolls and instance pins / stale pins
- Fashion layer on equip
- Soft stat targets (EoF six) and coverage UI
- Exotic class-item intent-lock across variants
- Personal custom synergy keywords / promote-to-global

## Traceability

| Spec item | Domain |
|-----------|--------|
| US1 / FR-001–007, FR-009, FR-014 | DBR-ID-*, DBR-SYN-001/003, DAC-P1-001–002 |
| US2 / FR-010–011 | DBR-CMPL-001–002, DAC-P1-003 |
| US3 / FR-008 | DBR-ID-008–009, DAC-VAR-004 |
| US4 / FR-012–013 | DBR-NAME-*, DAC-NME-001–002 |
| FR-003 | DAC-NME-002 |
| FR-004 | DAC-VAR-006 |
