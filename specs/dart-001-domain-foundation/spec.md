# Feature Specification: DART-001 Domain Foundation

**Feature Branch**: `dart-001-domain-foundation`

**Created**: 2026-07-24

**Status**: Active

**Input**: User description: "Melos (or equivalent) monorepo skeleton: package graph, CI-friendly dart test entry, no UI apps yet. Packages resolve; empty/smoke domain package; documented layout; no IO/UI deps allowed in domain pubspec."

**Program ID**: DART-001  
**Phase**: P0  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** monorepo skeleton only (workspace tool, package graph, smoke domain package, docs, CI-friendly test entry).

**Out of scope (later slices):** models (DART-002), hard/soft evaluators (DART-003+), Flutter/Jaspr apps, Drift/IO packages, OAuth, catalog UI.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Resolve pure domain package (Priority: P1)

As a multiplatform port engineer, I can open the monorepo and resolve a pure Dart `domain` package with zero Flutter/Jaspr/IO dependencies so later slices have a clean place for evaluators.

**Why this priority**: Without a resolving pure package graph, no later P0 domain work can land safely.

**Independent Test**: From repo root, workspace packages resolve (`dart pub get` / Melos bootstrap) and `packages/domain` has no forbidden deps in its pubspec.

**Acceptance Scenarios**:

1. **Given** a clean checkout on this branch, **When** I bootstrap workspace packages, **Then** dependency resolution succeeds for the root workspace and `packages/domain`.
2. **Given** `packages/domain/pubspec.yaml`, **When** I inspect dependencies, **Then** there are no Flutter SDK, Jaspr, Drift, http, path_provider, or other IO/UI packages listed as dependencies.

---

### User Story 2 - CI-friendly smoke test entry (Priority: P1)

As a CI or local developer, I can run one documented command that executes Dart tests for workspace packages (including a smoke test in domain) without requiring a UI shell.

**Why this priority**: Exit criteria require a CI-friendly `dart test` entry and proof the skeleton is green.

**Independent Test**: Run the documented test command; domain smoke test passes.

**Acceptance Scenarios**:

1. **Given** packages are bootstrapped, **When** I run the monorepo test entry (Melos test or equivalent), **Then** the domain smoke test passes and the command exits 0.
2. **Given** no Flutter/Jaspr app packages exist yet, **When** tests run, **Then** no app/device target is required.

---

### User Story 3 - Documented layout (Priority: P2)

As a contributor, I can read a short layout note describing where Dart packages live, what the domain package is for, and which dependency rules apply.

**Why this priority**: Prevents later slices from inventing a second layout or putting UI deps into domain.

**Independent Test**: Layout doc exists under the Dart packages area (or linked from root README) and matches the on-disk tree.

**Acceptance Scenarios**:

1. **Given** the monorepo skeleton, **When** I open the documented layout file, **Then** it lists the package graph, domain purity rules, and how to bootstrap/test.
2. **Given** the documented paths, **When** I compare to the repo tree, **Then** the smoke domain package path matches.

---

### Edge Cases

- Melos not installed globally: bootstrap via `dart pub global activate melos` or use workspace-native scripts documented in quickstart.
- Coexistence with existing Next.js tree: Dart packages must not break Node tooling; ignore Dart build artifacts in `.gitignore`.
- Accidental Flutter dependency on domain: forbidden; pubspec must stay SDK-only (plus optional pure-Dart dev_dependencies such as `test`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST include a Melos (or equivalent Dart workspace) monorepo configuration that discovers packages under a documented packages root.
- **FR-002**: Repository MUST include a pure Dart package `packages/domain` (name: `domain` or `destiny2_domain`) that resolves with the Dart SDK only for runtime dependencies.
- **FR-003**: `packages/domain` MUST NOT depend on Flutter, Jaspr, Drift, sqlite, http clients, path_provider, or other IO/UI packages.
- **FR-004**: `packages/domain` MUST include at least one smoke unit test proving the package loads and a trivial pure function/export works.
- **FR-005**: Repository MUST provide a CI-friendly command entry to run Dart tests across workspace packages (Melos script and/or documented `dart test` path).
- **FR-006**: Repository MUST document monorepo layout, bootstrap steps, test entry, and domain purity rules.
- **FR-007**: No Flutter or Jaspr application packages are created in this slice.

### Key Entities

- **Workspace root**: Melos/pub workspace configuration at multiplatform worktree root (alongside existing Next.js product tree).
- **Domain package**: Empty/smoke pure-Dart library reserved for later evaluator ports (DART-002+).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart pub get` (workspace) succeeds for the domain package without errors.
- **SC-002**: Domain smoke tests pass via the documented monorepo test command in under 60 seconds on a developer machine with Dart SDK installed.
- **SC-003**: Domain `pubspec.yaml` contains zero runtime dependencies other than the Dart SDK (dev_dependency `test` allowed).
- **SC-004**: Layout documentation exists and names the packages path and purity rule.
- **SC-005**: No UI app package directories are introduced by this slice.

## Assumptions

- Dart SDK ≥ 3.5 is available on implementer machines (workspace / Melos-compatible); Flutter is available on the machine but not required to *run* domain tests.
- Melos is the preferred orchestrator; if Melos activation fails, native Dart pub workspaces + a thin script still satisfy “or equivalent.”
- Co-locate Dart packages at repo root `packages/` rather than a nested `dart/` sub-repo to keep one git history with the multiplatform integration branch.
- Package public name uses `destiny2_domain` to avoid bare `domain` collisions on pub.dev later, with import path documented.
- Soft guidance / hard DBR rules are **not** implemented here — only the package shell.
