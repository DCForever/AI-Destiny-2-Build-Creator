# Feature Specification: DART-037 Equip Orchestrator

**Feature Branch**: `dart-037-equip-orchestrator`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "planEquipSteps + execute + partial status (write client). Best-effort partial; no full rollback; tests with mocked write API."

**Program ID**: DART-037  
**Phase**: P4  
**Depends**: DART-006 (equip-ready pure), DART-024 (profile/inventory shapes for location-aware plan)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- **Pure plan** (`planEquipSteps`) mirroring TypeScript `src/lib/builds/equipPlan.ts`:
  - Combat pin order: transfer (vault hop / vault pull) → equip per combat slot
  - Then optional artifact step, then fashion steps (omit empty)
  - Throw `NOT_EQUIP_READY` when a combat pin instance is missing from inventory
- **Bungie write client** (`BungieWriteClient`) mirroring `src/lib/bungie/writeClient.ts`:
  - `transferItem`, `equipItem`, `applyArtifactConfig`, `applyFashionSlot`
  - HTTP implementation via existing `BungieHttpClient` / transport
  - Mock factory for tests
- **Orchestrator** (`executeEquipPlan`) mirroring `src/lib/builds/equipOrchestrator.ts`:
  - Run planned steps in order via write client
  - Best-effort partial status (ok/error per step)
  - **No full rollback** of prior successful steps
- Unit tests with mocked write API / mocked HTTP (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Flutter equip UI / character pick / CTA (DART-038)
- DIM export UI (DART-039)
- Post-equip inventory resync UI wiring
- Full seasonal artifact socket wiring (parity: explicit failure stub until season-wired)
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)
- Product Next.js route changes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plan equip steps from pins + inventory (Priority: P1)

As a multiplatform host, I can call pure `planEquipSteps` with resolved combat equipment, optional artifact/fashion, inventory rows (location + character), and a target `characterId` to get an ordered list of transfer/equip/artifact/fashion steps without network I/O.

**Why this priority**: Roadmap goal `planEquipSteps`; foundation for execute.

**Independent Test**: Fixtures mirror `equipPlan.test.ts` — vault transfer, other-character vault hop, skip transfer when already on character, omit empty fashion/artifact, NOT_EQUIP_READY on missing combat instance.

**Acceptance Scenarios**:

1. **Given** a helmet pin whose instance is in vault, plus artifact and fashion ghost, **When** plan runs, **Then** kinds are `transfer → equip → artifact → fashion` with stable step ids.
2. **Given** a primary pin equipped on another character, **When** plan runs, **Then** steps are vault-hop transfer to vault, transfer from vault, then equip.
3. **Given** arms already on the target character inventory, **When** plan runs, **Then** only equip (no transfer).
4. **Given** empty equipment, null artifact, empty fashion slots, **When** plan runs, **Then** plan is empty.
5. **Given** a combat pin whose instanceId is absent from inventory, **When** plan runs, **Then** it throws with code `NOT_EQUIP_READY`.

---

### User Story 2 - Execute plan via write client (Priority: P1)

As a multiplatform host, I can execute a planned step list with a `BungieWriteClient` + access token context so each step maps to the correct Platform write action in order.

**Why this priority**: Roadmap goal `execute + write client`.

**Independent Test**: Mock write client records call order for transfer/equip/artifact/fashion; assert completed count and zero failures.

**Acceptance Scenarios**:

1. **Given** a four-step plan (transfer, equip, artifact, fashion), **When** `executeEquipPlan` runs against a success mock, **Then** write methods are invoked once each in plan order and status has `completed == 4`, `failed == 0`.
2. **Given** an HTTP write client + mocked transport returning Platform success, **When** transfer/equip posts fire, **Then** paths and body fields match Bungie Platform contracts (no client_secret).

---

### User Story 3 - Best-effort partial status (no rollback) (Priority: P1)

As a multiplatform host, when a middle step fails, prior successful steps remain applied (no automatic undo) and later steps still attempt so the status reports per-step ok/error plus completed/failed counts.

**Why this priority**: Roadmap exit criterion — best-effort partial; no full rollback.

**Independent Test**: Mock equip fails on one instance; assert prior transfer ok, failed equip has error string, later equip still runs and may ok; `completed`/`failed` counts match.

**Acceptance Scenarios**:

1. **Given** plan [transfer ok, equip fail, equip ok], **When** execute runs, **Then** step results are ok/false/ok, `completed == 2`, `failed == 1`, and no compensating transfer is issued to reverse the first step.
2. **Given** any step throws, **When** orchestrator catches, **Then** that step is `ok: false` with `error` message and execution continues.

---

### Edge Cases

- Combat claims without `instanceId` are skipped by the planner (wishlist gaps are not equip steps); missing inventory for a present instanceId hard-fails plan.
- Fashion without a matching owned hash still produces a fashion step with null `instanceId` (HTTP fashion apply will fail at execute — parity with TS).
- Artifact apply remains explicitly not fully wired on HTTP client (throws a clear error); mock can succeed for orchestrator tests.
- Soft guidance never auto-applies; this slice has no save path.
- No CLIENT_SECRET fields on write client or package surface.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain (or pure layer) MUST export `planEquipSteps(EquipPlanInput) → List<PlannedEquipStep>` with combat order transfer→equip, then artifact, then fashion.
- **FR-002**: Planner MUST vault-hop (to vault then from vault) when item is on another character; vault→character transfer when location is vault; skip transfer when already on target character.
- **FR-003**: Planner MUST throw with code `NOT_EQUIP_READY` when combat pin instance is missing from inventory.
- **FR-004**: Package MUST export `BungieWriteClient` with transfer/equip/artifact/fashion methods and a mock factory for tests.
- **FR-005**: HTTP write client MUST POST Platform equip/transfer endpoints with API key + Bearer token only (no client_secret).
- **FR-006**: Package MUST export `executeEquipPlan` that runs steps in order, records per-step ok/error, and never rolls back prior ok steps.
- **FR-007**: Equip status MUST expose `steps`, `completed`, and `failed` counts.
- **FR-008**: Unit tests MUST cover plan matrix + execute success + partial failure with mocked write API.
- **FR-009**: Soft guidance MUST NOT auto-apply; equip orchestrator does not mutate local library/save state.

### Key Entities

- **PlannedEquipStep**: id, kind (`transfer` | `equip` | `artifact` | `fashion`), optional slot/itemHash/instanceId/transferToVault/artifactConfig.
- **EquipPlanInput**: equipment map, optional artifact, optional fashion slots, inventory rows, characterId.
- **EquipInventoryItem**: instanceId, itemHash, location, optional characterId (plan input DTO).
- **WriteClientContext**: accessToken, membershipType.
- **EquipStepResult**: PlannedEquipStep + ok + optional error.
- **EquipStatus**: steps, completed, failed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Plan golden cases from TS `equipPlan.test.ts` pass in Dart unit tests.
- **SC-002**: Execute success + partial-failure cases from TS orchestrator tests pass with mock write client.
- **SC-003**: HTTP write client unit tests assert Platform POST shapes without secrets.
- **SC-004**: No full-rollback logic exists; partial status is the only failure model.

## Assumptions

- **A1**: Pure planner lives in `packages/domain` (zero IO) so Flutter/Jaspr hosts and later slices share one plan implementation.
- **A2**: Write client + `executeEquipPlan` live in `packages/bungie` and depend on `destiny2_domain` for plan step types.
- **A3**: Fashion plan input uses string slot keys (wire names) matching TS fashion.slots keys.
- **A4**: Artifact HTTP apply remains a documented stub throw until season wiring (product parity); mocks succeed in orchestrator tests.
- **A5**: Inventory location strings match product: `vault` | `character` | `equipped`.
- **A6**: Equip-ready gate (`assertEquipReady`) remains caller responsibility before plan/execute (route-level in product); planner only enforces combat instance presence for steps it builds.
- **A7**: No Flutter UI in this slice (DART-038).
- **A8**: No CLIENT_SECRET / confidential OAuth in this package surface.
