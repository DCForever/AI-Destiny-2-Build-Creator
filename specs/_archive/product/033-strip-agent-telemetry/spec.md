# Feature Specification: Strip Agent Debug Telemetry

**Feature Directory**: `specs/033-strip-agent-telemetry`  
**Branch**: `033-strip-agent-telemetry`  
**Created**: 2026-07-23  
**Status**: Draft  
**Input**: Remove leftover agent debug ingest telemetry (`#region agent log` blocks fetching `http://127.0.0.1:7497/ingest/...`) from production `src/` paths.

## Problem Statement

Several production code paths unconditionally send debug payloads (error messages, LLM endpoint/model, client failure details) to a fixed local ingest URL on port 7497. That behavior is leftover agent instrumentation: it is not product telemetry, adds failed network work on every generate path, and can leak operational details to whatever listens on that port.

## Stakeholders

- **Primary**: Developers and operators shipping Destiny 2 Build Creator
- **Secondary**: End users (indirectly benefit from fewer spurious network calls and no local debug side effects)

## User Scenarios & Testing

### US-1: Generate build without local debug side effects (P1)

**Actor**: End user (or automated client) generating a build  
**Precondition**: Application is running; no local process is required on port 7497  
**Flow**:
1. User triggers build generation (UI or API).
2. Server and client execute normal success or failure paths.
3. No request is made to `127.0.0.1:7497` (or any agent-log ingest URL) as part of generate/LLM/error handling.

**Acceptance**:
- Given generate succeeds or fails, when network activity is observed for the request lifecycle, then there are zero calls to the agent debug ingest endpoint from application code under `src/`.
- User-visible error messages and HTTP status codes for generate failures remain unchanged from pre-change behavior (aside from absence of the silent debug fetch).

### US-2: Developer verifies instrumentation is gone (P1)

**Actor**: Developer / reviewer  
**Flow**:
1. Search the tree under `src/` for agent-log region markers and the ingest URL pattern.
2. Run the standard quality gate (typecheck, lint, test, build).

**Acceptance**:
- Search returns no matches for `7497/ingest` or `#region agent log` under `src/`.
- Quality gate commands pass.

### US-3: LLM provider failures still surface correctly (P1)

**Actor**: End user when LLM backend fails  
**Flow**:
1. LLM client (OpenAI-compatible or Ollama path) fails to fetch or returns an error.
2. API and UI continue to report the failure through existing error channels.

**Acceptance**:
- Catch blocks still throw or return the same class of errors/status payloads as before.
- No replacement always-on telemetry is introduced in those catch paths.

## Requirements

### Functional Requirements

- **FR-001**: The codebase under `src/` MUST NOT contain `#region agent log` / `#endregion` blocks used for local debug ingest.
- **FR-002**: The codebase under `src/` MUST NOT call `http://127.0.0.1:7497/ingest/...` (or any path on port 7497 used for agent debug ingest).
- **FR-003**: Removing agent-log blocks MUST preserve surrounding control flow: try/catch structure, rethrows, HTTP status codes, and user-facing error JSON/UI messages.
- **FR-004**: The change MUST NOT introduce new always-on product telemetry, analytics SDKs, or unconditional external network calls as a substitute.
- **FR-005**: The change MUST NOT log secrets, auth tokens, full prompts, or API keys as part of cleanup.
- **FR-006**: All known sites MUST be cleaned, including at minimum:
  - `src/app/api/build/route.ts` (catch path)
  - `src/lib/services.ts` (`runBuildGeneration` start + LLM config)
  - `src/lib/llm/ollamaClient.ts` (request start/catch)
  - `src/lib/llm/openAiClient.ts` (request start/catch)
  - `src/components/GeneratorPage.tsx` (client non-ok and catch)
  - plus any other `src/**` hits of the same pattern discovered during implementation.

### Non-Functional / Quality

- **NFR-001**: `npm run typecheck` passes after the change.
- **NFR-002**: `npm run lint` passes after the change.
- **NFR-003**: `npm run test` passes after the change.
- **NFR-004**: `npm run build` passes after the change (when feasible in the environment).

## Success Criteria

- **SC-001**: A repository search under `src/` for `7497/ingest` and `#region agent log` returns **zero** matches.
- **SC-002**: Build generation and LLM error paths behave the same for users: failures still produce actionable errors; successes still return builds.
- **SC-003**: No new unconditional debug network side effect is present on the generate path.
- **SC-004**: Standard CI-equivalent local gates (typecheck, lint, test; build if run) are green.

## Scope

### In scope

- Deletion of leftover agent debug ingest instrumentation under `src/`.
- Verification via search and quality gates.
- Spec Kit artifacts for this feature (`specs/033-strip-agent-telemetry/`).

### Out of scope

- Redesigning LLM or generate error UX.
- Adding structured logging infrastructure or env-gated diagnostics (optional future work).
- Changing generate/analyze auth policy.
- Domain product rule changes (this is engineering cleanup, not player-facing feature semantics).

## Assumptions

- A1: No automated test asserts on the ingest side effect; if any do, they should be updated or removed as part of implementation (none expected).
- A2: Cleaning `src/` is the required gate; identical patterns outside `src/` may be cleaned opportunistically in the same pass if found, but are not required for acceptance unless they ship in production bundles.
- A3: Domain docs (`DBR`/`DAC`/`BR`) do not need updates because no product rule changes.
- A4: Session UUID in the ingest path is an identifier only and must not be reintroduced.

## Dependencies

- None. Independent of other improve batch items.

## Risks

- **R-001 (LOW)**: Over-deletion could remove legitimate comments that only look like agent regions — mitigate by matching the known `fetch('http://127.0.0.1:7497/ingest/...')` pattern and its enclosing region markers.
- **R-002 (LOW)**: Subtle control-flow breakage if a region is mid-expression — mitigate by deleting whole region blocks only and re-running typecheck/tests.
