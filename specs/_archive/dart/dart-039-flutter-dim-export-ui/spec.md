# Feature Specification: DART-039 Flutter DIM Export UI

**Feature Branch**: `dart-039-flutter-dim-export-ui`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "DIM jsonOnly / clipboard export. Blocked when not equip-ready."

**Program ID**: DART-039  
**Phase**: P4  
**Depends**: DART-010 (pure DIM builders + equipReady gate), DART-038 (Flutter equip UI / Builds detail equip-ready surface)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Windows** DIM export surface on **Builds library** detail when a **variant** is selected:
  - **Export CTA** (“Copy DIM JSON” / jsonOnly) that builds a gated `{ loadout }` payload via DART-010 `buildJsonOnlyDimExport`
  - **Clipboard** write of the pretty-printed JSON (no network)
  - **Equip-ready gate enforced** — CTA disabled and export blocked when not equip-ready (wishlist / stale / empty equipment)
  - Optional short readiness summary + last export status (copied / error)
- Pure display helpers for CTA enablement, blocked reason, and JSON encode
- Widget + unit tests with memory DB; injectable clipboard (no live Bungie; no CLIENT_SECRET)

**Out of scope (later / deferred):**

- dim.gg share / DIM Sync network client (roadmap deferred; needs API key + CORS)
- `collectVariantMods` DB I/O (callers pass empty modHashes unless already resolved)
- Full fashion / artifact wiring beyond what resolved equipment already exposes
- Soft guidance auto-apply (forbidden)
- Jaspr / mobile DIM export shells (DART-047)
- Node sidecar / CLIENT_SECRET (forbidden)
- Product Next.js route changes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Equip-ready gate blocks DIM export (Priority: P1)

As a Windows user with a selected variant that is **not** equip-ready (wishlist-only or stale pins), I see the DIM export CTA disabled and cannot copy a loadout payload. Attempting export programmatically surfaces `NOT_EQUIP_READY` guidance without writing the clipboard.

**Why this priority**: Roadmap exit — blocked when not equip-ready (DBR-EQP / DART-010 gate parity).

**Independent Test**: Seed wishlist pin → equipReady false → CTA disabled; `requestExport` returns error and clipboard never called.

**Acceptance Scenarios**:

1. **Given** a selected variant with only wishlist pins, **When** readiness is evaluated, **Then** equip-ready is false and Copy DIM JSON is disabled.
2. **Given** not equip-ready, **When** export is requested programmatically, **Then** clipboard is not written and status/error references not equip-ready.
3. **Given** no variant selected, **When** the panel is idle, **Then** export is disabled.

---

### User Story 2 - jsonOnly clipboard export when equip-ready (Priority: P1)

As a Windows user with an equip-ready variant (owned instance pins present in local inventory), I can press **Copy DIM JSON** to build a jsonOnly `{ loadout }` envelope via pure domain builders and place the JSON string on the system clipboard. Soft guidance never auto-applies.

**Why this priority**: Roadmap exit — DIM jsonOnly / clipboard export.

**Independent Test**: Owned pin + inventory → equipReady true → export → clipboard receives JSON containing `"loadout"` and equipped item hashes/instance ids; domain gate uses `assertEquipReady`.

**Acceptance Scenarios**:

1. **Given** owned instance pins present in local inventory, **When** readiness is evaluated, **Then** equip-ready is true and Copy DIM JSON is enabled.
2. **Given** equip-ready, **When** I export, **Then** clipboard receives a JSON string whose root object has a `loadout` key with DIM loadout fields (`id`, `name`, `classType`, `equipped`, …).
3. **Given** equip-ready combat pins with instance ids, **When** exported, **Then** `equipped` items include those hashes and instance `id` values (domain builder parity).
4. **Given** soft-stat targets on the build, **When** exported, **Then** they MAY appear as DIM `statConstraints` (soft enhancement; not blocking).

---

### User Story 3 - Preview / status without silent mutation (Priority: P2)

As a user, after a successful copy I see a brief status (“Copied DIM loadout JSON”) and may see a truncated JSON preview. Export never mutates build/variant data or soft targets.

**Why this priority**: UX feedback and hard rule that soft/export never write library state.

**Independent Test**: Successful export → status message set; soft targets unchanged; no DB writes to builds/sets from export path.

**Acceptance Scenarios**:

1. **Given** successful clipboard write, **When** export finishes, **Then** status indicates success and last JSON payload is retained for preview.
2. **Given** clipboard write failure, **When** export finishes, **Then** error is shown and no success status.
3. **Given** any export path, **When** complete, **Then** soft suggestions were never auto-applied and variant pins are unchanged.

---

### Edge Cases

- Empty combat equipment → equip-ready false → export blocked.
- Stale pin (instance missing after sync) → equip-ready false.
- Fashion/artifact absent → loadout unequipped empty / notes omit artifact (domain defaults).
- modHashes empty → parameters omit mods (DART-010 parity).
- Soft coverage chips remain display-only; export does not apply soft suggestions.
- Sign-in is **not** required for local jsonOnly clipboard (no network); equip-ready is the hard gate. (dim.gg later may require auth.)
- No CLIENT_SECRET anywhere in export surface.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Builds detail MUST show a DIM export panel when a variant is selected.
- **FR-002**: Panel MUST compute equip-ready from resolved variant equipment + local inventory pin index (same semantics as equip UI / DART-006).
- **FR-003**: Export CTA MUST be disabled when not equip-ready, exporting busy, or no variant bound.
- **FR-004**: Export MUST call domain `buildJsonOnlyDimExport` (which asserts equip-ready) and MUST NOT bypass the gate.
- **FR-005**: On success, system MUST write the jsonOnly payload as a UTF-8 JSON string to the clipboard (pretty-printed).
- **FR-006**: On gate failure, system MUST NOT write clipboard and MUST surface not-equip-ready guidance.
- **FR-007**: Soft guidance MUST NOT auto-apply as part of export; export MUST NOT mutate soft targets or pins.
- **FR-008**: Unit/widget tests MUST cover blocked CTA when not ready, successful clipboard payload shape when ready, and no clipboard on hard block (injectable clipboard; no live Bungie; no CLIENT_SECRET).

### Key Entities

- **JsonOnlyDimExport**: `{ loadout }` map from `buildJsonOnlyDimExport`.
- **DimExportReadinessView**: equipReady flag + pin statuses for UI.
- **DimExportController**: host orchestration (readiness, build payload, clipboard).
- **ClipboardWriter**: injectable `Future<void> Function(String text)` for tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Wishlist-only variant cannot write clipboard from export.
- **SC-002**: Owned-pin equip-ready variant can export and clipboard receives a `loadout` JSON envelope.
- **SC-003**: Domain gate throws/returns `NOT_EQUIP_READY` path when not ready; UI does not claim success.
- **SC-004**: No CLIENT_SECRET in host/export surface; pure Dart I/O only; no dim.gg network in this slice.

## Assumptions

- **A1**: DIM export panel lives on Builds library detail (with equip panel), not a new nav rail destination.
- **A2**: jsonOnly clipboard only — **no** dim.gg share in DART-039 (deferred per port decisions).
- **A3**: Clipboard via Flutter `Clipboard.setData` in production; injectable writer for tests.
- **A4**: Sign-in not required for local jsonOnly; equip-ready is the sole hard export gate for this slice.
- **A5**: Soft stat targets from build identity are passed into `VariantDimLoadoutInput` when present; soft never auto-applies.
- **A6**: `modHashes` empty unless already available without new mod-collection I/O.
- **A7**: Fashion/artifact inputs null/empty when host does not model them yet.
- **A8**: Loadout `id` generated per export (UUID string) for uniqueness; tests may inject fixed id.
- **A9**: Soft never auto-applies; export does not mutate soft targets or coverage.
- **A10**: Reuses DART-010 pure builders; no new domain package required.
