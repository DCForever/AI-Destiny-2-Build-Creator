# Feature Specification: Default Variant Composer

**Feature Branch**: `043-default-variant-composer`

**Created**: 2026-07-24

**Status**: Draft

**Input**: User description: "Spec kit slice for the future default-variant creation flow: tabbed composer (General, Subclass, Armor & Mod Set with Reuse|Create+Optimize, Weapon Set with Reuse|Create), then Finish for equip/export; non-default variants reuse the flow where possible. Canonical UX: `docs/build-composer-flow - Future direction.excalidraw`."

**Canonical UX board**: [`docs/build-composer-flow - Future direction.excalidraw`](../../docs/build-composer-flow%20-%20Future%20direction.excalidraw)

**Related product spine**: Intent → Compose → Equip (DAC-P1-001 … DAC-P1-008). This feature reshapes **how** the default variant is composed in the UI; it does not weaken hard blocks, soft guidance, or equip-ready rules.

## Clarifications

### Session 2026-07-24

- Q: Finish visibility when default is incomplete? → A: Show Finish always; equip/export disabled with clear missing-reason until complete (Option B)
- Q: What does New build open? → A: Opens tabbed default-variant composer immediately (General first; identity collected there) (Option A)
- Q: After Armor Reuse attach, optimize behavior? → A: Attach + optional Improve kit (not required) (Option B)
- Q: Non-default variant tab model? → A: Same full tabs always; lighter edits allowed inside tabs (Option A)
- Q: Tab access before class/subclass set? → A: Block opening Subclass/Armor/Weapon until class (and subclass where required) is set on General (Option B)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tabbed Default Variant Shell (Priority: P1)

A signed-in user chooses **New build** (or opens an existing build's **default variant**) and lands in a single composer shell with primary tabs: **General**, **Subclass**, **Armor & Mod Set**, and **Weapon Set**, plus always-visible **Finish**. **New build** does not use a separate pre-composer identity-only create step—General is where intent and identity are collected. They can move between tabs without losing in-progress choices on the variant. Soft guidance remains visible in context (at least on General and when reviewing readiness). Hard illegal states still prevent save where domain rules require it.

**Why this priority**: The future board's primary change is structure—one tabbed default-variant path instead of a flat multi-section dump and a separate Finish walkthrough for core combat categories.

**Independent Test**: Open default-variant composer; confirm four primary tabs; edit on General, switch to Subclass and back; prior General values still present; soft guidance still readable.

**Acceptance Scenarios**:

1. **Given** a signed-in user on Build, **When** they choose **New build**, **Then** they enter the tabbed default-variant composer on **General** without a separate identity-only create panel first.
2. **Given** a build with a default variant, **When** the user opens default-variant composition, **Then** they see primary tabs General, Subclass, Armor & Mod Set, and Weapon Set, plus Finish.
3. **Given** the user changes a field on one tab, **When** they switch to another primary tab and return, **Then** the prior change is still reflected (no silent reset).
4. **Given** designated synergies and optional soft targets, **When** the user views General (and readiness surfaces), **Then** soft coverage/stat guidance is available without auto-applying changes.
5. **Given** an illegal subclass kit, over-capacity mods, or exotic limit violation, **When** the user attempts a save that domain rules hard-block, **Then** save is rejected with a clear reason (existing domain behavior preserved).
6. **Given** a new build with class unset, **When** the user tries to open Subclass, Armor & Mod Set, or Weapon Set, **Then** those tabs do not activate and the UI indicates class must be set on General first.

---

### User Story 2 - General Tab: Intent, Identity, Artifact Context (Priority: P1)

On **General**, the user designates synergy types (intent), sets build identity fields (class, subclass tree anchor as required by product, exotic armor identity, optional shared exotic weapon, optional pinned Super), and can pick artifact perks for the default variant. Search/pick controls remain class- and subclass-scoped per existing create-build picker rules where those fields apply.

**Why this priority**: Intent and identity gate a valid build (DAC-P1-001–002); artifact is part of equippable default loadout.

**Independent Test**: On General, designate ≥1 synergy type, set class/subclass and optional exotic/super, select artifact perks; save succeeds when domain allows; zero synergy types still rejected with `NO_SYNERGY`.

**Acceptance Scenarios**:

1. **Given** a new or incomplete default variant, **When** the user is on General, **Then** they can designate Synergy Types and edit identity fields that define the build.
2. **Given** zero Synergy Types designated, **When** the user saves the build/default in a way that requires designations, **Then** save is rejected with the existing no-synergy failure.
3. **Given** class (and subclass where required) are set, **When** the user searches exotic armor or pinned Super, **Then** results stay scoped to class / class+subclass as already specified for create/edit pickers.
4. **Given** an artifact is selected with perks available, **When** the user toggles perks, **Then** the default variant stores that artifact configuration.

---

### User Story 3 - Subclass Tab: Grouped Ability and Aspect/Fragment Picks (Priority: P1)

On **Subclass**, the user completes the legal subclass kit using grouped lists: class ability, melee, grenade, movement, aspects, and fragments (capacity rules unchanged). The board treats ability groups as one visual group and aspects/fragments as another.

**Why this priority**: Default variant combat completeness requires a legal kit (DAC-P1-003 / subclass hard rules).

**Independent Test**: With class and subclass set on General, open Subclass; pick abilities and aspects/fragments within capacity; illegal over-pick is blocked or rejected on save per domain.

**Acceptance Scenarios**:

1. **Given** class and subclass are established, **When** the user opens Subclass, **Then** they see distinct pickers/lists for class ability, melee, grenade, movement, aspects, and fragments.
2. **Given** aspect fragment capacity, **When** the user selects fragments beyond capacity, **Then** the system prevents an illegal kit (existing capacity rules).
3. **Given** incomplete ability requirements for a chosen exotic (when those rules apply), **When** the user reviews or saves, **Then** existing exotic–ability guidance or hard rules still apply.

---

### User Story 4 - Armor & Mod Set: Reuse Existing Sets (Priority: P1)

On **Armor & Mod Set**, the user chooses **Reuse**. They search/filter **Armor** sets constrained to the build's class (and other existing attach filters as appropriate), see an armor sets list and a mod sets list, and attach selected sets live to the default variant (replace-by-type semantics for the same set type remain as today). After an armor set is attached, the user may optionally run **Improve kit** (optimize) on that attachment; improve is never required to leave Reuse or complete the tab.

**Why this priority**: Library reuse is the fast path for compose-via-sets (DAC-P1-004, DAC-P2-005).

**Independent Test**: With class set and at least one class-compatible armor set in the library, Reuse → find set → attach; default variant shows the attachment; detach still works.

**Acceptance Scenarios**:

1. **Given** Armor & Mod Set tab, **When** the user selects Reuse, **Then** they see search/filter and lists for armor sets (class-constrained) and mod sets.
2. **Given** a listed armor set compatible with the build, **When** the user attaches it, **Then** it is live-attached to the default variant (or equivalent current attach mode default).
3. **Given** a set already attached of the same type under replace-by-type rules, **When** the user attaches another, **Then** existing merge/replace behavior is preserved.
4. **Given** no matching library sets, **When** Reuse lists are empty, **Then** the user can still switch to Create without a hard library gate.
5. **Given** an armor set is live-attached via Reuse, **When** the user chooses optional Improve kit, **Then** optimize suggestions appear for confirm-only apply; dismissing or skipping improve leaves the attachment unchanged.

---

### User Story 5 - Armor & Mod Set: Create, Bonuses, Optimize, Inherit Tags (Priority: P1)

On **Armor & Mod Set**, the user chooses **Create**. They can choose armor set bonuses, open an **Optimize** path, review optimized armor set and mod set candidates, and select an armor set. On select, the new armor set **automatically inherits the build's synergies as concept tags** and receives a **generated name**. The user may add mods on armor pieces and save as a mod set, or select a mod set from optimized/listed options. Soft optimizer suggestions never apply without confirmation.

**Why this priority**: This is the future board's armor-first create path and the main reduction of "finish buried three steps deep."

**Independent Test**: Create path → set bonuses / run optimize (or skip to manual create) → select candidate → confirm new armor set name/tags reflect build synergies; confirm nothing auto-applied without confirm; attach is live on default variant.

**Acceptance Scenarios**:

1. **Given** Create sub-tab, **When** the user views content, **Then** they can choose armor set bonuses and access Optimize (or equivalent optimize entry) plus result lists for optimized armor and mod sets.
2. **Given** optimize results, **When** the user selects an armor set candidate and confirms, **Then** a library armor set is created/attached with a generated name and concept tags derived from the build's designated synergies.
3. **Given** an armor set is chosen, **When** the user configures mods on pieces and saves as a mod set (or picks a mod set), **Then** the mod set is available/attached per existing set-attach rules.
4. **Given** optimizer or soft improvement suggestions, **When** results appear, **Then** nothing mutates the variant or library until the user confirms a selection/apply action.
5. **Given** the user declines optimize, **When** they still need armor coverage, **Then** they can create/attach armor without being forced through optimize (in-flow create not gated).

---

### User Story 6 - Weapon Set: Reuse and Create by Slot (Priority: P1)

On **Weapon Set**, the user chooses **Reuse** (search/filter weapon sets, list, attach) or **Create** (Primary / Secondary / Heavy columns with catalog search constrained to each slot). Catalog results **prefer and indicate weapons that match the build's synergies** first, without hiding other legal options unless the user filters further.

**Why this priority**: Completes default combat weapons path alongside armor (DAC-P1-003–004).

**Independent Test**: Reuse attach a weapon set; Create pick primary/secondary/heavy with synergy-matching rows indicated first; save pins/wishlist rules unchanged.

**Acceptance Scenarios**:

1. **Given** Weapon Set → Reuse, **When** the user searches and attaches a weapon set, **Then** it attaches to the default variant under existing attach rules.
2. **Given** Weapon Set → Create, **When** the user views content, **Then** they see Primary, Secondary, and Heavy selection areas with slot-constrained catalog search.
3. **Given** the build has designated synergies with weapon-related evidence, **When** catalog results render, **Then** synergy-matching weapons are shown first and visually indicated; non-matching weapons remain reachable.
4. **Given** a desired roll the user does not own, **When** they save, **Then** wishlist vs equip-ready rules still apply (equip/export blocked until owned pins).

---

### User Story 7 - Finish Surfaces After Default Combat Categories Ready (Priority: P2)

**Finish** is always present as a primary surface alongside composition tabs. Until the default variant meets the product's "finished default" completeness bar (legal kit, weapons, armor, mods as required), equip and DIM export actions on Finish stay **disabled** and Finish shows a clear reason listing what is still missing. Finish is never the only path to create armor/weapon sets. When complete and equip-ready, equip/export unlock; when complete but wishlist-only, equip/export stay blocked by readiness with clear status.

**Why this priority**: Matches the board note that terminal equip actions follow default composition; secondary to getting compose tabs right. Always-visible Finish avoids a disappearing tab while still gating actions.

**Independent Test**: Incomplete default → Finish visible, equip/export disabled with missing reasons; complete equip-ready → actions enabled; wishlist-complete → blocked with readiness status.

**Acceptance Scenarios**:

1. **Given** the default variant is missing required combat coverage, **When** the user opens Finish, **Then** Finish is visible, equip and DIM export are disabled, and the UI states what categories or gaps remain.
2. **Given** the default variant meets completeness and is equip-ready, **When** the user opens Finish, **Then** they can equip in-game and/or export to DIM per DAC-P1-007–008.
3. **Given** a complete but not equip-ready (wishlist) default, **When** the user opens Finish, **Then** equip/export remain blocked with clear readiness status; save of desired rolls remains allowed per domain.

---

### User Story 8 - Non-Default Variants Reuse the Flow Lightly (Priority: P2)

For a **non-default** variant, the product uses the **same full primary tabs** as the default (General, Subclass, Armor & Mod Set, Weapon Set, plus Finish). The user may make lighter edits (e.g. change only weapons) without being forced through full create rituals on every tab. Empty combat slots on non-default variants still follow equip-with-gaps rules after confirmation.

**Why this priority**: Board explicitly calls out reuse without forcing full default rigor on every field—while keeping one interaction model.

**Independent Test**: Open a non-default variant; confirm full tab set; save after weapon-only edits; equip-with-gaps confirm still works.

**Acceptance Scenarios**:

1. **Given** a non-default variant, **When** the user opens composition, **Then** they see the same primary tabs as default (General, Subclass, Armor & Mod Set, Weapon Set, Finish)—not a reduced tab strip.
2. **Given** a non-default variant with only weapon differences from default, **When** the user edits Weapon Set only, **Then** they can save without being forced through full armor create.
3. **Given** empty slots on a non-default variant, **When** the user equips with gaps after confirm, **Then** DAC-VAR-001 behavior is preserved.

---

### Edge Cases

- Until guardian **class** is set on General, Subclass, Armor & Mod Set, and Weapon Set tabs cannot be opened (Finish and General remain available).
- Until **subclass** is set where required for kit picks, Subclass tab remains blocked even if class is set; Armor/Weapon may unlock with class alone when catalog scoping only needs class.
- Thin library: Create paths remain available; Reuse empty states must not hard-block compose.
- Class change after sets attached: existing detach/invalidation/clear rules apply; Reuse lists re-constrain to new class.
- Optimize with no inventory or no feasible kits: empty results with recovery (manual create, Reuse, or adjust bonuses)—no silent fake kits.
- Synergy tag inheritance on created armor sets: concept tags only (not identity); user can edit tags later in library if product already allows.
- Generated set names: unique enough to identify in lists; user can rename in library afterward.
- Capture-from-current-gear: not required as a primary tab on the future board; may remain as a secondary action if already present, but must not reintroduce a busy multi-panel default equal to the old Sets tab dump.
- Concurrent edit of library set while attached live: existing live-attach semantics.
- Offline / manifest stale: validation-first external data; fail clearly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Default-variant composition MUST present primary tabs: General, Subclass, Armor & Mod Set, Weapon Set, plus an always-visible **Finish** surface (see FR-017).
- **FR-002**: Tab switches MUST preserve in-progress default-variant edits already accepted into the working form/state for that session (no reset on tab change alone).
- **FR-003**: General MUST support synergy-type intent designation and build identity fields required by domain (class, subclass context, exotic armor identity, optional shared exotic weapon, optional pinned Super).
- **FR-004**: General MUST support default-variant artifact selection and perk configuration when an artifact is chosen.
- **FR-005**: Soft guidance for synergies/stats MUST remain visible without auto-applying loadout changes.
- **FR-006**: Subclass MUST expose grouped selection for class ability, melee, grenade, movement, aspects, and fragments subject to existing legality and capacity rules.
- **FR-007**: Armor & Mod Set MUST offer **Reuse** and **Create** sub-paths.
- **FR-008**: Armor Reuse MUST list/search armor sets constrained to the build's class and support attach to the default variant; mod sets MUST be listable/attachable in the same tab context.
- **FR-021**: After a successful Armor Reuse attach, the system MUST offer an optional **Improve kit** (optimize) action for that armor attachment. Improve MUST be skippable; it MUST NOT auto-apply results; Create remains the path where optimize is a first-class create step.
- **FR-009**: Armor Create MUST support choosing armor set bonuses and an Optimize entry that yields selectable optimized armor and mod candidates without auto-apply.
- **FR-010**: When the user confirms selection of a newly created armor set from Create/Optimize, the system MUST generate a set name and MUST attach concept tags derived from the build's designated synergies.
- **FR-011**: After armor is chosen, the user MUST be able to establish a mod set (from optimize list, library, or by saving mods configured on pieces) under existing mod-set rules.
- **FR-012**: Weapon Set MUST offer **Reuse** and **Create** sub-paths.
- **FR-013**: Weapon Reuse MUST search/list weapon sets and attach to the default variant under existing rules.
- **FR-014**: Weapon Create MUST provide Primary, Secondary, and Heavy selection with slot-constrained catalog search.
- **FR-015**: Weapon catalog results MUST prioritize and indicate items that match the build's synergies while still allowing other legal weapons.
- **FR-016**: Domain hard blocks (no synergy designations when required, illegal kits, mod capacity, exotic limits) and wishlist vs equip-ready gates MUST remain enforced.
- **FR-017**: A Finish surface for equip / DIM export (and clear wishlist/equip-ready status) MUST always be visible during default-variant composition. Equip and DIM export on Finish MUST stay disabled until the default meets the product's "default finished" completeness bar, with a clear missing-reason summary; when complete, equip/export further respect equip-ready gates. Finish MUST NOT be required as the only path to create armor/weapon sets.
- **FR-018**: Non-default variants MUST present the same full primary tab set as the default variant (General, Subclass, Armor & Mod Set, Weapon Set, Finish). The product MUST allow lighter edits (e.g. weapons-only changes) without forcing full default create rituals on every tab.
- **FR-019**: Canonical interaction structure for this feature is the Future direction Excalidraw board; deviations require an explicit spec update.
- **FR-020**: **New build** MUST open the tabbed default-variant composer immediately (starting on General). Intent and build identity MUST be collected in General (and related tabs), not via a separate pre-composer identity-only create step.
- **FR-022**: Until build **class** is set on General, the product MUST prevent opening Subclass, Armor & Mod Set, and Weapon Set tabs (controls disabled or non-activatable with a clear reason). **Subclass** tab further MUST remain blocked until subclass is set when subclass is required for kit composition. General and Finish remain reachable.

### Key Entities

- **Default variant**: The build's primary combat loadout under edit in the tabbed composer.
- **Primary composer tab**: One of General, Subclass, Armor & Mod Set, Weapon Set.
- **Set sub-path**: Reuse (library attach) vs Create (new set / optimize / slot fill) under Armor or Weapon tabs.
- **Optimized candidate**: Suggest-then-confirm armor or mod kit option from the optimizer; not canonical until user confirms.
- **Inherited concept tags**: Filter metadata copied from build synergy designations onto a newly created armor set (not build identity).
- **Finish surface**: Post-completeness actions for equip, DIM export, and readiness status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reviewer following only the tab labels can locate Intent/Identity, Subclass kit, Armor (reuse or create), and Weapons without opening a separate multi-section "Sets dump" as the primary path.
- **SC-002**: In a scripted walkthrough, a user can attach an existing class-compatible armor set from Armor → Reuse in one tab context (search → select → attach) without visiting a disconnected global Finish-first armor step.
- **SC-003**: In a scripted Create armor path, confirming an optimized or created armor set results in a named library set that shows concept tags corresponding to the build's designated synergies.
- **SC-004**: Weapon Create shows Primary/Secondary/Heavy searches; for a build with known weapon-linked synergies, matching weapons appear before non-matching ones and are visually indicated in at least one fixture dataset.
- **SC-005**: Soft guidance never changes pins/attachments without an explicit user confirm in any of the new paths (spot-check optimize + guidance).
- **SC-006**: Equip and DIM export remain impossible for non–equip-ready variants and possible for equip-ready complete defaults (regression on DAC-P1-005/007/008).
- **SC-007**: Non-default variant can be saved after weapon-only edits without mandatory armor recreate.
- **SC-008**: With an incomplete default, Finish is still reachable and shows at least one concrete missing reason; equip/export controls are not actionable until completeness (and then equip-ready) rules pass.
- **SC-009**: Choosing New build lands the user on General inside the tabbed composer with no intermediate identity-only create screen.
- **SC-010**: On a new build with no class, attempting to activate Subclass/Armor/Weapon tabs fails closed (no usable compose controls on those tabs) until class is set on General.

## Assumptions

- Canonical UX is `docs/build-composer-flow - Future direction.excalidraw` (Future lane + Default Variant Creation Flow section).
- **New build** enters the tabbed composer directly; a separate Create Build identity-only panel is retired for this flow (edit-existing still opens the same composer on the selected variant).
- Domain rules in `specs/domain-business-rules.md` and `specs/domain-acceptance-criteria.md` win on conflicts; this feature is primarily interaction architecture.
- Existing set attach modes (live default), replace-by-type, and library APIs remain the composition backend; UI is re-orchestrated rather than inventing a new domain model.
- Create-build picker scoping from `042-create-build-pickers` remains in force for exotic/super lookups on General.
- "Default finished" for **enabling** Finish equip/export means the same combat completeness bar already used for default variant completion (class, legal subclass kit, weapons, armor, mods)—not a new softer bar. Finish itself is always visible.
- Optimize may require signed-in inventory; empty inventory yields empty optimize results, not errors that brick Create.
- Armor Reuse is attach-first; optimize on Reuse is optional Improve kit only (never a forced gate).
- Generated armor set names may be pattern-based (e.g. build name + armor + disambiguator); exact pattern is an implementation detail as long as SC-003 holds.
- Capture-current-gear and dense concept-tag filter walls are not primary chrome on the future board; optional advanced actions may remain if they do not restore the old busy default layout.
- Fashion and non-combat cosmetics are out of the default tab spine unless already reachable elsewhere unchanged.
- LLM propose-for-confirm remains out of this composer spine.

## Out of Scope

- Changing equip-ready, wishlist, exotic limit, or mod energy **domain** rules (except UI surfacing)
- Full DIM feature parity
- Restoring Generator / multi-pass LLM as a primary tab
- Redesigning library Sets/Synergy pages except as needed for attach/create callbacks
- Shareable build links
- Non-default-only features that do not reuse this shell
- Pixel-perfect recreation of every Excalidraw frame annotation if product behavior is met

## Traceability

| Board area | Spec stories / FRs |
|------------|--------------------|
| General Tab + Intent/Identity + Artifact | US2, FR-003–005 |
| Subclass Tab groups | US3, FR-006 |
| Armor Reuse / Create / Optimize / tag inherit | US4–5, FR-007–011 |
| Weapon Reuse / Create + synergy-first catalog | US6, FR-012–015 |
| Finish after default complete | US7, FR-017 |
| Regular variants reuse lightly | US8, FR-018 |
| P1 spine equip-ready / hard block / wishlist | FR-016, SC-005–006 |
