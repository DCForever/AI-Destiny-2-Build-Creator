# Feature Specification: Armor Set Optimizer

**Feature Branch**: `026-armor-set-optimizer`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "I want to support creating sets from a build and attaching right away. In Sets, I want to do more advanced armor evaluation so that I can get a set of armor at once. Example: melee focused set with 2pcs from 2 different armor sets, a specific Exotic, prioritized stats, DIM-like combinations that support constraints, including bonuses from potential mods that increase relevant stats. Consider frameworks/libraries or porting/using DIM's version."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [business-rules.md](../business-rules.md)

**Prior slices**: [001](../001-build-sets-synergies/spec.md) (sets/builds), [008](../008-sets-catalog-lookup/spec.md) (armor lookup / set bonus / per-piece stats), [019](../019-soft-stat-targets/spec.md) (soft stat targets), [003](../003-owned-inventory-instances/spec.md) (owned instances)

## Clarifications

### Session 2026-07-14

- Q: When create-from-build or materialize runs with attach-now and the variant already has a live Set of that type attached, what happens? → A: Replace same-type live attachment(s) on the variant (detach old → attach new).
- Q: When inventory cannot fill every armor slot under hard constraints, return gapped kits or only complete kits? → A: Only complete five-slot kits; exclude incomplete combinations.
- Q: On create-from-build / materialize, if the intended Set name already exists for that type? → A: Auto-generate a unique name with numeric suffix; never fail solely for name collision.
- Q: Does materialize create new Sets or update existing ones? → A: Always create new Armor Set (+ optional Mod Set); never overwrite an existing Set’s items. **Superseded below for constrained Sets.**
- Q: How should stat priorities rank combinations when soft thresholds do not hard-filter? → A: Ordered lexicographic on estimated stats (priority order), then total of those stats.
- Q: Should optimizer constraints live on the Armor Set so better inventory can refresh the kit later? → A: Yes — persist constraints on the Armor Set.
- Q: When a better combination is found for a Set that already stores constraints, how is it applied? → A: Update items in place on that Armor Set (constraints unchanged unless edited); optionally refresh a linked Mod Set.
- Q: When should a constrained Armor Set be re-evaluated against newer inventory? → A: After inventory sync, surface a soft suggestion that a better kit exists; user confirms apply (no silent auto-apply).
- Q: After sync, which constrained Armor Sets are checked for a better kit? → A: Only those attached to ≥1 Build; opening an unattached constrained Set also triggers a check. Manual refresh remains available.
- Q: When create-from-build snapshots an Armor Set, which optimizer constraints are seeded? → A: Seed exotic lock + soft-stat priorities/thresholds from the Build when present; set-bonus goals start empty until the user adds them.
- Q: Which Armor Sets count as constrained for post-sync / on-open improvement checks? → A: Any Set with a stored optimizer-constraints payload (exotic and/or soft stats only is enough; empty set-bonus goals OK). User may clear constraints to opt out.
- Q: How should “already in another Armor Set” affect optimization? → A: Annotate pieces/kits with other-Set membership; optional soft prefer-reuse ranks higher-reuse kits after lexicographic stats (user-toggleable).
- Q: Which other Armor Sets count for “already used elsewhere”? → A: All other Armor Sets owned by the user; exclude the Set currently being optimized/refreshed.
- Q: When prefer-reuse tie-breaks two kits, what is counted? → A: Number of kit pieces that appear in ≥1 other Armor Set (0–5).
- Q: Do soft-removed Set items count as used in another Set? → A: No — only active (non-removed) Set items count.
- Q: Is prefer-reuse persisted on the Armor Set’s constraints? → A: Yes — store `preferReuse` on the Set’s optimizer constraints (default off); per-search override optional.

## Iteration Scope

**In scope (this iteration)**: (1) Create one or more Sets from an existing Build and attach them to that build immediately; (2) advanced **Armor Set** evaluation that returns ranked full-kit armor combinations under user constraints (exotic, set-bonus coverage goals, stat priorities), including estimated bonuses from candidate armor mods; (3) **persist those constraints on the Armor Set** when materializing; (4) **re-run optimization against a Set’s stored constraints** and apply a better complete kit by **updating that Set’s items in place** (optional Mod Set refresh); (5) after inventory sync, **soft-suggest** improvements for constrained Armor Sets **attached to Builds** (and when opening an unattached constrained Set); user confirms apply; (6) optional immediate attach on first materialize; (7) **annotate** armor instances already used in other Armor Sets and optionally **soft-prefer reuse** (after stat ranking) to help reduce duplicate pieces. Verification remains debug/API-first per project convention.

**Out of scope (this iteration)**: Production-polished optimizer UX; weapon-set or fashion-set “fill from build” beyond what is needed to snapshot currently attached gear; **silent automatic apply** of better kits without user confirmation; PvP/activity-specific loadout scoring beyond the user’s stated constraints; shipping a third-party optimizer as a black-box dependency without validation (evaluation of DIM/other approaches is deferred to planning/research).

**Verification**: Signed-in debug Builds and Sets surfaces plus automated contract tests exercise create-from-build → attach, constraint → combination list → materialize set, and mod-aware estimates.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Sets from a Build and Attach Immediately (Priority: P1)

A user working on a Build wants to capture the current composed gear into reusable Sets and attach those Sets to the same Build in one flow — without manually recreating Armor (and related) Sets piece by piece and then finding them again in the attach picker.

**Why this priority**: Closes the compose → library loop (DBR-PUR-003/004, DBR-CMP-001). Users who already have a working loadout need a fast path to reusable Sets without leaving the Build.

**Independent Test**: On a Build with armor (and optionally weapons/mods) resolved via pins or attached sets, run “create sets from build,” confirm new Sets appear with the expected slot contents, and confirm those Sets are attached to the Build (live by default) without a separate attach step.

**Acceptance Scenarios**:

1. **Given** a Build whose default variant has armor filled across slots, **When** the user creates Sets from the Build with attach-now, **Then** an Armor Set is created containing the current armor identities/instances for filled slots and is attached to that Build immediately.
2. **Given** the Build has exotic armor identity and/or soft stat targets, **When** an Armor Set is created from the Build, **Then** the Set’s stored optimizer constraints are seeded with that exotic lock (when set) and soft-stat priorities/thresholds derived from those targets; set-bonus coverage goals remain empty until the user adds them.
3. **Given** the Build also has weapon and/or mod selections, **When** the user includes those categories in create-from-build, **Then** corresponding Weapon and/or Mod Sets are created and attached the same way (empty categories are skipped).
4. **Given** a created Set would collide with an existing name for that set type, **When** create runs, **Then** the system auto-assigns a unique name with a numeric suffix (e.g. `… Armor (2)`) and proceeds — it never silently overwrites another Set and does not fail solely for name collision.
5. **Given** attach-now succeeds, **When** the user opens the Build’s attachments, **Then** the new Sets appear as live attachments without requiring a second attach action.
6. **Given** the user declines attach-now (create only), **When** create completes, **Then** Sets are saved to the library and the Build’s attachments are unchanged.
7. **Given** the variant already has a live Armor Set attached, **When** create-from-build attaches a new Armor Set with attach-now, **Then** the previous Armor Set is detached and only the new Armor Set remains attached for that type (same replace rule for Weapon and Mod categories when those are included).

---

### User Story 2 - Constrain a Full Armor Kit Search (Priority: P1)

A user wants a **full armor combination** (helmet, arms, chest, legs, class item as applicable) that satisfies constraints at once — for example: melee-focused priorities, a specific Exotic armor piece, and set-bonus goals such as **2-piece from armor set A and 2-piece from armor set B** — instead of picking pieces one slot at a time.

**Why this priority**: This is the core “advanced armor evaluation” value; per-piece catalog lookup (008) is insufficient for multi-constraint kits.

**Independent Test**: With a synced inventory containing enough armor to satisfy a known fixture of constraints (locked exotic + two distinct 2pc set-bonus goals + a primary prioritized stat), request combinations and confirm returned kits meet every hard constraint and are ranked by the stated priorities.

**Acceptance Scenarios**:

1. **Given** the user locks a specific Exotic armor item (by identity), **When** combinations are generated, **Then** every returned kit includes that Exotic in the correct slot and does not include a second exotic armor piece.
2. **Given** the user requires 2-piece coverage from set-bonus family A and 2-piece coverage from set-bonus family B, **When** combinations are generated, **Then** every returned kit satisfies both coverage goals (pieces counted toward each family are non-overlapping in the usual Destiny sense of active set bonuses).
3. **Given** the user sets an ordered priority among the EoF six stats (Class, Grenade, Melee, Super, Health, Weapons), **When** combinations are generated, **Then** results are ranked by **lexicographic** comparison of estimated stats in that priority order (higher first); ties break by the sum of the prioritized stats, then remaining totals as needed.
4. **Given** soft stat targets exist on a linked Build (019), **When** the user starts optimization from that Build, **Then** those targets MAY seed the optimizer’s priorities/thresholds (user can still edit before searching).
5. **Given** no owned armor can satisfy a hard constraint, **When** search completes, **Then** the user sees an empty result with a clear explanation of which constraints could not be met — not unrelated kits.

---

### User Story 3 - Browse DIM-Like Combination Results (Priority: P2)

A user reviews a list of candidate armor combinations that meet their constraints, comparable in spirit to DIM’s loadout optimizer results: each row is a full kit with estimated totals, constraint satisfaction, and enough identity to compare alternatives before committing.

**Why this priority**: Constraint satisfaction alone is not enough; builders need to compare “good enough” kits the way they do in DIM.

**Independent Test**: From a successful constrained search, inspect the result list: each entry shows five-slot (or filled-slot) identities, estimated six-stat totals, set-bonus summary, and exotic; selecting one entry prepares materialization without applying until confirmed.

**Acceptance Scenarios**:

1. **Given** multiple valid combinations, **When** results are shown, **Then** each combination lists all five armor pieces (name/slot/instance identity as available) and estimated EoF six-stat totals.
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

### User Story 5 - Materialize a Combination into a Constrained Armor Set (Priority: P2)

After choosing a combination, the user turns it into an Armor Set that **stores the optimizer constraints used for the search**, optionally creates a companion Mod Set, and can attach immediately — so the Set remains a living constrained kit, not a one-off snapshot.

**Why this priority**: Completes the value loop and enables later refresh when inventory improves.

**Independent Test**: Materialize a combination with known constraints; reload the Armor Set; confirm pieces match and stored constraints equal the search request (exotic, set-bonus goals, priorities/thresholds, mod-aware flag as applicable).

**Acceptance Scenarios**:

1. **Given** a selected combination from a constrained search, **When** the user confirms first-time materialize, **Then** a **new** Armor Set is created with the five pieces and the **search constraints are persisted** on that Set.
2. **Given** the combination included assumed mods and the user opts to save them, **When** materialize completes, **Then** a **new** Mod Set is created (or linked) with those mods; the Armor Set records the link when applicable.
3. **Given** the user chooses attach-now to a Build, **When** materialize completes, **Then** the new Sets are attached live, **replacing** any existing live attachment of the same set type on that variant.
4. **Given** materialize would violate exotic-slot rules or ownership checks, **When** confirm runs, **Then** the operation fails with a clear error and no partial silent attach. Name collisions are resolved by auto-suffix.

---

### User Story 5b - Refresh a Constrained Armor Set from Inventory (Priority: P2)

As the user acquires better armor, they re-run evaluation using the **constraints stored on an existing Armor Set** and apply an improved complete kit by **updating that Set’s items in place**, without creating a duplicate Set or breaking existing Build attachments to it.

**Why this priority**: Core reason to persist constraints on the Set; without in-place refresh, constrained Sets go stale.

**Independent Test**: Fixture Armor Set with stored dual-2pc + exotic + Melee priority; add a superior owned piece that still satisfies constraints; refresh; confirm Set id unchanged, items updated, constraints unchanged, and attached Builds still reference the same Set id.

**Acceptance Scenarios**:

1. **Given** an Armor Set with stored constraints, **When** the user runs refresh/optimize-from-set, **Then** search uses those constraints (editable for this run only if the product allows override — default is stored values) against current owned inventory.
2. **Given** a better complete combination than the current pieces (lexicographic rank), **When** the user confirms apply, **Then** the Armor Set’s slot items are **replaced in place**; Set id and name remain the same; stored constraints remain unless the user explicitly edits and saves them.
3. **Given** no better valid combination exists, **When** refresh completes, **Then** the user is told the current kit is already best (or shown equals); items are not needlessly rewritten.
4. **Given** a linked Mod Set and mod-aware estimates, **When** apply includes assumed mods, **Then** the linked Mod Set may be updated in place to match (or created if missing and user opts in).
5. **Given** a successful inventory sync and constrained Armor Sets **attached to at least one Build**, **When** a better complete kit exists under a Set’s stored constraints, **Then** the user sees a **soft suggestion** (not an automatic item swap); **When** they confirm apply, **Then** items update in place per scenarios 2–4.
6. **Given** sync completes and no **attached** constrained Set has a better kit, **When** the user views Builds, **Then** no improvement suggestion is shown for those Sets.
7. **Given** an unattached Armor Set with stored constraints, **When** the user opens that Set, **Then** the system checks for a better kit and soft-suggests if one exists (same confirm-to-apply rule).

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

### User Story 7 - Cross-Set Piece Reuse Awareness (Priority: P2)

When optimizing (or refreshing) an Armor Set, the user can see which candidate pieces are **already pinned in other Armor Sets**, and optionally prefer combinations that **reuse** those instances so one physical piece can support multiple Sets and they can delete duplicate rolls.

**Why this priority**: Directly supports vault hygiene with large inventories (~80/slot); secondary to hard constraints and stat lexicographic ranking.

**Independent Test**: Fixture two Armor Sets sharing one instance id on a slot; optimize a third (or refresh one) with prefer-reuse on; confirm that instance is annotated with the other Set name(s) and that equal-stat kits ranking favors higher reuse count when the toggle is on.

**Acceptance Scenarios**:

1. **Given** an owned armor instance already used in Armor Set X (and the search is not refreshing X), **When** it appears in an optimize combination, **Then** the piece (and/or combination) is annotated with Set X’s identity (name/id). Membership is considered across **all** of the user’s other Armor Sets.
2. **Given** prefer-reuse is **off**, **When** combinations are ranked, **Then** order matches lexicographic stats only (reuse annotations still visible).
3. **Given** prefer-reuse is **on** and two combinations are equal on lexicographic stats (and prioritized-stat sum tie-break), **When** ranked, **Then** the combination with the higher **reuse piece count** (how many of its five pieces appear in ≥1 other Armor Set) ranks higher.
4. **Given** prefer-reuse is **on** and combination A has better prioritized stats than B, **When** ranked, **Then** A still ranks above B even if B reuses more pieces (stats remain primary).

---

### Edge Cases

- Inventory not synced or empty for the class → empty results with a clear “sync / no eligible armor” message.
- Exotic class item vs classic exotic armor → exotic identity lock follows existing build/exotic rules; kits never include two exotic armor pieces.
- Incomplete kits (missing a slot in inventory under constraints) → **excluded**; optimizer returns only combinations with all five armor slots filled. Never fabricate unowned pieces. If no complete kit exists, empty result with explanation.
- Conflicting set-bonus goals that are mathematically impossible with five slots → empty results explaining the conflict.
- Wishlist-only / unowned catalog pieces → out of scope for combination search (owned inventory only); create-from-build may still snapshot wishlist pins as set items per existing wishlist rules where applicable.
- Manifest refresh making a piece stale → soft-stale behavior consistent with existing Sets rules; optimizer should not prefer invalid references for new assignments.
- Very large inventories → search still returns a ranked top slice in a usable time for interactive verification; user is told when results are truncated.
- Refresh finds no improvement → current kit retained; user sees a clear “already optimal under constraints” (or equivalent) outcome.
- Post-sync suggestion dismissed → Set items unchanged; suggestion may reappear on a later sync if still relevant.
- User clears stored constraints → Set no longer receives post-sync / on-open improvement suggestions until constraints are set again.
- User edits stored constraints to something currently unsatisfiable → search empty with explanation; existing items remain until a successful apply.
- Piece used only in the Set currently being refreshed → does not count as “other Set” reuse for that search (self is excluded from reuse annotations / prefer-reuse count).
- Soft-removed Set items → ignored for reuse annotations and prefer-reuse counts.
- Prefer-reuse on with no shared pieces → ranking identical to prefer-reuse off aside from empty annotations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create Sets from a Build’s current composed gear (Armor at minimum; Weapons and Mods when present and selected) in one action.
- **FR-001a**: When create-from-build creates an Armor Set, the system MUST seed stored optimizer constraints with the Build’s exotic armor identity (when set) and soft-stat priorities/thresholds derived from the Build’s soft stat targets (when present). Set-bonus coverage goals MUST start empty. Users MAY add or edit constraints afterward (FR-010b).
- **FR-002**: Users MUST be able to attach newly created Sets to that same Build immediately as part of the create-from-build action (opt-out allowed).
- **FR-002a**: When attach-now attaches a Set and the variant already has a live attachment of the **same set type**, the system MUST detach the previous same-type attachment(s) and attach the new Set (replace-by-type). Other set types on the variant remain unchanged. Detached Sets remain in the library.
- **FR-003**: Create-from-build MUST respect existing Set type rules (slot occupancy, exotic limits) and MUST NOT silently overwrite unrelated Sets. On name collision within the set type, the system MUST auto-assign a unique name via numeric suffix rather than failing the request.
- **FR-003a**: Materialize MUST use the same auto-unique naming behavior when the requested Armor/Mod Set name is already taken for that type.
- **FR-004**: Users MUST be able to request full-kit armor combinations from **owned** inventory subject to hard constraints: locked exotic identity (optional), set-bonus coverage goals (e.g. 2pc A + 2pc B), and class/eligibility rules. Every returned combination MUST include all five armor slots (helmet, arms, chest, legs, class item); incomplete kits MUST NOT appear in results.
- **FR-005**: Users MUST be able to express an **ordered** list of stat priorities and/or soft thresholds across the EoF six stats. Ranking MUST use lexicographic comparison on estimated stats in priority order, then the sum of prioritized stats for remaining ties (not opaque weighted scores in this iteration). When **prefer-reuse** is enabled, the **reuse piece count** (0–5: how many kit pieces appear in ≥1 other Armor Set) MUST apply only **after** those stat comparisons (soft tie-break), never above better stats.
- **FR-005a**: Optimize results MUST **annotate** each piece (or combination summary) with which **other** Armor Sets (all of the user’s Armor Sets except the Set being optimized/refreshed) already include that owned instance as an **active** item. Soft-removed items MUST NOT count. Users MUST be able to toggle **prefer-reuse**; the value MUST persist on the Armor Set’s optimizer constraints when saved (**default off** for new payloads). A per-search override MAY temporarily differ without saving unless the user saves constraints.
- **FR-006**: When started from a Build that has soft stat targets, the system MUST offer those targets as the default seed for optimizer priorities/thresholds (editable before search).
- **FR-007**: The system MUST return only combinations that satisfy all stated hard constraints; soft targets affect ranking/warnings, not hard exclusion, unless the user marks a threshold as required for this search.
- **FR-008**: Each returned combination MUST expose piece identities, estimated six-stat totals, set-bonus summary, exotic slot contents, and **cross-Set reuse annotations** sufficient to compare alternatives.
- **FR-009**: Users MUST be able to enable or disable inclusion of candidate armor-mod stat bonuses in estimates; when enabled, assumed mods MUST respect energy capacity and remain visible/auditable.
- **FR-010**: First-time materialize MUST create a **new** Armor Set (and optionally a **new** Mod Set) from a selected combination, persist the **optimizer constraints** used for that search onto the Armor Set, and support optional attach-now (replace-by-type per FR-002a). Auto-unique naming applies (FR-003a).
- **FR-010a**: Users MUST be able to re-run optimization using an Armor Set’s **stored constraints** and apply a chosen better combination by **updating that Set’s items in place** (same Set id). Stored constraints MUST NOT change unless the user explicitly edits and saves them.
- **FR-010b**: Users MUST be able to view and edit an Armor Set’s stored optimizer constraints (exotic lock, set-bonus goals, stat priorities/thresholds, mod-aware flag, **preferReuse**) independently of a one-off search.
- **FR-010c**: After a successful inventory sync, the system MUST evaluate Armor Sets that have a **stored optimizer-constraints payload** and are **attached to at least one Build**, and surface a **soft suggestion** when a better complete kit exists. Opening an **unattached** Armor Set that has stored constraints MUST also trigger the same check. A payload with only exotic and/or soft-stat fields (empty set-bonus goals) still qualifies. Clearing stored constraints opts the Set out of these checks. The system MUST NOT apply item changes until the user confirms. Manual refresh/re-optimize remains available without waiting for sync.
- **FR-010d**: Users MUST be able to clear an Armor Set’s stored optimizer constraints, after which post-sync and on-open improvement checks no longer apply to that Set until constraints are set again.
- **FR-011**: The same constrained evaluation and materialize flow MUST be available from Sets without a Build context (manual constraint entry); saving constraints onto the resulting Armor Set still applies.
- **FR-012**: Empty or failed searches MUST explain which constraints could not be satisfied.
- **FR-013**: Optimizer outputs used for new set assignments MUST NOT introduce invalid or stale manifest references beyond existing soft-stale display rules.
- **FR-014**: Verification MUST be possible via signed-in debug/API surfaces without requiring production-polished UI.

### Key Entities

- **Armor Optimization Request**: User-defined search intent — class, optional Build link, locked exotic, set-bonus coverage goals, stat priorities/thresholds, mod-aware flag, preferReuse, inventory scope (owned).
- **Armor Combination**: A candidate **complete** five-slot armor kit — piece references per slot (with cross-Set reuse annotations), estimated stats, set-bonus summary, optional assumed mods, reuse piece count, rank/score explanation. Gapped kits are out of scope for search results.
- **Set Bonus Coverage Goal**: A requirement such as “at least 2 pieces from set-bonus family X” (and optionally 4pc); multiple goals may be combined.
- **Armor Set Optimizer Constraints**: Persisted search intent on an **Armor Set** — locked exotic, set-bonus coverage goals, ordered stat priorities, optional thresholds / requireThresholds, includeModEstimates, **preferReuse** (default false). Presence of this payload (even partial) makes the Set eligible for improvement checks; clearing it opts out.
- **Materialized Sets**: First apply creates a new Armor Set (+ optional Mod Set) with constraints stored; later refresh **updates items in place** on that constrained Armor Set.
- **Create-from-Build Result**: One or more Sets derived from a Build’s current composition, with optional immediate attachments recorded on that Build. (Create-from-build does not itself invent optimizer constraints unless the user later adds them.)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a Build with a filled armor loadout, a user can create and attach an Armor Set in one flow in under 1 minute (excluding inventory sync time).
- **SC-002**: For a fixture inventory and a constraint set matching the melee + dual-2pc + exotic example, 100% of returned combinations satisfy every hard constraint in automated checks.
- **SC-003**: In the same fixture, at least one returned combination is among the top-ranked kits a human reviewer would accept when comparing estimated prioritized stats (agreement on top result or top-3 membership in review).
- **SC-004**: With mod-aware evaluation on, kits that only meet a soft Melee target after legal mods are ranked above otherwise similar kits that cannot meet it after mods (demonstrated by a fixed test fixture).
- **SC-005**: Users can materialize a chosen combination into an Armor Set (with constraints stored) and attach it to a Build (when requested) without a second manual attach step, with ≤2 confirmations total.
- **SC-005a**: After inventory improves, a user can refresh a constrained Armor Set and apply a better kit in place in under 1 minute; Set id remains stable for any Builds already attaching it.
- **SC-005b**: After sync, when a better kit exists for an **attached** constrained Armor Set, a soft suggestion appears; confirming apply updates items in place; dismissing leaves items unchanged. Opening an unattached constrained Set likewise soft-suggests when a better kit exists (verified in debug/API fixtures).
- **SC-006**: Empty-constraint-failure cases show a actionable reason in 100% of automated empty-result fixtures (no silent empty list without explanation).
- **SC-007**: Interactive constrained search on a large but realistic owned inventory returns an initial ranked result slice quickly enough for debug verification (target: first useful results feel interactive — under ~5 seconds on typical dev hardware for the fixture size used in tests; document measured baseline in planning if fixture grows).
- **SC-008**: In a fixture with two equal-stat kits where only one has a higher reuse piece count (pieces in ≥1 other Armor Set), enabling prefer-reuse ranks that kit first; disabling it does not use reuse for order; annotations remain visible in both cases.

## Assumptions

- Combination search uses **owned inventory instances** for the Build’s class (or the class selected in Sets); catalog-wide theorycraft without ownership is out of scope for this iteration.
- Optimizer results are **complete kits only** (all five armor slots); create-from-build may still snapshot partial composition when some slots are empty on the Build.
- Hard Destiny rules already in domain remain in force: one exotic armor, energy capacity by tier, Armor Set slot rules, live attach by default (DBR-CMP-*, DBR-MOD-*, DBR-STAT-*).
- “2pcs from 2 different armor sets” means user-configurable **set-bonus coverage goals** (at least 2pc of family A and at least 2pc of family B), not a single fixed preset.
- Optional **prefer-reuse** is a soft tie-break only after stats; **`preferReuse` defaults to off** and is stored on the Armor Set’s optimizer constraints (per-search override optional until saved).
- Cross-Set reuse is based on **owned instance ids** already present as **active** items on **any other Armor Set** the user owns (not merely same itemHash). Soft-removed Set items do not count. The Set under optimization/refresh is excluded from the “other” set list.
- Mod-aware evaluation considers **stat-granting armor mods** (and capacity-legal assignments). Activity-gated or highly situational mods may be included with soft warnings later; v1 may limit the candidate mod pool to clearly stat-relevant plugs.
- Create-from-build snapshots **current composition** (resolved pins / attached set contents as shown on the Build), not a re-optimized kit — optimization/refresh is a separate action. Armor Sets created this way **seed** exotic + soft-stat constraint fields from the Build; set-bonus goals are not inferred from equipped pieces.
- Attach-now (create-from-build and materialize) uses **replace-by-type**: detaches existing live attachments of the same set type on the variant before attaching the new Set(s); detached Sets stay in the library.
- Set names for create-from-build and **first-time** materialize are **auto-uniqued** with a numeric suffix on collision; users may still supply a preferred base name.
- Optimizer **constraints persist on the Armor Set**. First materialize creates the Set and stores constraints; later refresh applies better kits by **updating items in place** on that Set (linked Mod Set may update in place when applicable).
- Post-sync improvement checks run for Armor Sets that have a **stored constraints payload** and are **attached to ≥1 Build**; **opening** an unattached Set with a constraints payload also triggers a check. Exotic-only or soft-stats-only payloads qualify; empty set-bonus goals are OK. Clearing constraints opts out. Suggestions are **suggest-then-confirm** (soft); never silent auto-apply. Manual re-optimize remains available anytime.
- Debug/API-first delivery matches prior slices; production polish is deferred.
- Planning/research SHOULD evaluate established Destiny loadout-optimizer approaches (including DIM Loadout Optimizer algorithms/patterns and any reusable libraries or ports) for correctness and licensing fit; the product requirement is DIM-**like** constrained combination quality, not a mandatory dependency on DIM itself.

## Dependencies

- Owned inventory instances with armor stats (003 / post-008 sync).
- Armor set-bonus identity and catalog filters (008).
- Soft stat targets on Builds (019) for seeding priorities.
- Existing Sets CRUD, attach, and exotic/slot validation (001 / business rules).
- Soft guidance / full-loadout estimate concepts (017/019) for consistent stat accounting where reused.
