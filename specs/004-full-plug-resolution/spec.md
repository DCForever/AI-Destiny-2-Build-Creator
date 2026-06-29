# Feature Specification: Full Inventory Plug Resolution

**Feature Branch**: `004-full-plug-resolution`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Expand manifest-based plug lookup so every stored plug hash on owned weapon and armor instances resolves to a human-readable name when the manifest contains that plug; keep hash fallback and existing ResolvedPlug API shape; build on 003-owned-inventory-instances."

## Iteration Scope (UI)

**In scope (this iteration)**: Expand read-time plug name resolution for owned inventory instance list, single-instance detail, and perk text search (`q`). Cover typical equipped plugs on weapons and armor—including intrinsics, roll perks, origin and enhanced traits, weapon and armor mods, masterwork plugs, shaders, ornaments, kill trackers, and named default/empty socket plugs. Preserve backward-compatible instance responses and hash fallback for unknown plugs.

**Out of scope (this iteration)**: Stat breakdown bars, kill counts, weapon level or XP, loadout sharing, DIM-parity production UI; persisting resolved names at sync time; filtering instance plug lists to roll-only sockets; requiring inventory re-sync or database schema changes except when strictly necessary to meet resolution goals.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Readable Weapon Plug Names on Instance Detail (Priority: P1)

A signed-in player who has synced inventory opens owned instance detail for a weapon (via debug catalog drill-down or direct instance listing). Every equipped plug stored for that copy—including frame/intrinsic, barrel and magazine perks, origin or enhanced traits, weapon mods, masterwork stat, shader, ornament, and tracker sockets—displays as a human-readable name when the loaded game manifest defines that plug. Plugs the manifest cannot name still appear with their identifier so nothing is hidden.

**Why this priority**: Weapon rolls are the primary set-curation use case; unresolved hashes (e.g. Precision Frame, Synergy, Default Shader) make instance detail hard to trust and block perk text search.

**Independent Test**: With manifest loaded and inventory synced, fetch instance detail for a legendary weapon known to mix resolved and previously unresolved plugs. Verify roll perks and non-roll sockets (intrinsic, mod, shader, masterwork) show names, not raw hashes only.

**Acceptance Scenarios**:

1. **Given** a signed-in user with synced inventory and current manifest loaded, **When** they view a weapon instance whose plugs include intrinsic, roll perks, and cosmetic or mod sockets, **Then** each plug with a manifest display name shows `resolved: true` and a readable `displayName`.
2. **Given** a weapon instance with a plug hash absent from manifest or redacted, **When** instance detail is returned, **Then** that plug remains listed with `resolved: false` and `displayName` equal to the hash string—the request does not fail.
3. **Given** the instance list and single-instance endpoints for the same weapon copy, **When** both are requested, **Then** plug resolution results are consistent for the same stored plug hashes.

---

### User Story 2 - Readable Armor Plug Names on Instance Detail (Priority: P1)

A signed-in player views owned instance detail for an armor piece. Mods, intrinsics or archetype plugs, masterwork, ornaments, shaders, and other equipped sockets show human-readable names when manifest data exists, with the same graceful fallback as weapons.

**Why this priority**: Set building requires mod and armor identity clarity; armor shares the same resolution gap as weapons for non-roll sockets.

**Independent Test**: Fetch instance detail for a legendary armor piece with equipped mods and masterwork; confirm mod and non-mod plugs resolve where manifest entries exist.

**Acceptance Scenarios**:

1. **Given** a signed-in user with synced inventory and manifest loaded, **When** they view an armor instance with equipped mods and masterwork or cosmetic plugs, **Then** manifest-known plugs display readable names.
2. **Given** armor and weapon instances in the same inventory, **When** plug resolution runs, **Then** both equipment kinds use the same resolution rules and response shape.

---

### User Story 3 - Perk Text Search Uses Expanded Plug Names (Priority: P2)

A user or tester filters owned instances with perk text search (`q`). Matches include any equipped plug whose resolved display name contains the query, including newly resolved non-roll plugs (e.g. searching "Synergy" or "Precision") when those names are now available.

**Why this priority**: Search is a primary discovery path from feature 003; incomplete resolution makes `q` silently miss valid copies.

**Independent Test**: Sync inventory containing a weapon with an enhanced weapon mod; search instances with `q` set to that mod's display name; verify matching copies are returned.

**Acceptance Scenarios**:

1. **Given** instance list filtered by `q` matching a previously unresolved plug that now resolves, **When** the search runs, **Then** instances with that plug are included in results.
2. **Given** `q` matches only unresolved plugs (hash substring), **When** search runs, **Then** behavior degrades to hash or empty match without error.

---

### User Story 4 - Debug Verification of Resolution Coverage (Priority: P2)

A developer or QA tester uses the debug catalog owned-instance drill-down to confirm sync and resolution quality. Structured instance cards show a high proportion of named plugs versus hash-only entries for representative test weapons and armor.

**Why this priority**: Debug is the delivery channel for instance detail in this iteration; visible resolution gaps block validation of sync correctness.

**Independent Test**: Select owned catalog rows for one weapon and one armor piece in debug UI; inspect plug list; confirm ≥99% of equipped plugs show names for fixtures documented in quickstart.

**Acceptance Scenarios**:

1. **Given** debug catalog with owned scope and manifest loaded, **When** the user selects an owned weapon row and instance detail loads, **Then** the plug panel shows readable names for typical socket types listed in scope.
2. **Given** the same flow for armor, **When** instance detail loads, **Then** mod and non-mod plugs follow the same resolution and fallback rules as the API.

---

### Edge Cases

- What happens when manifest is not loaded or is stale? Instance data still returns from last sync; plug names resolve only where lookup data exists; unresolved plugs use hash fallback.
- What happens when a plug is a blank or default socket item that has a manifest name (e.g. "Default Shader")? It resolves to that name when defined in manifest.
- What happens when the same display name appears on multiple plugs? All plugs remain listed; consumers may deduplicate for display.
- What happens when manifest version changes between sync and view? Resolution uses current manifest at read time; stored plug hashes unchanged.
- What happens for removed or redacted content? Plug hash remains in response; resolution fails gracefully with hash display.
- What happens for exotic weapons with different socket layouts? Resolution applies to all stored enabled plugs regardless of weapon tier.
- What happens when the user is not signed in or has never synced? Existing auth and empty-state behavior from feature 003 unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST resolve stored plug hashes on owned weapon instances to human-readable names at read time when the loaded manifest contains a display name for that hash.
- **FR-002**: System MUST resolve stored plug hashes on owned armor instances to human-readable names at read time when the loaded manifest contains a display name for that hash.
- **FR-003**: Resolution MUST cover typical equipped plug categories on weapons and armor, including: intrinsics and frames; roll-column perks; origin traits and enhanced origin or weapon-mod traits; weapon mods and armor mods; masterwork stat and tracker plugs; shaders and ornaments; and named default or empty socket plugs present in manifest.
- **FR-004**: System MUST preserve the existing instance plug response shape (`hash`, `name`, `displayName`, `resolved`) without breaking changes for existing clients.
- **FR-005**: System MUST continue listing every plug hash stored at sync time; MUST NOT filter plugs to roll-only subsets.
- **FR-006**: When a plug hash cannot be resolved, system MUST set `name` to null, `displayName` to the hash string, and `resolved` to false—never omit the plug or fail the entire instance response.
- **FR-007**: Plug resolution MUST apply consistently to instance list responses, single-instance detail responses, and perk text search (`q`) filtering.
- **FR-008**: System MUST NOT require inventory re-sync or database schema changes unless strictly required to meet FR-001 through FR-003; prefer expanded manifest lookup at request time.
- **FR-009**: System MUST NOT persist resolved display names on inventory rows at sync time for this feature.
- **FR-010**: System MUST require authentication for instance listing and detail; unauthenticated requests MUST NOT return inventory data (unchanged from feature 003).
- **FR-011**: System MUST NOT add stat breakdown bars, kill counts, weapon XP, loadout sharing, or production inventory browser UI in this feature.

### Key Entities

- **Resolved Plug**: An equipped modification on an instance. Unchanged from feature 003: manifest hash, optional resolved name, display name for UI, and boolean resolved flag.
- **Inventory Instance**: A single owned copy from synced inventory; plug hashes are the input to resolution; no change to stored fields for this feature.
- **Manifest Plug Definition**: Game content entry that supplies a display name for a plug hash; resolution succeeds when lookup finds a usable name.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With current manifest loaded, at least 99% of equipped plugs on each of two documented test fixtures (one representative legendary weapon, one representative legendary armor piece) display readable names rather than hash-only display names.
- **SC-002**: A tester can identify a weapon copy's intrinsic, roll perks, and at least one non-roll socket (mod, shader, or masterwork) by name from instance detail without using an external inventory manager, in under 30 seconds.
- **SC-003**: Perk text search returns instances when `q` matches a newly resolved non-roll plug name (e.g. an enhanced weapon mod or intrinsic frame name) in 100% of fixture test cases where that plug is equipped.
- **SC-004**: Existing instance API consumers that ignore unresolved plugs continue to function without modification when resolution coverage increases.
- **SC-005**: Unresolved plugs still appear in responses with hash fallback in 100% of cases where manifest lookup fails—no silent omission.

## Assumptions

- Feature 003 (owned inventory instances) is implemented: instance list, detail endpoints, sync-populated plug hashes, and debug catalog drill-down exist.
- Bungie manifest refresh is available; plug names are derived from manifest at read time, not from a fixed subset of pre-extracted entity stores alone.
- Typical household-scale inventories remain suitable for in-memory resolution and search; no pagination changes required.
- Enhanced weapon mods and enhanced origin traits are treated as first-class resolution targets even when not indexed in legacy roll-perk or origin-trait catalogs.
- Debug catalog remains the primary verification surface; production inventory browser is out of scope.
- Authentication, sync prompt, and empty inventory behaviors remain as defined in feature 003.

## Dependencies

- Feature 003-owned-inventory-instances: instance API shape, sync pipeline, debug catalog instance drill-down.
- Manifest availability for plug definition lookup.
- Existing authenticated session and manual inventory sync.
