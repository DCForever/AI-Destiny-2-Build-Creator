# Feature Specification: Synergy Refinement

**Feature Branch**: `006-synergy-refinement`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Synergies need more refinement. 1. Should be auto-named from the selections. Verb: Scorch - Skyburners Oath. 2. Verb is not its own synergy, but should instead be to list a specific verb like Scorch or Sever. Melee and Grenade should also support specific grenades. 3. The Debug UI does not let me pick from the available weapons, weapon_perk, origin_traits, or armor_set_bonuses. These options should all be read and none should be free-form. 4. The description should show for any weapons, weapon_perk, origin_traits, or armor_set_bonuses."

## Clarifications

### Session 2026-06-29

- Q: Should Melee and Grenade sub-type pickers be limited or comprehensive? → A: Any melee or any grenade from the full curated catalog (user picks one specific ability/type).
- Q: Does Super require a sub-type picker like Melee/Grenade? → A: Yes — Super follows the same pattern (required specific super selection).
- Q: Should Element be a synergy category? → A: Yes — Element is its own synergy category requiring a specific element sub-type (e.g., Kinetic, Solar, Arc, Void).
- Q: Should Kinetic Weapon remain a synergy option? → A: No — Kinetic Weapon is removed from creatable synergy categories.
- Q: What should the Damage synergy category be called? → A: Renamed to **DPS** (replaces "Damage").
- Q: Can one game element be linked to multiple synergies? → A: Yes — synergies are multi-select per target; e.g. a weapon may have both a DPS synergy and a Verb: Void Breach synergy (many-to-many, no exclusivity).
- Q: Can Melee, Grenade, or Super use a category-wide sub-type instead of a specific ability? → A: Yes — each offers a **Base** sub-type meaning all melees, all grenades, or all supers respectively.
- Q: Is Kinetic available as an element sub-type? → A: Yes — **Kinetic** is a selectable element under the Element synergy category (distinct from the removed Kinetic Weapon synergy category).

## Iteration Scope

**In scope**: Refining how synergies are defined and verified in internal debug tools—auto-generated names, specific or Base sub-type selection for Verb/Melee/Grenade/Super/Element synergies, updated synergy category list (add Element, rename Damage→DPS, remove Kinetic Weapon), many-to-many multi-synergy associations per link target, catalog-backed link pickers (no free-text entry), and read-only description display for linked game elements.

**Out of scope**: Polished production synergy editor UI, changes to suggestion-ranking algorithms, and bulk migration of legacy synergies (existing records—including legacy `kinetic_weapon` and `damage` types—remain readable; new/edited synergies follow the refined rules).

**Builds on**: [001-build-sets-synergies](../001-build-sets-synergies/spec.md) User Story 4 (Define and Manage Synergies) and existing synergy link kinds (weapon, weapon_perk, origin_trait, armor_set_bonus).

## Synergy Categories

| Category | Sub-type required? | Sub-type source | Auto-name pattern |
|----------|-------------------|-----------------|-------------------|
| Verb | Yes | Curated verb vocabulary (deduplicated); no Base option | `Verb: {verb} — {link}` |
| Melee | Yes | **Base** (all melees) or any specific melee from full curated catalog | `Melee: Base — {link}` or `Melee: {melee} — {link}` |
| Grenade | Yes | **Base** (all grenades) or any specific grenade from full curated catalog | `Grenade: Base — {link}` or `Grenade: {grenade} — {link}` |
| Super | Yes | **Base** (all supers) or any specific super from full curated catalog | `Super: Base — {link}` or `Super: {super} — {link}` |
| Element | Yes | Specific damage element (Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic); no Base option | `Element: {element} — {link}` |
| Primary Weapon | No | — | `Primary Weapon — {link}` |
| Special Weapon | No | — | `Special Weapon — {link}` |
| Heavy Weapon | No | — | `Heavy Weapon — {link}` |
| DPS | No | — | `DPS — {link}` |
| Healing | No | — | `Healing — {link}` |

**Removed categories** (not creatable; legacy records remain readable): Kinetic Weapon (synergy category—use Element: Kinetic instead), Damage (superseded by DPS).

**Association model**: Many-to-many — one synergy may link to multiple targets; one target (weapon, perk, origin trait, armor set bonus) may be linked to **multiple synergies** simultaneously (e.g. DPS + Verb: Void Breach on the same weapon).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Auto-Generated Synergy Names (Priority: P1)

A curator creating a synergy should not need to type a display name manually. As they choose the synergy category, any required sub-type (e.g., a specific verb, element, or Base), and a linked game element, the system composes a human-readable name that reflects those choices—such as **Verb: Scorch — Skyburner's Oath**, **Melee: Base — Monte Carlo**, or **Element: Solar — Skyburner's Oath**.

**Why this priority**: Consistent naming reduces errors, makes synergy lists scannable, and removes duplicate or ambiguous labels that block reliable filtering and build attachment.

**Independent Test**: On the synergies debug page, select Verb + Scorch + link Skyburner's Oath; confirm the name field shows the composed label before create, and the saved synergy uses that name.

**Acceptance Scenarios**:

1. **Given** a user is creating a synergy, **When** they select category Verb, sub-type Scorch, and link weapon Skyburner's Oath, **Then** the synergy name is automatically set to a label equivalent to `Verb: Scorch — Skyburner's Oath` (category, sub-type, and link display name separated clearly).
2. **Given** the user changes any of category, sub-type, or linked element before saving, **Then** the auto-generated name updates immediately to reflect the new combination.
3. **Given** a synergy is saved with an auto-generated name, **When** it appears in synergy lists and build attachment pickers, **Then** the same composed name is shown everywhere.
4. **Given** the user selects category Element and sub-type Solar, **When** they link a weapon, **Then** the auto-generated name follows the pattern `Element: Solar — {link name}`.
5. **Given** the user selects category Melee and sub-type Base, **When** they link a weapon, **Then** the auto-generated name follows the pattern `Melee: Base — {link name}`.

---

### User Story 2 - Specific or Base Sub-Types for Verb, Melee, Grenade, Super, and Element (Priority: P1)

Verb and Element synergies must identify a **specific** verb or element. Melee, Grenade, and Super synergies must identify either **Base** (applies to all melees, all grenades, or all supers) or a **specific** ability from the full curated catalog. Other categories (Primary Weapon, Special Weapon, Heavy Weapon, DPS, Healing) use category alone without a sub-type picker.

**Why this priority**: Curators need both broad category synergies (e.g., any grenade build) and precise ones (e.g., a specific super); Verb and Element remain specific-only because a generic verb/element synergy is not meaningful without naming the verb or element.

**Independent Test**: Create Melee + Base + one link; synergy saves as category-wide melee. Create Super + Hammer of Sol + one link; synergy saves with specific super sub-type. Attempt Verb without sub-type; save blocked.

**Acceptance Scenarios**:

1. **Given** the user selects synergy category Verb, **When** the form is shown, **Then** a required sub-type picker lists available verbs (e.g., Scorch, Sever, Void Breach) from the curated verb vocabulary with no Base option and does not allow saving without a selection.
2. **Given** the user selects category Grenade, **When** the form is shown, **Then** a required sub-type picker lists **Base** (all grenades) plus any specific grenade type from the full curated catalog.
3. **Given** the user selects category Melee, **When** the form is shown, **Then** a required sub-type picker lists **Base** (all melees) plus any specific melee ability from the full curated catalog.
4. **Given** the user selects category Super, **When** the form is shown, **Then** a required sub-type picker lists **Base** (all supers) plus any specific super ability from the full curated catalog.
5. **Given** the user selects category Element, **When** the form is shown, **Then** a required sub-type picker lists specific damage elements (Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic) with no Base option.
6. **Given** the user selects category Element and sub-type Kinetic, **When** they link a weapon, **Then** the auto-generated name follows the pattern `Element: Kinetic — {link name}`.
7. **Given** the user selects a category that does not require a sub-type (e.g., DPS), **When** they complete the form, **Then** no sub-type picker is shown and naming uses category + link only (e.g., `DPS — Witherhoard`).
8. **Given** the user attempts to create a synergy with category Kinetic Weapon or Damage, **When** they open the category picker, **Then** those options are not available (Kinetic Weapon removed—use Element: Kinetic; Damage replaced by DPS).
9. **Given** an existing synergy created under legacy categories (`kinetic_weapon`, `damage`, or generic Verb), **When** the user views it, **Then** it remains visible and editable; saving after edit must conform to refined rules (migrate `kinetic_weapon` to Element: Kinetic where applicable; migrate `damage` to DPS).

---

### User Story 3 - Multi-Synergy Associations per Target (Priority: P1)

A single game element (weapon, weapon perk, origin trait, or armor set bonus) may be linked to **multiple synergies** at the same time. There is no exclusivity—a weapon can simultaneously carry both a DPS synergy and a Verb: Void Breach synergy.

**Why this priority**: Real loadouts combine several interaction types on one piece of gear; restricting one synergy per target would misrepresent how players actually build.

**Independent Test**: Link DPS synergy and Verb: Void Breach synergy to the same weapon; reverse lookup on that weapon returns both synergies.

**Acceptance Scenarios**:

1. **Given** a weapon already linked to a DPS synergy, **When** the user creates or links a Verb: Void Breach synergy to the same weapon, **Then** both synergies are stored and neither replaces the other.
2. **Given** a link target with multiple synergies, **When** the user runs reverse lookup on that target, **Then** **all** linked synergies are returned and displayed.
3. **Given** a user is designating synergies on a build or browsing catalog, **When** a target has multiple linked synergies, **Then** all linked synergy badges or labels are shown (multi-select display, not a single pick).
4. **Given** the same synergy type linked twice to the same target with different sub-types (e.g., two different Verb synergies), **When** both are saved, **Then** both associations are preserved.

---

### User Story 4 - Catalog-Backed Link Pickers (Priority: P2)

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

### User Story 5 - Description Preview for Linked Elements (Priority: P2)

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
- Legacy synergies with type `kinetic_weapon` or `damage` remain listable and deletable; re-save prompts migration to Element: Kinetic (former Kinetic Weapon) or DPS (former Damage).
- Base sub-type synergies (Melee: Base, Grenade: Base, Super: Base) apply broadly in suggestion and reverse-lookup context—matching any ability of that kind on the linked target or in build context.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST auto-generate synergy display names from the selected category, required sub-type (when applicable), and primary linked element display name, using a consistent pattern: `{Category}: {Sub-type} — {Link name}` for Verb, Melee, Grenade, Super, and Element (including `Base` as sub-type label); `{Category} — {Link name}` for categories without sub-types.
- **FR-002**: System MUST require a specific verb selection when synergy category is Verb; generic Verb-only synergies without a named verb MUST NOT be creatable; Verb sub-type MUST NOT offer a Base option.
- **FR-003**: System MUST require a sub-type when synergy category is Grenade; the sub-type picker MUST offer **Base** (all grenades) plus any specific grenade from the full curated catalog.
- **FR-004**: System MUST require a sub-type when synergy category is Melee; the sub-type picker MUST offer **Base** (all melees) plus any specific melee from the full curated catalog.
- **FR-005**: System MUST require a sub-type when synergy category is Super; the sub-type picker MUST offer **Base** (all supers) plus any specific super from the full curated catalog.
- **FR-006**: System MUST support synergy category **Element** with a required specific element sub-type (Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic); Element sub-type MUST NOT offer a Base option.
- **FR-007**: Sub-type options for Verb, Melee, Grenade, Super, and Element MUST be drawn from curated, system-maintained vocabularies (not user-typed strings).
- **FR-008**: System MUST NOT offer **Kinetic Weapon** as a creatable synergy category; kinetic loadout synergies MUST use **Element: Kinetic** instead; existing `kinetic_weapon` records remain readable and deletable; re-save MUST migrate to Element with Kinetic sub-type.
- **FR-009**: System MUST rename the **Damage** synergy category to **DPS** for all new synergies; existing `damage` records remain readable; re-save MUST migrate type to `dps`.
- **FR-010**: Synergy associations MUST be **many-to-many**: one link target MAY be linked to multiple synergies simultaneously; linking a new synergy to a target MUST NOT remove existing synergies on that target.
- **FR-011**: Reverse lookup and catalog/browse views MUST return and display **all** synergies linked to a target (multi-select display), not a single exclusive synergy.
- **FR-012**: Synergy link pickers for weapon, weapon_perk, origin_trait, and armor_set_bonus MUST be populated exclusively from catalog data; free-text or raw numeric hash entry for these link kinds MUST NOT be available in verification UI.
- **FR-013**: Selecting a link from catalog pickers MUST populate all required link fields (identity, display name, and kind-specific attributes) needed for validation and persistence per existing synergy link rules.
- **FR-014**: When a weapon, weapon_perk, origin_trait, or armor_set_bonus is selected as a link, the verification UI MUST display that element's catalog description read-only before save.
- **FR-015**: Auto-generated names MUST update live in the create/edit form when category, sub-type, or link selection changes, prior to submit.
- **FR-016**: Validation MUST reject synergy create/update when any required sub-type is missing, when a removed category is selected, or when any link cannot be resolved against current catalog data, with a clear error message.
- **FR-017**: Existing synergies created before this refinement MUST remain listable and deletable; editing and re-saving MUST conform to the refined rules.

### Key Entities

- **Synergy**: A documented interaction with category, sub-type (for Verb/Melee/Grenade/Super/Element—including `Base` where allowed), auto-generated name, optional curator notes, and one or more links to game elements.
- **Synergy sub-type**: A specific verb, melee ability, grenade type, super ability, damage element, or **Base** (category-wide for Melee/Grenade/Super only) that narrows or scopes the synergy.
- **Synergy link**: Association to a catalog-backed weapon, weapon perk, origin trait, or armor set bonus—always resolved from curated lists in verification UI.
- **Synergy association**: Many-to-many relationship between synergies and link targets; one target may carry multiple synergies (e.g., DPS + Verb: Void Breach on one weapon).
- **Catalog entry**: A manifest-backed record (weapon, perk, origin trait, armor set, or set bonus) supplying display name and description for pickers and preview.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Curators can create a fully specified Verb synergy (verb + link) without typing a name or link identifier manually—100% of required fields chosen via pickers in user testing.
- **SC-002**: Zero new synergies with unresolved or free-text link targets are accepted in verification flows (validation catches 100% of picker bypass attempts in test scenarios).
- **SC-003**: For all four link kinds with descriptions in catalog data, description preview appears within one selection action of choosing the link (no extra clicks).
- **SC-004**: Auto-generated names match the defined pattern for at least 95% of tested combinations across Verb, Melee (Base + specific), Grenade, Super, Element, and non-sub-type categories in acceptance testing.
- **SC-005**: Time to create a synergy with one link decreases versus the prior free-form debug form (target: under 60 seconds for a familiar curator in manual QA).
- **SC-006**: Kinetic Weapon and Damage do not appear as creatable options; 100% of new synergies use the refined category set including DPS and Element.
- **SC-007**: In acceptance testing, linking a second synergy to a target that already has one succeeds 100% of the time and reverse lookup shows all linked synergies.

## Assumptions

- Verb vocabulary is aggregated from existing subclass verb metadata already curated in the project (deduplicated by verb name).
- Melee, grenade, and super sub-type lists are derived from curated subclass/ability metadata covering **all** abilities of each kind in the game, plus a synthetic **Base** entry at the top of each picker.
- Element sub-types are the seven damage elements: Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic.
- Many-to-many association per BR-SYN-008 from 001-build-sets-synergies is explicitly reinforced in this refinement; no exclusivity constraint is added.
- This iteration updates the **internal verification UI** (`/debug/synergies`); production synergy editor remains deferred per 001 iteration scope.
- Auto-generated names are system-owned on create; manual name override is out of scope unless a future iteration adds it.
- Primary link for naming is the first (or only) link selected at save time when multiple links are supported later; single-link create flow is the MVP for this refinement.
- Armor set bonus picker continues the two-step pattern: select set → select piece threshold → select bonus from that set's defined perks.
