# Feature Specification: Owned Inventory Instance Detail

**Feature Branch**: `003-owned-inventory-instances`

**Created**: 2026-06-28

**Status**: Draft

**Input**: User description: "Expose owned inventory instances (not just manifest catalog rows) so signed-in users can find a weapon or armor piece they own and see which specific copy they have — including resolved perk names and basic instance metadata — comparable to a lightweight DIM item popup."

## Iteration Scope (UI)

**In scope (this iteration)**: APIs and domain logic to list and inspect individual owned inventory copies with resolved perk names and instance metadata; extension of the existing debug catalog experience to drill into instance detail; optional additive summary on owned catalog browse responses.

**Out of scope (this iteration)**: Production-polished inventory browser UI; full Destiny Item Manager parity (stat breakdown bars, kill tracker, weapon level/XP, ornaments, shaders, notes, tags, loadout sharing); pagination of instance lists; triggering inventory re-sync on every search.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - List Owned Copies of a Weapon or Armor Piece (Priority: P1)

A signed-in player who has synced their inventory searches for a weapon or armor piece they own (for example, by item name). Instead of seeing a single collapsed row with an ownership count, they see **each owned copy separately**, with enough detail to distinguish rolls: power level, where the copy lives (vault, character, or equipped), masterwork and crafted status, and a human-readable list of equipped perks and traits (barrel, magazine, traits, origin trait where applicable).

**Why this priority**: This is the core gap blocking roll-level set curation. Without per-instance visibility, users cannot pick a specific copy when building sets or validating synergies.

**Independent Test**: A signed-in user with synced inventory searches for an owned weapon that exists in multiple copies. They receive a list where each copy is a distinct entry with power, location, flags, and resolved perk names. Verifiable via debug catalog drill-down or direct instance listing without requiring set editor or production UI.

**Acceptance Scenarios**:

1. **Given** a signed-in user with synced inventory who owns three copies of the same weapon, **When** they request owned instances for that weapon, **Then** they see three separate entries (not one row with `ownedCount: 3`), each with distinct instance identity, power, location, and perk list.
2. **Given** a signed-in user viewing an owned armor piece with multiple copies across vault and characters, **When** they list instances for that armor, **Then** each copy shows power, location (vault, character, or equipped), masterwork status, and resolved mod or perk plugs where stored.
3. **Given** manifest data is available for perk resolution, **When** an instance is displayed, **Then** equipped plug identifiers are shown as readable perk or trait names.
4. **Given** a plug identifier cannot be resolved against the manifest, **When** an instance is displayed, **Then** the unknown plug is still listed using its identifier so the roll is not hidden.

---

### User Story 2 - Drill Into Instance Detail from Debug Catalog (Priority: P1)

A developer or QA tester uses the debug catalog with owned scope. After searching and selecting a catalog result, they can open instance-level detail (structured view or readable panel) showing the full instance payload—not only manifest-level fields such as name, icon, and slot.

**Why this priority**: Debug verification is the primary delivery channel for this iteration and is required to validate sync correctness and catalog behavior before production UI exists.

**Independent Test**: On the debug catalog page with owned scope, select an owned item and confirm instance detail appears with power, location, flags, plugs, and sync metadata. No production UI required.

**Acceptance Scenarios**:

1. **Given** the debug catalog is open with owned scope and the user is signed in with synced inventory, **When** they search for and select an owned item, **Then** they can view per-instance detail for that item without leaving the debug flow.
2. **Given** the debug catalog in a non-production environment, **When** an unauthenticated user attempts access, **Then** they receive the same authentication requirement as other debug and user-scoped features.
3. **Given** production deployment, **When** a user navigates to debug routes, **Then** those routes are not available (consistent with existing debug access rules).

---

### User Story 3 - Query Owned Instances by Item Identity (Priority: P2)

A user or downstream workflow knows the manifest identity of an item (from catalog search, set editor, or external reference). They request all owned instances matching that identity and receive roll detail for each copy so they can choose which specific instance to attach when building a set.

**Why this priority**: Set-building and synergy validation need a stable way to resolve "this weapon hash" into "these are my rolls," enabling future `instanceId` attachment without redesigning the API shape.

**Independent Test**: Given a known item identity and synced inventory, request instances filtered by that identity and receive a complete list with roll fields. Does not require catalog browse or debug UI if called directly.

**Acceptance Scenarios**:

1. **Given** a signed-in user with synced inventory and a known item identity, **When** they request owned instances for that identity, **Then** all matching copies are returned with instance identity, roll metadata, and resolved plugs.
2. **Given** a signed-in user with no copies of the requested item, **When** they request instances for that identity, **Then** they receive an empty result with a clear message—not an error implying sync failure.
3. **Given** instance listing responses, **When** a consumer stores a chosen instance identity for set attachment, **Then** the response shape includes a stable per-copy identifier suitable for future set item references.

---

### User Story 4 - Optional Owned Summary on Catalog Browse (Priority: P2)

When browsing the owned catalog (weapons or armor), each catalog row may optionally include a summary of owned copies (for example, power, perk names, location per copy) or a pointer to the dedicated instance listing—without removing or breaking existing manifest-level fields that current clients expect.

**Why this priority**: Improves discoverability from existing catalog flows but is additive; core value is delivered by User Stories 1 and 3 without this enhancement.

**Independent Test**: Request owned-scoped catalog browse and confirm existing fields remain present; when instance summary is enabled, additional instance data appears without breaking clients that ignore new fields.

**Acceptance Scenarios**:

1. **Given** owned-scoped catalog browse, **When** a client consumes the response, **Then** manifest-level fields (name, icon, slot, ownership indicators) remain available as today.
2. **Given** instance summary is included on a catalog row, **When** the user inspects that row, **Then** they see at least power, location, and perk summary per owned copy or a clear link to fetch full instance detail.

---

### User Story 5 - Stat and Tracker Display (Priority: P3 — Deferred)

Full weapon stat bars, kill tracker, and weapon experience display are deferred unless implementation cost is negligible. Document as future enhancement only; not required for v1 acceptance.

**Why this priority**: Users need roll and location identity first; stat bars and trackers are DIM-parity polish that does not block set curation.

**Independent Test**: Not applicable for v1; excluded from gate criteria.

**Acceptance Scenarios**:

1. **Given** v1 scope, **When** instance detail is shown, **Then** stat bars and kill tracker are not required fields.

---

### Edge Cases

- What happens when the user is signed in but has never synced inventory? Return an empty instance list with guidance to sync (consistent with existing owned-catalog sync prompt behavior).
- What happens when the user is not signed in? Return a clear authentication error; do not expose any inventory data.
- What happens when sync data is stale relative to manifest? Instance data still displays from last sync; perk names resolve when manifest is available; document `syncedAt` so consumers know freshness.
- What happens when an item has zero equipped plugs in stored data? Show instance metadata with an empty or minimal plug list; do not fail the request.
- What happens when the same perk appears in multiple socket types? List all equipped plugs; consumers may deduplicate if needed.
- What happens when inventory contains items no longer in manifest (removed content)? Show instance with stored hash and any persisted roll tags; unresolved plugs degrade gracefully.
- What happens when a user owns many copies of one item? Return the full user-scoped list without pagination in v1 (consistent with existing list API policy).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users to list their synced inventory instances as separate entries (one row per owned copy), not collapsed by manifest item identity alone.
- **FR-002**: System MUST support filtering instance lists by manifest item identity so all copies of a specific weapon or armor piece can be retrieved.
- **FR-003**: System MUST support filtering or searching instance lists by equipment category (weapon vs armor and applicable slot or bucket) and by text matching resolved perk or trait names where data allows.
- **FR-004**: Each instance response MUST include: unique instance identity, manifest item identity, equipment category or bucket, storage location (vault, character, or equipped), character association when applicable, power level, masterwork flag, crafted flag, equipped plug identifiers, resolved plug display names paired with identifiers, roll classification tags when computed, and last-sync timestamp.
- **FR-005**: System MUST resolve equipped plug identifiers to human-readable names when manifest data is available.
- **FR-006**: System MUST degrade gracefully when a plug identifier cannot be resolved—show the identifier rather than omitting the plug or failing the entire instance.
- **FR-007**: System MUST return a clear empty state when the user has not synced inventory, including actionable guidance to sync (consistent with existing owned-catalog patterns).
- **FR-008**: System MUST require authentication for all instance listing and detail capabilities; unauthenticated requests MUST NOT return inventory data.
- **FR-009**: System MUST expose instance listing and detail through the same debug verification surface used for catalog testing, subject to existing debug access rules (authentication required; unavailable in production).
- **FR-010**: System MUST preserve existing owned-scoped catalog browse behavior; instance detail MUST be additive and MUST NOT remove manifest-level browse capabilities.
- **FR-011**: Owned-scoped catalog responses MAY include an optional per-row summary of owned instances or a pointer to instance listing, without breaking clients that expect only manifest-level catalog fields.
- **FR-012**: Instance response shape MUST support future attachment of a specific instance identity to set items without requiring a breaking API change.
- **FR-013**: System MUST NOT require inventory re-sync on each catalog or instance search; consumers use the existing manual sync action.
- **FR-014**: System MUST NOT include full stat breakdown bars, kill tracker, weapon level or XP, ornaments, shaders, user notes, or loadout sharing in v1 instance detail.

### Key Entities

- **Inventory Instance**: A single owned copy of an item in a user's synced inventory. Distinguished by unique instance identity from the same manifest item identity as other copies. Carries power, location, flags, equipped plugs, roll tags, and sync metadata.
- **Resolved Plug**: A equipped modification on an instance (perk, trait, mod, barrel, magazine, origin trait, etc.) represented as a display name paired with its manifest identifier. May be unresolved when manifest lookup fails.
- **Instance Location**: Where a copy lives—vault, on a specific character, or equipped on a character—with character association when not in vault.
- **Catalog Item (manifest row)**: The definition-level item (name, icon, slot, element) used for browse and search; may summarize or link to multiple inventory instances when scope is owned.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a signed-in user with synced inventory searches for a weapon they own in multiple copies, they can view each copy as a separate entry with power, location, and perk names within one interaction flow (search → instance list).
- **SC-002**: In 95% of test cases with current manifest loaded, equipped plugs on owned weapons display as readable perk or trait names rather than raw identifiers only.
- **SC-003**: QA can verify sync correctness for at least one weapon and one armor piece via debug instance detail, confirming power, location, masterwork or crafted flags, and plug list match expectations after sync.
- **SC-004**: A user can identify which owned copy has two specified perks (for example, by name) without using an external inventory manager, in under 30 seconds for items with fewer than 10 copies.
- **SC-005**: Unauthenticated or never-synced users receive a clear, actionable response (auth error or sync prompt) with zero instance data leaked in 100% of unauthorized or empty-state test cases.
- **SC-006**: Existing owned-catalog browse clients continue to function without modification when instance summary fields are absent or ignored.

## Assumptions

- Bungie account sign-in and manual inventory sync already work and populate per-instance storage with instance identity, plugs, power, location, and flags.
- Manifest refresh is available for perk and trait name resolution; v1 does not require sync pipeline changes unless stored plug data is insufficient for resolution.
- The existing inventory storage after sync is the source of truth for instance listing; no new external data sources in v1.
- Debug-only UI delivery is acceptable for this iteration, consistent with the build-sets-synergies feature iteration scope.
- Full user-scoped instance lists without pagination are acceptable in v1, consistent with existing list API policy for user-owned data.
- Roll tags already computed during sync may be surfaced when present; v1 does not require new roll-tag algorithms unless needed for search.
- Set editor integration to pick a specific instance identity is a follow-on consumer of this API shape; v1 delivers listing and detail only.
- Aligns with overhaul goals for viewing and filtering owned weapons and armor at roll level and supports set creation workflows that need specific perk combinations.

## Dependencies

- Existing authenticated session and inventory sync capability.
- Manifest data for plug name resolution.
- Build Sets and Synergies feature (001): catalog browse, debug access rules, and future set item attachment with roll data.
