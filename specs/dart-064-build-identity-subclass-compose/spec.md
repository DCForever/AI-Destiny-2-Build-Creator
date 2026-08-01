# Feature Specification: DART-064 Build Identity, Subclass Kit, Manifest Pickers

**Feature Branch**: `dart-064-build-identity-subclass-compose`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Identity Confirm/Fork; subclass kit composer; Manifest pickers; hard-block UX; Jaspr attach pickers. Exit: GAP-UI-BUILD-01, 02, 05, 08, 09. DBR-ID-008 Confirm/Fork on identity change; full subclass kit composer + capacity plain language; Manifest search exotic/Super pickers; client hard-block dual exotic/kit UX; Jaspr named set picker + per-slot pins. Soft never auto-applies; no CLIENT_SECRET. Cutover GO unchanged."

**Program ID**: DART-064  
**Phase**: P9  
**Depends**: DART-061  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-BUILD-01, 02, 05, 08, 09**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **DBR-ID-008 Confirm/Fork**: identity-affecting updates require `identityAction: confirm | fork` or Cancel; no silent in-place apply (GAP-UI-BUILD-01)
- **Subclass kit composer** on Windows Flutter + Jaspr: aspects, fragments, super/melee/grenade/classAbility (+ name); capacity plain language; persists on build subclass JSON (GAP-UI-BUILD-02)
- **Manifest search pickers** for exotic armor + Super (named search primary; hashes not primary input) (GAP-UI-BUILD-05)
- **Client hard-block UX** for dual exotic composition + illegal subclass kit with plain-language reasons before/at save; soft never disables Save (GAP-UI-BUILD-08)
- **Jaspr attach/pin**: named library set picker + per-slot pin edit (no raw id-only primary path) (GAP-UI-BUILD-09)
- Pure Dart I/O only; soft guidance never auto-applies; no `CLIENT_SECRET`
- **Cutover GO unchanged**

**Out of scope (do not implement in this slice):**

- Finish one-tap Create/Capture walkthrough (DART-067 / GAP-UI-BUILD-03)
- Build Finish armor optimizer path (DART-067 / GAP-UI-BUILD-04)
- Variant loadout icon overview density (DART-068 / GAP-UI-BUILD-06)
- Sets board / dense rows (DART-065)
- Synergy catalog picker (DART-066)
- Mobile-specific polish beyond shared use-case behavior
- Production cutover re-gate; Next.js product worktree edits

## Assumptions

- **A1**: Identity fields requiring Confirm/Fork match product: `synergyTypes`, `exoticArmorHash` (with class-item→class-item non-identity when modes known), `exoticWeaponHash`, `pinnedSuper`. Name/class/soft-stats alone do **not** require Confirm/Fork. Subclass kit edits require Confirm when they change ability/aspect/fragment identity material that is part of build subclass JSON **or** when treated as identity via concurrent exotic/super pins; pure soft-stat and display name stay free.
- **A2**: Subclass kit identity change is **included** when `subclass` differs from stored kit (aspects/fragments/abilities/name) — product SubclassTab saves kit as identity-related persist; Confirm/Fork applies when kit differs (parity with intentional identity mutation). Soft alone never blocks.
- **A3**: Class-item exotic mode: when armor slot lookup is unavailable offline, any exoticArmorHash change is treated as identity-affecting (safe classic default). When slot is known ClassItem on both sides, swap is non-identity (TS parity).
- **A4**: Fork copies all variants with attachments as **snapshot** (product forkBuildWithIdentity). Soft never auto-applies on fork.
- **A5**: Manifest pickers source from OfflineCatalog / entity bundle base items (`exotic-armor`, `abilities` with super kind; optional exotic-weapons). Empty catalog → plain-language empty state; free-text name fallback allowed but not primary.
- **A6**: Client hard-block UX is advisory pre-filter; domain/use-case gates remain authoritative on save.
- **A7**: Soft never auto-applies; no OAuth/secret work; pure Dart I/O only. Cutover GO presentation-only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identity Confirm / Fork (Priority: P1)

As a user changing identity fields on an existing build, I must Confirm in-place (all variants keep that identity) or Fork a new build or Cancel. Silent in-place apply is blocked.

**Why this priority**: GAP-UI-BUILD-01; DBR-ID-008.

**Independent Test**: App-package unit tests for IDENTITY_CONFIRM_REQUIRED, confirm path, fork path; host shows Confirm/Fork/Cancel chrome when identity pending.

**Acceptance Scenarios**:

1. **Given** existing build with synergy type A, **When** user updates synergy types without identityAction, **Then** use case throws `IDENTITY_CONFIRM_REQUIRED` with changed field list and nothing is written.
2. **Given** pending identity change, **When** user Confirm, **Then** build updates in place and retains id.
3. **Given** pending identity change, **When** user Fork, **Then** a new build id is created with forked identity + variant snapshots; original unchanged.
4. **Given** softStatTargets-only update, **When** saved without identityAction, **Then** succeeds without Confirm.

---

### User Story 2 - Subclass kit composer (Priority: P1)

As a user on Windows or Jaspr Build compose, I edit full subclass kit (aspects, fragments, super/melee/grenade/classAbility) with plain-language capacity status and save kit on the build.

**Why this priority**: GAP-UI-BUILD-02; DBR-CMPL-001 / DBR-BLD-001 surface.

**Independent Test**: Host/controller tests edit kit fields; persistence round-trip via `subclass` JSON; capacity banner when over aspect/fragment limits.

**Acceptance Scenarios**:

1. **Given** selected build, **When** user sets two aspects + fragments within capacity, **Then** kit saves and reloads.
2. **Given** three aspects selected, **When** capacity evaluated, **Then** plain-language illegal kit hard-block is shown and save is hard-blocked.
3. **Given** capacity unresolved (no aspect entity data), **Then** fragment capacity hard-check is not forced; UI states capacity unknown.

---

### User Story 3 - Manifest search exotic / Super pickers (Priority: P2)

As a user setting identity exotic armor or Super, I search by name from Manifest/entity catalog rather than typing raw hashes as the primary path.

**Why this priority**: GAP-UI-BUILD-05; DBR-ID-001 presentation.

**Independent Test**: Pure search helper filters catalog rows; host picker selects named item and fills hash+name.

**Acceptance Scenarios**:

1. **Given** exotic-armor rows in catalog, **When** user searches name fragment, **Then** matching named hits appear.
2. **Given** user selects a hit, **Then** exotic armor pin stores hash + display name (hash not sole UI).
3. **Given** abilities catalog with supers, **When** Super picker used, **Then** pinnedSuper is set to ability name.

---

### User Story 4 - Client hard-block dual exotic / kit UX (Priority: P2)

As a user composing identity/kit, primary save/actions surface hard blocks (too many exotics, illegal kit) with plain-language reasons before or at save. Soft misses never disable Save.

**Why this priority**: GAP-UI-BUILD-08; DAC-DST-009 / BR-UI-001.

**Independent Test**: Pure compose hard-block aggregator; host asserts hard banner keys and that soft miss alone leaves Save enabled.

**Acceptance Scenarios**:

1. **Given** draft with two exotic armor hashes in composition, **When** client evaluates, **Then** TOO_MANY_EXOTICS plain-language block listed.
2. **Given** illegal aspect count, **Then** ILLEGAL_SUBCLASS_KIT listed and identity save blocked.
3. **Given** only soft coverage misses, **Then** Save remains enabled (soft never auto-applies / never hard-blocks).

---

### User Story 5 - Jaspr named set picker + per-slot pins (Priority: P2)

As a Jaspr web user attaching sets and pinning slots, I pick sets by library name and edit pins per slot — not free-text set id as the only path.

**Why this priority**: GAP-UI-BUILD-09.

**Independent Test**: Web host tests select named set from attachable list; pin instance per live slot.

**Acceptance Scenarios**:

1. **Given** attachable sets in library, **When** compose attach UI opens, **Then** named set options are primary (dropdown/list by name).
2. **Given** live attachment with multiple slot pins, **When** user edits each pin, **Then** per-slot pin controls exist (not single first-pin-only field as sole path).
3. **Given** no attachable sets, **Then** plain-language empty state (no raw-id requirement).

---

### Edge Cases

- Cancel identity dialog discards draft fields / reloads stored identity
- Fork when name collides: append ` (fork)` (product parity)
- Empty entity catalog: pickers show empty; manual name still possible as secondary residual
- Soft guidance never auto-applies on any identity/kit path
- No `CLIENT_SECRET` in packages or hosts

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `updateUserBuild` MUST detect identity field changes and require `identityAction` confirm|fork or throw `IDENTITY_CONFIRM_REQUIRED` (no write).
- **FR-002**: Confirm MUST update the same build id in place after hard gates.
- **FR-003**: Fork MUST create a new build with updated identity, copy variants with snapshot attachments, leave original unchanged, and surface `forkedFromId` in result metadata when applicable.
- **FR-004**: Hosts MUST present Confirm / Fork / Cancel when identity confirm is required.
- **FR-005**: Hosts MUST provide subclass kit composer fields and persist via build subclass JSON.
- **FR-006**: Hosts MUST show plain-language subclass capacity (aspects max 2; fragments vs capacity when resolved).
- **FR-007**: Identity exotic armor + Super MUST be selectable via Manifest/catalog name search when catalog data present.
- **FR-008**: Client compose MUST surface hard-block reasons for dual exotic + illegal kit; soft misses MUST NOT disable Save.
- **FR-009**: Jaspr attach MUST use named set picker and per-slot pin editors as primary UX.
- **FR-010**: Soft guidance never auto-applies; no CLIENT_SECRET.

### Key Entities

- **IdentityAction**: `confirm` | `fork`
- **IdentityFieldChange**: list of wire field names that differ
- **SubclassKit**: aspects, fragments, super/melee/grenade/classAbility, name
- **ManifestPick**: hash + display name (+ optional icon) from entity catalog
- **ComposeHardBlock**: code + plain-language message for client UX

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Package tests prove IDENTITY_CONFIRM_REQUIRED, confirm, fork, and soft-stat bypass.
- **SC-002**: Host tests (Windows + Jaspr) prove Confirm/Fork chrome and kit persistence.
- **SC-003**: Manifest search pickers select named exotic armor / Super without raw-hash-only primary path when catalog seeded.
- **SC-004**: Client hard-block banners appear for illegal kit / dual exotic; soft miss alone leaves Save enabled.
- **SC-005**: Jaspr attach uses named set list + per-slot pins.
- **SC-006**: GAP-UI-BUILD-01, 02, 05, 08, 09 marked closed; roadmap DART-064 done; cutover GO unchanged.

## Assumptions

See **Assumptions** section above (A1–A7).
