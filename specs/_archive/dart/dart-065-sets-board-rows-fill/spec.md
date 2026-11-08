# Feature Specification: DART-065 Sets Board, Dense Rows, Slot Fill

**Feature Branch**: `dart-065-sets-board-rows-fill`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Armor EoF base-roll board; dense item rows; slot-fill Catalog; replace confirm; weapon perks. Exit: GAP-UI-SETS-01, 02, 03, 07, 10. DAC-NME-004/BR-SET-010/011 armor base-roll EoF six-stat board + totals; item rows icons/traits/origin/synergies/Instance|Wishlist; both shells embedded catalog fill density (Jaspr not hash-only); occupied-slot replace confirm; weapon fill persists/shows selectedPerks/trait perks. Soft never auto-applies; no CLIENT_SECRET. Cutover GO unchanged."

**Program ID**: DART-065  
**Phase**: P9  
**Depends**: DART-061  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-SETS-01, 02, 03, 07, 10**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **Armor base-roll EoF six-stat board** + set totals for armor sets when instance pins have resolvable stats (GAP-UI-SETS-01; DAC-NME-004 / BR-SET-010 / BR-SET-011 / DBR-STAT-008)
- **Dense set item rows**: catalog meta (element/type/frame/tier/origin when known), selected trait perks, linked synergies, Instance vs Wishlist (GAP-UI-SETS-02)
- **Slot-fill Catalog density** on Windows + Jaspr: search + named results, slot filter, All|Owned, instance pin or wishlist — **Jaspr retires hash-only primary path** (GAP-UI-SETS-03)
- **Occupied-slot replace confirm** naming current item; cancel leaves slot unchanged (GAP-UI-SETS-07; BR-SLOT-006)
- **Weapon fill selectedPerks**: persist trait perk hashes from owned sockets; detail shows trait names not barrel/mag/stock (GAP-UI-SETS-10; BR-ROLL-001)
- Soft never auto-applies; no `CLIENT_SECRET`; cutover GO unchanged

**Out of scope (do not implement in this slice):**

- Sets library search/tag AND filters (DART-066 / GAP-UI-SETS-04)
- Readiness / Fill next / Used-by chrome (DART-066 / GAP-UI-SETS-05)
- Delete set + SET_IN_USE host control (DART-066 / GAP-UI-SETS-06)
- Synergy catalog picker / manage (DART-066)
- Full icon art pipeline polish (DART-068 icons residual)
- Armor mod energy board beyond base roll
- Mobile-specific sets surface
- Production cutover re-gate; Next.js product worktree edits

## Assumptions

- **A1**: Armor base-roll board uses inventory `statValues` via `buildArmorBaseStatBoard` (DART-063). Full DIM plug-investment armor_stats sum when raw plug defs unavailable is **residual** (PROC-06): live-minus-mods strip is not re-implemented if plug defs absent; board shows resolvable base values when present, "stats unknown" for wishlist / missing rolls.
- **A2**: Trait perks for display = plugs with `columnKind == trait` (or trait-labeled columns) from socket enrichment; when only flat `selectedPerks`/`plugHashes` exist, show named hashes when plug name map available, otherwise `#hash` without inventing names. Non-trait columns (barrel/mag/stock) are never primary trait chips.
- **A3**: Replace confirm applies to **single-occupant** slots (weapon/armor/pair fixed slots). Mod multi-slot (`helmet:hash`) only confirms when the **exact** write key is already occupied.
- **A4**: Catalog fill density minimum: free-text search + named list + meta subtitle + All|Owned + instance vs definition-only. Full multi-facet CatalogScreen parity is optional residual; not required if search+owned works.
- **A5**: Icons: show icon URL text/avatar when `CatalogItem.icon` present; full ItemIcon chrome residual → DART-068.
- **A6**: Linked synergies: reverse lookup by itemHash (weapon / exotic_armor) via existing `listUserSynergiesByTarget` / catalog annotate; empty when none.
- **A7**: Soft never auto-applies; pure Dart I/O only; no CLIENT_SECRET. Cutover GO presentation-only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Armor EoF base-roll board (Priority: P1)

As a user viewing an armor set with pinned instances, I see the EoF six-stat board (Health/Melee/Grenade/Super/Class/Weapons) per piece and set totals from base roll only.

**Why this priority**: GAP-UI-SETS-01; DAC-NME-004 / BR-SET-010 / BR-SET-011.

**Independent Test**: Pure `sumArmorSetStats` unit tests; host shows board keys when fixture inventory has statValues; wishlist piece shows stats unknown.

**Acceptance Scenarios**:

1. **Given** armor set with instance-pinned helmet having statValues for all six, **When** detail opens, **Then** piece row shows six values and set totals include that piece.
2. **Given** wishlist (no instanceId) armor piece, **When** board rendered, **Then** that piece shows stats unknown / dashes (no fabricated zeros).
3. **Given** weapon set, **When** detail opens, **Then** armor totals board is not shown.

---

### User Story 2 - Dense item rows (Priority: P1)

As a user viewing filled set slots, I see dense rows with identity meta, trait perks, Instance|Wishlist, and linked synergies when known.

**Why this priority**: GAP-UI-SETS-02; BR-SET-010.

**Independent Test**: Presentation helper builds meta chips; host keys assert Instance/Wishlist and trait labels.

**Acceptance Scenarios**:

1. **Given** filled weapon with catalog meta + instanceId, **When** row rendered, **Then** shows name, Instance badge, and available meta (element/type/frame).
2. **Given** item with selectedPerks / trait plug cards, **When** row rendered, **Then** trait names (or #hash) appear; barrel-only columns do not appear as primary traits when classified.
3. **Given** library synergy linked to itemHash, **When** row rendered, **Then** linked synergy label appears.

---

### User Story 3 - Slot-fill Catalog density (Priority: P1)

As a user filling a slot on Windows or Jaspr, I pick from an embedded catalog search with named items, All|Owned, and instance or wishlist — not hash-only on Jaspr.

**Why this priority**: GAP-UI-SETS-03.

**Independent Test**: Windows picker already slot-filters; Jaspr fill UI exposes search list + pick by name; hash fields not primary.

**Acceptance Scenarios**:

1. **Given** OfflineCatalog items matching slot, **When** fill opens, **Then** named results appear (not hash-only primary).
2. **Given** Owned scope with instances, **When** user pins instance, **Then** set item stores instanceId.
3. **Given** All scope without instances, **When** user confirms definition only, **Then** wishlist pin (null instanceId).

---

### User Story 4 - Occupied-slot replace confirm (Priority: P2)

As a user replacing a filled non-mod multi-slot (or exact mod key), I must confirm with the current item name; cancel leaves the slot unchanged.

**Why this priority**: GAP-UI-SETS-07; BR-SLOT-006.

**Independent Test**: Host dialog/confirm step; pure helper `slotNeedsReplaceConfirm`; cancel path keeps previous itemHash.

**Acceptance Scenarios**:

1. **Given** occupied primary slot with "Old Gun", **When** user picks replacement, **Then** confirm names "Old Gun" before write.
2. **Given** confirm cancelled, **Then** slot still holds Old Gun.
3. **Given** empty slot, **When** fill, **Then** no replace confirm required.

---

### User Story 5 - Weapon selectedPerks on fill (Priority: P2)

As a user pinning an owned weapon instance, selected trait perk hashes persist on the set item and show on the detail row.

**Why this priority**: GAP-UI-SETS-10; BR-ROLL-001.

**Independent Test**: fillSlot passes selectedPerks; repository stores list; detail shows trait labels.

**Acceptance Scenarios**:

1. **Given** owned instance with trait socket plugs, **When** pin instance, **Then** set item `selectedPerks` contains trait plug hashes.
2. **Given** wishlist definition-only pin, **When** fill, **Then** selectedPerks may be empty (no instance rolls).
3. **Given** stored selectedPerks, **When** detail loads, **Then** trait chips resolve names when map available.

---

### Edge Cases

- Missing inventory / empty entity catalog: dense rows degrade to name(hash)·Instance|Wishlist only
- Incomplete armor stats: board marks incomplete; does not invent zeros for missing stats
- Soft guidance never auto-applies on any sets path
- No `CLIENT_SECRET` in packages or hosts

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Armor set detail MUST show EoF six-stat per-piece values and set totals from base-roll resolvable stats when instances pinned (DAC-NME-004 / BR-SET-010/011).
- **FR-002**: Wishlist armor pieces MUST NOT invent roll zeros; UI states stats unknown.
- **FR-003**: Filled item rows MUST surface Instance vs Wishlist and catalog identity meta when known.
- **FR-004**: Selected trait perks MUST display (names preferred); non-trait columns excluded when classified.
- **FR-005**: Linked library synergies for the item hash MUST surface when reverse lookup finds them.
- **FR-006**: Slot fill on **both** Windows and Jaspr MUST use catalog search density (named items + All|Owned + instance/wishlist); Jaspr MUST NOT use hash-only as primary path.
- **FR-007**: Replacing an occupied single-occupant slot MUST require explicit confirm naming current item; cancel leaves unchanged (BR-SLOT-006).
- **FR-008**: Weapon instance fill MUST persist `selectedPerks` trait hashes from sockets when available (BR-ROLL-001).
- **FR-009**: Soft guidance MUST never auto-apply; no CLIENT_SECRET in clients.
- **FR-010**: Cutover GO remains unchanged (presentation fidelity only).

### Success Criteria

- GAP-UI-SETS-01, 02, 03, 07, 10 closed with parity-specific tests (board totals, dense meta, Jaspr non-hash fill, replace confirm, selectedPerks stored).
- Soft never auto-applies; secret scan still clean.
- Roadmap row DART-065 → done; Current pointer → DART-066.

## Non-goals residual (PROC-06)

- Full plug-def armor_stats investment sum when browser lacks raw DestinyInventoryItemDefinition → residual; board uses stored statValues.
- Pixel-perfect ItemIcon / atlas chrome → DART-068.
- Library search/tags/delete/readiness → DART-066.
