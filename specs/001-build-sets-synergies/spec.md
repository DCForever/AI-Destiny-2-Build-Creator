# Feature Specification: Build Sets and Synergies

**Feature Branch**: `001-build-sets-synergies`

**Created**: 2026-06-17

**Status**: Draft

**Input**: User description: "# Overhaul Plan" with detailed goals for CRUD on builds, weapons, armor, categorized sets of items (weapon sets, armor sets, mod sets, exotic pairs, fashion sets), and many types of synergies (melee, verbs, grenades, weapons, supers, damage, healing, intelligently generated). Capabilities include intelligently combining sets into builds, suggesting weapon rolls for synergies, and supporting multiple variant builds per exotic using different sets.

## Clarifications

### Session 2026-06-17

- Q: What should happen when a user attempts to delete a Set that is currently attached to one or more Builds? → A: Block deletion and show/list the affected builds; require the user to detach the set from those builds first.
- Q: When a Set is attached to a Build, and that Set is later edited by the user (e.g., items are added or removed from the Set), what should happen to the Build(s) that already use the Set? → A: A (live references by default), but on the Build the user can choose to use a snapshot instead.
- Q: Must Set names be unique for a user? → A: B (unique within the same category or Set type) — **superseded 2026-06-28**: unique per set type only; tags are separate multi-select metadata.
- Q: When and how does the system surface suggested Sets or synergies? → A: C (Combination: automatic contextual recommendations appear during editing, plus an explicit "Suggest sets/synergies" action or goal input)
- Q: How are Fashion Sets treated compared to functional sets (weapon, armor, mod sets)? → A: A (Purely for organization and cosmetics; ignored for build stats, synergies, suggestions, and composition)

### Session 2026-06-22

- Q: What equipment slots can a Set occupy, and are mods required? → A: A set may have 0 or 1 item per equipment slot among helmet, arms, chest, legs, class item, primary, special, and heavy; mods are optional but encouraged.
- Q: What defines a Build versus its variants regarding equipment, subclass, and synergies? → A: A build includes a default variant composed of attached sets with at least one equipment slot filled; all variants share the same subclass, aspects, and designated synergies; exotic armor is defined at build level; exotic weapon may differ per variant; variants differ in attached sets and optionally exotic weapon.
- Q: What is required before a build variant can be saved? → A: At least one equipment slot (helmet, arms, chest, legs, class item, primary, special, or heavy) must be filled via attached sets.
- Q: Should sets use a unified equipment container or separate set types? → A: B — keep separate set types (Weapon, Armor, Mod, Pair, Fashion); each type obeys 0–1 per applicable slot within its own domain.
- Q: When a user adds an item to an already-occupied slot within the same set, what should happen? → A: Replace the existing item in that slot, with a confirmation prompt before overwriting.
- Q: If a build has more than one synergy designated to guide suggestions, how should they be weighted? → A: C — multiple synergies allowed; all designated synergies contribute equally to set and roll suggestions.
- Q: Where are exotic weapon and exotic armor defined relative to build variants? → A: C (hybrid) — exotic armor is build-level and shared by all variants; exotic weapon may differ per variant.
- Q: How should Pair Sets interact with build-level exotic armor? → A: Pair Set exotic armor must match the build's exotic armor; the Pair Set primarily supplies the variant's exotic weapon.

### Session 2026-06-28

- Q: Are set categories free-form text or a controlled vocabulary? → A: **Controlled concept tags** from a system-defined Destiny vocabulary (PVE, PVP, Solar, Melee, Grandmaster, Dungeon, Solo, Support, etc.) — not user-typed strings.
- Q: Can a set have multiple categories/tags? → A: **Yes** — multi-select from the controlled vocabulary; set **name** remains user-defined and separate from tags.
- Q: How do users discover sets to attach to a build? → A: Filter sets (and builds) by **tag combination with AND semantics** (e.g. Solar + Melee) in the Sets list, Builds list, and SetAttachPicker without leaving the attach flow.
- Q: What game elements can a Synergy be associated with? → A: **Weapons**, **weapon perks**, **origin traits**, and **armor set bonuses** (2-piece and 4-piece). Multiple links per synergy. Examples: *Cast No Shadows* origin trait → Melee synergy; *Eutechnology* 2pc (*Gift of the Ley Lines*) and 4pc (*Techeun's Foresight*) → Void synergy.
- Q: Can the same item/target have more than one synergy? → A: **Yes** — association is **many-to-many**. A single origin trait, perk, weapon, or armor set bonus MAY be linked to **multiple synergies** (e.g. *Cast No Shadows* linked to both a Melee synergy and a Verb synergy). Reverse lookup and catalog UI MUST show **all** linked synergies.

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

A user can create, name, tag, edit, view, and delete reusable collections ("Sets") by type: Weapon Sets, Armor Sets, Mod Sets, Exotic Weapon + Exotic Armor Pair Sets, and Fashion Sets. Each set type enforces at most one item per applicable equipment slot within its domain: Weapon Sets (primary, special, heavy), Armor Sets (helmet, arms, chest, legs, class item), Pair Sets (one exotic weapon slot and one exotic armor slot), Mod Sets (optional mod selections, encouraged but not required), Fashion Sets (cosmetic only). Any slot within a set's domain may be left empty. Fashion Sets do not affect functional build logic, synergies, or suggestions. Sets carry one or more **concept tags** from a controlled Destiny vocabulary (e.g. name `Ferropotent` with tags `[Solar, Melee, PVE]`).

**Why this priority**: Sets are the foundational building block described in the overhaul. All intelligent combination, variant builds, and synergies depend on users first being able to curate their own sets. This slice delivers immediate standalone value for organization.

**Independent Test**: A signed-in user creates a new Weapon Set named `Solar PVE` with tags `[Solar, PVE]`, adds a weapon with specific perks/barrels/masterwork (full roll data), saves the set, later removes ("deletes") that weapon entry from the set — the UI can still display the previous roll details, and alternatives matching the perks are offered. Edits name/tags, and (after ensuring it is not attached to builds) deletes the set. This can be fully verified through the sets UI and list without any build, synergy, or generation features.

**Acceptance Scenarios**:

1. **Given** the user is viewing their item collections, **When** they create a new Weapon Set named `Solar PVE`, assign concept tags `[Solar, PVE]`, and add up to one weapon per slot (primary, special, heavy) with chosen perks/barrels/masterwork (full roll data stored), **Then** the set appears in their Sets list with the chosen name, tags, and correct base items + roll details.
2. **Given** an existing set, **When** the user edits its concept tags or adds/removes items, **Then** the changes are immediately reflected when viewing the set and in any set listings.
3. **Given** a Weapon Set with a primary weapon already assigned, **When** the user adds a different primary weapon, **Then** the system prompts for confirmation and replaces the existing item on confirm.
4. **Given** a set the user owns that is not attached to any builds, **When** they remove ("delete") a weapon entry from the set, **Then** the UI can still show the previous full roll details (perks, barrels, etc.) for that entry, alternatives matching the roll are offered, and the rest of the set remains. (The whole set can be deleted when not attached.)
5. **Given** a set the user owns that is attached to one or more builds, **When** they attempt to delete it, **Then** the deletion is blocked, the user is shown the list of affected builds, and the set is not deleted until detached from all referencing builds.
6. **Given** the user has an existing Weapon Set named `PVE`, **When** they attempt to create or rename another Weapon Set to `PVE`, **Then** the operation is rejected with a clear error that the name is already in use within the Weapon Set type.
7. **Given** the user assigns an invalid or unknown tag value, **When** they save the set, **Then** the operation is rejected with a clear validation error.

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

A user can associate one or more Sets with a Build's default variant. The build defines exotic armor shared by all variants; each variant may define its own exotic weapon. The default variant MUST have at least one equipment slot filled via attached sets before the build can be saved. All variants share the same subclass, aspects, and designated synergies (multiple allowed; all contribute equally to suggestions). When attaching a set, the user can choose a live reference or a snapshot. The system provides set suggestions automatically and on explicit request based on exotic context, subclass, and designated synergies.

**Why this priority**: Directly enables the core capability "Combine sets intelligently to create builds" and the Felwinters Helm + Monte Carlo example. This slice can be validated once sets and basic builds exist.

**Independent Test**: User creates a Melee-focused build, attaches an Armor Set named `Ferropotent` (tags `[Melee, Solar]`) choosing snapshot and a Weapon Set named `Grenade Loop` (tags `[Grenade]`) choosing live link. Later edits the live Set and confirms the build reflects the change, while the snapshot one stays fixed. Requires at least one synergy record (create via minimal seed or US4 CRUD) before build save per FR-024.

**Acceptance Scenarios**:

1. **Given** the user has created several categorized sets, **When** they create or edit a build and select relevant sets (e.g. a Solar Weapons set for a solar build), **Then** the sets are saved with the build and visible on the build sheet.
2. **Given** the user attaches a Set to a build, **When** they choose "live reference", **Then** later edits to that Set (add/remove items) are reflected when viewing the build.
3. **Given** the user attaches a Set to a build, **When** they choose "snapshot", **Then** later edits to that Set do not affect the build; the build retains the state at the time of attachment.
4. **Given** a build with an exotic and playstyle, **When** the user requests set suggestions (explicitly or via goal description), **Then** the system proposes sets matching the exotic, subclass verbs, or concept tags.
5. **Given** the user is creating or editing a build, **When** they select an exotic or subclass, **Then** the system automatically surfaces contextual set suggestions without explicit request.
6. **Given** a build that uses sets, **When** the user views or exports the build, **Then** the attached sets are included in the summary and export data (with indication if live or snapshot).
7. **Given** the user has sets tagged `[Solar, Melee]` and `[Solar, PVE]`, **When** they attach sets to a build and filter by `Solar` + `Melee`, **Then** only the Solar+Melee set(s) appear; if none exist, an informative empty state is shown.

---

### User Story 4 - Define and Manage Synergies (Priority: P4)

Users can create, edit, view, and delete Synergies of various types (Melee synergies, Destiny 2 Verb synergies, Grenade, Primary/Special/Heavy Weapon, Kinetic, Super, Damage, Healing). Each synergy can be **linked** to manifest-backed targets: weapons, weapon perks, origin traits, and armor set bonuses (2-piece and 4-piece).

**Why this priority**: Synergies are a major goal area (8+ types listed). Defining them manually provides immediate value for documentation and later use in suggestions, independently of automatic generation.

**Independent Test**: User creates a Melee synergy linked to the *Cast No Shadows* origin trait; creates a Void synergy linked to *Eutechnology* 2-piece (*Gift of the Ley Lines*) and 4-piece (*Techeun's Foresight*) bonuses. Browses the synergies library, filters by type, and sees links on catalog items. No build association required for this test.

**Acceptance Scenarios**:

1. **Given** the user wants to document a combo, **When** they create a new Melee synergy and link the *Cast No Shadows* origin trait, **Then** the synergy is saved with its type, links, and appears in the synergies catalog.
2. **Given** the user documents an armor set interaction, **When** they create a Void synergy and link *Eutechnology* 2-piece (*Gift of the Ley Lines*) and 4-piece (*Techeun's Foresight*) bonuses, **Then** both armor set bonus links are stored on the same synergy.
3. **Given** existing synergies, **When** the user filters the catalog by synergy type (e.g., "Grenade"), **Then** only matching synergies are shown.
4. **Given** a synergy linked to a weapon perk, origin trait, or armor set bonus, **When** the user views that element in the weapon/armor catalog or inventory, **Then** **all** linked synergies are surfaced as tags or notes.
5. **Given** multiple synergies link to the same target (e.g. *Cast No Shadows* linked to both Melee and Verb synergies), **When** the user views that target or creates links, **Then** all associations are preserved and displayed — no exclusivity constraint.
6. **Given** the user adds a link, **When** the target cannot be resolved in the manifest (invalid hash or unknown name), **Then** save is rejected with a clear validation error.

---

### User Story 5 - Suggest Weapon Rolls for Sets and Synergies (Priority: P5)

While browsing or building, users receive suggestions for specific weapon rolls (perks) that would be strong for a chosen set or synergy.

**Why this priority**: Explicitly listed capability. Provides actionable "hunt for" value on top of sets and synergies.

**Independent Test**: User selects a synergy or a set named `Solar PVE` tagged `[Solar, PVE]`; the UI shows 2-3 recommended god-roll weapons/perks that fit the synergy/set theme. Can be validated by viewing suggestions without a full build.

**Acceptance Scenarios**:

1. **Given** a selected synergy or tagged set, **When** the user requests roll suggestions (explicitly), **Then** the system returns specific weapons + perk combinations relevant to the synergy or set concept tags.
2. **Given** the user is viewing sets or synergies in context of a build, **When** the build context matches, **Then** the system automatically surfaces relevant roll suggestions.
3. **Given** the user owns some but not all suggested rolls, **When** they view suggestions, **Then** owned vs unowned items are clearly distinguished.

---

### User Story 6 - Create Variant Builds Using Different Sets (Priority: P6)

A user can easily create and manage multiple variants of the same build that share subclass, aspects, designated synergies, and exotic armor but may use different attached Sets and exotic weapons (e.g., one survivability variant with Osteo Striga and one DPS variant with Vex Mythoclast, both using the same exotic helmet).

**Why this priority**: Directly supports the stated need for "a multiple build for each exotic where only some of the sets differ".

**Independent Test**: Starting from one build with a fixed exotic armor piece, the user duplicates a variant (using snapshots of sets), swaps attached armor/weapon sets and changes the exotic weapon to create a second variant. Both variants remain under the same build. Verifiable in the builds list and variant comparison views.

**Acceptance Scenarios**:

1. **Given** an existing build with exotic armor and a default variant, **When** the user creates a new variant with different attached Sets and a different exotic weapon, **Then** both variants are saved under the same build with shared exotic armor, subclass, aspects, and designated synergies.
2. **Given** a variant with no equipment slots filled via attached sets, **When** the user attempts to save, **Then** the save is rejected with a clear message that at least one equipment slot must be filled.
3. **Given** multiple variants for the same build, **When** the user searches or filters builds by exotic armor, **Then** all variants of that build are discoverable together with indicators of set and exotic-weapon differences.
4. **Given** two variants, **When** the user compares them, **Then** differences in attached sets, exotic weapon, and playstyle notes are highlighted while shared exotic armor, subclass, aspects, and designated synergies are shown as common.

---

### Edge Cases

- When a user attempts to delete a Set that is attached to one or more Builds, the deletion is blocked. The system must show the list of affected Builds, and the user must detach the Set from those Builds before the Set can be deleted.
- Set names must be unique per user per Set type. Creating a duplicate name within the same Set type results in an error.
- Concept tags are selected from a controlled vocabulary; invalid tag values are rejected. Multi-tag filters use AND semantics (e.g. Solar + Melee requires both tags).
- What happens when a user has hundreds of sets or very large sets (50+ items)?
- How are conflicts resolved when multiple synergies apply to the same items in a build? → **Not a conflict**: the same target MAY link to multiple synergies (many-to-many). When a build designates multiple synergies, all contribute equally to suggestions (FR-024). Equipment matching any linked synergy is relevant context.
- What occurs if the manifest updates and items in a user's set are deprecated or changed?
- Can sets be shared or are they strictly private per user?
- Fashion Sets are treated purely as cosmetic and organizational (ignored for build composition, synergies, suggestions, and stats, unlike weapon/armor/mod sets).
- Within a single set, a slot cannot hold more than one item; adding to an occupied slot replaces the existing item after user confirmation.
- Attaching multiple set types to one variant must not assign two items to the same equipment slot (e.g., a Weapon Set primary and a Pair Set exotic weapon cannot both occupy primary without conflict resolution).
- When a Pair Set is attached to a variant, its exotic armor MUST match the build's exotic armor; mismatch is rejected with a clear error. The Pair Set's exotic weapon populates the variant's exotic weapon slot.
- A build variant cannot be saved unless at least one equipment slot is filled via attached sets.
- Variants of the same build always share subclass, aspects, designated synergies, and exotic armor; exotic weapon may differ per variant. Changing shared build-level fields requires editing the parent build.
- A build without at least one designated synergy cannot be saved (or suggestions are blocked until at least one is set).
- When multiple synergies are designated on a build, all contribute equally to set and roll suggestions (no single primary).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create, name, tag, edit, view, and delete Sets of weapons.
- **FR-002**: System MUST allow users to create, name, tag, edit, view, and delete Sets of armor.
- **FR-003**: System MUST support additional Set types including Mods, Exotic Weapon + Exotic Armor pairs, and Fashion Sets.
- **FR-018**: Fashion Sets MUST be treated as purely cosmetic and organizational. They MUST NOT participate in build composition, synergies, suggestions, or stats calculations (unlike functional weapon, armor, or mod sets).
- **FR-004**: Users MUST be able to assign one or more **concept tags** to Sets from a system-defined controlled vocabulary (e.g. Melee, Grenade, PVE, Solar, Grandmaster, Dungeon, Solo, Support).
- **FR-005**: Set names MUST be unique per **(userId, setType)** for a given user. The system MUST reject creation or rename that would create a duplicate name within the same Set type.
- **FR-006**: System MUST provide fast filtering and search for the complete weapon catalog ("all weapons").
- **FR-007**: System MUST provide fast filtering and search for the user's owned weapons ("my weapons"), integrated with inventory sync.
- **FR-008**: System MUST provide equivalent fast filtering for all armor and my armor.
- **FR-009**: System MUST allow users to attach one or more Sets to a Build, with a choice per attachment of live reference (edits to the Set affect the Build) or snapshot (Build uses the Set state at the time of attachment).
- **FR-010**: System MUST provide suggestions for relevant Sets both automatically (contextual based on exotic, subclass, or playstyle during build creation/editing) and on explicit user request (via "Suggest" action or goal description). Automatic suggestions MUST work via deterministic rules in US3 (P3); LLM-enhanced explicit suggestions MAY ship in polish (Phase 9).
- **FR-011**: System MUST support creation, editing, viewing, and deletion of Synergies for the listed types (Melee, Verb, Grenade, Primary Weapon, Special Weapon, Heavy Weapon, Kinetic Weapon, Super, Damage, Healing).
- **FR-012**: System MUST allow users to associate synergies with **weapons**, **weapon perks**, **origin traits**, and **armor set bonuses** (2-piece and 4-piece) for discovery, documentation, and suggestions. Multiple links per synergy MUST be supported. The same target MAY be linked to **multiple synergies** (many-to-many); reverse lookup MUST return all linked synergies for a target.
- **FR-013**: System MUST provide suggested weapon rolls (specific perks) that complement a chosen set or synergy.
- **FR-019**: For weapon SetItems, the system MUST store the full selected roll data (perks including barrels, magazine, traits, masterwork, etc.). When a SetItem is removed from a set, the previous roll configuration MUST still be displayable, and the system SHOULD offer alternatives (other weapons with matching or similar perks/rolls).
- **FR-014**: Users MUST be able to create multiple variants under the same build sharing exotic armor but using different attached Sets and optionally different exotic weapons (typically using snapshots for stable variants).
- **FR-015**: System MUST make it easy to discover and switch between variants for the same build (filterable by shared exotic armor and per-variant exotic weapon).
- **FR-016**: System MUST support intelligent suggestion of **synergies** (and sets per FR-010), triggered both automatically (contextual during build editing) and explicitly (when user requests suggestions or describes a goal, e.g., "Melee focused build using Felwinters Helm + Monte Carlo"). Deterministic synergy matching (type, tags, links) MUST ship in US3/US4; LLM ranking MAY ship in Phase 9.
- **FR-017**: System MUST block deletion of a Set if it is currently attached to any Build variant(s). The user MUST be shown the list of affected builds/variants and detach the Set from all of them before deletion is allowed.
- **FR-020**: Each Set MUST enforce at most one item per applicable equipment slot within its type's domain: Weapon Sets (primary, special, heavy), Armor Sets (helmet, arms, chest, legs, class item), Pair Sets (exotic weapon, exotic armor). Slots within a set's domain may be empty.
- **FR-021**: Mod Sets and optional mods on other set types SHOULD encourage mod selection; mods are not required for a valid set but the UI MUST encourage adding mods where relevant.
- **FR-026**: When multiple attached sets would populate the same equipment slot on a variant, the system MUST detect the conflict and block save until resolved.
- **FR-027**: When a user adds an item to an occupied slot within the same set, the system MUST prompt for confirmation and replace the existing item on confirm.
- **FR-028**: When a Pair Set is attached to a build variant, its exotic armor MUST match the build's exotic armor. On mismatch, attachment MUST be rejected. The Pair Set primarily supplies the variant's exotic weapon.
- **FR-022**: A Build MUST include a default variant composed of attached sets with at least one equipment slot filled before the build can be saved.
- **FR-023**: All variants of a Build MUST share the same subclass, aspects, and exotic armor. Variants MAY differ in attached sets and exotic weapon.
- **FR-024**: Each Build MUST designate at least one synergy to guide suggestions. Multiple synergies MAY be designated; when more than one is present, all MUST contribute equally to set and roll suggestions.
- **FR-025**: A Build variant MUST NOT be saved unless at least one equipment slot is filled via attached sets.
- **FR-029**: System MUST expose the canonical concept tag list for UI pickers and validate all persisted tag assignments against it.
- **FR-030**: Builds MUST support the same concept tag assignment model as Sets.
- **FR-031**: System MUST allow filtering Sets and Builds by one or more concept tags; when multiple tags are selected, results MUST include only entities that have **all** selected tags (AND semantics).
- **FR-032**: When attaching sets to a build variant, the user MUST be able to filter available sets by concept tags without leaving the attach flow.

### Key Entities *(include if feature involves data)*

- **Build**: A saved configuration with shared subclass, aspects, exotic armor, and at least one designated synergy (multiple allowed; all weighted equally for suggestions). Contains one default variant and zero or more additional variants. Variants share build-level exotic armor but may differ in attached Sets and exotic weapon.
- **BuildVariant**: A named slice of a Build that composes equipment by attaching Sets and may specify an exotic weapon. Must have at least one equipment slot filled before save. An attached Set can be a live reference or a snapshot, chosen per variant.
- **Set**: A named collection belonging to a user with zero or more concept tags. Distinct types each with slot rules within their domain:
  - **Weapon Set**: 0–1 each in primary, special, heavy (full roll data per weapon SetItem).
  - **Armor Set**: 0–1 each in helmet, arms, chest, legs, class item.
  - **Mod Set**: optional mod selections (encouraged, not required).
  - **Pair Set**: 0–1 exotic weapon and 0–1 exotic armor. When attached to a build variant, the exotic armor MUST match the build's exotic armor; the pair primarily supplies the variant's exotic weapon.
  - **Fashion Set**: cosmetic/organizational only; excluded from build composition, synergies, and suggestions.
  Set names MUST be unique per (userId, setType) for a given user.

  For weapons in a set (SetItem): full roll data is stored (selected perks, barrels, masterwork, etc.) so that the exact configuration can be shown even if the SetItem is later removed ("deleted") from the set, and alternatives (similar weapons matching the perks/roll) can be offered.
- **Synergy**: A documented interaction between abilities, verbs, weapons, or effects. Has a **type** (Melee, Grenade, Void, etc.) and zero or more **links** to manifest-backed targets:
  - **Weapon** (item hash)
  - **Weapon perk** (perk plug hash)
  - **Origin trait** (e.g. Cast No Shadows → Melee synergy)
  - **Armor set bonus** (armor set name + 2pc or 4pc + bonus name, e.g. Eutechnology *Gift of the Ley Lines* / *Techeun's Foresight* → Void synergy)
  Links form a **many-to-many** graph: one synergy → many targets; one target → many synergies (FR-012).
  Builds may **designate** synergies separately via `build_synergies` to guide suggestions (FR-024).
- **Item**: Reference to a weapon or armor piece from the manifest (used inside Sets, Builds, and Synergies).
- **ConceptTag**: A system-defined label in a facet of the controlled Destiny vocabulary (activity, element, playstyle, role). Users select zero or more tags when creating or editing Sets and Builds. UI notation like `Solar:Melee` is a filter shorthand for two tags (AND), not a single compound tag value.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a new categorized set containing at least 3 items in under 60 seconds.
- **SC-002**: Users can locate a previously created set or synergy using search or concept tag filters in under 5 seconds.
- **SC-003**: A user can attach relevant sets to a build and see the effect on the build presentation within the same session.
- **SC-004**: When viewing a build's shared exotic armor, the system surfaces at least two distinct variants using different sets or exotic weapons (for users who have created them).
- **SC-005**: 80% of users attempting to create a set-based build for a stated goal (e.g. "Melee focused") can complete the flow without external help on their first try.
- **SC-006**: Roll suggestions for a set or synergy return at least 2 relevant, manifest-valid weapon/perk combinations.
- **SC-007**: The system supports users maintaining at least 30 sets and 20 synergies without noticeable slowdown in listing or filtering.

## Assumptions

- Users who want "my" weapons and armor will sign in and perform inventory sync (existing capability).
- The full Bungie manifest (weapons, armor, perks) is available for browsing "all" items.
- Set membership stores references to items rather than full copies, so manifest updates can be reflected.
- Concept tags form a **controlled taxonomy** maintained in the codebase (`src/data/conceptTags.ts`); extensible via data file updates. Users cannot create custom tags in v1.
- "Intelligently" generated or suggested content will use a combination of user-defined data, deterministic rules, and the existing LLM research pipeline.
- Basic build CRUD (create, edit, view, delete) and loadout saving either already exist or will be available as a foundation for attaching sets (this feature focuses on the sets/synergies layer).
- Fashion Sets are primarily for visual organization and may have lighter validation than functional combat sets.
- Synergies start as user-curated documentation and later gain suggestion capabilities.
- No sharing of private sets or synergies between users is required in the initial scope.
- Equipment slots for build variants span helmet, arms, chest, legs, class item, primary, special, heavy across attached set types. Mods are optional and encouraged via Mod Sets or mod selections on other sets.
- Set types remain distinct (Weapon, Armor, Mod, Pair, Fashion); slot cardinality applies per type domain, not as one unified eight-slot container.
- A build's default variant is the initial set composition; additional variants reuse build-level subclass, aspects, designated synergies, and exotic armor; exotic weapon may change per variant.
