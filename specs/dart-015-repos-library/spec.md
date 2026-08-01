# Feature Specification: DART-015 Repos Library

**Feature Branch**: `dart-015-repos-library`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Repositories: builds/sets/synergies/variants CRUD (no Bungie). Round-trip fixtures; RESTRICT attach semantics on set delete."

**Program ID**: DART-015  
**Phase**: P1  
**Depends**: DART-014 (Drift migrations done)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Drift-backed **repository layer** in `packages/db` for local library entities:
  - **Builds** (incl. tags + synergy type designations)
  - **Sets** (incl. tags; attachment refs lookup)
  - **Set items** (persist list/upsert/soft-remove — raw row CRUD, no catalog validation)
  - **Synergies** (incl. evidence links)
  - **Build variants** (incl. variant↔set attachments replace/list)
- **Round-trip fixtures**: create → read → update → read equality for each entity family
- **RESTRICT attach semantics**: deleting a set that is still attached to a variant MUST fail (FK RESTRICT); unattached sets delete successfully
- Minimal **user** insert helper so FK-owned rows can be seeded in tests/hosts
- Pure Dart I/O only (Drift/sqlite3); co-located tests under `packages/db/test/`

**Out of scope (later slices):**

- Inventory repository / sync (DART-016)
- Application use cases / hard-gate save pipeline (DART-027 / DART-028)
- Bungie HTTP, OAuth, inventory profile (DART-021+)
- Manifest / entity resolution for item display names (DART-017+)
- Flutter / Jaspr UI
- Set composition / mod energy validation (product `setItemService` domain rules — use cases later)
- Soft guidance evaluation or auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Repositories use **own record types** (mirroring product `*Repository.ts` shapes) rather than requiring `destiny2_domain` DTOs. Mapping to domain models is DART-027 use cases.
- **A2**: Callers supply string IDs (UUID or fixture ids). Repos do not generate IDs internally except optional defaults on attachment replace when id omitted.
- **A3**: `subclass` and JSON columns are stored as **JSON strings**; soft stat targets serialized as product-compatible JSON object string (empty `{}` default).
- **A4**: Build synergy type rows store empty string `""` for null subType (SQLite UNIQUE null-safety), exposed as `null` in records — same as product.
- **A5**: Set item “upsert” here is **persistence-level**: insert new active row; optional soft-remove previous active row for same slot when `replaceExisting` is true. No exotic/mod energy gates (A5 intentional vs product setItemService).
- **A6**: Soft guidance never auto-applies; repos are pure persistence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Library entity round-trips (Priority: P1)

As a multiplatform data layer, I can create, read, update, and delete builds, sets, synergies, and variants (with child tags/links/items/attachments as applicable) so later use cases and UI have a stable local library store.

**Why this priority**: Roadmap exit — “Round-trip fixtures.”

**Independent Test**: `dart test packages/db` with in-memory DB: seed user → create each entity family → get returns same fields → update mutates → get reflects update → delete removes (or cascade per FK).

**Acceptance Scenarios**:

1. **Given** a memory DB and user, **When** I create a build with tags and synergy types, **Then** `getBuild` returns matching name/class/tags/synergyTypes/timestamps.
2. **Given** a build, **When** I create a variant and replace attachments with a set, **Then** `listVariants` / `listAttachments` round-trip mode and setId.
3. **Given** a set with tags and an active set item, **When** I list sets and active items, **Then** fields match the insert.
4. **Given** a synergy with links, **When** I get by id, **Then** links are present with kind/displayName hashes.
5. **Given** created entities, **When** I update name (or links/tags) and re-get, **Then** updates persist.
6. **Given** an unattached set, **When** I delete it, **Then** delete succeeds and get returns null.

---

### User Story 2 - RESTRICT on set delete when attached (Priority: P1)

As a user managing sets, the system MUST refuse to delete a set that is still attached to any build variant, preserving product RESTRICT semantics so builds do not silently lose attachments.

**Why this priority**: Roadmap exit — “RESTRICT attach semantics on set delete.”

**Independent Test**: Attach set to variant → `deleteSet` / raw delete throws or returns failure without removing set; detach or delete variant first → set delete succeeds.

**Acceptance Scenarios**:

1. **Given** a set attached to a variant via `variant_set_attachments`, **When** repository `deleteSet` runs, **Then** the set row remains and an error/false outcome surfaces (SQLite RESTRICT).
2. **Given** attachments removed (or variant deleted cascading attachments), **When** `deleteSet` runs, **Then** the set is removed.
3. **Given** `findAttachmentsBySetId`, **When** set is attached, **Then** refs include buildId/variantId names for callers to show “in use.”

---

### User Story 3 - User-scoped isolation helpers (Priority: P2)

As a multi-user local DB (single-device multi-account later), list/get operations are scoped by `userId` so one user’s library is not returned for another.

**Why this priority**: Matches product repository contracts; prevents cross-user leaks in tests and hosts.

**Independent Test**: Two users each with a build/set/synergy; list for user A never includes user B’s rows.

**Acceptance Scenarios**:

1. **Given** two users with builds, **When** `listBuilds(userA)`, **Then** only user A builds.
2. **Given** wrong userId on get, **When** `getBuild(userB, idOfA)`, **Then** null.

---

### Edge Cases

- Delete build cascades variants and attachments (FK CASCADE) — set rows remain.
- Empty tag/synergyType/link lists are valid.
- `replaceAttachments` clears prior attachments for the variant then inserts the new list.
- Soft-removed set items (`removedAt` set) are excluded from active lists but remain in full list.
- Duplicate set name per (user, type) may violate unique index — surface as exception (same as SQLite).
- Soft never auto-applies via repository methods.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose repositories for builds, sets, set items, synergies, and variants on `AppDatabase`.
- **FR-002**: Each primary entity MUST support create, get (user-scoped where applicable), list, update, and delete.
- **FR-003**: Round-trip tests MUST pass for builds, sets (+ item), synergies (+ links), variants (+ attachments).
- **FR-004**: Set delete MUST respect **ON DELETE RESTRICT** from `variant_set_attachments`; tests MUST prove attached delete fails and unattached succeeds.
- **FR-005**: `findAttachmentsBySetId` MUST return build/variant refs for attached sets.
- **FR-006**: Child rows (tags, synergy types, links) MUST be written/read with parents as in product repos.
- **FR-007**: Pure packages MUST remain free of Drift; `destiny2_db` is the only home for these repos this slice.
- **FR-008**: No Bungie network, no CLIENT_SECRET, no Node sidecar.
- **FR-009**: Soft guidance never auto-applies.
- **FR-010**: Inventory/Bungie repos MUST NOT be implemented in this slice.

### Key Entities

- **BuildRecord**: identity + tags + synergy type designations + softStatTargets JSON
- **SetRecord**: library set + tags + optimizer/linkedMod fields
- **SetItemRecord**: slot occupancy row (persistence fields only)
- **SynergyRecord / SynergyLinkRecord**: library synergy + evidence links
- **VariantRecord / AttachmentRecord**: build variant + set attachments
- **SetAttachmentRef**: build/variant display refs for set-in-use

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/db` passes including round-trip and RESTRICT cases.
- **SC-002**: Specs under `specs/dart-015-repos-library/`; branch merges to `feature/multiplatform-dart` only.
- **SC-003**: No pure-package Drift dependency; P0 graph guard still green if run.
- **SC-004**: Exit criteria satisfied: round-trip fixtures + RESTRICT attach on set delete.
