# Feature Specification: DART-027 App Use Cases Library

**Feature Branch**: `dart-027-app-use-cases-library`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Application use cases: set/synergy CRUD + attach (in-process, no HTTP). Use cases call repos + pure domain; tests with in-memory/Drift."

**Program ID**: DART-027  
**Phase**: P3  
**Depends**: DART-015 (repos library), DART-011 (domain parity gate)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- New workspace package **`packages/app`** (`destiny2_app`): **in-process application use cases** (no HTTP routes, no Flutter/Jaspr UI)
- **Set library use cases**: list / get detail / create / update / delete; duplicate name guard; RESTRICT surface on delete when attached; map records ↔ domain `GearSet` / `SetType`
- **Set item use cases (persistence-level)**: upsert active item + soft-remove, scoped by user ownership of the set (no exotic/mod-energy hard gates — those belong to set composition polish / DART-028+)
- **Synergy library use cases**: list / get / create / update / delete; creatable-type check via pure domain; **designation (type + subType) immutable after create**; link kind validation via pure `SynergyLinkKind`
- **Attach use cases**: prepare/replace variant set attachments (live/snapshot); max one fashion set; snapshot configs from active set items when mode is snapshot and configs omitted; **replace-by-type** helper (preserve other types, live-attach new set)
- Pure **domain mappers** from db records → domain `GearSet`, `Synergy`, `Attachment`, `SetItem`
- Typed **use-case errors** (duplicate name, set in use, not found, designation immutable, invalid type/mode/kind, fashion limit)
- Unit tests with **in-memory Drift** (`AppDatabase.memory()`)

**Out of scope (later slices):**

- Build/variant save pipeline with hard gates + soft coverage (DART-028)
- Flutter Sets / Synergy library UI (DART-030 / DART-031)
- Manifest-backed set item validation (exotic limits, mod energy, perk grid)
- Synergy subtype vocabularies / link enrichment / designation consolidation merge
- Optimizer constraints object parse/serialize beyond opaque JSON string passthrough
- Bungie HTTP / OAuth / inventory
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Use cases live in **`destiny2_app`**, not inside `destiny2_db` or `destiny2_domain`. Domain stays pure (SDK only); db stays Drift persistence; app orchestrates.
- **A2**: Callers may supply string IDs; when omitted, use cases generate opaque IDs (UUID-style hex) via an injectable generator for tests.
- **A3**: Timestamps use injectable `now()` ISO-8601 UTC strings (default wall clock).
- **A4**: Synergy create accepts any wire type in `creatableSynergyTypeWires`; legacy types are not creatable. Read/update of existing legacy rows is allowed if already stored.
- **A5**: Designation immutability matches product `synergyService`: changing `type` or `subType` on update throws; name/description/links may change.
- **A6**: Attach ignores unknown `setId` (not owned / missing) rather than failing the whole replace — product `prepareAttachments` skips missing sets. Fashion count > 1 throws.
- **A7**: Soft guidance never auto-applies; no hard DBR kit evaluation in this slice.
- **A8**: No HTTP; Flutter hosts will call these use cases in-process later.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set library CRUD (Priority: P1)

As a compose host, I can create, list, update, and delete gear sets for a local user, with duplicate names blocked per (user, type) and attached sets refusing delete.

**Why this priority**: Core library spine for DART-030 and attach.

**Independent Test**: In-memory DB; create set → list → update name → attach to variant → delete fails → detach → delete ok.

**Acceptance Scenarios**:

1. **Given** a user, **When** I create a weapon set named "Kinetic", **Then** get/list return it with type `weapon` and domain `GearSet` mapping matches.
2. **Given** an existing weapon set "Kinetic", **When** I create another weapon set "Kinetic", **Then** use case fails with duplicate-name error.
3. **Given** a set attached to a variant, **When** I delete it, **Then** error surfaces set-in-use with attachment refs (set remains).
4. **Given** an unattached set, **When** I delete it, **Then** it is removed.
5. **Given** invalid type wire `"foo"`, **When** create is called, **Then** invalid set type error.

---

### User Story 2 - Synergy library CRUD + designation immutability (Priority: P1)

As a compose host, I can create and maintain synergies with evidence links; type/subtype cannot change after create.

**Why this priority**: Roadmap set/synergy CRUD; DART-031 depends on this.

**Independent Test**: Create synergy with creatable type + valid link kind → update description/links ok → attempt type change fails → delete removes.

**Acceptance Scenarios**:

1. **Given** user, **When** I create synergy type `melee` with an `exotic_armor` link, **Then** get returns name/type/links.
2. **Given** existing synergy, **When** I update description and links, **Then** designation unchanged and fields update.
3. **Given** existing synergy, **When** I change type or subType, **Then** designation-immutable error.
4. **Given** non-creatable type wire on create, **When** create runs, **Then** invalid synergy type error.
5. **Given** invalid link kind, **When** create runs, **Then** invalid link kind error.

---

### User Story 3 - Attach sets to variants (Priority: P1)

As a compose host, I can attach library sets to a build variant (live or snapshot), enforce at most one fashion set, and replace attachment by set type.

**Why this priority**: Exit criteria “attach”; enables later variant compose UI.

**Independent Test**: Seed build + variant + sets; prepareAttachments live+snapshot; fashion double attach fails; replaceAttachmentByType swaps armor only.

**Acceptance Scenarios**:

1. **Given** armor + mod sets and a variant, **When** I attach both live, **Then** listAttachments returns two rows.
2. **Given** snapshot mode without configs, **When** set has active items, **Then** snapshotConfigs are frozen from active items.
3. **Given** one fashion already attached, **When** I attach a second fashion, **Then** fashion-limit error and attachments unchanged (transactional replace — either full success or throw before write when validation fails first).
4. **Given** armor+weapon attached, **When** replaceAttachmentByType(armor, newArmorSet), **Then** armor is the new set live and weapon remains.
5. **Given** mode wire invalid, **When** prepare runs, **Then** invalid attachment mode error.

---

### Edge Cases

- Update/delete of missing set or synergy returns null / not-found style result (not crash).
- Empty links list on synergy create is allowed.
- Empty name after trim fails validation.
- Soft-removed set items are excluded when building snapshot configs.
- Soft guidance never auto-applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package `destiny2_app` MUST expose set, synergy, and attachment use cases callable in-process with `AppDatabase` + `userId`.
- **FR-002**: Set create/update MUST validate `SetType` via pure domain and block duplicate (user, type, name).
- **FR-003**: Set delete MUST surface set-in-use when attachments exist (wrap repo RESTRICT / `SetInUseException`).
- **FR-004**: Set get detail MUST include set row, items (active + optionally all), and attachment refs.
- **FR-005**: Synergy create MUST require creatable type wires from pure domain and valid `SynergyLinkKind` for each link.
- **FR-006**: Synergy update MUST refuse designation (type + subType) changes.
- **FR-007**: Attachment prepare MUST support live/snapshot modes, fashion max-one, and snapshot freeze from active items.
- **FR-008**: `replaceAttachmentByType` MUST preserve other set types and live-attach the new set of matching type.
- **FR-009**: Mappers MUST convert library records to pure domain `GearSet`, `Synergy`, `Attachment`, `SetItem` where applicable.
- **FR-010**: Use cases MUST NOT use HTTP, Flutter, Jaspr, CLIENT_SECRET, or Node sidecar.
- **FR-011**: Soft suggestions MUST NOT auto-apply.
- **FR-012**: Tests MUST use in-memory Drift and cover US1–US3 acceptance scenarios.

### Key Entities

- **CreateSetCommand / UpdateSetCommand** — use-case inputs
- **SetDetail** — set + items + usedBy refs
- **CreateSynergyCommand / UpdateSynergyCommand** — use-case inputs
- **SetAttachmentInput** — setId + mode + optional snapshotConfigs
- **UseCaseException** — typed failure codes
- Domain: `GearSet`, `SetType`, `Synergy`, `SynergyType`, `SynergyLinkKind`, `Attachment`, `AttachmentMode`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/app` green for set, synergy, attach suites.
- **SC-002**: Specs under `specs/dart-027-app-use-cases-library/`; branch merges to `feature/multiplatform-dart` only.
- **SC-003**: `destiny2_domain` remains pure (no app/db deps); graph guard still green for pure packages.
- **SC-004**: Exit criteria: use cases call repos + pure domain; tests with in-memory/Drift.

## Assumptions

See A1–A8 above.
