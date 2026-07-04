# Feature Specification: Per-Copy Weapon Perk Grid

**Feature Branch**: `011-per-copy-perk-grid`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Per-copy weapon perk selection (DIM-style perk grid). When I pick a specific owned weapon copy in the debug UI I can only see the single equipped perk in each column, and the perk-selection dropdowns show the weapon TYPE's full roll pool (identical for every copy). I want: when I choose a specific weapon instance/copy, I want to see every perk that THAT copy actually has access to, laid out by column like Destiny Item Manager (DIM) shows it — each column listing the alternate perks the copy can switch between, with the currently equipped one marked. I then want to select, per column, which perk I want to use, and save that selection to the set/build via the API so it records the exact copy (instanceId) plus my chosen perks. The same weapon can drop with different rolls, and some copies (crafted, enhanced, multi-perk drops) can switch between multiple perks in a column. To build correctly I need to pick from the perks a specific copy genuinely has, not the weapon's theoretical pool."

## Clarifications

### Session 2026-07-03

- Q: How should the grid render an **exotic** weapon's columns (intrinsic trait, catalyst, few/no random columns)? → A: **Use the same per-column grid** — show whatever columns have options (intrinsic and catalyst appear as their own, usually single-option, columns; random columns appear when the exotic has them). Exotics are in scope. (FR-016)
- Q: How should **enhanced vs base** perk variants appear in a column? → A: **Show both** the base and enhanced variants as **separate selectable options**, with the enhanced one **labeled "Enhanced"** (DIM-like, information-preserving). (FR-017)
- Q: When a copy was synced **before** per-copy alternate-perk data was captured (stale copy), what is the re-sync/degradation behavior? → A: **Automatically trigger a re-sync** when the grid is opened for a copy that lacks per-copy perk data, then render the grid from the refreshed data; the equipped-only degraded state (FR-015) applies only while the refresh is pending or if it fails. (FR-018)

## Iteration Scope

**In scope**: Replacing the weapon-**type** perk approximation in the disambiguation picker (delivered by [010-instance-disambiguation](../010-instance-disambiguation/spec.md)) with **real per-copy perk data**. When a user selects one owned weapon copy from the instance carousel, the system presents a **per-column perk grid for that specific copy** — modeled after how Destiny Item Manager (DIM) presents a weapon: each column (barrel, magazine, the trait column(s), intrinsic/frame, origin trait, masterwork) lists the perks **that copy** can actually slot, with the currently-equipped perk marked and preselected. The user picks **one perk per column** (or keeps the equipped defaults), then attaches the copy to a **set** slot via the existing write path, recording the copy's **instanceId** plus the **chosen perk hash per column**. Copies with a single perk per column show one option; crafted/enhanced/multi-perk copies show multiple selectable options in the relevant columns. When per-copy data is unavailable, the grid degrades to the copy's equipped perks with a clear indicator.

**Out of scope**: Actually **inserting or changing perks on the in-game item** via the Bungie API (this feature only records the selection in our own set/build); **armor** perk/mod selection (weapons only); a mixed carousel of different items (unchanged from 010 — copies of one selected item only); **build/variant** attachment (sets only, unchanged from 010 — the picker must not preclude reusing it for builds later); production-polished UI; changing how armor Tier / stats / set-bonus are shown (unchanged from 010).

**Builds on**: [010-instance-disambiguation](../010-instance-disambiguation/spec.md) (the instance carousel, the weapon perk-selection UI shell, per-copy `instanceId` persistence on set items, and the `PUT` set-item write path with `selectedPerks`), [003-owned-inventory-instances](../003-owned-inventory-instances/spec.md) (per-copy instance listing with equipped plugs, power, location, stable identifier), and [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (set item lookup/attachment).

**Verification**: On the signed-in debug Sets surface, a user searches a weapon they own in multiple copies, selects one copy from the carousel, sees a per-column perk grid populated from **that copy's** real available perks (equipped marked), changes one or more columns, clicks "Put item", and confirms the saved set item records that copy's `instanceId` and the chosen perk hashes. A second copy of the same weapon with a different roll shows a different grid. Automated tests cover per-column grouping from per-copy data, equipped marking/defaulting, override selection and persisted payload, and graceful degradation when per-copy data is absent.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See a Copy's Real Perks Laid Out by Column (Priority: P1)

A user who has selected one specific owned weapon copy sees a **per-column perk grid for that exact copy**, like DIM: each column shows the perks **that copy** can slot in that column (the equipped perk plus any alternates it can switch to), with the equipped perk clearly marked. This replaces today's behavior where each column shows only the single equipped perk and the selection dropdowns show the weapon **type's** full theoretical roll pool (identical for every copy).

**Why this priority**: This is the core value. To build a correct loadout the user must see the perks a *specific copy* genuinely has — not the single equipped one, and not the weapon type's theoretical pool. Everything else depends on this data being real and per-copy.

**Independent Test**: Select a weapon copy from the carousel; confirm the grid groups perks into columns (barrel, magazine, trait column(s), intrinsic/frame, origin, masterwork), each column lists the perks that copy can slot with the equipped one marked, and that a second copy of the same weapon with a different roll shows a different grid.

**Acceptance Scenarios**:

1. **Given** a copy with a single perk per column, **When** the grid renders, **Then** each column shows exactly one option and it is marked equipped.
2. **Given** a crafted/multi-perk copy that can switch perks in one or more columns, **When** the grid renders, **Then** those columns show all the perks that copy can switch between, and the equipped one is marked.
3. **Given** any weapon copy, **When** the grid renders, **Then** intrinsic frame, origin trait, and masterwork each appear as their own column (usually a single option).
4. **Given** two copies of the same weapon with different rolls, **When** each is selected in turn, **Then** the grids differ to reflect each copy's own available perks.
5. **Given** a perk whose name cannot be resolved, **When** the grid renders, **Then** the perk is still shown by identifier rather than omitted.
6. **Given** an armor copy (not a weapon), **When** it is selected, **Then** no perk grid is shown (kind-appropriate flow, unchanged from 010).

---

### User Story 2 - Pick Perks Per Column and Save Them to the Set (Priority: P1)

From the per-copy grid the user chooses **one perk per column** (or keeps the equipped defaults), then clicks "Put item". The attachment records the copy's **instanceId** and the **chosen perk hash for each column**. Columns the user did not touch keep the equipped perk; only changed columns are overridden — and the resulting per-column selection is exactly what is sent to and stored by the API.

**Why this priority**: Seeing the real perks is only useful if the user's chosen roll can be captured against the exact copy. Recording `instanceId` + selected perks is what makes "build correctly with this copy" meaningful.

**Independent Test**: Select a copy whose columns have multiple options, change at least one column away from equipped, click "Put item", and verify the saved set item records that copy's `instanceId` and a perk hash per column matching the selection (equipped defaults for untouched columns, the override for changed ones).

**Acceptance Scenarios**:

1. **Given** a rendered grid, **When** it first loads, **Then** the equipped perk in each column is preselected.
2. **Given** the user changes the selection in some columns and leaves others, **When** they click "Put item", **Then** the saved selection contains the overrides for changed columns and the equipped defaults for untouched columns.
3. **Given** the user makes no changes, **When** they click "Put item", **Then** the copy's equipped perks are recorded by default.
4. **Given** a selected copy, **When** the attachment is saved, **Then** the set item records that copy's specific `instanceId` (a different copy would yield a different saved reference).
5. **Given** a target slot that is already occupied, **When** the user attaches the copy, **Then** the existing occupied-slot replace confirmation still applies (no regression from 010/001).

---

### User Story 3 - Degrade Gracefully When Per-Copy Data Is Unavailable (Priority: P2)

When per-copy alternate-perk data is not available for a chosen copy, the grid does not break: it shows the copy's **equipped perks only** (one option per column, preselected) with a **clear indicator** that alternates could not be loaded, and the user can still attach the copy with its equipped perks.

**Why this priority**: Not every copy will have per-copy alternate data available (older synced copies, exotics with no random columns, transient resolution failures). The feature must never crash or silently show the wrong (weapon-type) pool; it must fall back to what is known for that copy.

**Independent Test**: Select a copy for which per-copy alternate data is unavailable; confirm the grid shows only the equipped perks with a visible "alternates unavailable" indicator, no crash occurs, and "Put item" still records the equipped perks and `instanceId`.

**Acceptance Scenarios**:

1. **Given** a copy with no per-copy alternate data, **When** the grid renders, **Then** it shows the equipped perks (one per column) with a clear degraded-state indicator.
2. **Given** the degraded state, **When** the user clicks "Put item", **Then** the copy's equipped perks and `instanceId` are still recorded.
3. **Given** a transient failure loading per-copy data, **When** the grid renders, **Then** the user sees the degraded state rather than an error page or the weapon-type pool.

---

### Edge Cases

- **Exotic weapons**: rendered with the same per-column grid — intrinsic and catalyst appear as their own (usually single-option) columns, and any random columns appear when the exotic has them (FR-016).
- **Enhanced vs base perks** (crafted/enhanced copies): both variants appear as separate options, with the enhanced one labeled "Enhanced" (FR-017).
- **Stale copy** synced before per-copy capture existed: an automatic re-sync is triggered when the grid opens; the equipped-only degraded state shows only while the refresh is pending or if it fails (FR-018).
- The automatic re-sync (FR-018) must not loop indefinitely if it repeatedly fails, and must show a pending/loading state rather than blocking the carousel.
- A column where the same perk appears via multiple sources (e.g. curated and random) is shown once (de-duplicated).
- A socket that is not perk-bearing (shaders, trackers, ornaments, empty cosmetic sockets) is excluded from the grid.
- A perk plug that cannot be resolved to a name is shown by identifier, never hidden.
- A column that ends up with zero available perks for the copy is omitted rather than shown empty.
- The chosen copy becomes stale between selection and save (e.g. after a refresh) — existing stale-item handling applies; an invalid reference is not attached.
- Switching between copies in the carousel refreshes the grid to the newly selected copy.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a user selects a specific owned **weapon** copy, the system MUST present that copy's perks as a **per-column grid**, one column per perk-bearing socket (barrel, magazine, the trait column(s), intrinsic/frame, origin trait, masterwork), replacing the weapon-type roll-pool approximation used previously.
- **FR-002**: Each column MUST list the perks **that specific copy** can slot in that column — the equipped perk plus the alternates the copy can switch to — and MUST NOT show the weapon type's theoretical curated/random pool.
- **FR-003**: The currently-equipped perk in each column MUST be visibly **marked** and **preselected**.
- **FR-004**: A column in which the copy has only one available perk MUST show exactly one option.
- **FR-005**: A column in which the copy can switch among multiple perks (e.g. crafted, enhanced, or multi-perk drops) MUST show all of those perks and allow the user to choose one.
- **FR-006**: Intrinsic frame, origin trait, and masterwork MUST each be presented as their own column (typically single-option).
- **FR-007**: Two different copies of the same weapon with different rolls MUST render grids that reflect each copy's own available perks (different rolls produce different grids).
- **FR-008**: Users MUST be able to select **exactly one** perk per column; columns the user does not change MUST retain the equipped perk as the default.
- **FR-009**: On attachment ("Put item"), the system MUST persist the selected copy's **instanceId** together with the **chosen perk hash for each column** to the set item.
- **FR-010**: The perks sent to and stored by the API MUST equal the equipped defaults for untouched columns and the user's chosen perk for each overridden column.
- **FR-011**: The system MUST display a perk whose name cannot be resolved by its **identifier** rather than hiding it (carried over from 010).
- **FR-012**: The perk grid MUST apply to **weapons only**; selecting an **armor** copy MUST NOT show the grid (kind-appropriate flow, unchanged from 010).
- **FR-013**: The grid MUST reflect the **specific selected copy** and MUST refresh when the user switches to a different copy in the carousel.
- **FR-014**: The system MUST capture and make available each owned weapon copy's **per-column available perks** (equipped plus alternates) — data not captured today, where only the single equipped plug per socket is stored — so the grid reflects real per-copy perks rather than the weapon-type pool.
- **FR-015**: When per-copy alternate-perk data is **unavailable** for a copy, the system MUST degrade to showing the copy's **equipped perks only** with a **clear indicator**, MUST NOT crash, and MUST NOT fall back to the weapon-type pool.
- **FR-016**: **Exotic** weapons MUST use the same per-column grid: the system MUST show whichever columns have options for the copy, presenting the intrinsic trait and catalyst as their own (usually single-option) columns and any random columns the exotic has. Exotic weapons are in scope for the grid.
- **FR-017**: When a copy's column can hold both a **base** and an **enhanced** version of a perk, the system MUST show **both as separate selectable options** and MUST label the enhanced variant (e.g. "Enhanced") so the user can distinguish and choose between them.
- **FR-018**: When a chosen copy lacks captured per-copy perk data (e.g. it was synced before this capability existed), the system MUST **automatically trigger a re-sync** for that copy's data when the grid is opened and then render the grid from the refreshed data. The equipped-only degraded state (FR-015) applies only while the automatic re-sync is pending or if it fails; the automatic re-sync MUST NOT block or corrupt the compare/attach flow and MUST NOT loop indefinitely on repeated failure.
- **FR-019**: Recording perks MUST NOT modify the in-game item (no Bungie perk insert); selections are stored only on the set/build.
- **FR-020**: The existing set-item attachment path, per-copy `instanceId` persistence, slot compatibility, and occupied-slot replace confirmation MUST continue to work with **no regression** (unchanged from 010/008/001).
- **FR-021**: Non-perk-bearing sockets (shaders, trackers, ornaments, empty cosmetic sockets) MUST be excluded from the grid.

### Key Entities

- **Per-copy perk column**: A perk-bearing socket for one specific copy, carrying the perks that copy can slot in it (equipped plus alternates), which perk is equipped/default, and each perk's resolved name (or identifier when unresolved).
- **Per-copy perk grid**: The ordered collection of a copy's perk columns (barrel, magazine, trait column(s), intrinsic/frame, origin, masterwork) — the DIM-style layout for that exact copy.
- **Perk selection**: The user's chosen perk per column (defaulting to the equipped perk), persisted as the roll on the set item alongside the copy's `instanceId`.
- **Degraded grid**: The equipped-only fallback shown when per-copy alternate data is unavailable, with an explicit indicator.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a selected weapon copy, 100% of the copy's perk columns display the perks that copy can actually slot (equipped plus alternates), verified against both a crafted/multi-perk example and a static-roll example.
- **SC-002**: Two copies of the same weapon with different rolls produce visibly different grids in 100% of verification cases.
- **SC-003**: The equipped perk is preselected in every column in 100% of cases, and only columns the user changes differ from equipped in the saved payload.
- **SC-004**: On save, the persisted set item records the copy's `instanceId` and one chosen perk hash per column matching the user's selection in 100% of verification cases (a different copy yields a different saved reference).
- **SC-005**: When per-copy data is unavailable, the grid degrades to equipped-only with a clear indicator and produces zero crashes; the weapon-type pool is never shown as if it were the copy's perks.
- **SC-006**: A user can identify the right copy and record the intended per-column roll in under 90 seconds without an external tool (e.g. DIM).
- **SC-007**: Zero regression in existing `instanceId` attachment, slot compatibility, occupied-slot replace confirmation, and stale-item handling, verified by automated tests.

## Assumptions

- This feature **reuses 010's** instance carousel, the weapon perk-selection UI shell, per-copy `instanceId` persistence, and the `PUT` set-item write path with `selectedPerks`; the change is to drive them from **real per-copy data** instead of the weapon-type approximation.
- Capturing each copy's per-column alternates requires storing **more than the single equipped plug per socket** that is stored today (a per-socket / per-column structure). Copies synced before the capability exists lack this data; opening the grid for such a copy **automatically triggers a re-sync** to backfill it (FR-018), with the equipped-only state shown only while that refresh is pending or if it fails.
- "Columns" means the weapon's **perk-bearing** sockets grouped by category (barrel, magazine, trait column(s), intrinsic/frame, origin trait, masterwork); cosmetic/utility sockets are excluded (FR-021).
- Selection is **one perk per column**; the persisted roll continues to use the existing set-item perk-selection field (one chosen hash per column), keyed to the copy's `instanceId`.
- Recording a selection is a **build-authoring** action only; it does not insert/change perks on the in-game item and does not define a "roll to hunt" suggestion.
- Debug Sets is the verification venue (signed-in, non-production), consistent with 010; production UI inherits behavior when promoted.
- Weapon-type perk-pool resolution (010's `perk-options`) may remain as the degradation source of last resort only where it does not contradict FR-015 (per-copy data is preferred; the type pool must never be shown as the copy's real perks).

## Dependencies

- [010-instance-disambiguation](../010-instance-disambiguation/spec.md): instance carousel, perk-selection UI shell, per-copy `instanceId` persistence, and `PUT` set-item write path.
- [003-owned-inventory-instances](../003-owned-inventory-instances/spec.md): per-copy instance listing with equipped plugs, power, location, and stable identifier.
- [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md): set item lookup and attachment.
- [001-build-sets-synergies](../001-build-sets-synergies/spec.md): set-item slot rules and occupied-slot replace confirmation.
- **Per-copy perk data source**: resolving each copy's per-column available perks (equipped plus alternates) requires per-instance reusable-plug data plus, for random-roll sockets, the resolved plug set for that socket, and manifest socket-category definitions to group sockets into columns. This reopens 010's deferred research item **R2 (per-instance reusable plugs)** and the **"true per-column grouping"** follow-on, both of which 010 intentionally deferred (see [010 research.md](../010-instance-disambiguation/research.md)).

## Context & Known Constraints *(for research/planning, not final design)*

- The current inventory sync requests a limited set of Bungie profile components and keeps only the **single equipped plug hash per socket**, discarding alternates; per-copy alternate perks are therefore neither captured nor stored today.
- DIM derives the per-copy grid from **per-instance reusable plugs** (Bungie item component 310, `DestinyItemReusablePlugsComponent` — per socket, the plug items the instance can insert with `canInsert`/`enabled`) and, for random rolls, the socket's `randomizedPlugSetHash` resolved via the profile plug-sets component.
- Perks are currently stored as a **flat plug-hash list** with no column index; capturing per-column alternates likely needs a per-socket structure (e.g. socket/column → options) and a corresponding sync/schema change — the surface 010 intentionally avoided.
- The weapon-type `perk-options` endpoint from 010 exposes the type's curated ∪ randomized pool (identical for every copy); this feature must present the **specific copy's** perks instead.
