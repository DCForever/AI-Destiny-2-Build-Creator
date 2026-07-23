# Feature Specification: Catalog Universal Search

**Feature Branch**: `027-catalog-universal-search`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "I want to add a universal search to the catalog. I want to be able to search for artifact perks, origin traits, weapons, etc... Anything that can be used in a set or build or synergy. From the detail of the item, I want to be able create or add to a set or synergy."

## Iteration Scope

**In scope (this iteration)**: One Catalog-wide search that finds composition-relevant entities (weapons, armor, mods, perks, origin traits, artifact perks, exotic armor/weapons, armor set bonuses, subclass pieces used in builds, and other attachable/linkable targets) by name and description; result browsing with kind labels; item detail from a result; from detail, create a new Set or Synergy or add the item to an existing Set or Synergy using the same attachment/link rules the product already enforces.

**Out of scope (this iteration)**: Replacing every specialized filter UI; fashion-only cosmetics that never attach to combat sets/builds/synergies; bulk multi-select add; offline/unsigned full personal-library actions; redesign of non-Catalog library pages beyond deep-links opened from Catalog detail.

**Builds on**: [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md), [009-description-search](../009-description-search/spec.md), [006-synergy-refinement](../006-synergy-refinement/spec.md), domain composition and synergy rules (`DBR-CMP-*`, `DBR-SYN-*`, `DBR-ROLL-010`).

**Verification**: Signed-in user can type one query in Catalog, see mixed-kind hits, open a hit's detail, and complete at least one create-or-add path for a Set and one for a Synergy without leaving the Catalog flow (except confirmation dialogs).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find any composition piece from one Catalog search (Priority: P1)

A Guardian building loadouts wants a single search box in Catalog that finds weapons, armor, origin traits, artifact perks, mods, and other pieces they might put on a Set, Build, or Synergy—without guessing which specialized browser to open first.

**Why this priority**: This is the core ask; without universal discovery, create/add-from-detail has nothing coherent to attach to.

**Independent Test**: Enter a known name (e.g. an origin trait, an artifact perk, a weapon) and confirm matching results appear with clear type labels and ownership/context when available. Empty and no-manifest cases show clear messages.

**Acceptance Scenarios**:

1. **Given** Catalog is open and manifest data is ready, **When** the user enters a free-text query of at least one meaningful character sequence, **Then** results include hits across composition-relevant kinds (not weapons-only), each labeled with kind and primary display name.
2. **Given** a query that matches multiple kinds (e.g. a word appearing on a perk and a weapon), **When** results are shown, **Then** the user can distinguish kinds without opening every row.
3. **Given** a query with no matches, **When** results are shown, **Then** the user sees an empty state with a clear message—not unrelated filler items.
4. **Given** inventory is synced for a signed-in user, **When** a result is an equippable item the user owns, **Then** ownership is indicated consistently with existing Catalog ownership patterns.
5. **Given** manifest is not ready, **When** the user attempts universal search, **Then** they see a clear "manifest required / refresh" style prompt and cannot get false empty results that look like "no matches."

---

### User Story 2 - Inspect detail for a search hit (Priority: P1)

After finding a hit, the user opens a detail view that explains what the piece is (name, kind, description/effects, and other identity fields already used elsewhere in Catalog) so they can decide whether to attach or link it.

**Why this priority**: Create/add actions require a confident identity; detail is the bridge between discovery and composition.

**Independent Test**: From a result row, open detail for at least one item-like entity and one perk/trait-like entity; verify identity and description content is shown and matches Catalog expectations for that kind.

**Acceptance Scenarios**:

1. **Given** a result list with a weapon or armor hit, **When** the user opens detail, **Then** they see name, kind, description (when known), and relevant combat identity (slot/class/element as applicable).
2. **Given** a result that is a perk, origin trait, or artifact perk, **When** the user opens detail, **Then** they see name, kind, and effect/description text used for synergy evidence decisions.
3. **Given** detail is open, **When** the user closes or goes back, **Then** they return to the search results without losing the active query.

---

### User Story 3 - Create or add to a Set from Catalog detail (Priority: P1)

From an item's detail, the user can start a new Set with that piece or add it to an existing compatible Set slot, reusing product rules for set type, slot fitness, replace confirmation, and exotic exclusivity.

**Why this priority**: Explicit product goal—search is a composition entry point, not browse-only.

**Independent Test**: From a weapon detail opened via universal search, add to an existing Weapon Set slot (or create a new Weapon Set and place the piece). Repeat conceptually for armor/mod-compatible kinds. Illegal placements are blocked with the same user-facing constraints as Set fill elsewhere.

**Acceptance Scenarios**:

1. **Given** detail for an attachable gear piece and the user is signed in, **When** they choose **Add to existing Set**, **Then** they can pick a compatible Set and slot (or the system proposes the only legal slot) and complete attachment under existing Set rules.
2. **Given** detail for an attachable gear piece and the user is signed in, **When** they choose **Create Set**, **Then** they can name a Set of a legal type for that piece and the piece is placed in a legal slot on create (or immediately offered for placement).
3. **Given** the target Set slot is occupied, **When** the user confirms add/replace, **Then** the existing occupied-slot replace confirmation still applies.
4. **Given** adding the piece would violate exotic exclusivity or slot legality, **When** the user attempts the action, **Then** the action is not completable and the reason is understandable (same class of Destiny hard constraints as Set fill).
5. **Given** the user is signed out, **When** they attempt create/add to Set, **Then** they are prompted to sign in and no partial personal Set is created.

---

### User Story 4 - Create or add to a Synergy from Catalog detail (Priority: P2)

From detail, the user can create a new library Synergy with this object as evidence, or add this object as a link on an existing Synergy—subject to synergy link-kind rules and "at most once per synergy" dedupe.

**Why this priority**: Completes the "set or synergy" composition loop; slightly secondary to Set attach because Sets are the normal gear path, but still core to the ask.

**Independent Test**: From an origin trait or weapon perk detail, add as a link on an existing Synergy; from another detail, create a new Synergy draft that includes the object. Invalid link kinds are refused.

**Acceptance Scenarios**:

1. **Given** detail for an object that is a valid synergy evidence kind, **When** the user chooses **Add to existing Synergy**, **Then** they pick a Synergy and the link is added with correct kind and display identity.
2. **Given** detail for a valid synergy evidence object, **When** the user chooses **Create Synergy**, **Then** they can create a library Synergy (type/subtype per existing create rules) with this object linked as initial evidence.
3. **Given** the object is already linked on the chosen Synergy, **When** the user attempts add again, **Then** the system does not create a duplicate link (same target at most once per synergy).
4. **Given** the object cannot be a synergy link kind, **When** the user views detail actions, **Then** synergy actions are unavailable or clearly disabled with reason—not a failed save after the fact only.
5. **Given** the user is signed out, **When** they attempt create/add to Synergy, **Then** they are prompted to sign in.

---

### User Story 5 - Narrow results by kind without leaving universal search (Priority: P3)

While using universal search, the user can optionally filter the mixed result list to one or more kinds (e.g. only origin traits) so large queries stay scannable.

**Why this priority**: Improves scan quality once P1 search works; not required for MVP if results are well labeled and sorted.

**Independent Test**: Run a broad query, toggle a kind filter, and confirm only that kind remains; clearing filters restores the full mixed list for the same query.

**Acceptance Scenarios**:

1. **Given** mixed results for a query, **When** the user selects a kind filter, **Then** only matching kinds remain and the query text is unchanged.
2. **Given** active kind filters yield zero rows, **When** results update, **Then** empty state explains that filters may be too narrow (distinct from "no matches for query").

---

### Edge Cases

- Query is whitespace-only → treat as no search (prompt to type) rather than full dump of the catalog.
- Very short queries may return large sets → results remain usable (grouped or capped with clear "refine query" guidance); system does not hang or freeze the Catalog shell.
- Same display name on different kinds → both can appear; kind label disambiguates.
- Stale or redacted manifest entries → excluded or marked unavailable; cannot be attached/linked.
- Wishlist vs owned instance: Catalog detail may start from catalog identity; pinning a specific owned copy uses existing instance-selection rules when the Set path requires an instance.
- Fashion-only cosmetics not used in Sets/Builds/Synergies → excluded from universal composition search by default.
- Unsigned browse: search and detail work for manifest entities; personal create/add actions require sign-in.
- Concurrent edit: if target Set/Synergy was deleted before save, user sees a clear failure and can pick another target.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Catalog MUST provide a **universal search** entry point that accepts free-text queries and returns composition-relevant entities across kinds in one result set.
- **FR-002**: Universal search MUST include at least: weapons, exotic weapons, armor (including exotic armor), armor mods, weapon perks, origin traits, artifact perks, armor set bonuses, and subclass-related pieces that Builds already treat as selectable kit parts (abilities/aspects/fragments as applicable to current product composition).
- **FR-003**: Each result MUST show a human-readable **kind**, **name**, and enough secondary context (icon and/or short meta) to scan without opening detail.
- **FR-004**: Search MUST match against **name** and **description/effect text** where those fields exist for the kind (not name-only for perks/traits whose value is in the description).
- **FR-005**: Users MUST be able to open a **detail** view from any result without losing the active query when returning.
- **FR-006**: Detail MUST expose **Set actions** when the entity can legally appear on a Set: create Set and add to existing Set, subject to type/slot/exotic/energy rules already enforced for Sets.
- **FR-007**: Detail MUST expose **Synergy actions** when the entity is a valid synergy evidence kind: create Synergy and add link to existing Synergy, subject to link validation and per-synergy dedupe rules.
- **FR-008**: Set and Synergy actions that mutate personal library data MUST require an authenticated user.
- **FR-009**: Universal search MUST degrade clearly when manifest/entity data is unavailable (no silent empty success).
- **FR-010**: Empty query, empty matches, and filter-narrowed-empty states MUST be distinguishable to the user.
- **FR-011**: Ownership indication for equippable items MUST stay consistent with existing Catalog owned-vs-all semantics when inventory is available.
- **FR-012**: Optional kind filters MAY narrow the current result set without clearing the query (User Story 5).
- **FR-013**: Actions that would violate Destiny/product hard constraints MUST be prevented in the same spirit as existing Set fill and Synergy link flows (not selectable or blocked with clear reason before a confusing failure).
- **FR-014**: Completing create/add MUST leave the user with confirmation of success (updated target name or navigation to the Set/Synergy) so they know the composition change stuck.

### Key Entities

- **Universal Search Query**: Ephemeral free-text string plus optional kind filters scoped to a Catalog session.
- **Composition Search Hit**: A single discoverable entity reference (kind + identity + display fields + optional ownership summary) suitable for opening detail.
- **Catalog Detail Context**: The focused entity plus available composition actions (Set create/add, Synergy create/add) derived from kind and auth state.
- **Set Placement Intent**: Target Set (new or existing), slot, and item identity (and instance when required by existing Set rules).
- **Synergy Link Intent**: Target Synergy (new or existing) and evidence link identity for the focused entity.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In acceptance testing, users find a known origin trait, artifact perk, and weapon each in under **60 seconds** using only universal Catalog search (no external wiki hash lookup).
- **SC-002**: At least **90%** of first-time test users complete **add to existing Set** or **create Set** from a search detail without assistance.
- **SC-003**: At least **90%** of first-time test users complete **add to existing Synergy** or **create Synergy** from a valid evidence detail without assistance.
- **SC-004**: For typical manifest size and a common short query, results become usable within **5 seconds** under normal local app conditions (same class of expectation as existing Catalog browse).
- **SC-005**: Zero regressions in existing specialized Catalog filters and Set/Synergy attachment rules as verified by automated gates and smoke of prior Catalog paths.
- **SC-006**: In a scripted empty-state pass, whitespace query, no-match query, and manifest-unavailable states each show distinct, non-blank guidance (checklist pass/fail).

## Assumptions

- Catalog remains the primary home for this search; Sets/Synergies pickers may later reuse the same discovery language but are not required to be rewritten in this iteration.
- "Anything used in a set or build or synergy" means **composition-relevant** entities already modeled in the product's library flows—not every Destiny string in the universe (e.g. pure lore triumphs stay out).
- Existing Set slot legality, exotic exclusivity, mod energy, and Synergy link-kind validation remain authoritative; this feature routes into them rather than inventing parallel rules.
- Description search quality may follow the same name + description expectation established for [009-description-search](../009-description-search/spec.md); exact ranking algorithm is a planning concern.
- Create Set / Create Synergy from detail uses the same naming uniqueness and type rules as creating those entities elsewhere.
- Unsigned users may browse search hits; personal mutations require sign-in.
- Fashion-only items that are not part of combat composition are out of default result scope.
- Instance pinning (specific owned copy) continues to use existing owned-instance selection when the user chooses a Set path that needs a copy; universal search detail may begin at catalog identity.

## Dependencies

- Catalog browse and ownership patterns from earlier Catalog features.
- Description-bearing entity text from [009-description-search](../009-description-search/spec.md).
- Set attachment and slot rules from [001-build-sets-synergies](../001-build-sets-synergies/spec.md) / [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md).
- Synergy link kinds and validation from [006-synergy-refinement](../006-synergy-refinement/spec.md) and domain `DBR-SYN-*`.
