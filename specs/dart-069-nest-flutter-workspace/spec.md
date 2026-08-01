# Feature Specification: DART-069 Nest Dart/Flutter Workspace Under `flutter/`

**Feature Branch**: `044-nest-flutter-workspace`

**Created**: 2026-08-01

**Status**: Implemented

**Input**: User description: "Move all the flutter code down into a flutter subfolder"

**Program ID**: DART-069

**Phase**: Repo structure / developer experience

**Depends**: Existing Melos/pub workspace on `feature/multiplatform-dart`

**Integration base**: `feature/multiplatform-dart`

**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

### In scope

- Relocate the entire Dart multiplatform workspace so its root is `flutter/` under the monorepo
- Include pure packages, IO/UI packages, Flutter hosts, Jaspr `web_host`, and Dart `tool/`
- Move workspace config that belongs with that tree (`pubspec.yaml` workspace + melos, lockfile, analysis options, melos pointer)
- Update developer entrypoints: IDE launch configs, ignore rules, operational docs/README paths, workspace-root detection used by gates
- Preserve Next.js app and shared product/spec trees at repository root
- Record the structural decision for the monorepo layout

### Out of scope

- Renaming pub package names or changing runtime product behavior
- Moving Next.js under a separate folder
- Moving `specs/` or multiplatform `docs/` into `flutter/`
- Merging Jaspr into Flutter hosts
- Product domain rule changes (no new DBR/DAC/BR required for path layout alone)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Contributor finds and runs the multiplatform stack (Priority: P1)

A contributor opening the monorepo can tell where the multiplatform Dart/Flutter work lives, open that workspace root, and run the usual install, analyze, test-gate, and host launch flows without hunting mixed Next.js and Dart files at the same level.

**Why this priority**: Without a clear, working workspace root after the move, no other multiplatform work is safe.

**Independent Test**: From a clean clone checkout of this branch, a contributor can locate `flutter/`, install workspace deps, and complete the documented P0/pure gate (or equivalent documented health check) successfully.

**Acceptance Scenarios**:

1. **Given** the monorepo at repository root, **When** a contributor lists top-level project folders, **Then** multiplatform app/package code is under `flutter/` and the Next.js app remains at repository root (`package.json`, `src/`).
2. **Given** the contributor’s working directory is the Dart workspace root (`flutter/`), **When** they install dependencies and run the documented pure/P0 gate, **Then** the gate completes successfully with the same intent as before the move.
3. **Given** IDE launch configurations for hosts/packages, **When** the contributor launches a documented host configuration, **Then** the configuration points at paths under `flutter/` and resolves the correct package.

---

### User Story 2 - Automation and gates keep working (Priority: P1)

CI scripts, local gate tools, and secret/graph guards still resolve the Dart workspace whether invoked with a working directory of the monorepo root or of `flutter/`, and they scan the relocated package trees.

**Why this priority**: Broken gates would silently regress purity and cutover checks.

**Independent Test**: Run workspace-root detection and the pure package graph guard / P0 gate after the move; all pass.

**Acceptance Scenarios**:

1. **Given** tools that previously assumed `packages/` at monorepo root, **When** they run after the move, **Then** they locate pure packages under the new Dart workspace root and report clean results for an unchanged purity policy.
2. **Given** a developer starts a gate from monorepo root **or** from `flutter/`, **When** workspace root detection runs, **Then** it resolves to the Dart workspace that contains `packages/` and `apps/`.

---

### User Story 3 - Docs and onboarding match the tree (Priority: P2)

README and multiplatform onboarding docs describe the nested layout and the single convention that Dart commands run with working directory `flutter/` (hosts still run from their app folders under that tree).

**Why this priority**: Stale paths cause repeated contributor friction even if code works.

**Independent Test**: A reader following root README multiplatform section and `flutter/packages/README.md` (or successor path) can reproduce install/run steps without inventing paths.

**Acceptance Scenarios**:

1. **Given** root README multiplatform section, **When** read after the move, **Then** it points at `flutter/` for packages/apps and does not claim `packages/` lives at monorepo root.
2. **Given** operational multiplatform docs that instruct `dart run tool/…`, **When** updated, **Then** they state cwd `flutter/` (or equivalent explicit path) so copy-paste works.

---

### Edge Cases

- Generated caches (`.dart_tool/`, host `build/`) left at old paths must not be treated as source of truth; regenerate under `flutter/`.
- Jaspr `web_host` remains outside the pub workspace member list but still lives under `flutter/apps/web_host`.
- Historical slice specs may still mention old paths until bulk-updated; operational paths (gates, README, launch configs, active quickstarts) must be correct.
- Path dependencies between sibling packages under `flutter/packages` and hosts under `flutter/apps` must keep working without rewriting relative `../` depth if both trees move together.
- Next.js tests that only mention Dart paths as fixtures/strings must not break the Node gate.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST place the multiplatform Dart workspace root at `flutter/` (relative to monorepo root).
- **FR-002**: `flutter/` MUST contain the relocated `packages/`, `apps/` (including `windows_host`, `mobile_host`, `web_host`), and Dart `tool/` trees.
- **FR-003**: Dart workspace configuration (`pubspec.yaml` workspace + melos scripts, lockfile as applicable, shared analysis options, melos pointer) MUST live under `flutter/`, not monorepo root.
- **FR-004**: Next.js application files (`package.json`, `src/`, Node scripts/gate) MUST remain at monorepo root and keep functioning without depending on old top-level `packages/` / `apps/` locations.
- **FR-005**: Shared product/spec trees (`specs/`, multiplatform `docs/`) MUST remain at monorepo root (not nested under `flutter/`).
- **FR-006**: Developers MUST have a documented single convention: run Dart workspace commands with working directory `flutter/` unless a host-specific command requires the host app directory under `flutter/apps/…`.
- **FR-007**: Workspace root detection used by Dart tools MUST resolve the Dart workspace when started from monorepo root or from `flutter/`.
- **FR-008**: IDE launch configurations for Dart/Flutter hosts and packages MUST use paths under `flutter/`.
- **FR-009**: Ignore rules MUST cover Dart/Flutter generated artifacts under the new layout.
- **FR-010**: Operational documentation (root multiplatform blurb, packages README after move, critical gate quickstarts) MUST reflect the nested layout.
- **FR-011**: After the move, pure-package graph policy and P0/pure test gate MUST still pass for unchanged package purity rules.
- **FR-012**: Pub path dependencies among packages and from hosts to packages MUST resolve successfully after the mechanical move.
- **FR-013**: The structural layout decision MUST be recorded as an accepted project decision (vault/repo as appropriate).

### Key Entities

- **Monorepo root**: Next.js app + shared docs/specs + nested `flutter/` workspace.
- **Dart workspace root (`flutter/`)**: Pub workspace / Melos root for multiplatform packages, apps, and tools.
- **Host apps**: Flutter Windows/mobile shells and Jaspr web shell under `flutter/apps/`.
- **Shared packages**: Domain through UI packages under `flutter/packages/`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of multiplatform package and host source trees that lived under top-level `packages/` and `apps/` are reachable only under `flutter/` (no duplicate live source trees at monorepo root).
- **SC-002**: A contributor can complete documented dependency install + pure/P0 gate from the Dart workspace root in one guided path without path-not-found errors.
- **SC-003**: Documented IDE launch entries for at least one Flutter host resolve without manual path correction after checkout.
- **SC-004**: Next.js typecheck or unit test command at monorepo root still succeeds after the move (no accidental breakage of the legacy web stack).
- **SC-005**: Workspace root detection succeeds from both monorepo root and `flutter/` in automated checks or tool self-tests.
- **SC-006**: Root multiplatform onboarding text no longer instructs contributors to treat monorepo-root `packages/` as the live Dart tree.

## Assumptions

- “All the flutter code” means the whole multiplatform Dart workstream (not only `ui_flutter` / Flutter hosts), including pure Dart packages and Jaspr web host, because they share one pub workspace.
- Git history should be preserved via moves where practical (`git mv`).
- Bulk rewriting every historical `specs/dart-*` path string is desirable but secondary to operational correctness; at minimum operational docs and active configs are updated in this feature.
- No product behavior or domain rule changes are required solely for nesting folders.
- Melos 7+ continues to read workspace members from `flutter/pubspec.yaml`.
