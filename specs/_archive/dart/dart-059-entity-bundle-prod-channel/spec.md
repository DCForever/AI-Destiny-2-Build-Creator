# Feature Specification: DART-059 Entity Bundle Prod Channel

**Feature Branch**: `dart-059-entity-bundle-prod-channel`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Choose/harden entity bundle distribution for web. GAP-WEB-02; RB-05 / RC-WEB-DATA. Channel (ship-in-app/CDN/hybrid) + versioning; prod web Catalog loads non-fixture entity data offline; offline compose without Next manifest API."

**Program ID**: DART-059  
**Phase**: P8  
**Depends**: DART-044 (prebuilt entity bundles)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) — **D-WEB-DB** prefer prebuilt entity bundles on web; no browser raw rebuild  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-WEB-02**  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RB-05** / **RC-WEB-DATA**

## Scope boundary

**In scope:**

- **Choose** and document production entity-bundle distribution channel: **hybrid** (ship-in-app primary for offline-after-install + optional CDN override for hot version bumps)
- **Versioning contract**: channel pointer document (`channel.json`) + bundle `manifestVersion` / `bundleVersion`
- Pure Dart channel types + URL candidate resolution (testable without browser)
- Harden Jaspr `WebEntityBundleLoader` to resolve channel → try ordered URLs → report source (ship-in-app | cdn) and version
- Ship **production channel path** (`web/entities/prod/bundle.json` + `web/entities/channel.json`) distinct from DART-044 MVP fixture path (`web/entities/prebuilt/…`)
- Prod web Catalog loads non-fixture (channel-prod) entity data offline after install (same-origin static assets; no Next `/api` manifest)
- Offline compose continues without Next manifest API (entities from prebuilt channel; builds/sets/synergies in Drift OPFS)
- Close **GAP-WEB-02**; clear **RB-05**; set **RC-WEB-DATA** **PASS** with evidence
- Soft never auto-applies; pure Dart I/O only; no `CLIENT_SECRET`; no Node sidecar

**Out of scope (do not implement in this slice):**

- Full raw DestinyManifest download / isolate rebuild in browser (desktop remains DART-018)
- Dual-run ops / PRODUCTION_CUTOVER GO (DART-060–061)
- Service-worker / full PWA offline shell (ship-in-app static assets suffice for “after install” of the SPA package)
- Growing the prod sample bundle to full live Destiny item catalog size (operators replace sample with extracted prod bundle; format + channel are fixed)
- CDN hosting infrastructure provisioning (code accepts optional `cdnUrl`; ops owns the host)
- Changing product DBR/DAC hard/soft rules

## Assumptions

- **A1**: **Chosen channel = hybrid**. Primary offline path is **ship-in-app** same-origin static JSON under `/entities/prod/`. Optional **CDN** URL may be set in `channel.json` or compile-time define for hot updates; on CDN failure the loader **falls back** to ship-in-app.
- **A2**: “Non-fixture” means Catalog default path uses **prod channel** assets (`channelId: prod`, versioned `entity-bundle-prod-*`), not the DART-044 demo path labeled `prebuilt-mvp-*`. Repo may still ship a **small sample** prod bundle for CI/demo; operators swap in full extract without code changes.
- **A3**: “Offline after install” means once the web app static assets (including ship-in-app bundle) are installed/cached with the deploy, Catalog facets and compose library work **without** calling Next.js manifest APIs or requiring a live Bungie entity rebuild.
- **A4**: Compose offline path already uses Drift OPFS + pure use cases (DART-046); this slice only ensures entity definitions for Catalog / pins do not depend on Next.
- **A5**: Legacy `/entities/prebuilt/bundle.json` remains as a **dev/demo fallback** only when channel pointer or prod path is missing.
- **A6**: Soft guidance never auto-applies; no OAuth/secret work in this slice.
- **A7**: Pure Dart I/O only; no Node sidecar; no `CLIENT_SECRET`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Documented hybrid channel with versioning (Priority: P1)

As a cutover operator, I have a published decision that web entities use **hybrid** distribution (ship-in-app primary, optional CDN) with an explicit versioning scheme (`channel.json` + bundle `manifestVersion`).

**Why this priority**: Exit criteria require chosen channel documented with versioning; RB-05 / RC-WEB-DATA.

**Independent Test**: Doc + pure Dart channel parse/resolve unit tests; constants match doc paths.

**Acceptance Scenarios**:

1. **Given** the channel decision doc, **When** read, **Then** it states hybrid, ship-in-app primary path, optional CDN, and versioning fields.
2. **Given** a valid `channel.json`, **When** parsed, **Then** `channelId`, `bundleVersion`, `distribution`, and `shipInAppPath` are available.
3. **Given** hybrid channel with both CDN and ship-in-app, **When** candidates are resolved, **Then** CDN URL is tried before ship-in-app path.

---

### User Story 2 - Prod Catalog loads non-fixture entities offline (Priority: P1)

As a browser user on the production Jaspr host, Catalog loads entity data from the **prod channel** (not MVP fixture version id) after app install, using same-origin assets, without Next manifest API.

**Why this priority**: Exit criteria — prod web Catalog offline non-fixture data.

**Independent Test**: Loader tests with channel + prod bundle fixtures; assert version prefix / channel source; Catalog path uses channel resolver.

**Acceptance Scenarios**:

1. **Given** channel pointer + prod bundle JSON, **When** loader runs, **Then** status is ready with prod bundle version and source ship-in-app (or cdn when injected).
2. **Given** CDN fetch fails and ship-in-app succeeds, **When** hybrid load runs, **Then** ready status with source ship-in-app (fallback).
3. **Given** loaded prod catalog, **When** facets apply, **Then** pure offline filter works (no network beyond initial static fetch).
4. **Given** host bootstrap, **When** default URLs are used, **Then** they point at channel / prod paths (not only prebuilt-mvp).

---

### User Story 3 - Offline compose without Next manifest API (Priority: P1)

As a web user with OPFS writer + entity channel loaded, I can compose builds offline without calling Next `/api` manifest endpoints.

**Why this priority**: Exit criteria — offline compose without Next manifest API.

**Independent Test**: Code/docs assert entity loader uses only static entity URLs; compose services use Drift + domain (existing tests remain green); no Next manifest path in entity channel code.

**Acceptance Scenarios**:

1. **Given** entity channel load path, **When** inspected, **Then** URLs are under `/entities/…` or optional CDN — never Next `/api/manifest` or similar.
2. **Given** Settings / docs, **When** read, **Then** they state Catalog + compose entities come from prebuilt channel, full rebuild is desktop-first.
3. **Given** existing compose/library tests, **When** re-run, **Then** they stay green (non-regression).

---

### Edge Cases

- Channel JSON missing → fall back to default prod path then legacy prebuilt path
- CDN only configured but offline → ship-in-app fallback still works
- Empty prod bundle stores → empty phase (same as DART-044), not crash
- Invalid channel schema → typed error / safe fallback
- Soft never auto-applies

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST document the chosen distribution channel as **hybrid** (ship-in-app primary, optional CDN) with versioning.
- **FR-002**: System MUST define a channel pointer document schema (`schemaVersion`, `channelId`, `bundleVersion`, `distribution`, `shipInAppPath`, optional `cdnUrl`).
- **FR-003**: System MUST resolve ordered load candidates: CDN (if set) then ship-in-app then legacy prebuilt fallback.
- **FR-004**: Jaspr web host MUST load entities via channel-aware loader for Catalog (and shared entity bootstrap).
- **FR-005**: Production default paths MUST use `/entities/channel.json` + `/entities/prod/bundle.json` (not only MVP prebuilt).
- **FR-006**: Web entity path MUST NOT call Next.js manifest APIs or perform full raw browser rebuild.
- **FR-007**: Offline compose MUST continue to work without Next manifest API (entities from channel; library in Drift).
- **FR-008**: Cutover checklist MUST clear RB-05 and set RC-WEB-DATA PASS with evidence when exit criteria are met.
- **FR-009**: Soft guidance MUST never auto-apply; no `CLIENT_SECRET` in clients.

### Key Entities

- **EntityBundleChannel**: Pointer document (version + distribution + paths)
- **EntityBundleDistribution**: `shipInApp` | `cdn` | `hybrid`
- **EntityBundleLoadSource**: which candidate succeeded (`shipInApp` | `cdn` | `legacyPrebuilt`)
- **EntityBundleDocument**: existing DART-044 bundle body
- **WebEntityBundleLoader**: channel-aware fetch + parse + OfflineCatalog

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Channel parse/resolve unit tests pass (hybrid ordering + fallback).
- **SC-002**: Web loader tests pass for prod channel load + CDN→ship-in-app fallback.
- **SC-003**: GAP-WEB-02 closed; RB-05 cleared; RC-WEB-DATA **PASS** in cutover checklist with dated evidence.
- **SC-004**: Roadmap DART-059 status **done**; Current pointer advances to DART-060.
- **SC-005**: No Next manifest API dependency in entity channel load path (static `/entities` or optional CDN only).

## Assumptions (defaults for NEEDS CLARIFICATION)

See Assumptions A1–A7 above. No open NEEDS CLARIFICATION retained.
