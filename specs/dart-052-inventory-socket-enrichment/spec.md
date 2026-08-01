# Feature Specification: DART-052 Inventory Socket Enrichment

**Feature Branch**: `dart-052-inventory-socket-enrichment`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Enrich socket plugs for perk grids (weapon socket context). GAP-INV-03 closed: stored socket plugs for weapons include columnKind/columnLabel (or equivalent) usable by instance perk grids; parity tests vs Next buildStoredSocketPlugs with socket fixtures; intentional thinning opens GAP residual at merge (PROC-06); soft never auto-applies; no CLIENT_SECRET"

**Program ID**: DART-052  
**Phase**: P6  
**Depends**: DART-050 (stable inventory set + vault resolution); DART-051 optional co-wiring  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-INV-03**

## Scope boundary

**In scope:**

- Port pure `classifyWeaponSocket` + `buildStoredSocketPlugs` parity with Next (`src/lib/inventory/instances/`)
- Weapon socket context: plug category / itemTypeDisplayName maps + `weaponPerkSocketIndexes` (category hash `4241085061`)
- Wire inventory normalize / `syncUserInventory` so weapon rows store plugs with `columnKind` + `columnLabel` when context is available
- Injectable context builder (and optional explicit maps) on `syncUserInventory` / `syncIfStale`
- Golden unit tests mirroring Next `classifyWeaponSocket.test.ts` + buildStoredSocketPlugs socket fixtures
- Production host wiring when raw DestinyInventoryItemDefinition is available (Windows Settings + equip; Jaspr equip when raw/defs allow)
- Package docs for socket enrichment; soft never auto-applies; no CLIENT_SECRET
- Intentional thinning opens GAP residual (PROC-06)

**Out of scope (do not implement in this slice):**

- Settings diagnostics UI (DART-053 / GAP-INV-04)
- Live Next-vs-Dart inventory harness (DART-054 / GAP-INV-05)
- Full instance perk-grid UI (product 011 host chrome) — only **stored** plug shape for grids
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / confidential cookie parity
- Node sidecar
- Armor socket grids

## Assumptions

- **A1**: Plug categories and item types come from injected maps / raw `DestinyInventoryItemDefinition` (`plug.plugCategoryIdentifier`, `itemTypeDisplayName`). MVP has no dedicated weapon-perks entity store for category strings.
- **A2**: `weaponPerkSocketIndexes` from weapon item `sockets.socketCategories` entry with `socketCategoryHash === 4241085061` (Next `WEAPON_PERKS_CATEGORY_HASH` / `getPerkSocketIndexes`).
- **A3**: Without socket context, normalize may fall back to raw `socketCapture` maps (no `columnKind`/`columnLabel`) — incomplete enrichment for hosts without raw tables (web MVP). Document residual; not permanent pure-function thinning.
- **A4**: Non-weapon buckets store `socketPlugs: null` (Next `buildSocketPlugsForItems` parity). Weapons with empty/missing capture → null.
- **A5**: Soft metadata only; never auto-applies build edits.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pure classify + buildStoredSocketPlugs parity (Priority: P1)

As a multiplatform engineer, pure classification labels barrel/magazine/trait/intrinsic/origin/masterwork/catalyst columns and excludes cosmetics so stored plugs match Next for socket fixtures.

**Why this priority**: GAP-INV-03 exit criteria; golden parity is the measurable gate.

**Independent Test**: Unit tests in `packages/bungie` inject category/type maps + perk socket indexes matching Next fixtures.

**Acceptance Scenarios**:

1. **Given** barrel/magazine/trait categories on perk socket indexes, **When** `classifyWeaponSocket` / `buildStoredSocketPlugs` run, **Then** columns are Barrel / Magazine / Trait 1 / Trait 2 with kinds.
2. **Given** cosmetic shader category, **When** classify runs, **Then** `includeInGrid` is false (omitted from stored list).
3. **Given** intrinsic / origin / masterwork / catalyst categories, **When** classify runs, **Then** kinds and labels match Next.
4. **Given** Enhanced Trait under bare `frames` category with item type, **When** classify runs, **Then** kind is `trait` and included.
5. **Given** socket outside weapon-perk indexes without a known kind, **When** classify runs, **Then** excluded from grid.

---

### User Story 2 - Sync normalize emits enriched socket plugs (Priority: P1)

As a signed-in Guardian, after inventory sync, weapon rows in Drift carry socket plugs with `columnKind`/`columnLabel` when weapon socket context is supplied, so instance perk grids can render columns.

**Why this priority**: Exit criteria require stored enrichment, not only a pure helper.

**Independent Test**: `syncUserInventory` fixtures with socket capture + context assert stored plug maps include kinds/labels.

**Acceptance Scenarios**:

1. **Given** a Kinetic weapon with socketCapture + context (categories + perk indexes), **When** sync runs, **Then** Drift `socketPlugs` entries include `columnKind` and `columnLabel`.
2. **Given** the same weapon without context builder, **When** sync runs, **Then** plugs fall back to raw capture maps (no invented kinds) or null — documented degradation.
3. **Given** armor / non-weapon, **When** sync runs, **Then** `socketPlugs` is null.
4. **Given** soft guidance, **When** plugs are stored, **Then** they never auto-apply as build edits.

---

### User Story 3 - Production hosts supply socket context (Priority: P1)

As a multiplatform engineer, production sync call sites supply weapon socket context when raw item definitions are available so Windows Settings sync is not stuck on raw-only plugs.

**Why this priority**: PROC-02; pure function alone does not close GAP-INV-03 on hosts.

**Independent Test**: Windows Settings / equip wiring passes builder; package or host tests prove enriched plugs with fixture defs.

**Acceptance Scenarios**:

1. **Given** Windows Settings `syncNow` with raw defs available, **When** sync runs, **Then** weapon socket context builder is wired into `syncUserInventory`.
2. **Given** Windows / Jaspr equip `syncIfStale`, **When** inventory is refreshed, **Then** the same builder is passed when available.
3. **Given** web without raw defs, **When** builder cannot load categories, **Then** residual thinning is documented (PROC-06) — not claimed as full parity.

---

### User Story 4 - Docs + gap closure (Priority: P2)

As a finish-spec reviewer, GAP-INV-03 is closed (or partial with explicit residual), package docs describe socket enrichment, and roadmap advances.

**Why this priority**: PROC-01/06 documentation gate.

**Independent Test**: Docs + feature-gaps status; no “sync button works” success claims.

**Acceptance Scenarios**:

1. **Given** package README inventory section, **When** read, **Then** `buildStoredSocketPlugs` / columnKind parity is documented.
2. **Given** finish-spec, **When** success is claimed, **Then** criteria cite stored plugs with columnKind/columnLabel + parity tests.
3. **Given** intentional thinning (e.g. web raw-less), **When** present, **Then** GAP residual is opened (PROC-06); otherwise GAP-INV-03 closed for package + Windows path.

---

### Edge Cases

- Unknown plug hash (missing category) + in perk indexes → index-based barrel/mag/trait labels.
- Unknown plug hash outside perk indexes → excluded.
- Kill-tracker masterwork category → excluded (`includeInGrid: false`).
- Gear-tier `enhancements.*` cosmetics → excluded.
- Vault weapons after DART-050 resolve: equipment bucket so weapon path applies.
- Soft never auto-applies; no CLIENT_SECRET.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide pure `classifyWeaponSocket` with Next-parity kinds, labels, and includeInGrid rules.
- **FR-002**: System MUST provide pure `buildStoredSocketPlugs` producing stored plugs with `socketIndex`, `equippedPlugHash`, `reusablePlugHashes` (equipped ∪ reusables, unique), `columnKind`, `columnLabel`.
- **FR-003**: System MUST support building `WeaponSocketContext` from raw DestinyInventoryItemDefinition-shaped tables (perk indexes + plug category/type maps).
- **FR-004**: `syncUserInventory` / normalize MUST emit enriched socket plugs for weapons when context is available.
- **FR-005**: Sync MUST accept optional weapon socket context builder (and/or testable injection path).
- **FR-006**: Non-weapon items MUST store `socketPlugs: null`.
- **FR-007**: Unit tests MUST match Next socket classification fixtures and a buildStoredSocketPlugs end-to-end fixture.
- **FR-008**: Production hosts (Windows Settings, Windows equip; Jaspr equip when data available) MUST wire context builders when raw defs exist.
- **FR-009**: Soft suggestions never auto-apply; socket plugs are storage/display metadata only.
- **FR-010**: No CLIENT_SECRET in any path.
- **FR-011**: Intentional thinning MUST open GAP residual (PROC-06); otherwise mark GAP-INV-03 closed (or partial with residual note for web raw-less path).

### Key Entities

- **SocketColumnKind**: `barrel` | `magazine` | `trait` | `intrinsic` | `origin` | `masterwork` | `catalyst`
- **StoredSocketPlug**: socketIndex, equippedPlugHash, reusablePlugHashes, columnKind, columnLabel
- **WeaponSocketContext**: plugCategoryByHash, plugItemTypeByHash, weaponPerkSocketIndexes
- **RawSocketCapture**: pre-classification capture from profile parse
- **InventoryItemRecord.socketPlugs**: JSON array of plug maps on Drift

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pure classify/build unit tests pass for Next golden socket fixtures (barrel/mag/traits, cosmetics excluded, intrinsic/origin/mw/catalyst, enhanced trait frames).
- **SC-002**: `syncUserInventory` fixture tests store plugs with `columnKind`/`columnLabel` when context provided.
- **SC-003**: Production Windows sync paths wire socket context builder when raw defs available.
- **SC-004**: GAP-INV-03 closed or residual documented with PROC-06; soft never auto-applies; no CLIENT_SECRET.
- **SC-005**: Roadmap DART-052 → done; Current pointer → DART-053.
