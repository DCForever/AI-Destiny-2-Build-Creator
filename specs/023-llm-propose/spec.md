# Feature Specification: LLM Propose-for-Confirm

**Feature Branch**: `023-llm-propose`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "Manual LLM pass that proposes synergies, keywords, and gear evidence for user confirmation. No auto-apply to builds. Manual re-run only. Debug/API-first."

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md)

**Refs**: DBR-LLM-001–005, DAC-P2-004

## Clarifications

None yet — defaults from DBR-LLM-*.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual Start Pass (Priority: P1)

User explicitly starts an LLM description pass (debug/API). No automatic runs on manifest refresh or save.

**Independent Test**: Trigger pass endpoint; without trigger, no proposals appear.

### User Story 2 - Propose Synergies / Keywords / Evidence (Priority: P1)

Pass analyzes descriptions of equippable/changeable pieces and returns **proposals** (synergies, keywords, evidence links) — not persisted library records until confirmed.

**Independent Test**: Mock LLM returns structured proposals; API returns them without writing synergies/sets.

### User Story 3 - Confirm Before Persist (Priority: P1)

User confirms/edits proposals; only then create/update curated records. Reject/skip leaves library unchanged.

**Independent Test**: Confirm one proposal → record exists; skip others → absent.

### User Story 4 - Debug Verification (Priority: P2)

Debug UI: Start pass → review proposals → confirm/skip → inspect library.

## Requirements *(mandatory)*

- **FR-001**: LLM pass MUST be manually started (no auto on manifest/save).
- **FR-002**: Output MUST be propose-for-confirmation only until user confirms.
- **FR-003**: Scope MAY include weapons, perks, armor/exotics, abilities/aspects/fragments, mods, artifact perks (DBR-LLM-003).
- **FR-004**: New keywords MUST require user confirm into vocabulary.
- **FR-005**: Re-runs are manual (DBR-LLM-005).
- **FR-006**: Debug/API-first; injectable/mockable LLM client for tests.
- **FR-007**: MUST NOT auto-apply proposals onto builds/variants.

## Success Criteria *(mandatory)*

- **SC-001**: Unconfirmed proposals do not create synergies/sets.
- **SC-002**: Confirmed proposal creates expected library record.
- **SC-003**: Gate green with mocked LLM.
- **SC-004**: Debug path completes start → confirm/skip.

## Assumptions

- Existing `/api/llm` or ollama stack may be reused/adapted.
- Full production curation UX out of scope.

## Out of Scope

- Auto LLM on every manifest change
- Auto-apply to builds
- Production polish UI beyond debug
