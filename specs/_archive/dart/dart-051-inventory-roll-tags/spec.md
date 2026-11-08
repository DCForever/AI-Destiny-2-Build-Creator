# Feature Specification: DART-051 Inventory Roll Tags

**Feature Branch**: `dart-051-inventory-roll-tags`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port computeRollTags parity for weapon inventory rows. GAP-INV-02; roll tags match Next computeRollTags golden fixtures for crafted/champion/build samples; soft never auto-applies; PROC-06 if thinning."

**Program ID**: DART-051  
**Phase**: P6  
**Depends**: DART-050 (stable inventory set + vault resolution)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-INV-02**

## Scope boundary

**In scope:**

- Port pure `computeRollTags` parity with Next `src/lib/inventory/rollTags.ts` (Crafted, champion frame/perk, MeleeBuildCandidate, OrbitBuild)
- Wire inventory normalize (`_normalizeItems` / `syncUserInventory`) so stored rows get full roll tags when perk name map + weapon meta are available
- Golden unit tests matching Next `rollTags.test.ts` fixtures (crafted / champion / build samples)
- Injectable perk name map + weapon roll meta (maps and/or builders) on `syncUserInventory` / `syncIfStale`
- Production host wiring when entity/raw data is available (Windows Settings + equip; Jaspr equip) — same call sites as DART-050 enrichment path
- Package docs: crafted-only fallback is incomplete enrichment when maps empty (not full FEAT-INV-ROLL-TAGS parity)
- Soft guidance never auto-applies; no CLIENT_SECRET
- Intentional thinning opens GAP residual (PROC-06)

**Out of scope (do not implement in this slice):**

- Socket plug columnKind/columnLabel enrichment (DART-052 / GAP-INV-03)
- Settings diagnostics UI (DART-053 / GAP-INV-04)
- Live Next-vs-Dart inventory harness (DART-054 / GAP-INV-05)
- Full MVP `weapon-perks` entity store extraction expansion (hosts may resolve plug names from raw DestinyInventoryItemDefinition; dedicated weapon-perks store remains product residual if still missing)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / confidential cookie parity
- Node sidecar

## Assumptions

- **A1**: Dart MVP entity stores lack a dedicated `weapon-perks` store. Perk **names** for roll tags are resolved via injected `Map<int,String>` (tests) or raw `DestinyInventoryItemDefinition.displayProperties.name` for equipped plug hashes (Windows production when raw tables exist). Catalog/weapon meta supplies `frame` + `itemTypeName` for legendary weapons.
- **A2**: Frame-based champion tags apply only when weapon meta is provided (Next: legendary `WeaponRecord` with `originTraitHashes`); without meta, perk-name and crafted tags still apply.
- **A3**: Empty perk map + empty weapon lookup degrades to Crafted-only (when `isCrafted`) — acceptable offline/test degradation, not production-complete enrichment. Documented; not intentional permanent thinning of the pure function.
- **A4**: Tag wire strings match product `RollTag` union exactly: `Crafted`, `ChampionBarrier`, `ChampionOverload`, `ChampionUnstoppable`, `MeleeBuildCandidate`, `OrbitBuild`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pure computeRollTags parity (Priority: P1)

As a multiplatform engineer, pure `computeRollTags` returns the same tag sets as Next for crafted, frame-champion, perk-champion, MeleeBuildCandidate, and OrbitBuild golden fixtures so inventory quality UX and tag queries can rely on stored tags.

**Why this priority**: GAP-INV-02 exit criteria; golden parity is the measurable gate.

**Independent Test**: Unit tests in `packages/bungie` inject perk maps and weapon meta matching `src/lib/inventory/rollTags.test.ts` and assert tag membership.

**Acceptance Scenarios**:

1. **Given** Hand Cannon plugs Pugilist + Swashbuckler, **When** `computeRollTags` runs, **Then** tags contain `MeleeBuildCandidate`.
2. **Given** only Pugilist (missing Swashbuckler), **When** compute runs, **Then** tags do **not** contain `MeleeBuildCandidate`.
3. **Given** Demolitionist + Adrenaline Junkie on any weapon type, **When** compute runs, **Then** tags contain `OrbitBuild`.
4. **Given** `isCrafted: true` and empty plugs, **When** compute runs, **Then** tags equal `['Crafted']`.
5. **Given** Scout Rifle with Adaptive Frame weapon meta, **When** compute runs, **Then** tags contain `ChampionBarrier`.
6. **Given** plug named "Anti-Barrier Rounds", **When** compute runs (no weapon meta), **Then** tags contain `ChampionBarrier`.

---

### User Story 2 - Sync normalize emits roll tags (Priority: P1)

As a signed-in Guardian, after inventory sync, weapon rows in Drift carry roll tags derived from plug hashes + weapon frame/type (not only Crafted), so owned pickers and tag queries match product behavior for those samples.

**Why this priority**: Exit criteria require normalize path, not only a pure helper.

**Independent Test**: `syncUserInventory` fixtures with perk map + weapon meta assert stored `rollTags` for crafted/champion/build samples.

**Acceptance Scenarios**:

1. **Given** a crafted weapon with empty plugs and no meta maps, **When** sync runs, **Then** stored `rollTags` includes `Crafted` (backward compatible).
2. **Given** a Hand Cannon instance with Pugilist + Swashbuckler plug hashes and perk name map + weapon meta, **When** sync runs, **Then** Drift row `rollTags` contains `MeleeBuildCandidate`.
3. **Given** Adaptive Frame Scout Rifle meta and no plugs, **When** sync runs, **Then** stored tags contain `ChampionBarrier`.
4. **Given** missing perk map and weapon meta, **When** sync runs with non-crafted item, **Then** `rollTags` is empty (no invented tags).

---

### User Story 3 - Production hosts supply enrichment inputs (Priority: P1)

As a multiplatform engineer, production sync call sites supply perk name resolution and weapon roll meta when entity/raw data is available so roll tags are not stuck at Crafted-only after a real Settings sync.

**Why this priority**: PROC-02; pure function alone does not close GAP-INV-02 on hosts.

**Independent Test**: Windows Settings / equip wiring passes builders or maps; package or host tests prove non-Crafted tags when fixtures provide defs/catalog.

**Acceptance Scenarios**:

1. **Given** Windows Settings `syncNow` with catalog/raw available, **When** sync runs, **Then** enrichment inputs (perk map and/or weapon meta builders) are wired into `syncUserInventory`.
2. **Given** Windows / Jaspr equip `syncIfStale`, **When** inventory is refreshed, **Then** the same enrichment inputs are passed.
3. **Given** soft guidance, **When** tags are computed, **Then** they are stored only — never auto-applied as build edits.

---

### User Story 4 - Docs + gap closure (Priority: P2)

As a finish-spec reviewer, GAP-INV-02 is closed (or partial only with explicit residual), package docs describe roll tag enrichment, and roadmap advances.

**Why this priority**: PROC-01/06 documentation gate.

**Independent Test**: Docs + feature-gaps status; no “button works” success claims.

**Acceptance Scenarios**:

1. **Given** package README inventory section, **When** read, **Then** roll tags / computeRollTags parity is documented.
2. **Given** finish-spec, **When** success is claimed, **Then** criteria cite golden fixture tag parity — not only sync success.
3. **Given** intentional thinning, **When** present, **Then** GAP residual is opened (PROC-06); otherwise GAP-INV-02 closed.

---

### Edge Cases

- Unknown plug hashes (missing from perk map) → ignored for name rules; frame rules still apply when meta present.
- Weapon meta missing for itemHash → no frame champion tag; perk/crafted rules still apply.
- Exotic catalog rows: Next only uses legendary `WeaponRecord` for frame path; Dart weapon meta lookup should prefer legendary weapons store / non-exotic catalog rows with frame+itemTypeName.
- Soft never auto-applies; no CLIENT_SECRET.
- Tags are unordered sets logically; compare with contains / set equality (order may match insertion order of pure port).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide pure `computeRollTags(plugHashes, perkNameMap, {weapon, isCrafted})` with Next-parity rules for Crafted, champion (frame + perk name patterns), MeleeBuildCandidate, OrbitBuild.
- **FR-002**: Champion frame resolution MUST use `getChampionCounterForFrame` from `destiny2_sandbox_data` (existing port of product championCounters).
- **FR-003**: `syncUserInventory` / normalize MUST emit `rollTags` via `computeRollTags` (not hardcoded Crafted-only).
- **FR-004**: Sync MUST accept optional perk name map and/or builder and optional weapon roll meta map and/or builder.
- **FR-005**: When enrichment maps are empty, normalize MUST still tag `Crafted` when `isCrafted` is true and MUST NOT invent other tags.
- **FR-006**: Unit tests MUST match Next golden fixtures for crafted/champion/build samples.
- **FR-007**: Production hosts (Windows Settings, Windows equip, Jaspr equip) MUST wire enrichment builders when entity/raw data is available.
- **FR-008**: Soft suggestions never auto-apply; roll tags are storage/display metadata only.
- **FR-009**: No CLIENT_SECRET in any path.
- **FR-010**: Intentional thinning MUST open GAP residual (PROC-06); otherwise mark GAP-INV-02 closed.

### Key Entities

- **RollTag** (wire string): `Crafted` | `ChampionBarrier` | `ChampionOverload` | `ChampionUnstoppable` | `MeleeBuildCandidate` | `OrbitBuild`
- **RollTagWeaponMeta**: `frame`, `itemTypeName` (legendary weapon subset)
- **PerkNameMap**: plug itemHash → display name
- **InventoryItemRecord.rollTags**: stored JSON string array on Drift row

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pure `computeRollTags` unit tests pass for all Next golden cases (MeleeBuildCandidate, OrbitBuild, Crafted, frame ChampionBarrier, perk ChampionBarrier).
- **SC-002**: `syncUserInventory` fixture tests store matching tags for crafted/champion/build samples when maps provided.
- **SC-003**: Production sync call sites wire enrichment inputs (not Crafted-only forever).
- **SC-004**: GAP-INV-02 closed or residual documented with PROC-06; soft never auto-applies; no CLIENT_SECRET.
- **SC-005**: Roadmap DART-051 → done; Current pointer → DART-052.
