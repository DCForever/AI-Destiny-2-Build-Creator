# Feature Specification: Reject client proposal fallback on confirm

**Feature Branch**: `037-reject-proposal-fallback`  
**Created**: 2026-07-23  
**Status**: Active  
**Input**: Improve prompt `specs/023-llm-propose/improve/reject-client-proposal-fallback.md`

## User Scenarios & Testing

### User Story 1 - Confirm only server-held proposals (Priority: P1)

As a signed-in guardian, when I accept proposals from a scan that the server still holds, confirm creates synergies only from those server-stored proposal ids.

**Why this priority**: Core happy path must keep working after removing the insecure fallback.

**Independent Test**: Run mock propose pass, confirm one synergy id, assert one user synergy created.

**Acceptance Scenarios**:

1. **Given** an in-memory pass from a successful scan, **When** the user confirms accepted synergy ids, **Then** matching synergies are created and listed for the user.
2. **Given** accepted ids that are not on the server pass, **When** confirm runs, **Then** those ids create no synergies (skipped/ignored).

### User Story 2 - Missing pass never trusts client bodies (Priority: P1)

As an attacker or confused client, posting crafted `proposals` (or any body) against an unknown `passId` must not create synergies.

**Why this priority**: Closes DBR-LLM-002 bypass via client-supplied proposal replay.

**Independent Test**: Clear store, call `confirmProposals` with non-empty fallback-shaped payload and accepted ids; expect 404-class error and zero synergies.

**Acceptance Scenarios**:

1. **Given** no server pass for `passId`, **When** confirm is invoked with accepted ids and client proposal arrays, **Then** the call fails with unknown-pass 404 and creates zero synergies.
2. **Given** a lost pass after HMR/restart, **When** the client confirms without re-scanning, **Then** the error message tells them to re-run the scan.

### User Story 3 - Pass ownership (Priority: P2)

As the system, a propose pass is bound to the authenticated user who created it so another session cannot confirm a stolen pass id.

**Why this priority**: Optional hardening called out in the improve prompt; small and in-scope.

**Independent Test**: Save pass under user A, confirm as user B → 404/forbidden-equivalent with zero synergies.

**Acceptance Scenarios**:

1. **Given** a pass stored with `userId` A, **When** user B confirms, **Then** confirm fails without creating synergies.
2. **Given** a pass stored with `userId` A, **When** user A confirms valid ids, **Then** synergies are created.

## Requirements

### Functional Requirements

- **FR-001**: System MUST NOT rebuild or trust client-supplied proposal lists on confirm.
- **FR-002**: When `getProposePass(passId)` is missing, confirm MUST fail with the existing unknown-pass error (HTTP 404) and MUST create zero synergies.
- **FR-003**: Accepted ids MUST resolve only against server-stored proposals for that pass.
- **FR-004**: Confirm request contract MUST stop accepting or MUST ignore `proposals` on the body; docs MUST reflect the contract.
- **FR-005**: System SHOULD bind stored passes to the creating `userId` and reject confirm from a different user as unknown pass.
- **FR-006**: Unknown-pass error copy MUST direct the client to re-run the scan after refresh/restart.
- **FR-007**: Tests MUST cover malicious missing-pass + client proposals path and happy-path confirm with server pass.

### Key Entities

- **Propose pass**: Server-held ephemeral record (`passId`, `createdAt`, `proposals`, optional `userId`).
- **Proposal**: Server-authored candidate (synergy/keyword/evidence) with stable id within the pass.
- **Confirm result**: Created synergy mappings, skipped ids, ignored keyword/evidence ids.

## Success Criteria

- **SC-001**: Unit test proves missing pass + client proposals throws and creates zero synergies.
- **SC-002**: Unit test proves valid server pass + accepted synergy still creates one synergy.
- **SC-003**: `rg -n "proposalsFallback" src` shows no trust-client-rebuild path.
- **SC-004**: `npm run test`, `npm run typecheck`, and `npm run lint` pass.

## Assumptions

- Clarify skipped; assumptions documented here.
- In-memory store remains acceptable; SQLite durability is out of scope.
- Keyword/evidence kinds remain non-persisting on accept (v1).
- Domain DBR-LLM-002 already states propose-for-confirm; this change enforces it and does not introduce a new product rule beyond optional user binding noted in feature BR.
- Clients may still hold proposal copies for UI display but MUST NOT send them as authority on confirm.
