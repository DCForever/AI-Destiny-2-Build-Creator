# Feature Specification: DART-047 Jaspr Equip Export

**Feature Branch**: `dart-047-jaspr-equip-export`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Equip-ready + DIM json + optional equip on web. Same domain packages as Flutter."

**Program ID**: DART-047  
**Phase**: P5  
**Depends**: DART-046 (Jaspr compose spine), DART-037 (equip orchestrator), DART-010 (DIM builders)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (D-IO pure Dart; Public+PKCE; soft never auto-applies)

## Scope boundary

**In scope:**

- Jaspr **web host** equip + DIM surfaces on **Build compose** when a **variant** is selected:
  - **Equip-ready** evaluation (same pure domain `computeEquipReady` / pin statuses as Flutter)
  - **DIM jsonOnly** clipboard export via domain `buildJsonOnlyDimExport` (blocked when not equip-ready)
  - **Optional equip**: character pick (class-filtered) + Apply CTA + gaps confirm + step report via DART-037 plan/execute
- Pure display helpers for readiness, pin gaps, equip CTA enablement, DIM CTA, step report, JSON preview
- Controllers with injectable write client / profile client / clipboard (tests: memory DB, no live Bungie)
- Wire public API key only for live profile/write clients (never `CLIENT_SECRET`)

**Out of scope (later / deferred):**

- dim.gg share / DIM Sync network client
- Full inventory sync UI / owned catalog filter on web (readiness uses local inventory table when present)
- Optimizer on web
- Soft guidance auto-apply (forbidden)
- Flutter Windows/mobile changes
- Node sidecar / confidential OAuth / CLIENT_SECRET
- Product Next.js route changes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Equip-ready on web compose (Priority: P1)

As a web user with a selected variant, I see equip-ready status and pin gap labels (wishlist/stale/owned). Soft guidance remains display-only and never auto-applies.

**Why this priority**: Roadmap exit — equip-ready on web using same domain packages as Flutter.

**Independent Test**: Seed wishlist pin → equipReady false; seed owned instance + inventory row → equipReady true.

**Acceptance Scenarios**:

1. **Given** a selected variant with only wishlist pins, **When** readiness is evaluated, **Then** equip-ready is false and pin gap list shows wishlist.
2. **Given** owned instance pins present in local inventory, **When** readiness is evaluated, **Then** equip-ready is true.
3. **Given** no variant selected, **When** equip/export sections render, **Then** readiness is idle / CTAs disabled.

---

### User Story 2 - DIM jsonOnly clipboard export (Priority: P1)

As a web user with an equip-ready variant, I can **Copy DIM JSON** to build a jsonOnly `{ loadout }` envelope and place it on the clipboard. Export is blocked when not equip-ready.

**Why this priority**: Roadmap exit — DIM json on web.

**Independent Test**: Owned pin + inventory → export → clipboard receives JSON with `loadout`; wishlist → no clipboard write.

**Acceptance Scenarios**:

1. **Given** not equip-ready, **When** export is requested, **Then** clipboard is not written and status/error references not equip-ready.
2. **Given** equip-ready owned pins, **When** I export, **Then** clipboard receives pretty-printed JSON with root `loadout` and equipped hashes/instance ids.
3. **Given** successful export, **When** finished, **Then** status indicates copied and optional truncated JSON preview is available.
4. **Given** any export path, **When** complete, **Then** soft suggestions were never auto-applied and pins are unchanged.

---

### User Story 3 - Optional equip + step report (Priority: P2)

As a signed-in web user with equip-ready variant and matching-class character, I can Apply equip (optional write path). Empty combat slots require gaps confirm. Step report shows completed/failed. Soft never auto-applies.

**Why this priority**: Roadmap — optional equip on web; same DART-037 domain/orchestrator as Flutter.

**Independent Test**: Mock write client; equip-ready + character → apply → write called + step report; not ready → no write.

**Acceptance Scenarios**:

1. **Given** signed out, **When** equip section renders, **Then** sign-in guidance is shown and Apply is disabled.
2. **Given** equip-ready, matching character selected, no empty combat gaps (or after confirm), **When** Apply runs with mock write, **Then** step report shows completed ≥ 0 and write client was invoked.
3. **Given** equip-ready with empty combat slots, **When** Apply pressed, **Then** gaps confirm appears; cancel → no write; confirm → execute.
4. **Given** not equip-ready, **When** Apply invoked programmatically, **Then** write client is not called.

---

### Edge Cases

- Empty combat equipment → equip-ready false → equip + DIM blocked.
- Stale pin (instance missing in inventory) → equip-ready false.
- Character class mismatch → equip blocked.
- Fashion/artifact optional; plan may omit when not modeled.
- Second tab without writer DB → compose blocked (existing); equip/export not available.
- No CLIENT_SECRET anywhere in equip/export surface.
- Sign-in not required for local jsonOnly DIM; equip requires sign-in + write client.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Build compose MUST show equip-ready summary and pin gap list when a variant is bound.
- **FR-002**: Readiness MUST use domain `computeEquipReady` with resolved equipment + local inventory pin index (same as Flutter).
- **FR-003**: DIM export CTA MUST be disabled when not equip-ready, exporting, loading, or no variant.
- **FR-004**: DIM export MUST call domain `buildJsonOnlyDimExport` (asserts equip-ready) and MUST NOT bypass the gate; MUST write clipboard only on success.
- **FR-005**: Equip Apply CTA MUST be disabled when not signed in, no character, not equip-ready, or busy.
- **FR-006**: Equip MUST call `assertEquipReady` before `planEquipSteps` / `executeEquipPlan` (DART-037).
- **FR-007**: Empty combat slots when equip-ready MUST require explicit gaps confirm before execute.
- **FR-008**: After equip execute, UI MUST show step report (completed/failed + step lines).
- **FR-009**: Soft guidance MUST NOT auto-apply as part of equip or export.
- **FR-010**: Unit tests MUST cover blocked DIM when not ready, successful clipboard when ready, equip gate with mock write client (no live Bungie; no CLIENT_SECRET).

### Key Entities

- **EquipReadyResult / PinStatus**: domain readiness (DART-006).
- **JsonOnlyDimExport**: `{ loadout }` from `buildJsonOnlyDimExport` (DART-010).
- **EquipController**: web host orchestration (characters, readiness, confirm, execute).
- **DimExportController**: web host orchestration (readiness, payload, clipboard).
- **ClipboardWriter**: injectable `Future<void> Function(String text)`.
- **EquipStatus / EquipStepResult**: domain plan execute report (DART-037).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Wishlist-only variant cannot write clipboard from DIM export or invoke write client from Apply.
- **SC-002**: Owned-pin equip-ready variant can export jsonOnly `{ loadout }` to clipboard.
- **SC-003**: Optional equip with mock write produces step report; gaps cancel prevents write.
- **SC-004**: Same domain packages as Flutter (`destiny2_domain` equip-ready / dim / plan; `destiny2_bungie` write orchestrator); no CLIENT_SECRET; pure Dart I/O only.

## Assumptions

- **A1**: Equip + DIM live on Build compose detail (not new nav destinations).
- **A2**: DIM is jsonOnly clipboard only — no dim.gg.
- **A3**: Inventory for readiness comes from local Drift inventory table (may be empty until user has synced data; tests seed rows). Full web inventory sync UI is later.
- **A4**: Pre-equip `syncIfStale` is optional and skippable in tests; production may call it when profile client + token available.
- **A5**: Soft never auto-applies; export/equip do not mutate soft targets or pins (except equip writes to Bungie, not local soft state).
- **A6**: Clipboard default uses browser clipboard API; tests inject capturing writer.
- **A7**: Characters via `BungieProfileClient.getCharacters`; write via `BungieWriteClient` + `executeEquipPlan`.
- **A8**: Public API key only (`BUNGIE_API_KEY` dart-define); never CLIENT_SECRET.
- **A9**: No NEEDS CLARIFICATION retained — defaults above apply.
