# Feature Specification: Transactional variant saves

**Feature Branch**: `039-transactional-variant-saves`

**Created**: 2026-07-23

**Status**: Active

**Input**: Equipment-affecting variant/build attachment saves must validate then commit (or roll back). Bare create without attachments stays progressive. Illegal attach leaves DB unchanged.

**Improve**: `specs/build-save-integrity/improve/002-transactional-variant-saves.md`

## User Scenarios & Testing

### User Story 1 - Rejected attach does not corrupt variant (Priority: P1)

Composer tries to attach an illegal kit (e.g. incomplete default loadout, pair armor mismatch, dual exotic). API returns hard `ApiError`; prior attachments and equipment fields on the variant remain exactly as before the request.

**Why this priority**: DBR-CMP-006/007, DBR-MOD-001 — illegal kits cannot be saved; torn rows break trust.

**Independent Test**: Create legal empty build; attempt illegal `updateUserVariant` attachments; assert `listAttachments` unchanged and error code preserved.

**Acceptance Scenarios**:

1. **Given** a default variant with no attachments, **When** user PATCHes incomplete weapon-only attachments, **Then** API returns `DEFAULT_VARIANT_INCOMPLETE` and attachments stay empty.
2. **Given** a default variant with prior legal empty state, **When** user PATCHes pair set with wrong exotic armor, **Then** API returns `PAIR_ARMOR_MISMATCH` and no attachment rows exist.

### User Story 2 - Legal attach still commits (Priority: P1)

Legal equipment-affecting updates still persist attachments and variant fields and are visible via `getBuildDetail`.

**Independent Test**: Non-default or complete path that passes gates commits attachments.

### User Story 3 - Progressive bare create (Priority: P1)

`createUserBuild` without default attachments does not require full combat loadout.

**Independent Test**: Create with synergies only; succeeds with empty default variant.

### User Story 4 - Create with illegal default attachments leaves no orphan (Priority: P2)

If create supplies illegal default attachments, no build/variant/attachment illegal state remains.

## Requirements

- FR-001: Equipment-affecting `updateUserVariant` validates planned state before committing writes (or wraps writes so `ApiError` rolls back).
- FR-002: `createUserBuild` with `defaultVariant.attachments` validates before durable illegal attach; failure leaves no orphan illegal build state.
- FR-003: `prepareAttachments` planning can run without write; replace participates after validation or inside transaction.
- FR-004: Name/notes-only variant updates skip full equipment validation.
- FR-005: Bare create without attachments remains allowed.
- FR-006: `ApiError` codes/status stay compatible.
- FR-007: Regression test proves DB unchanged after illegal attach; success path still commits.
- FR-008: `createUserVariant` duplicate path follows same validate-then-commit semantics when copying attachments.

## Success

- SC-001: Illegal attach regression green; prior attachments unchanged.
- SC-002: Legal paths and bare create still pass existing tests.
- SC-003: typecheck / targeted tests pass.

## Domain

Enforces DBR-CMP-006, DBR-CMP-007, DBR-MOD-001, DBR-SUB-004 save atomicity without changing the gate rules themselves.
