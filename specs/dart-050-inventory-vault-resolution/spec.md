# Feature Specification: DART-050 Inventory Vault Resolution

**Feature Branch**: `dart-050-inventory-vault-resolution`

**Created**: 2026-07-25

**Status**: Implemented (merge pending)

**Input**: User description: "Wire equipmentBucketLookup so vault/postmaster copies are stored. GAP-INV-01, GAP-INV-06 docs, GAP-INV-07 opt, PROC-01/02/06."

**Program ID**: DART-050  
**Phase**: P6  
**Depends**: DART-024 (profile/inventory sync), DART-017/018 (entity stores + Windows raw tables)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — GAP-INV-01, GAP-INV-06 residual, GAP-INV-07 optional; PROC-01/02/06

## Scope boundary

**In scope:**

- Build itemHash → equipment bucket lookup from `DestinyInventoryItemDefinition` raw table and/or entity store / catalog slot labels (parity with Next `buildEquipmentBucketLookup`)
- Wire **non-empty** `equipmentBucketLookup` into **every** production sync path that calls `syncUserInventory` / `syncIfStale`:
  - Windows Settings `syncNow`
  - Windows equip `syncIfStale`
  - Jaspr equip `syncIfStale`
  - Document / leave hook for future web Settings (DART-056)
- Package unit + host fixture tests assert `diagnostics.resolution.resolvedFromTransfer > 0` when vault/postmaster fixtures are present with lookup
- Host tests **fail** if vault fixtures omit lookup (or if production wiring path does not supply lookup for vault fixtures)
- Package docs stop treating empty lookup as production-OK
- Document Owned catalog still requires entity stores (GAP-INV-06 residual → DART-053 UX)
- Finish-spec rejects “user can sync” alone; intentional thinning must open GAP+RB (PROC-06)
- Optional: `parseWeaponStatValues` parity for weapon/transfer combat stats (GAP-INV-07 P2)

**Out of scope (do not implement in this slice):**

- Roll tags enrichment (DART-051 / GAP-INV-02)
- Socket plug columnKind/columnLabel enrichment (DART-052 / GAP-INV-03)
- Settings diagnostics UI (DART-053 / GAP-INV-04)
- Live Next-vs-Dart inventory harness (DART-054 / GAP-INV-05)
- Full Jaspr Settings sync depth / Owned web depth (DART-056)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / confidential cookie parity
- Node sidecar

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vault / postmaster copies land in Drift (Priority: P1)

As a signed-in Guardian on Windows, when I sync inventory from Settings (or equip triggers a stale sync), weapons and armor sitting in the vault or postmaster are stored in Drift with their **equipment** buckets (Kinetic/Energy/Power/Helmet/…), not dropped as unresolved transfer containers.

**Why this priority**: GAP-INV-01 P0; equip pin pool under-reports vault-owned gear without this.

**Independent Test**: Unit + host fixtures with vault General / Postmaster items and a non-empty lookup assert stored rows with Kinetic (or armor) bucket labels and `resolvedFromTransfer > 0`.

**Acceptance Scenarios**:

1. **Given** a vault General item with known itemHash whose definition maps to Kinetic, **When** `syncUserInventory` runs with a non-empty equipmentBucketLookup, **Then** Drift stores the instance with `bucket = Kinetic`, `location = vault`, and diagnostics `resolvedFromTransfer >= 1`.
2. **Given** the same vault item, **When** sync runs with empty lookup, **Then** the item is dropped (`droppedNonEquipment >= 1`) and not stored (existing library behavior preserved for tests of the drop path).
3. **Given** a postmaster armor item with lookup to Helmet, **When** sync runs with lookup, **Then** Drift stores `bucket = Helmet`.

---

### User Story 2 - Production hosts always wire lookup (Priority: P1)

As a multiplatform engineer, every production call site that performs inventory sync builds and passes a non-empty `equipmentBucketLookup` whenever entity/manifest data is available, so vault resolution cannot silently regress to empty-lookup defaults.

**Why this priority**: PROC-02; package API remaining optional is fine for unit tests, but production hosts must not omit lookup.

**Independent Test**: Windows Settings controller, Windows equip, and Jaspr equip tests (or compile-time wiring inspection + host fixtures) supply lookup builders; vault fixture host tests fail without lookup.

**Acceptance Scenarios**:

1. **Given** Windows Settings `InventorySyncController.syncNow`, **When** sync runs with vault fixtures and a lookup provider that maps those hashes, **Then** stored inventory includes vault-resolved gear and `resolvedFromTransfer > 0`.
2. **Given** Windows / Jaspr equip `syncIfStale`, **When** inventory is stale and vault fixtures need resolution, **Then** the equip path passes the same style of non-empty lookup into `syncIfStale`.
3. **Given** a host test vault fixture that expects resolution, **When** the test omits lookup wiring, **Then** the test fails (assert stored vault row / resolvedFromTransfer, not merely “sync completed”).

---

### User Story 3 - Docs + process residuals (Priority: P1)

As a finish-spec reviewer, package docs and gap trackers no longer present empty lookup as production-OK; Owned entity-store dependency is documented (GAP-INV-06 residual); intentional thinning would open GAP+RB (PROC-06).

**Why this priority**: PROC-01/06; prevents closing “user can sync” as full inventory parity.

**Independent Test**: README / package docs state production hosts MUST supply lookup; feature-gaps GAP-INV-01 marked closed or partial with residual notes; GAP-INV-06 residual → DART-053 explicit.

**Acceptance Scenarios**:

1. **Given** `packages/README.md` inventory sync section, **When** read, **Then** empty lookup is documented as **test-only / drops vault**, not production-OK.
2. **Given** Owned catalog after vault-capable sync, **When** entity cache is empty, **Then** docs state Owned definitions still require entity stores (DART-053 UX warning later).
3. **Given** finish-spec for this slice, **When** success is claimed, **Then** criteria cite vault/postmaster stored with equipment buckets — not only “sync button works”.

---

### User Story 4 - Optional weapon combat stats (Priority: P3)

As a player viewing owned weapon rolls, combat stats (RPM/Impact/Range/…) are stored on weapon and vault weapon rows when profile components provide them (GAP-INV-07).

**Why this priority**: Optional P2 in roadmap; not a cutover P0.

**Independent Test**: Unit parse fixtures for weapon stat hashes map to named combat stats.

**Acceptance Scenarios**:

1. **Given** a weapon (or transfer-container weapon) with combat stat components, **When** inventory is parsed, **Then** `statValues` includes combat names (RPM/Impact/…) not only armor-hash names.

---

### Edge Cases

- Lookup available for some vault hashes but not others → resolve what we can; count remainder as `droppedNonEquipment`.
- Raw `DestinyInventoryItemDefinition` missing on disk (web / never refreshed) → fall back to entity/catalog slot map when available; otherwise empty map (vault drops — same as today, but production Windows path prefers raw table after manifest download).
- Non-equipment definition bucketTypeHash (shader, consumable) → omit from lookup; item drops if transfer container.
- Soft guidance never auto-applies; no CLIENT_SECRET in any host path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide `buildEquipmentBucketLookup` (or equivalent pure helper) that maps itemHash → equipment bucketHash from DestinyInventoryItemDefinition-shaped data (inventory.bucketTypeHash), only retaining hashes that are equipment buckets.
- **FR-002**: System MUST provide a fallback builder from entity/catalog slot labels (Kinetic/Energy/Power/Helmet/…) to equipment bucket hashes for hosts without raw tables.
- **FR-003**: `syncUserInventory` / `syncIfStale` MUST continue to accept `equipmentBucketLookup` and apply `resolveTransferContainerBuckets` before Drift write.
- **FR-004**: Windows Settings `syncNow` MUST build and pass non-empty lookup when manifest/entity data is available.
- **FR-005**: Windows equip path `syncIfStale` MUST pass the same lookup builder/result.
- **FR-006**: Jaspr equip path `syncIfStale` MUST pass lookup when entity/catalog data is available.
- **FR-007**: Unit tests MUST assert `resolvedFromTransfer > 0` for vault fixtures with lookup and Kinetic (or armor) stored bucket labels.
- **FR-008**: Host tests with vault fixtures MUST fail if lookup is omitted (assert resolution / stored vault equipment rows).
- **FR-009**: Package docs MUST state empty lookup drops vault/postmaster and is **not** production-OK.
- **FR-010**: Docs MUST record GAP-INV-06 residual: Owned still needs entity stores → DART-053 UX.
- **FR-011**: Finish-spec / success criteria MUST reject “user can sync” alone (PROC-01); intentional thinning opens GAP+RB (PROC-06).
- **FR-012** (optional): Weapon/transfer parse MUST use combat `parseWeaponStatValues` parity (GAP-INV-07).

### Key Entities

- **EquipmentBucketLookup**: Map itemHash → equipment bucketHash (Kinetic/Energy/Power/armor/subclass hashes only)
- **InventoryResolutionCounts**: resolvedFromTransfer, droppedNonEquipment, storedTotal, storedEquipment
- **RawInventoryItem**: pre-resolve may carry vault/postmaster bucketHash; post-resolve carries equipment bucketHash

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After sync with vault/postmaster fixtures + lookup, Drift contains those weapon/armor instances with Kinetic/Energy/Power/armor bucket labels (not VaultGeneral/Postmaster).
- **SC-002**: Package unit tests report `diagnostics.resolution.resolvedFromTransfer > 0` for vault-with-lookup fixtures.
- **SC-003**: Host tests assert vault resolution (fail without lookup wiring).
- **SC-004**: Every production sync call site (Windows Settings, Windows equip, Jaspr equip) wires lookup building.
- **SC-005**: Package README no longer advertises empty optional lookup as production-OK.
- **SC-006**: GAP-INV-06 residual documented; GAP-INV-01 closed or marked partial only if residual thinning is explicitly GAP/RB-tracked.
- **SC-007**: Soft never auto-applies; no CLIENT_SECRET introduced.

## Assumptions

- Windows hosts after manifest refresh have `DestinyInventoryItemDefinition` on disk under StorageRoot (DART-018).
- Entity MVP stores cover weapons + exotic armor slots; legendary armor resolution prefers raw table (entity-only fallback incomplete — acceptable residual when raw missing, not production-OK on Windows with raw present).
- Live dual-account Next count harness is DART-054 (out of scope); this slice uses fixtures for resolution proof.
- Optional GAP-INV-07 is delivered in this slice if low-risk; otherwise left open with residual note.
- Future web Settings sync reuses the same lookup helper (DART-056) — document hook only if no Settings path exists yet.
