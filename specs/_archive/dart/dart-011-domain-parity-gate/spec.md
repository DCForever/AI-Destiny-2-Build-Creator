# Feature Specification: DART-011 Domain Parity Gate

**Feature Branch**: `dart-011-domain-parity-gate`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Aggregate parity suite + package dependency lint (domain has zero IO/UI). Single command runs full pure suite; melos graph guard; P0 phase gate."

**Program ID**: DART-011  
**Phase**: P0 (phase gate)  
**Depends**: DART-003–010  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Aggregate **P0 pure suite** entry: one documented command runs all pure-package tests (`destiny2_domain` + `destiny2_sandbox_data`)
- **Package dependency / graph guard**: fail CI/local if pure packages declare forbidden IO/UI runtime dependencies (Flutter, Jaspr, Drift, http, path_provider, etc.)
- Melos (or equivalent) scripts wired for non-interactive use
- Document **P0 phase gate** success criteria so P1 (Drift/storage) may start only after this gate is green
- Lightweight self-test of the graph guard (detects a forbidden dep fixture)

**Out of scope (later slices):**

- Drift, StorageRoot, Flutter/Jaspr apps (DART-012+)
- Network / Bungie HTTP clients (DART-021+)
- Expanding product domain rules (DBR/DAC/BR content)
- Re-porting evaluators already landed in DART-003–010
- Node sidecar or product Next.js gate changes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single-command full pure suite (Priority: P1)

As a multiplatform port engineer or CI job, I can run one command that executes the entire pure-domain and sandbox-data test suite so P0 parity is one green/red signal.

**Why this priority**: Roadmap exit criterion — “Single command runs full pure suite.”

**Independent Test**: From repo root after `dart pub get`, run the documented P0/parity command; both domain and sandbox_data tests execute; exit code 0 when all pass.

**Acceptance Scenarios**:

1. **Given** packages are bootstrapped, **When** I run the documented single aggregate command, **Then** tests from `packages/domain` and `packages/sandbox_data` both run and the command exits 0 on current green suite.
2. **Given** a failing test in either pure package, **When** I run the same command, **Then** the aggregate exits non-zero.
3. **Given** Melos is only available via `dart run melos` (not on PATH), **When** I use the documented entry, **Then** the suite still runs without interactive package prompts.

---

### User Story 2 - Pure package graph / dependency guard (Priority: P1)

As an engineer, I can run a graph/dependency lint that fails if `destiny2_domain` or other declared pure packages gain Flutter, Jaspr, Drift, http, path_provider, or similar IO/UI runtime dependencies.

**Why this priority**: Roadmap exit criterion — “melos graph guard”; domain must stay zero IO/UI for P0 phase exit.

**Independent Test**: Guard passes on current pubspecs; guard fails when a fixture/synthetic pubspec lists a forbidden runtime dependency.

**Acceptance Scenarios**:

1. **Given** current `packages/domain/pubspec.yaml` and `packages/sandbox_data/pubspec.yaml`, **When** the graph guard runs, **Then** it exits 0 and reports pure packages as clean.
2. **Given** a temporary or fixture pubspec with `http` (or `flutter`, `drift`, etc.) under `dependencies:`, **When** the guard evaluates it under pure rules, **Then** it fails with a clear message naming the package and forbidden dependency.
3. **Given** only allowed `dev_dependencies` such as `test` and `lints`, **When** the guard runs, **Then** it does not fail.

---

### User Story 3 - P0 phase gate documentation (Priority: P2)

As a contributor starting P1, I can read that DART-011 is the P0 phase gate, which command proves the gate, and that Drift/UI work must not start until it is green.

**Why this priority**: Phase gate communication; prevents premature P1 without pure suite trust.

**Independent Test**: Docs under this slice and packages README / roadmap pointer describe the gate command and pure-package list.

**Acceptance Scenarios**:

1. **Given** the slice docs, **When** I open quickstart (or packages README gate section), **Then** I see the single gate command and what it checks.
2. **Given** the roadmap after finish-spec, **When** DART-011 is done, **Then** Current pointer advances to DART-012 and DART-011 status is `done`.

---

### Edge Cases

- Melos not on PATH: prefer `dart run melos …` and/or a root Dart tool that does not require global Melos.
- Interactive Melos package selection in CI: gate and test scripts must be non-interactive (`--no-select` or root-level single run).
- Future pure packages: guard config lists pure package paths so new pure packages can be added without inventing a second mechanism.
- Soft guidance never auto-applies; this slice only gates existing pure tests and deps — no product rule changes.
- Domain remains free of CLIENT_SECRET / network — guard reinforces no http client deps in pure packages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST provide a single documented command that runs the full pure test suite for all P0 pure packages (`packages/domain`, `packages/sandbox_data` at minimum).
- **FR-002**: That command MUST exit non-zero if any pure-package test fails.
- **FR-003**: Repository MUST provide a package dependency / graph guard that inspects pure-package `pubspec.yaml` runtime `dependencies` for forbidden IO/UI packages.
- **FR-004**: Forbidden runtime dependencies MUST include at least: Flutter SDK/plugins, Jaspr, Drift/sqlite3/sqflite, `http`/`dio`, `path_provider` (and documented equivalents).
- **FR-005**: The graph guard MUST pass on the current pure package pubspecs and MUST be covered by a unit/self-test that proves a forbidden dep is detected.
- **FR-006**: Melos scripts (or documented equivalents) MUST expose non-interactive entries for full pure tests and for the P0 gate (guard + suite).
- **FR-007**: Documentation MUST name the P0 gate command and state that P1 (storage/Drift) depends on this gate.
- **FR-008**: This slice MUST NOT introduce Flutter/Jaspr apps, Drift packages, or network clients into pure packages.

### Key Entities

- **Pure package**: Workspace package required to have zero IO/UI runtime dependencies (today: `destiny2_domain`, `destiny2_sandbox_data`).
- **P0 parity gate**: Aggregate command = graph guard + full pure suite.
- **Forbidden dependency set**: Names/prefixes that violate D-PATH / D-IO purity for pure packages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: One command from repo root runs domain + sandbox_data tests and exits 0 on the green suite in under 2 minutes on a developer machine with Dart SDK.
- **SC-002**: Graph guard exits 0 on current pure pubspecs and exits non-zero when a forbidden runtime dep is injected in a fixture test.
- **SC-003**: Melos (or equivalent) script names are documented and runnable without interactive prompts in non-TTY CI.
- **SC-004**: P0 phase gate is documented; roadmap marks DART-011 done and points to DART-012 after merge.

## Assumptions

- Pure packages for this gate are exactly the workspace members under `packages/` that are marked pure today: `domain` and `sandbox_data`. Future pure packages are added to the guard allowlist/list explicitly.
- Graph guard focuses on **declared runtime dependencies** in pubspec (and may inspect resolved package config when present); it does not require a full pub dependency solver reimplementation.
- `dev_dependencies` may include `test` and `lints`; the guard does not require zero dev deps.
- Soft/hard product rules are already covered by DART-003–010 golden tests; this slice aggregates them rather than re-specifying domain behavior.
- Global Melos on PATH is optional; `dart run melos` and pure `dart` tool entry points are sufficient.
- No NEEDS CLARIFICATION markers retained; defaults above are locked for implement.
