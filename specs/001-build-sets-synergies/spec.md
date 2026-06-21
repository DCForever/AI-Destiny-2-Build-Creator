# Feature Specification: Build Sets and Synergies

**Feature Branch**: `001-build-sets-synergies`

**Created**: 2026-06-17

**Status**: Draft

**Input**: User description: "# Overhaul Plan" with detailed goals for CRUD on builds, weapons, armor, categorized sets of items (weapon sets, armor sets, mod sets, exotic pairs, fashion sets), and many types of synergies (melee, verbs, grenades, weapons, supers, damage, healing, intelligently generated). Capabilities include intelligently combining sets into builds, suggesting weapon rolls for synergies, and supporting multiple variant builds per exotic using different sets.

## Clarifications

### Session 2026-06-17

- Q: What should happen when a user attempts to delete a Set that is currently attached to one or more Builds? → A: Block deletion and show/list the affected builds; require the user to detach the set from those builds first.
- Q: When a Set is attached to a Build, and that Set is later edited by the user (e.g., items are added or removed from the Set), what should happen to the Build(s) that already use the Set? → A: A (live references by default), but on the Build the user can choose to use a snapshot instead.
- Q: Must Set names be unique for a user? → A: B (unique within the same category or Set type)
- Q: When and how does the system surface suggested Sets or synergies? → A: C (Combination: automatic contextual recommendations appear during editing, plus an explicit "Suggest sets/synergies" action or goal input)
- Q: How are Fashion Sets treated compared to functional sets (weapon, armor, mod sets)? → A: A (Purely for organization and cosmetics; ignored for build stats, synergies, suggestions, and composition)

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Demonstrated to users independently
  (Per constitution: user stories are the primary vehicle for small testable increments.)
-->

### User Story 1 - Create and Manage Categorized Item Sets (Priority: P1)

A user can create, name, categorize, edit, view, and delete reusable collections ("Sets") of weapons, armor pieces, mods, exotic pairs, or fashion items. Fashion Sets are purely cosmetic/organizational and do not affect functional build logic, synergies, or suggestions. Categories include examples like "Melee:Ferropotent", "Solar Weapons PVE", "Grenade".

**Why this priority**: Sets are the foundational building block described in the overhaul. All intelligent combination, variant builds, and synergies depend on users first being able to curate their own sets. This slice delivers immediate standalone value for organization.

**Independent Test**: A signed-in user creates a new "Solar Weapons PVE" weapon set, adds a weapon with specific perks/barrels/masterwork (full roll data), saves the set, later removes ("deletes") that weapon entry from the set — the UI can still display the previous roll details, and alternatives matching the perks are offered. Edits name/category, and (after ensuring it is not attached to builds) deletes the set. This can be fully verified through the sets UI and list without any build, synergy, or generation features.

**Acceptance Scenarios**:

1. **Given** the user is viewing their item collections, **When** they create a new Weapon Set, assign category "Solar Weapons PVE", and add 4 specific weapons with chosen perks/barrels/masterwork (full roll data stored), **Then** the set appears in their Sets list with the chosen name, category, correct base items + roll details.
2. **Given** an existing set, **When** the user edits its category or adds/removes items, **Then** the changes are immediately reflected when viewing the set and in any set listings.
3. **Given** a set the user owns that is not attached to any builds, **When** they remove ("delete") a weapon entry from the set, **Then** the UI can still show the previous full roll details (perks, barrels, etc.) for that entry, alternatives matching the roll are offered, and the rest of the set remains. (The whole set can be deleted when not attached.)
4. **Given** a set the user owns that is attached to one or more builds, **When** they attempt to delete it, **Then** the deletion is blocked, the user is shown the list of affected builds, and the set is not deleted until detached from all referencing builds.
5. **Given** the user has an existing "PVE" Weapon Set, **When** they attempt to create or rename another Weapon Set to "PVE", **Then** the operation is rejected with a clear error that the name is already in use within the Weapon Set category/type.

---

### User Story 2 - View and Filter All Weapons and Armor (Priority: P2)

Users can browse the complete catalog of weapons and armor items and quickly filter them, distinguishing between "all available" items (from manifest) and "my" owned items (from inventory).

**Why this priority**: The goals explicitly call out fast filtering for both global and personal weapons/armor. This provides discovery and inventory awareness independently of sets or builds.

**Independent Test**: User opens the weapons browser, applies filters for weapon type + archetype + "my owned only", sees correct results. Separately filters the full catalog without login/inventory. Can be tested without sets, builds, or synergies present.

**Acceptance Scenarios**:

1. **Given** the user is not signed in, **When** they browse weapons and apply type and perk filters, **Then** they see matching items from the full manifest with clear indication they are not owned.
2. **Given** the user has synced inventory, **When** they switch to "My Weapons" view and filter by category or keyword, **Then** only owned items matching the filter are shown, with accurate ownership status.
3. **Given** any weapon or armor list, **When** the user searches or filters by name, type, or other attributes, **Then** results update instantly and include relevant metadata (archetype, champion coverage, etc.).

---

### User Story 3 - Attach Sets to Builds (Priority: P3)

A user can associate one or more of their Sets (weapon, armor, mod, etc.) with a Build. When attaching, the user can choose a live reference (future edits to the Set will affect the Build) or a snapshot (the Build captures the Set's state at attachment time). The system provides suggestions for relevant Sets both automatically (contextual during build editing based on exotic/subclass/playstyle) and when the user explicitly requests them.

**Why this priority**: Directly enables the core capability "Combine sets intelligently to create builds" and the Felwinters Helm + Monte Carlo example. This slice can be validated once sets and basic builds exist.

**Independent Test**: User creates a Melee-focused build, attaches a "Melee:Ferropotent" Armor Set choosing snapshot and a "Grenade" Weapon Set choosing live link. Later edits the live Set and confirms the build reflects the change, while the snapshot one stays fixed. Testable without full synergy rules or intelligent generation.

**Acceptance Scenarios**:

1. **Given** the user has created several categorized sets, **When** they create or edit a build and select relevant sets (e.g. a Solar Weapons set for a solar build), **Then** the sets are saved with the build and visible on the build sheet.
2. **Given** the user attaches a Set to a build, **When** they choose "live reference", **Then** later edits to that Set (add/remove items) are reflected when viewing the build.
3. **Given** the user attaches a Set to a build, **When** they choose "snapshot", **Then** later edits to that Set do not affect the build; the build retains the state at the time of attachment.
4. **Given** a build with an exotic and playstyle, **When** the user requests set suggestions (explicitly or via goal description), **Then** the system proposes sets matching the exotic, subclass verbs, or category tags.
5. **Given** the user is creating or editing a build, **When** they select an exotic or subclass, **Then** the system automatically surfaces contextual set suggestions without explicit request.
6. **Given** a build that uses sets, **When** the user views or exports the build, **Then** the attached sets are included in the summary and export data (with indication if live or snapshot).

---

### User Story 4 - Define and Manage Synergies (Priority: P4)

Users can create, edit, view, and delete Synergies of various types (Melee synergies, Destiny 2 Verb synergies, Grenade, Primary/Special/Heavy Weapon, Kinetic, Super, Damage, Healing).

**Why this priority**: Synergies are a major goal area (8+ types listed). Defining them manually provides immediate value for documentation and later use in suggestions, independently of automatic generation.

**Independent Test**: User creates a "Meleefire" synergy linking specific melee abilities and weapons, assigns it a type, saves it. Later browses the synergies library and finds it, edits description, and deletes it. No build association required for this test.

**Acceptance Scenarios**:

1. **Given** the user wants to document a combo, **When** they create a new Melee synergy and specify participating abilities/weapons, **Then** the synergy is saved and appears in the synergies catalog with its type and details.
2. **Given** existing synergies, **When** the user filters the catalog by synergy type (e.g., "Grenade"), **Then** only matching synergies are shown.
3. **Given** a synergy attached to items the user owns, **When** they view their items or sets, **Then** relevant synergies are surfaced as tags or notes.

---

### User Story 5 - Suggest Weapon Rolls for Sets and Synergies (Priority: P5)

While browsing or building, users receive suggestions for specific weapon rolls (perks) that would be strong for a chosen set or synergy.

**Why this priority**: Explicitly listed capability. Provides actionable "hunt for" value on top of sets and synergies.

**Independent Test**: User selects a synergy or a "Solar Weapons PVE" set; the UI shows 2-3 recommended god-roll weapons/perks that fit the synergy/set theme. Can be validated by viewing suggestions without a full build.

**Acceptance Scenarios**:

1. **Given** a selected synergy or categorized set, **When** the user requests roll suggestions (explicitly), **Then** the system returns specific weapons + perk combinations relevant to the synergy or set category.
2. **Given** the user is viewing sets or synergies in context of a build, **When** the build context matches, **Then** the system automatically surfaces relevant roll suggestions.
3. **Given** the user owns some but not all suggested rolls, **When** they view suggestions, **Then** owned vs unowned items are clearly distinguished.

---

### User Story 6 - Create Variant Builds Using Different Sets (Priority: P6)

A user can easily create and manage multiple builds that use the same exotic weapon or armor but different attached Sets (e.g., one healing/survivability focused and one DPS focused for Vex Mythoclast).

**Why this priority**: Directly supports the stated need for "a multiple build for each exotic where only some of the sets differ".

**Independent Test**: Starting from one Vex Mythoclast build, the user duplicates it (using snapshots of the sets) and swaps the attached armor/weapon sets to create a second variant. Both builds are saved and listed separately. Verifiable in the builds list and detail views.

**Acceptance Scenarios**:

1. **Given** an existing build using an exotic, **When** the user creates a "variant" and changes only the attached Sets, **Then** both the original and variant are saved as distinct builds with different set associations.
2. **Given** multiple variants for the same exotic, **When** the user searches or filters builds by exotic, **Then** all variants are discoverable together with indicators of their set differences.
3. **Given** two variants, **When** the user compares them, **Then** differences in attached sets and resulting playstyle notes are highlighted.

---

### Edge Cases

- When a user attempts to delete a Set that is attached to one or more Builds, the deletion is blocked. The system must show the list of affected Builds, and the user must detach the Set from those Builds before the Set can be deleted.
- Set names must be unique within the same category or Set type for a user. Creating a duplicate name in the same category/type results in an error.
- What happens when a user has hundreds of sets or very large sets (50+ items)?
- How are conflicts resolved when multiple synergies apply to the same items in a build?
- What occurs if the manifest updates and items in a user's set are deprecated or changed?
- Can sets be shared or are they strictly private per user?
- Fashion Sets are treated purely as cosmetic and organizational (ignored for build composition, synergies, suggestions, and stats, unlike weapon/armor/mod sets).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create, name, categorize, edit, view, and delete Sets of weapons.
- **FR-002**: System MUST allow users to create, name, categorize, edit, view, and delete Sets of armor.
- **FR-003**: System MUST support additional Set types including Mods, Exotic Weapon + Exotic Armor pairs, and Fashion Sets.
- **FR-018**: Fashion Sets MUST be treated as purely cosmetic and organizational. They MUST NOT participate in build composition, synergies, suggestions, or stats calculations (unlike functional weapon, armor, or mod sets).
- **FR-004**: Users MUST be able to assign categories to sets (free-form or suggested tags such as "Melee", "Grenade", "PVE", "Solar").
- **FR-005**: Set names MUST be unique within the same category or Set type for a given user. The system MUST reject creation or rename that would create a duplicate name in the same category/type.
- **FR-006**: System MUST provide fast filtering and search for the complete weapon catalog ("all weapons").
- **FR-007**: System MUST provide fast filtering and search for the user's owned weapons ("my weapons"), integrated with inventory sync.
- **FR-008**: System MUST provide equivalent fast filtering for all armor and my armor.
- **FR-009**: System MUST allow users to attach one or more Sets to a Build, with a choice per attachment of live reference (edits to the Set affect the Build) or snapshot (Build uses the Set state at the time of attachment).
- **FR-010**: System MUST provide suggestions for relevant Sets both automatically (contextual based on exotic, subclass, or playstyle during build creation/editing) and on explicit user request (via "Suggest" action or goal description).
- **FR-011**: System MUST support creation, editing, viewing, and deletion of Synergies for the listed types (Melee, Verb, Grenade, Primary Weapon, Special Weapon, Heavy Weapon, Kinetic Weapon, Super, Damage, Healing).
- **FR-012**: System MUST allow users to associate synergies with items, sets, or builds for discovery and documentation.
- **FR-013**: System MUST provide suggested weapon rolls (specific perks) that complement a chosen set or synergy.
- **FR-019**: For weapon SetItems, the system MUST store the full selected roll data (perks including barrels, magazine, traits, masterwork, etc.). When a SetItem is removed from a set, the previous roll configuration MUST still be displayable, and the system SHOULD offer alternatives (other weapons with matching or similar perks/rolls).
- **FR-014**: Users MUST be able to create multiple distinct builds using the same exotic but different attached Sets (typically using snapshots for stable variants).
- **FR-015**: System MUST make it easy to discover and switch between variant builds for the same exotic.
- **FR-016**: System MUST support intelligent suggestion of sets or synergies, triggered both automatically (contextual during build editing) and explicitly (when user requests suggestions or describes a goal, e.g., "Melee focused build using Felwinters Helm + Monte Carlo").
- **FR-017**: System MUST block deletion of a Set if it is currently attached to any Build(s). The user MUST be shown the list of affected Builds and detach the Set from all of them before deletion is allowed.

### Key Entities *(include if feature involves data)*

- **Build**: A saved configuration of subclass, exotic, weapons, armor, mods, and attached Sets and Synergies. Supports variants. An attached Set can be a live reference (edits to the Set propagate to the Build) or a snapshot (Build captures the Set state at the time of attachment, chosen per Build).
- **Set**: A named, categorized collection of items. Types include Weapon Set, Armor Set, Mod Set, Pair, Fashion Set. Belongs to a user. Set names MUST be unique within the same category or Set type for a given user. Fashion Sets are purely cosmetic/organizational and do not participate in build composition, synergies, or suggestions.

  For weapons in a set (SetItem): full roll data is stored (selected perks, barrels, masterwork, etc.) so that the exact configuration can be shown even if the SetItem is later removed ("deleted") from the set, and alternatives (similar weapons matching the perks/roll) can be offered.
- **Synergy**: A documented interaction between abilities, verbs, weapons, or effects. Has a type and participating elements.
- **Item**: Reference to a weapon or armor piece from the manifest (used inside Sets, Builds, and Synergies).
- **Category / Tag**: User-applied or system labels used for organization and suggestions (e.g., Melee, Solar, PVE, Grenade).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a new categorized set containing at least 3 items in under 60 seconds.
- **SC-002**: Users can locate a previously created set or synergy using search or category filters in under 5 seconds.
- **SC-003**: A user can attach relevant sets to a build and see the effect on the build presentation within the same session.
- **SC-004**: When viewing an exotic, the system surfaces at least two distinct variant builds using different sets (for users who have created them).
- **SC-005**: 80% of users attempting to create a set-based build for a stated goal (e.g. "Melee focused") can complete the flow without external help on their first try.
- **SC-006**: Roll suggestions for a set or synergy return at least 2 relevant, manifest-valid weapon/perk combinations.
- **SC-007**: The system supports users maintaining at least 30 sets and 20 synergies without noticeable slowdown in listing or filtering.

## Assumptions

- Users who want "my" weapons and armor will sign in and perform inventory sync (existing capability).
- The full Bungie manifest (weapons, armor, perks) is available for browsing "all" items.
- Set membership stores references to items rather than full copies, so manifest updates can be reflected.
- Categories are lightweight (tags or labels) rather than a rigid taxonomy.
- "Intelligently" generated or suggested content will use a combination of user-defined data, deterministic rules, and the existing LLM research pipeline.
- Basic build CRUD (create, edit, view, delete) and loadout saving either already exist or will be available as a foundation for attaching sets (this feature focuses on the sets/synergies layer).
- Fashion Sets are primarily for visual organization and may have lighter validation than functional combat sets.
- Synergies start as user-curated documentation and later gain suggestion capabilities.
- No sharing of private sets or synergies between users is required in the initial scope.
