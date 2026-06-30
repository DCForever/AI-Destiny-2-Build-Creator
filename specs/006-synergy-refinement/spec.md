# Feature Specification: Synergy Refinement

**Feature Branch**: `006-synergy-refinement`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Synergies need more refinement. 1. Should be auto-named from the selections. Verb: Scorch - Skyburners Oath. 2. Verb is not its own synergy, but should instead be to list a specific verb like Scorch or Sever. Melee and Grenade should also support specific grenades. 3. The Debug UI does not let me pick from the available weapons, weapon_perk, origin_traits, or armor_set_bonuses. These options should all be read and none should be free-form. 4. The description should show for any weapons, weapon_perk, origin_traits, or armor_set_bonuses."

## Clarifications

### Session 2026-06-29

- Q: Should Melee and Grenade sub-type pickers be limited or comprehensive? → A: Any melee or any grenade from the full curated catalog (user picks one specific ability/type).
- Q: Does Super require a sub-type picker like Melee/Grenade? → A: Yes — Super follows the same pattern (required specific super selection).
- Q: Should Element be a synergy category? → A: Yes — Element is its own synergy category requiring a specific element sub-type (e.g., Solar, Arc, Void).
- Q: Should Kinetic Weapon remain a synergy option? → A: No — Kinetic Weapon is removed from creatable synergy categories.
- Q: What should the Damage synergy category be called? → A: Renamed to **DPS** (replaces "Damage").

## Iteration Scope

**In scope**: Refining how synergies are defined and verified in internal debug tools—auto-generated names, specific sub-type selection for Verb/Melee/Grenade/Super/Element synergies, updated synergy category list (add Element, rename Damage→DPS, remove Kinetic Weapon), catalog-backed link pickers (no free-text entry), and read-only description display for linked game elements.

**Out of scope**: Polished production synergy editor UI, changes to suggestion-ranking algorithms, and bulk migration of legacy synergies (existing records—including legacy `kinetic_weapon` and `damage` types—remain readable; new/edited synergies follow the refined rules).

**Builds on**: [001-build-sets-synergies](../001-build-sets-synergies/spec.md) User Story 4 (Define and Manage Synergies) and existing synergy link kinds (weapon, weapon_perk, origin_trait, armor_set_bonus).

## Synergy Categories

| Category | Sub-type required? | Sub-type source | Auto-name pattern |
|----------|-------------------|-----------------|-------------------|
| Verb | Yes | Curated verb vocabulary (deduplicated) | `Verb: {verb} — {link}` |
| Melee | Yes | Any melee ability from full curated catalog | `Melee: {melee} — {link}` |
| Grenade | Yes | Any grenade type from full curated catalog | `Grenade: {grenade} — {link}` |
| Super | Yes | Any super ability from full curated catalog | `Super: {super} — {link}` |
| Element | Yes | Specific damage element (Solar, Arc, Void, Stasis, Strand, Prismatic) | `Element: {element} — {link}` |
| Primary Weapon | No | — | `Primary Weapon — {link}` |
| Special Weapon | No | — | `Special Weapon — {link}` |
| Heavy Weapon | No | — | `Heavy Weapon — {link}` |
| DPS | No | — | `DPS — {link}` |
| Healing | No | — | `Healing — {link}` |

**Removed categories** (not creatable; legacy records remain readable): Kinetic Weapon, Damage (superseded by DPS).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Auto-Generated Synergy Names (Priority: P1)

A curator creating a synergy should not need to type a display name manually. As they choose the synergy category, any required sub-type (e.g., a specific verb or element), and a linked game element, the system composes a human-readable name that reflects those choices—such as **Verb: Scorch — Skyburner's Oath** or **Element: Solar — Skyburner's Oath**.

**Why this priority**: Consistent naming reduces errors, makes synergy lists scannable, and removes duplicate or ambiguous labels that block reliable filtering and build attachment.

**Independent Test**: On the synergies debug page, select Verb + Scorch + link Skyburner's Oath; confirm the name field shows the composed label before create, and the saved synergy uses that name.

**Acceptance Scenarios**:

1. **Given** a user is creating a synergy, **When** they select category Verb, sub-type Scorch, and link weapon Skyburner's Oath, **Then** the synergy name is automatically set to a label equivalent to `Verb: Scorch — Skyburner's Oath` (category, sub-type, and link display name separated clearly).
2. **Given** the user changes any of category, sub-type, or linked element before saving, **Then** the auto-generated name updates immediately to reflect the new combination.
3. **Given** a synergy is saved with an auto-generated name, **When** it appears in synergy lists and build attachment pickers, **Then** the same composed name is shown everywhere.
4. **Given** the user selects category Element and sub-type Solar, **When** they link a weapon, **Then** the auto-generated name follows the pattern `Element: Solar — {link name}`.

---

### User Story 2 - Specific Sub-Types for Verb, Melee, Grenade, Super, and Element (Priority: P1)

Verb, Melee, Grenade, Super, and Element synergies must identify a **specific** gameplay element—not merely the broad category. Melee and Grenade pickers include **any** melee ability or grenade type from the full curated catalog. Super requires picking a specific super ability. Element requires picking a specific damage element. Other categories (Primary Weapon, Special Weapon, Heavy Weapon, DPS, Healing) use category alone without a sub-type picker.

**Why this priority**: A generic "Verb" or "Element" synergy is too vague to guide builds or suggestions; curators need precision about which verb, ability, or element the synergy documents.

**Independent Test**: Attempt to create a Verb synergy without selecting a specific verb; save is blocked. Create Super + Hammer of Sol + one link; synergy is saved with super sub-type metadata.

**Acceptance Scenarios**:

1. **Given** the user selects synergy category Verb, **When** the form is shown, **Then** a required sub-type picker lists available verbs (e.g., Scorch, Sever, Ignition) from the system's curated verb vocabulary and does not allow saving without a selection.
2. **Given** the user selects category Grenade, **When** the form is shown, **Then** a required sub-type picker lists **any** grenade type from the full curated grenade catalog and does not allow saving without a selection.
3. **Given** the user selects category Melee, **When** the form is shown, **Then** a required sub-type picker lists **any** melee ability from the full curated melee catalog and does not allow saving without a selection.
4. **Given** the user selects category Super, **When** the form is shown, **Then** a required sub-type picker lists **any** super ability from the full curated super catalog (same pattern as Melee/Grenade) and does not allow saving without a selection.
5. **Given** the user selects category Element, **When** the form is shown, **Then** a required sub-type picker lists specific damage elements (Solar, Arc, Void, Stasis, Strand, Prismatic) and does not allow saving without a selection.
6. **Given** the user selects a category that does not require a sub-type (e.g., DPS), **When** they complete the form, **Then** no sub-type picker is shown and naming uses category + link only (e.g., `DPS — Witherhoard`).
7. **Given** the user attempts to create a synergy with category Kinetic Weapon or Damage, **When** they open the category picker, **Then** those options are not available (Kinetic Weapon removed; Damage replaced by DPS).
8. **Given** an existing synergy created under legacy categories (`kinetic_weapon`, `damage`, or generic Verb), **When** the user views it, **Then** it remains visible and editable; saving after edit must conform to refined rules (migrate type to DPS where applicable).

---

### User Story 3 - Catalog-Backed Link Pickers (Priority: P2)

When associating a synergy with a weapon, weapon perk, origin trait, or armor set bonus, the user must choose from searchable lists sourced from current game catalog data. Free-text entry for these link targets is not permitted.

**Why this priority**: Free-form names and hashes cause validation failures and unusable synergies; pickers ensure every link resolves and matches manifest-backed records.

**Independent Test**: Open create-synergy form for each link kind; verify only pickers appear (no raw text/hash fields), selections populate required link fields, and invalid manual values cannot be submitted.

**Acceptance Scenarios**:

1. **Given** link kind weapon, **When** the user searches the picker, **Then** results come from the weapons catalog and selecting one sets the link to that weapon's canonical identity and display name.
2. **Given** link kind weapon_perk, **When** the user searches, **Then** results come from the perks catalog (optionally scoped to a parent weapon when applicable) and selecting one sets perk identity and display name.
3. **Given** link kind origin_trait, **When** the user searches, **Then** results come from the origin-traits catalog and selecting one sets trait name/hash—no free-text origin trait field.
4. **Given** link kind armor_set_bonus, **When** the user picks an armor set, **Then** they choose 2-piece or 4-piece threshold and then a bonus from that set's defined bonuses—no free-text set or bonus names.
5. **Given** any link kind, **When** the user attempts to submit without selecting from the catalog, **Then** save is rejected with a clear validation message.

---

### User Story 4 - Description Preview for Linked Elements (Priority: P2)

When the user selects a weapon, weapon perk, origin trait, or armor set bonus as a synergy link, the system displays that element's in-game description (or bonus text) read-only in the form so the curator understands what they are linking before saving.

**Why this priority**: Descriptions disambiguate similarly named perks or bonuses and reduce mistaken links during documentation.

**Independent Test**: Select Skyburner's Oath as a weapon link; confirm weapon description text appears. Switch to an origin trait; confirm trait description updates.

**Acceptance Scenarios**:

1. **Given** the user selects a weapon link, **When** the selection is made, **Then** the weapon's catalog description is shown read-only below or beside the picker.
2. **Given** the user selects a weapon_perk link, **When** the selection is made, **Then** the perk's description text is shown read-only.
3. **Given** the user selects an origin_trait link, **When** the selection is made, **Then** the origin trait's description is shown read-only.
4. **Given** the user selects an armor_set_bonus link (set + piece count + bonus), **When** the selection is complete, **Then** the bonus description from catalog data is shown read-only.
5. **Given** the user clears or changes the link selection, **When** the picker value changes, **Then** the description panel updates or hides accordingly.

---

### Edge Cases

- What if catalog search returns no matches? Show an empty state with guidance to refine search; do not fall back to free-text entry.
- What if a previously saved link's catalog record becomes unavailable after a game data update? Display the persisted display name with a stale indicator; block **new** links to invalid records only.
- What if auto-generated name would exceed maximum name length? Truncate the link display portion with an ellipsis while preserving category and sub-type.
- What if two different selection combinations produce the same auto-name? Allow both (names need not be unique); list views may show link kind or sub-type as disambiguation context.
- Sub-type vocabularies (verbs, grenades, melees, supers) should be deduplicated where the same name appears across subclasses (e.g., Scorch on multiple subclasses → one Scorch option).
- Legacy synergies with type `kinetic_weapon` or `damage` remain listable and deletable; re-save prompts migration to valid category (DPS for former Damage synergies).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST auto-generate synergy display names from the selected category, required sub-type (when applicable), and primary linked element display name, using a consistent pattern: `{Category}: {Sub-type} — {Link name}` for Verb, Melee, Grenade, Super, and Element; `{Category} — {Link name}` for categories without sub-types.
- **FR-002**: System MUST require a specific verb selection when synergy category is Verb; generic Verb-only synergies MUST NOT be creatable or savable without a named verb sub-type.
- **FR-003**: System MUST require a specific grenade selection when synergy category is Grenade; the sub-type picker MUST include any grenade from the full curated catalog; generic Grenade-only synergies MUST NOT be creatable.
- **FR-004**: System MUST require a specific melee ability selection when synergy category is Melee; the sub-type picker MUST include any melee from the full curated catalog; generic Melee-only synergies MUST NOT be creatable.
- **FR-005**: System MUST require a specific super ability selection when synergy category is Super; the sub-type picker MUST include any super from the full curated catalog, following the same pattern as Melee and Grenade.
- **FR-006**: System MUST support synergy category **Element** with a required specific element sub-type (Solar, Arc, Void, Stasis, Strand, Prismatic); generic Element-only synergies MUST NOT be creatable.
- **FR-007**: Sub-type options for Verb, Melee, Grenade, Super, and Element MUST be drawn from curated, system-maintained vocabularies (not user-typed strings).
- **FR-008**: System MUST NOT offer **Kinetic Weapon** as a creatable synergy category; existing `kinetic_weapon` records remain readable and deletable only.
- **FR-009**: System MUST rename the **Damage** synergy category to **DPS** for all new synergies; existing `damage` records remain readable; re-save MUST migrate type to `dps`.
- **FR-010**: Synergy link pickers for weapon, weapon_perk, origin_trait, and armor_set_bonus MUST be populated exclusively from catalog data; free-text or raw numeric hash entry for these link kinds MUST NOT be available in verification UI.
- **FR-011**: Selecting a link from catalog pickers MUST populate all required link fields (identity, display name, and kind-specific attributes) needed for validation and persistence per existing synergy link rules.
- **FR-012**: When a weapon, weapon_perk, origin_trait, or armor_set_bonus is selected as a link, the verification UI MUST display that element's catalog description read-only before save.
- **FR-013**: Auto-generated names MUST update live in the create/edit form when category, sub-type, or link selection changes, prior to submit.
- **FR-014**: Validation MUST reject synergy create/update when any required sub-type is missing, when an removed category is selected, or when any link cannot be resolved against current catalog data, with a clear error message.
- **FR-015**: Existing synergies created before this refinement MUST remain listable and deletable; editing and re-saving MUST conform to the refined rules.

### Key Entities

- **Synergy**: A documented interaction with category, optional sub-type (for Verb/Melee/Grenade/Super/Element), auto-generated name, optional curator notes, and one or more links to game elements.
- **Synergy sub-type**: A specific verb, melee ability, grenade type, super ability, or damage element that narrows a synergy beyond its broad category.
- **Synergy link**: Association to a catalog-backed weapon, weapon perk, origin trait, or armor set bonus—always resolved from curated lists in verification UI.
- **Catalog entry**: A manifest-backed record (weapon, perk, origin trait, armor set, or set bonus) supplying display name and description for pickers and preview.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Curators can create a fully specified Verb synergy (verb + link) without typing a name or link identifier manually—100% of required fields chosen via pickers in user testing.
- **SC-002**: Zero new synergies with unresolved or free-text link targets are accepted in verification flows (validation catches 100% of picker bypass attempts in test scenarios).
- **SC-003**: For all four link kinds with descriptions in catalog data, description preview appears within one selection action of choosing the link (no extra clicks).
- **SC-004**: Auto-generated names match the defined pattern for at least 95% of tested combinations across Verb, Melee, Grenade, Super, Element, and non-sub-type categories in acceptance testing.
- **SC-005**: Time to create a synergy with one link decreases versus the prior free-form debug form (target: under 60 seconds for a familiar curator in manual QA).
- **SC-006**: Kinetic Weapon and Damage do not appear as creatable options; 100% of new synergies use the refined category set including DPS and Element.

## Assumptions

- Verb vocabulary is aggregated from existing subclass verb metadata already curated in the project (deduplicated by verb name).
- Melee, grenade, and super sub-type lists are derived from curated subclass/ability metadata covering **all** abilities of each kind in the game.
- Element sub-types are the six damage elements: Solar, Arc, Void, Stasis, Strand, Prismatic.
- This iteration updates the **internal verification UI** (`/debug/synergies`); production synergy editor remains deferred per 001 iteration scope.
- Auto-generated names are system-owned on create; manual name override is out of scope unless a future iteration adds it.
- Primary link for naming is the first (or only) link selected at save time when multiple links are supported later; single-link create flow is the MVP for this refinement.
- Armor set bonus picker continues the two-step pattern: select set → select piece threshold → select bonus from that set's defined perks.
