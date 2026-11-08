# Feature Specification: DART-066 Synergy Catalog Picker, Jaspr Manage, Sets Library

**Feature Branch**: `dart-066-synergy-picker-manage-sets-library`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Synergy catalog picker + Jaspr manage; Sets library filters/readiness/delete. Exit: GAP-UI-SYN-01, 02, 04, 06, 09; GAP-UI-SETS-04, 05, 06. BR-SYN-011 omit-linked + BR-SYN-012 labels; Jaspr detail/edit/links; library search/type filters; delete synergy; Sets search+tag AND, Fill next/used-by, SET_IN_USE delete. Soft never auto-applies; no CLIENT_SECRET."

**Program ID**: DART-066  
**Phase**: P9  
**Depends**: DART-063 (synergy reverse tags helpful)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-SYN-01, 02, 04, 06, 09; GAP-UI-SETS-04, 05, 06**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **Synergy evidence catalog search picker** by link kind with BR-SYN-011 omit already-linked targets (GAP-UI-SYN-01)
- **BR-SYN-012 weapon-perk source labels** on picker rows (exotic intrinsic/trait vs legendary perk vs legendary & exotic) (GAP-UI-SYN-02)
- **Jaspr synergy detail/edit/links manage** comparable to Windows dual-pane (GAP-UI-SYN-04)
- **Synergy library search + type/subtype filters** on Windows + Jaspr (GAP-UI-SYN-06)
- **Delete library synergy** with confirm on both shells (GAP-UI-SYN-09)
- **Sets library search + multi-tag AND + type facet** (GAP-UI-SETS-04; BR-TAG-007)
- **Sets readiness strip, Fill next, Used-by builds** (GAP-UI-SETS-05)
- **Delete set + SET_IN_USE** plain-language block when attached (GAP-UI-SETS-06; BR-DEL-001)
- Soft never auto-applies; no `CLIENT_SECRET`; cutover GO unchanged

**Out of scope (do not implement in this slice):**

- DesignationLabel verb/element icons chrome (DART-068 / GAP-UI-SYN-05)
- Full weapon-perk entity extract when offline catalog lacks plug rows (PROC-06 residual: hash/name catalog search + labels when source known)
- Mobile synergy/sets top-level surfaces (still N/A per surface matrix)
- Production cutover re-gate; Next.js product worktree edits

## Assumptions

- **A1**: Evidence picker uses OfflineCatalog / OwnedCatalogBridge `CatalogItem` rows filtered by link kind. When specialized stores for `weapon_perk` / `origin_trait` / `artifact_perk` / `armor_set_bonus` are absent, free-text name/hash still resolves into a valid link write; specialized density is residual.
- **A2**: BR-SYN-011 dedupe key matches product `coverageKeyFromLink` / `linkDedupeKey` (kind + target hash/name fields).
- **A3**: BR-SYN-012 labels use optional `WeaponPerkSource` (`exotic` | `legendary` | `both`) + plug role; when source unknown, row shows name without fabricated source label.
- **A4**: Tag AND filter requires every selected tag id present on the set's `tagIds` (empty tag filter = no tag constraint). Concept tag labels from sandbox_data when available.
- **A5**: Readiness capacity = board slot count for set type (weapon/armor/pair/fashion); mod sets show mod count without fixed capacity fill-next (product parity: mods_only skips Fill next).
- **A6**: SET_IN_USE surfaces `UseCaseErrorCode.setInUse` with buildIds/variantIds details as plain language.
- **A7**: Soft never auto-applies; pure Dart I/O only; no CLIENT_SECRET.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Synergy evidence catalog picker (Priority: P1)

As a curator adding evidence to a library synergy, I search catalog by link kind, see resolved named targets, omit already-linked hits (BR-SYN-011), and add valid links — not free-text-only + raw hash.

**Why this priority**: GAP-UI-SYN-01; BR-SYN-002/005/011; DBR-SYN-001/014.

**Independent Test**: Pure `filterOutLinked*` + `coverageKeyFromLink` unit tests; host search adds link with itemHash/perkHash.

**Acceptance Scenarios**:

1. **Given** draft already links weapon hash 1, **When** picker searches weapons, **Then** hash 1 is omitted from results.
2. **Given** catalog weapon "Lodestar", **When** user picks it as weapon kind, **Then** draft gains link with displayName + itemHash.
3. **Given** invalid empty display, **When** add attempted, **Then** rejected without silent save.

---

### User Story 2 - Weapon-perk source labels (Priority: P1)

As a curator searching weapon perks, each hit shows exotic intrinsic/trait vs legendary perk vs legendary & exotic when source is known.

**Why this priority**: GAP-UI-SYN-02; BR-SYN-012.

**Independent Test**: Pure `formatWeaponPerkSourceLabel` golden tests match product.

**Acceptance Scenarios**:

1. **Given** source exotic + Intrinsic, **Then** label "Exotic intrinsic".
2. **Given** source legendary + Trait, **Then** label "Legendary perk".
3. **Given** source both, **Then** label "Legendary & exotic".
4. **Given** null source, **Then** no fabricated label.

---

### User Story 3 - Jaspr synergy manage (Priority: P1)

As a web user, I select a synergy and edit name/description/links and delete — not create+list only.

**Why this priority**: GAP-UI-SYN-04.

**Independent Test**: SynergiesController select + update + delete + draft links; page exposes detail form.

**Acceptance Scenarios**:

1. **Given** existing synergy, **When** select, **Then** detail shows locked designation + edit fields.
2. **Given** draft link changes, **When** save links, **Then** persisted and list refreshes.
3. **Given** delete confirm, **When** delete, **Then** row removed and selection cleared.

---

### User Story 4 - Synergy library filters (Priority: P2)

As a user with many synergies, I free-text search and filter by type/subtype so the rail updates.

**Why this priority**: GAP-UI-SYN-06.

**Independent Test**: Pure `filterSynergies`; host wires search + type chips.

**Acceptance Scenarios**:

1. **Given** rows melee + grenade, **When** type filter melee, **Then** only melee shown.
2. **Given** query "hammer", **When** applied, **Then** name/type/subtype haystack match.
3. **Given** subtype filter, **When** combined with type, **Then** AND semantics.

---

### User Story 5 - Delete synergy (Priority: P2)

As a user, I delete a library synergy from detail with confirmation.

**Why this priority**: GAP-UI-SYN-09.

**Independent Test**: Controller deleteSelected; UI confirm control keys.

**Acceptance Scenarios**:

1. **Given** selected synergy, **When** delete confirmed, **Then** `deleteUserSynergy` runs and list refreshes.
2. **Given** cancel, **Then** synergy remains.

---

### User Story 6 - Sets library search + tag AND (Priority: P2)

As a user browsing sets, I filter by free-text name, optional type, and multi-select tags with AND.

**Why this priority**: GAP-UI-SETS-04; BR-TAG-007.

**Independent Test**: Pure `filterSets`; host filter chrome.

**Acceptance Scenarios**:

1. **Given** tags pve+solar on set A only, **When** filter tags [pve, solar], **Then** only A.
2. **Given** query matches name, **When** applied, **Then** matching sets remain.
3. **Given** type facet armor, **When** applied, **Then** non-armor excluded.

---

### User Story 7 - Sets readiness / Fill next / Used-by (Priority: P2)

As a user on set detail, I see filled/capacity, Fill next for first empty board slot, and used-by build refs when attachments exist.

**Why this priority**: GAP-UI-SETS-05.

**Independent Test**: Pure readiness helpers; host renders strip + CTA + usedBy pills.

**Acceptance Scenarios**:

1. **Given** weapon set with 1/3 filled, **When** detail opens, **Then** shows "1/3 filled" and Fill next names empty slot.
2. **Given** attachments, **When** detail opens, **Then** used-by build ids/names appear.
3. **Given** mod set, **When** detail opens, **Then** mod count shown without mandatory Fill next (A5).

---

### User Story 8 - Delete set + SET_IN_USE (Priority: P2)

As a user, I delete unused sets; attached sets show plain-language SET_IN_USE and remain.

**Why this priority**: GAP-UI-SETS-06; BR-DEL-001.

**Independent Test**: Controller deleteSelected maps UseCaseException; host shows message.

**Acceptance Scenarios**:

1. **Given** unattached set, **When** delete confirmed, **Then** set removed.
2. **Given** set attached to variant, **When** delete, **Then** error mentions in use / SET_IN_USE and set remains.
3. **Given** cancel, **Then** set remains.

---

### Edge Cases

- Empty catalog: picker shows empty results; manual residual optional not required as primary
- Soft guidance never auto-applies on any path
- No `CLIENT_SECRET` in packages or hosts
- Designation remains immutable after create (existing DBR-SYN-012)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hosts MUST offer catalog search by evidence link kind and add resolved targets with hashes where known (GAP-UI-SYN-01).
- **FR-002**: Picker results MUST omit targets already on the draft link list by coverage key (BR-SYN-011).
- **FR-003**: Weapon-perk rows MUST show BR-SYN-012 source labels when source is known (GAP-UI-SYN-02).
- **FR-004**: Jaspr MUST support select → detail edit name/description/links + delete (GAP-UI-SYN-04).
- **FR-005**: Both shells MUST filter synergy library by free-text and type/subtype facets (GAP-UI-SYN-06).
- **FR-006**: Both shells MUST expose delete synergy with confirm (GAP-UI-SYN-09).
- **FR-007**: Both shells MUST filter sets by free-text, optional type, and multi-tag AND (GAP-UI-SETS-04).
- **FR-008**: Set detail MUST show filled/capacity readiness, Fill next when applicable, and used-by attachments (GAP-UI-SETS-05).
- **FR-009**: Both shells MUST expose delete set; SET_IN_USE blocks with plain language (GAP-UI-SETS-06).
- **FR-010**: Soft suggestions MUST never auto-apply; no CLIENT_SECRET in clients.

### Success Criteria

- Pure unit tests green for filters, coverage keys, perk labels, readiness.
- Windows + Jaspr host tests cover picker omit-linked, filters, delete, readiness/SET_IN_USE.
- GAP rows closed in feature-gaps + ui-fidelity; roadmap DART-066 done; pointer → DART-068.
