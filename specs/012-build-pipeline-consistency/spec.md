# Feature Specification: Build Pipeline Consistency

**Feature Branch**: `012-build-pipeline-consistency`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "I want to make sure that there are no gaps in how builds are created, sets are attached, variants are accounted for, and synergies are attached. I want to make sure that there is consistency in lookups across the debug UI"

## Iteration Scope

**In scope (this iteration)**: Close end-to-end gaps in the build composition pipeline (create build → designate synergies → manage variants → attach/detach sets → resolve/verify) and align **lookup and selection patterns** across all debug verification surfaces (Builds, Sets, Synergies, Catalog, and related suggestion flows) so every identity a user must choose is picked from the same catalog-backed discovery model—not typed as raw hashes, free-form IDs, or ad-hoc JSON where a picker already exists elsewhere.

**Out of scope (this iteration)**: Polished production build/set editors; new synergy or set domain rules beyond what prior specs already define; pagination of large lists; changing business rules for live vs snapshot, exotic armor/weapon placement, or synergy weighting (those remain as established in 001 and later refinements).

**Verification**: A signed-in tester can walk the full pipeline on debug pages without leaving the debug UI or inventing hashes/IDs by hand for happy-path flows. Automated checks cover attach/create validation and that debug lookup behaviors stay aligned across surfaces.

## Clarifications

### Session 2026-07-08

- Q: Must the default variant have equipment filled at build create time? → A: Allow create with an empty default variant; equipment is required only when saving/resolving a variant that must be non-empty per existing rules (staged pipeline: create → designate → attach → resolve).
- Q: When attaching a set to a variant that already has attachments, what happens to existing attachments? → A: Attach adds or updates that one set; other attachments on the variant are preserved (no wipe-on-single-attach).
- Q: Can the user remove a set attachment from a variant in this iteration? → A: Yes — list current attachments on the selected variant and remove one without affecting the others.
- Q: Is per-variant exotic weapon selection in scope for debug Builds? → A: Yes — optional exotic weapon picker on the selected variant (catalog search → set or clear).
- Q: What happens when the user has no synergies yet and tries to create a build? → A: Block create with a clear message and a path/link to Synergies debug to create one first (no inline synergy wizard; ≥1 designation rule retained).

### Session 2026-07-08 (lookup empty-search scoping)

- Q: Where does empty-search → “all items, but scoped to prior choices” apply? → A: Subclass structured form (abilities, aspects, fragments) plus exotic armor/weapon lookups scoped by guardian class.
- Q: How is “fits this subclass” defined for abilities/aspects/fragments? → A: Scope by guardian class + element of the selected subclass (e.g. Stormcaller → Warlock + Arc).
- Q: How should Prismatic subclasses be scoped? → A: Same rule — class + element `Prismatic` only. Prismatic has its own specific supers/grenades/melees/etc.; do not widen to all elements for the class.
- Q: When does empty-query “list all scoped options” run? → A: On explicit Search/Browse with an empty query; refresh if class/subclass changes while results are already shown.
- Q: If the user changes subclass after picking abilities, what happens to incompatible selections? → A: Clear incompatible ability/aspect/fragment selections; keep compatible ones; refresh open result lists.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Build Without Manual Hashes or Guesswork (Priority: P1)

A tester creating a build on the debug Builds surface chooses exotic armor, subclass elements, concept tags, and designated synergies through the same kind of searchable, catalog-backed pickers used on Catalog/Sets/Synergies—rather than typing exotic armor hashes, free-text names that can drift from the hash, or opaque subclass JSON.

**Why this priority**: Build creation is the entry point of the pipeline. If creation still depends on raw hashes and incomplete synergy selection, every downstream attach/variant/suggest flow is unverifiable or misleading.

**Independent Test**: On debug Builds, create a named build for a class by picking exotic armor from catalog search, selecting subclass pieces from available options, assigning tags, and designating one or more existing synergies from a picker—then confirm the saved build reflects those choices without any manual hash fields on the happy path.

**Acceptance Scenarios**:

1. **Given** a signed-in user on debug Builds, **When** they create a build, **Then** exotic armor is chosen via catalog-style lookup (search/filter → select), and the stored identity and display name stay consistent with the chosen catalog item.
2. **Given** the create-build flow, **When** the user designates synergies, **Then** they select from their existing synergies list (multi-select allowed) rather than relying on an invisible default seed or empty attachment.
3. **Given** subclass configuration is required, **When** the user fills subclass fields, **Then** they pick from available class/subclass options (or an equivalent structured picker)—not by inventing free-form JSON as the only path. Empty searches list all options still valid for the current class/subclass (and exotic armor/weapon lookups are scoped by guardian class).
4. **Given** the user has selected abilities/aspects/fragments for a subclass, **When** they change to a different subclass (or class) whose class+element scope no longer includes those choices, **Then** incompatible selections are cleared, compatible ones remain, and any open result lists refresh to the new scope.
5. **Given** required fields are incomplete (no exotic armor selected, or no synergy designated when required by existing rules), **When** the user attempts to save, **Then** creation is blocked with a clear validation message naming what is missing.
6. **Given** a successful create, **When** the user views the build detail, **Then** exotic armor, tags, designated synergies, and the default variant are all visible and match what was selected — even if the default variant still has no set attachments yet.
7. **Given** the user has selected exotic armor, synergies, and subclass but has not attached any sets, **When** they create the build, **Then** creation succeeds with an empty default variant; attaching sets is a later step.

---

### User Story 2 - Attach Sets to the Correct Variant With Full Context (Priority: P1)

A tester attaching sets to a build selects the target **variant** from the build’s known variants and chooses sets through a filtered attach picker (including concept-tag AND filtering), with live vs snapshot mode explicit—so attachments always land on the intended variant and respect existing set-type and exotic-armor rules.

**Why this priority**: Set attachment is how equipment enters a build. Gaps here (free-text variant IDs, unfiltered set lists, unclear which variant is active) are the primary source of “pipeline holes.”

**Independent Test**: Create or open a build with at least two variants; attach a Weapon Set to variant A and an Armor Set to variant B using pickers only; confirm resolved equipment for each variant shows the correct attachments and modes.

**Acceptance Scenarios**:

1. **Given** a build with one or more variants, **When** the user opens attach-set, **Then** they select the target variant from a list of that build’s variants (name + identity)—not by typing a raw variant ID as the primary path.
2. **Given** the attach flow, **When** the user chooses a set, **Then** they can filter sets by type and by concept-tag combination (AND semantics), matching the SetAttachPicker behavior already required for builds.
3. **Given** the user attaches a set, **When** they choose live or snapshot, **Then** the attachment is recorded on the selected variant with that mode, and later set edits behave according to existing live/snapshot rules.
4. **Given** a variant that already has one or more set attachments, **When** the user attaches a different set, **Then** the new set is added (or an existing attachment for the same set is updated) and previously attached sets remain on that variant.
5. **Given** a Pair Set whose exotic armor does not match the build’s exotic armor, **When** the user attempts to attach it, **Then** the operation is rejected with a clear explanation (existing Pair/exotic rule).
6. **Given** attachments on multiple variants, **When** the user requests resolved equipment for each variant, **Then** each resolution reflects only that variant’s attachments (plus shared build-level exotic armor / subclass / synergies).
7. **Given** a variant with two or more set attachments listed, **When** the user removes one attachment, **Then** that set is detached from the variant and the remaining attachments are unchanged.

---

### User Story 3 - Account for Every Variant in Debug Workflows (Priority: P1)

A tester can list, select, duplicate, compare, and resolve **all** variants of a build from the debug Builds surface without losing track of which variant is active, and without workflows that silently default to “first variant only.” They can optionally set or clear each variant’s **exotic weapon** via catalog-backed lookup (variants may differ by attached sets and exotic weapon).

**Why this priority**: Prior debug flows often assume a single default variant. Incomplete variant accounting breaks attach, suggest, compare, and export verification. Exotic weapon is part of how variants differ under existing rules.

**Independent Test**: Duplicate a variant, switch selection between default and copy, attach different sets to each, set a different exotic weapon on the copy, run compare and resolved export for both; confirm no action applies to the wrong variant.

**Acceptance Scenarios**:

1. **Given** a build with multiple variants, **When** the user loads the build on debug Builds, **Then** all variants are listed and selectable; the active selection is always visible.
2. **Given** an active variant selection, **When** the user runs attach, suggest-sets, resolved view, or export, **Then** those actions target the selected variant—not an implicit first variant.
3. **Given** the user duplicates a variant, **When** the copy is created, **Then** it appears in the variant list, becomes selectable, and starts from the duplicated attachments per existing rules.
4. **Given** two or more variants, **When** the user runs compare, **Then** the comparison covers the build’s variants with clear per-variant differences (attachments / exotic weapon where applicable).
5. **Given** no variant is selected, **When** the user attempts a variant-scoped action, **Then** the UI blocks the action and prompts them to select a variant.
6. **Given** a selected variant, **When** the user picks an exotic weapon from catalog search (or clears it), **Then** that variant’s exotic weapon identity is updated and other variants are unchanged.

---

### User Story 4 - Attach and Review Synergies on Builds Consistently (Priority: P2)

A tester can designate, add, remove, and review synergies on a build using the same synergy identity and listing patterns as the Synergies debug page—so build↔synergy attachment is visible, editable after create, and consistent with many-to-many link rules already defined for synergies.

**Why this priority**: Synergies guide suggestions; if builds cannot reliably attach/review them in debug, suggest-sets and suggest-rolls cannot be trusted end-to-end.

**Independent Test**: Create two synergies on Synergies debug; on Builds debug, attach both to a build (at create and via edit), remove one, and confirm suggest-synergies / suggest-sets still reflect the remaining designations.

**Acceptance Scenarios**:

1. **Given** existing user synergies, **When** the user designates synergies on a build (create or edit), **Then** they pick from a searchable/filterable list of their synergies (by name and type), not free-text IDs.
2. **Given** a build with designated synergies, **When** the user views the build, **Then** all designated synergies are listed with names and types consistent with the Synergies debug listing.
3. **Given** a build with designated synergies, **When** the user removes one designation, **Then** the build updates and subsequent suggestions no longer treat the removed synergy as designated.
4. **Given** the user has no synergies yet, **When** they attempt to create a build, **Then** creation is blocked with a clear message that at least one synergy is required and a visible path/link to the Synergies debug page to create one first—not an inline synergy wizard and not a silent placeholder.

---

### User Story 5 - Consistent Lookups Across Debug Surfaces (Priority: P2)

A tester moving between Catalog, Sets, Synergies, and Builds debug pages experiences one consistent lookup model: search/filter → results with names and descriptions where applicable → select → confirm. Surfaces that previously required raw hashes or free-text IDs for the same entity types are brought to parity for happy-path flows.

**Why this priority**: Cross-page inconsistency is the user’s explicit second goal; it also prevents false confidence when one page “works” and another still accepts invalid manual input.

**Independent Test**: For each entity type used in the pipeline (exotic armor, set, synergy, weapon/armor item, perk/origin trait/set bonus link), perform selection on every debug page that needs that entity and confirm the same picker capabilities and result fields appear (within entity-appropriate filters).

**Acceptance Scenarios**:

1. **Given** exotic armor selection is needed on Builds (create/filter) and anywhere else exotic armor is chosen in debug, **When** the user looks up exotic armor, **Then** the experience matches Catalog exotic armor browse (search by name, class filter, owned scope as applicable)—not a bare hash field as the primary path.
2. **Given** set selection is needed on Builds attach and on Sets management, **When** the user looks up sets, **Then** both surfaces support name visibility, type, and tag AND filtering consistently.
3. **Given** synergy selection is needed on Builds and Synergies, **When** the user looks up synergies, **Then** both surfaces show name, type, and enough identity to distinguish duplicates; selection does not require typing synergy IDs.
4. **Given** item/perk/trait/set-bonus lookup already exists on Catalog/Sets/Synergies, **When** a debug page needs that same entity, **Then** it reuses the same lookup behavior (filters, description visibility, empty states)—not a divergent free-text path for the happy path.
5. **Given** a lookup returns no matches for a non-empty query (or after scoping filters), **When** results are shown on any debug surface, **Then** the user sees a clear empty state—not unrelated items or a silent failure.
6. **Given** the user opens a scoped lookup (subclass ability/aspect/fragment, or exotic armor/weapon) with an empty search box, **When** they search/browse, **Then** they see all items that remain valid under the current scoping choices (not an error and not an unscoped full catalog dump).
7. **Given** advanced/power-user needs, **When** a raw hash or ID field remains for escape-hatch debugging, **Then** it is clearly labeled as optional/advanced and is not required for the documented happy-path acceptance scenarios.

---

### Edge Cases

- What happens when the user switches the active variant mid-flow after selecting a set but before confirming attach? The attach must use the variant selected at confirm time; if selection changed, the UI confirms the target variant name before applying.
- What happens to existing attachments when attaching another set? They are **preserved**; attach is additive/update-in-place for the chosen set, not a wipe of the variant’s attachment list.
- How does the system handle a build whose default variant has no equipment slots filled yet? **Create is allowed** with an empty default variant. Existing variant-scoped save/resolve rules still apply afterward; debug UI surfaces validation clearly when a non-empty composition is required for a later action, instead of blocking create.
- What if a designated synergy is deleted while still attached to builds? Follow existing synergy/build referential rules; debug UI refreshes designations and shows a clear stale/missing state if a designation can no longer resolve.
- What if set list or synergy list is empty when opening an attach/designate picker? Show an informative empty state with a path to create the missing entity on the appropriate debug page.
- What if the user has zero synergies at build create? **Block create** with a clear required-synergy message and a link/path to `/debug/synergies`; do not offer an inline synergy-create wizard on Builds in this iteration.
- What if the user searches with an empty query on a scoped lookup? Return **all items still valid for current choices** (class / subclass as applicable)—not an error and not the unscoped full catalog.
- What if the selected subclass is Prismatic? Scope to **class + element Prismatic** only (Prismatic’s own supers/grenades/etc.), not every elemental option for that class.
- What if the user changes subclass after selecting abilities? **Clear incompatible** ability/aspect/fragment selections; keep compatible ones; refresh open result lists.
- What if catalog data is unavailable or stale for an exotic armor previously saved on a build? Show the stored name/hash with a stale indicator; block new selections that fail catalog validation, consistent with soft-stale item rules.
- What if the user filters builds by exotic armor using a picker selection vs an old hash filter? Both must resolve to the same build set when the same exotic armor identity is chosen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Debug Builds create flow MUST allow selecting exotic armor via catalog-backed lookup; happy-path create MUST NOT require typing a raw exotic armor hash.
- **FR-002**: Debug Builds create/edit flows MUST allow designating one or more synergies via picker from the user’s synergies; designated synergies MUST be visible after save. When the user has no synergies, create MUST be blocked with a clear message and a path/link to Synergies debug—not an inline synergy-create wizard and not silent seeding.
- **FR-003**: Debug Builds MUST support structured subclass selection sufficient to satisfy existing build subclass requirements without raw JSON as the only happy-path input.
- **FR-020**: For subclass structured lookups (supers, grenades, melees, class abilities, movement, aspects, fragments) and for exotic armor/weapon lookups, an empty search MUST return all items that remain valid under current scoping choices (guardian class; and for subclass fields, the selected subclass). Non-empty search MUST further filter within that same scoped set. Empty-query listing MUST run on explicit Search/Browse (not auto-fetch on field mount alone); if results are already shown and class/subclass changes, the scoped result list MUST refresh.
- **FR-021**: Subclass-field scoping MUST use the selected subclass’s **guardian class + element** (from subclass metadata). Example: Stormcaller → only Warlock + Arc options for the relevant ability/aspect/fragment kind. Prismatic subclasses use the same rule with element `Prismatic` (their own specific ability/aspect/fragment set)—MUST NOT widen to all elements for the class. Exotic armor/weapon lookups MUST be scoped by the build’s guardian class where class applies.
- **FR-022**: When the user changes guardian class or subclass, the system MUST clear ability/aspect/fragment selections that are outside the new class+element scope, keep selections that remain valid, and refresh any open scoped result lists to the new scope.
- **FR-004**: System MUST reject build create/update that violates existing required fields (including designated synergy) with explicit, user-visible validation messages. Build **create** MUST allow an empty default variant (no set attachments / no filled equipment slots yet); existing non-empty variant rules apply to later save/resolve steps, not to initial create.
- **FR-015**: After create, users MUST be able to attach sets to the (possibly empty) default variant as a separate step; the staged pipeline create → designate → attach → resolve is the supported happy path.
- **FR-019**: Build create MUST continue to require ≥1 designated synergy; absence of any user synergies is an explicit block with navigation guidance to Synergies debug, not a relaxation of the designation rule.
- **FR-005**: Debug Builds MUST list all variants for the selected build and require an explicit variant selection for every variant-scoped action (attach set, suggest sets, resolve, export).
- **FR-006**: Debug Builds attach-set flow MUST select sets via a picker that supports set type and concept-tag AND filtering, and MUST record live vs snapshot mode on the selected variant.
- **FR-016**: Attaching a set to a variant MUST preserve other attachments already on that variant (add or update the chosen set only). A single attach action MUST NOT wipe the variant’s full attachment list.
- **FR-017**: Debug Builds MUST list the selected variant’s current set attachments and allow removing one attachment without affecting the others.
- **FR-007**: Attach and resolve behavior MUST continue to enforce existing Pair Set / build exotic armor consistency and live vs snapshot semantics; this feature MUST NOT weaken those rules.
- **FR-008**: Variant duplicate and compare actions MUST operate on the explicitly selected build/variants and MUST refresh the variant list so every variant remains selectable afterward.
- **FR-018**: Debug Builds MUST allow setting or clearing the selected variant’s optional exotic weapon via catalog-backed lookup (happy path MUST NOT require typing a raw exotic weapon hash); build-level exotic armor remains separate and shared across variants.
- **FR-009**: Users MUST be able to add and remove synergy designations on an existing build from debug Builds after create, with listings consistent with Synergies debug (name, type).
- **FR-010**: Across debug surfaces (Builds, Sets, Synergies, Catalog, and suggestion pages that select the same entities), lookups for the same entity kind MUST present consistent search/filter → select behavior and comparable result identity fields (name, type/kind, and description when that entity already shows descriptions elsewhere).
- **FR-011**: Happy-path debug flows for build create, set attach, synergy designate, and variant select MUST be completable without manual entry of opaque IDs or hashes; any remaining raw ID/hash inputs MUST be optional advanced escape hatches only.
- **FR-012**: Empty and error states for all pipeline lookups and attaches MUST be explicit (no silent failure, no unrelated results).
- **FR-013**: Filtering builds by exotic armor in debug MUST use the same exotic armor identity as create-time selection (picker-backed), so list filter and create stay consistent.
- **FR-014**: End-to-end verification MUST demonstrate one continuous path: create build → designate synergies → ensure/select variant → attach sets → resolve/compare—without switching to manual hash/ID entry for those steps.

### Key Entities

- **Build**: User-owned loadout container with shared subclass, exotic armor, concept tags, and designated synergies; owns one or more variants.
- **Build Variant**: Named equipment composition under a build; holds set attachments (live or snapshot) and optional per-variant exotic weapon; all variants share build-level subclass, exotic armor, and synergies.
- **Set Attachment**: Link from a variant to a Set in live or snapshot mode; subject to set-type slot rules and Pair/exotic constraints.
- **Synergy Designation**: Build-level association to one or more Synergies that guide suggestions equally.
- **Debug Lookup**: Shared selection pattern used across debug pages to find and choose catalog items, sets, synergies, and related entities by searchable attributes rather than raw identifiers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A tester completes the full pipeline (create build → designate ≥1 synergy → attach ≥1 set to a chosen variant → view resolved output) in under 5 minutes using only picker-based selections on the happy path.
- **SC-002**: In acceptance testing, 100% of happy-path build creates, set attaches, synergy designations, and variant selections succeed without typing raw hashes or opaque IDs.
- **SC-003**: For a build with 2+ variants, 100% of attach/suggest/resolve/export actions in a scripted checklist apply to the intentionally selected variant (zero cross-variant mis-applies).
- **SC-004**: Cross-surface lookup parity checklist passes for exotic armor, sets, and synergies: each entity is selectable with consistent identity fields on every debug page that needs it.
- **SC-005**: 100% of blocked invalid operations (missing synergy, mismatched Pair exotic armor, no variant selected, empty required picker) show a clear message naming the problem in manual verification.
- **SC-007**: For Stormcaller (Warlock + Arc), empty Super/Grenade/etc. Search/Browse returns only Warlock+Arc options of that kind; switching to Dawnblade clears Arc-only incompatible picks and shows Solar-scoped options instead.

## Assumptions

- Existing domain rules from 001 (and refinements in 006–011) remain authoritative for live/snapshot, exotic armor at build level, exotic weapon per variant, Pair matching, synergy weighting, and set slot cardinality; this feature closes verification and selection gaps rather than redefining those rules. Clarification 2026-07-08: **empty default variant at create is allowed**; 001’s “at least one equipment slot filled” constraint applies to later variant save/resolve readiness, not to blocking initial build create in this pipeline.
- Debug UI remains the delivery and verification venue (signed-in, non-production), consistent with prior iterations.
- Catalog, Sets, and Synergies already have stronger picker patterns for many entity types; Builds (and any lagging controls on other debug pages) are brought up to that bar.
- “Consistency” means same discovery model and comparable result fields for the same entity kind—not identical page layout or pixel-perfect UI.
- Optional advanced raw hash/ID fields may remain for debugging edge cases but are excluded from happy-path success criteria.
- Suggestion quality algorithms are unchanged; this feature only ensures designations and attachments feeding suggestions are correctly selectable and visible.
- Production UI will inherit these selection behaviors when promoted later; designing production chrome is out of scope here.
