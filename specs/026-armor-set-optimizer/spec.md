# Feature Specification: Armor Set Optimizer

**Feature Branch**: `026-armor-set-optimizer`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "I want to support creating sets from a build and attaching right away. In Sets, I want to do more advanced armor evaluation so that I can get a set of armor at once. Example: melee focused set with 2pcs from 2 different armor sets, a specific Exotic, prioritized stats, DIM-like combinations that support constraints, including bonuses from potential mods that increase relevant stats. Consider frameworks/libraries or porting/using DIM's version."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [business-rules.md](../business-rules.md)

**Prior slices**: [001](../001-build-sets-synergies/spec.md) (sets/builds), [008](../008-sets-catalog-lookup/spec.md) (armor lookup / set bonus / per-piece stats), [019](../019-soft-stat-targets/spec.md) (soft stat targets), [003](../003-owned-inventory-instances/spec.md) (owned instances)

## Iteration Scope

**In scope (this iteration)**: (1) Create one or more Sets from an existing Build and attach them to that build immediately; (2) advanced **Armor Set** evaluation that returns ranked full-kit armor combinations under user constraints (exotic, set-bonus coverage goals, stat priorities), including estimated bonuses from candidate armor mods; (3) apply a chosen combination into an Armor Set (and optionally a companion Mod Set) with optional immediate attach. Verification remains debug/API-first per project convention.

**Out of scope (this iteration)**: Production-polished optimizer UX; weapon-set or fashion-set “fill from build” beyond what is needed to snapshot currently attached gear; automatic background re-optimization when inventory changes; PvP/activity-specific loadout scoring beyond the user’s stated constraints; shipping a third-party optimizer as a black-box dependency without validation (evaluation of DIM/other approaches is deferred to planning/research).

**Verification**: Signed-in debug Builds and Sets surfaces plus automated contract tests exercise create-from-build → attach, constraint → combination list → materialize set, and mod-aware estimates.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Sets from a Build and Attach Immediately (Priority: P1)

A user working on a Build wants to capture the current composed gear into reusable Sets and attach those Sets to the same Build in one flow — without manually recreating Armor (and related) Sets piece by piece and then finding them again in the attach picker.

**Why this priority**: Closes the compose → library loop (DBR-PUR-003/004, DBR-CMP-001). Users who already have a working loadout need a fast path to reusable Sets without leaving the Build.

**Independent Test**: On a Build with armor (and optionally weapons/mods) resolved via pins or attached sets, run “create sets from build,” confirm new Sets appear with the expected slot contents, and confirm those Sets are attached to the Build (live by default) without a separate attach step.

**Acceptance Scenarios**:

1. **Given** a Build whose default variant has armor filled across slots, **When** the user creates Sets from the Build with attach-now, **Then** an Armor Set is created containing the current armor identities/instances for filled slots and is attached to that Build immediately.
2. **Given** the Build also has weapon and/or mod selections, **When** the user includes those categories in create-from-build, **Then** corresponding Weapon and/or Mod Sets are created and attached the same way (empty categories are skipped).
3. **Given** a created Set would collide with an existing name for that set type, **When** create runs, **Then** the system either auto-suggests a unique name or rejects with a clear uniqueness error — never silently overwrites another Set.
4. **Given** attach-now succeeds, **When** the user opens the Build’s attachments, **Then** the new Sets appear as live attachments without requiring a second attach action.
5. **Given** the user declines attach-now (create only), **When** create completes, **Then** Sets are saved to the library and the Build’s attachments are unchanged.

---

### User Story 2 - Constrain a Full Armor Kit Search (Priority: P1)

A user wants a **full armor combination** (helmet, arms, chest, legs, class item as applicable) that satisfies constraints at once — for example: melee-focused priorities, a specific Exotic armor piece, and set-bonus goals such as **2-piece from armor set A and 2-piece from armor set B** — instead of picking pieces one slot at a time.

**Why this priority**: This is the core “advanced armor evaluation” value; per-piece catalog lookup (008) is insufficient for multi-constraint kits.

**Independent Test**: With a synced inventory containing enough armor to satisfy a known fixture of constraints (locked exotic + two distinct 2pc set-bonus goals + a primary prioritized stat), request combinations and confirm returned kits meet every hard constraint and are ranked by the stated priorities.

**Acceptance Scenarios**:

1. **Given** the user locks a specific Exotic armor item (by identity), **When** combinations are generated, **Then** every returned kit includes that Exotic in the correct slot and does not include a second exotic armor piece.
2. **Given** the user requires 2-piece coverage from set-bonus family A and 2-piece coverage from set-bonus family B, **When** combinations are generated, **Then** every returned kit satisfies both coverage goals (pieces counted toward each family are non-overlapping in the usual Destiny sense of active set bonuses).
3. **Given** the user sets an ordered or weighted priority among the EoF six stats (Class, Grenade, Melee, Super, Health, Weapons), **When** combinations are generated, **Then** results are ordered so higher-priority stats are favored in ranking (ties break by next priority, then total relevant stats).
4. **Given** soft stat targets exist on a linked Build (019), **When** the user starts optimization from that Build, **Then** those targets MAY seed the optimizer’s priorities/thresholds (user can still edit before searching).
5. **Given** no owned armor can satisfy a hard constraint, **When** search completes, **Then** the user sees an empty result with a clear explanation of which constraints could not be met — not unrelated kits.

---

### User Story 3 - Browse DIM-Like Combination Results (Priority: P2)

A user reviews a list of candidate armor combinations that meet their constraints, comparable in spirit to DIM’s loadout optimizer results: each row is a full kit with estimated totals, constraint satisfaction, and enough identity to compare alternatives before committing.

**Why this priority**: Constraint satisfaction alone is not enough; builders need to compare “good enough” kits the way they do in DIM.

**Independent Test**: From a successful constrained search, inspect the result list: each entry shows five-slot (or filled-slot) identities, estimated six-stat totals, set-bonus summary, and exotic; selecting one entry prepares materialization without applying until confirmed.

**Acceptance Scenarios**:

1. **Given** multiple valid combinations, **When** results are shown, **Then** each combination lists the armor pieces (name/slot/instance identity as available) and estimated EoF six-stat totals.
2. **Given** set-bonus constraints, **When** a combination is displayed, **Then** the active 2pc/4pc summary for that kit is visible.
3. **Given** the user selects a combination, **When** they have not yet confirmed, **Then** no Armor Set is created or modified.
4. **Given** more results than a practical page, **When** browsing, **Then** the user can still review a useful top slice (ranked) and is not forced to load an unbounded dump in the verification UI.

---

### User Story 4 - Include Candidate Mod Stat Bonuses in Evaluation (Priority: P2)

When ranking combinations, the user wants estimates to include **potential armor mods that increase relevant stats** (within energy capacity), so kits are not judged on base armor rolls alone when mods would close a soft target or lift a prioritized stat.

**Why this priority**: Matches DBR-STAT-005 (full loadout estimate includes mods) and the user’s explicit request; without mods, melee-focused kits are systematically undervalued.

**Independent Test**: Fixture two kits with similar base rolls where only one can reach a Melee soft target after plausible mod assignment; confirm the mod-aware ranking prefers the kit that reaches the target (or scores higher on prioritized Melee) and exposes which candidate mods were assumed.

**Acceptance Scenarios**:

1. **Given** mod-aware evaluation is enabled, **When** combinations are ranked, **Then** estimated totals include assumed armor mods that grant relevant stats, subject to per-piece energy capacity (tier ≤4 → 10; tier 5 → 11).
2. **Given** a combination’s estimate includes assumed mods, **When** the user views that combination, **Then** they can see which mods were assumed (at least by name/slot) so the estimate is auditable.
3. **Given** no legal mod assignment improves a prioritized stat further under energy rules, **When** the kit is scored, **Then** the estimate uses the best legal assignment found (or base-only if none apply) without inventing illegal over-capacity loadouts.
4. **Given** the user disables mod-aware evaluation, **When** combinations are ranked, **Then** estimates use armor (and other non-mod known bonuses already in scope) without assuming new mods.

---

### User Story 5 - Materialize a Combination into Sets (Priority: P2)

After choosing a combination, the user turns it into an Armor Set (and optionally a Mod Set reflecting assumed mods) and can attach those Sets to a Build immediately — connecting the optimizer back to composition.

**Why this priority**: Completes the value loop; ranked results that cannot become Sets would leave the library unused.

**Independent Test**: Select a combination from search results, confirm materialize (+ optional attach to a Build), reload Sets/Build attachments, and verify slots and optional mod plugs match the chosen combination.

**Acceptance Scenarios**:

1. **Given** a selected combination, **When** the user confirms materialize, **Then** an Armor Set is created/updated with one item per filled armor slot from the combination (respecting existing Armor Set slot rules, including at most one exotic armor).
2. **Given** the combination included assumed mods and the user opts to save them, **When** materialize completes, **Then** a Mod Set is created/updated with those mods organized per armor piece within energy rules.
3. **Given** the user chooses attach-now to a Build, **When** materialize completes, **Then** the new/updated Sets are attached to that Build immediately (live by default).
4. **Given** materialize would violate set name uniqueness or exotic-slot rules, **When** confirm runs, **Then** the operation fails with a clear error and no partial silent attach.

---

### User Story 6 - Run Advanced Evaluation from Sets (Priority: P3)

A user opens Sets (without starting from a Build) and runs the same constrained armor evaluation to produce a new Armor Set for their library — optionally attaching later.

**Why this priority**: Supports the secondary library journey (DAC-P2) and the user’s “In Sets…” request; Build-seeded flow (P1/P2) already delivers the primary path.

**Independent Test**: From debug Sets, define constraints without a Build context, generate combinations, materialize an Armor Set, and confirm it appears in the Sets list.

**Acceptance Scenarios**:

1. **Given** the user is on Sets with no Build selected, **When** they run constrained armor evaluation, **Then** they can set exotic, set-bonus goals, and stat priorities manually.
2. **Given** a successful materialize from Sets, **When** the Sets list refreshes, **Then** the new Armor Set is present and editable like any other Armor Set.
3. **Given** the user later attaches that Set to a Build, **When** attach succeeds, **Then** behavior matches existing live-attach rules (no special optimizer-only attachment type).

---

### Edge Cases

- Inventory not synced or empty for the class → empty results with a clear “sync / no eligible armor” message.
- Exotic class item vs classic exotic armor → exotic identity lock follows existing build/exotic rules; kits never include two exotic armor pieces.
- Incomplete kits (missing a slot in inventory) → either omit that slot with an explicit gap flag or exclude the kit; never fabricate unowned pieces.
- Conflicting set-bonus goals that are mathematically impossible with five slots → empty results explaining the conflict.
- Wishlist-only / unowned catalog pieces → out of scope for combination search (owned inventory only); create-from-build may still snapshot wishlist pins as set items per existing wishlist rules where applicable.
- Manifest refresh making a piece stale → soft-stale behavior consistent with existing Sets rules; optimizer should not prefer invalid references for new assignments.
- Very large inventories → search still returns a ranked top slice in a usable time for interactive verification; user is told when results are truncated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create Sets from a Build’s current composed gear (Armor at minimum; Weapons and Mods when present and selected) in one action.
- **FR-002**: Users MUST be able to attach newly created Sets to that same Build immediately as part of the create-from-build action (opt-out allowed).
- **FR-003**: Create-from-build MUST respect existing Set type rules (slot occupancy, exotic limits, name uniqueness per type) and MUST NOT silently overwrite unrelated Sets.
- **FR-004**: Users MUST be able to request full-kit armor combinations from **owned** inventory subject to hard constraints: locked exotic identity (optional), set-bonus coverage goals (e.g. 2pc A + 2pc B), and class/eligibility rules.
- **FR-005**: Users MUST be able to express stat priorities and/or soft thresholds across the EoF six stats for ranking combinations.
- **FR-006**: When started from a Build that has soft stat targets, the system MUST offer those targets as the default seed for optimizer priorities/thresholds (editable before search).
- **FR-007**: The system MUST return only combinations that satisfy all stated hard constraints; soft targets affect ranking/warnings, not hard exclusion, unless the user marks a threshold as required for this search.
- **FR-008**: Each returned combination MUST expose piece identities, estimated six-stat totals, set-bonus summary, and exotic slot contents sufficient to compare alternatives.
- **FR-009**: Users MUST be able to enable or disable inclusion of candidate armor-mod stat bonuses in estimates; when enabled, assumed mods MUST respect energy capacity and remain visible/auditable.
- **FR-010**: Users MUST be able to materialize a selected combination into an Armor Set and optionally a Mod Set, with optional immediate attach to a Build.
- **FR-011**: The same constrained evaluation and materialize flow MUST be available from Sets without a Build context (manual constraint entry).
- **FR-012**: Empty or failed searches MUST explain which constraints could not be satisfied.
- **FR-013**: Optimizer outputs used for new set assignments MUST NOT introduce invalid or stale manifest references beyond existing soft-stale display rules.
- **FR-014**: Verification MUST be possible via signed-in debug/API surfaces without requiring production-polished UI.

### Key Entities

- **Armor Optimization Request**: User-defined search intent — class, optional Build link, locked exotic, set-bonus coverage goals, stat priorities/thresholds, mod-aware flag, inventory scope (owned).
- **Armor Combination**: A candidate full (or explicitly gapped) armor kit — piece references per slot, estimated stats, set-bonus summary, optional assumed mods, rank/score explanation.
- **Set Bonus Coverage Goal**: A requirement such as “at least 2 pieces from set-bonus family X” (and optionally 4pc); multiple goals may be combined.
- **Materialized Sets**: Armor Set and optional Mod Set produced from a chosen combination; may be newly created or an explicit update target.
- **Create-from-Build Result**: One or more Sets derived from a Build’s current composition, with optional immediate attachments recorded on that Build.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a Build with a filled armor loadout, a user can create and attach an Armor Set in one flow in under 1 minute (excluding inventory sync time).
- **SC-002**: For a fixture inventory and a constraint set matching the melee + dual-2pc + exotic example, 100% of returned combinations satisfy every hard constraint in automated checks.
- **SC-003**: In the same fixture, at least one returned combination is among the top-ranked kits a human reviewer would accept when comparing estimated prioritized stats (agreement on top result or top-3 membership in review).
- **SC-004**: With mod-aware evaluation on, kits that only meet a soft Melee target after legal mods are ranked above otherwise similar kits that cannot meet it after mods (demonstrated by a fixed test fixture).
- **SC-005**: Users can materialize a chosen combination into an Armor Set and see it attached to a Build (when requested) without a second manual attach step, with ≤2 confirmations total.
- **SC-006**: Empty-constraint-failure cases show a actionable reason in 100% of automated empty-result fixtures (no silent empty list without explanation).
- **SC-007**: Interactive constrained search on a large but realistic owned inventory returns an initial ranked result slice quickly enough for debug verification (target: first useful results feel interactive — under ~5 seconds on typical dev hardware for the fixture size used in tests; document measured baseline in planning if fixture grows).

## Assumptions

- Combination search uses **owned inventory instances** for the Build’s class (or the class selected in Sets); catalog-wide theorycraft without ownership is out of scope for this iteration.
- Hard Destiny rules already in domain remain in force: one exotic armor, energy capacity by tier, Armor Set slot rules, live attach by default (DBR-CMP-*, DBR-MOD-*, DBR-STAT-*).
- “2pcs from 2 different armor sets” means user-configurable **set-bonus coverage goals** (at least 2pc of family A and at least 2pc of family B), not a single fixed preset.
- Stat “focus” is expressed via ordered/weighted priorities and optional thresholds aligned with the EoF six and existing soft-stat targets; it is not a separate seventh scoring system.
- Mod-aware evaluation considers **stat-granting armor mods** (and capacity-legal assignments). Activity-gated or highly situational mods may be included with soft warnings later; v1 may limit the candidate mod pool to clearly stat-relevant plugs.
- Create-from-build snapshots **current composition** (resolved pins / attached set contents as shown on the Build), not a re-optimized kit — optimization is a separate action that can then materialize + attach.
- Debug/API-first delivery matches prior slices; production polish is deferred.
- Planning/research SHOULD evaluate established Destiny loadout-optimizer approaches (including DIM Loadout Optimizer algorithms/patterns and any reusable libraries or ports) for correctness and licensing fit; the product requirement is DIM-**like** constrained combination quality, not a mandatory dependency on DIM itself.

## Dependencies

- Owned inventory instances with armor stats (003 / post-008 sync).
- Armor set-bonus identity and catalog filters (008).
- Soft stat targets on Builds (019) for seeding priorities.
- Existing Sets CRUD, attach, and exotic/slot validation (001 / business rules).
- Soft guidance / full-loadout estimate concepts (017/019) for consistent stat accounting where reused.
