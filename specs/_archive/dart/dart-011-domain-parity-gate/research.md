# Research: DART-011 Domain Parity Gate

**Date**: 2026-07-24  
**Branch**: `dart-011-domain-parity-gate`

## Decisions

### R1 — Single command is a root Dart tool (not only Melos exec)

**Decision**: Primary P0 gate entry is `dart run tool/p0_parity_gate.dart` (guard + full pure suite). Melos exposes the same via `dart run melos run p0-gate`.

**Why**: Melos 7 `exec` scripts spawn `melos` from PATH; this worktree often has Melos only as a root dev_dependency (`dart run melos`). Interactive package selection also breaks CI. A root Dart tool is PATH-independent and non-interactive.

### R2 — Graph guard = declared runtime dependencies on pure packages

**Decision**: Fail if pure package `pubspec.yaml` `dependencies:` maps contain forbidden package names/prefixes. `dev_dependencies` may include `test` / `lints`.

**Why**: Pure packages currently have `dependencies: {}`. Declared deps are the purity contract reviewers and automation can enforce without reimplementing the pub solver. Roadmap “melos graph guard” is satisfied by a dedicated graph-guard script + Melos script name.

### R3 — Pure package set is explicit

**Decision**: Config lists `packages/domain` and `packages/sandbox_data`. New pure packages must be added to the list intentionally.

**Why**: Avoid auto-scanning future IO packages (Drift, Flutter apps) as pure.

### R4 — Forbidden set mirrors packages/README purity rule

**Decision**: Forbid flutter*, jaspr*, drift*, sqlite3, sqflite, http, dio, path_provider*, and related storage/network plugins documented in the guard constant list.

**Why**: Aligns with D-IO / D-PATH and DART-001 purity rule; prevents accidental client I/O in domain.

### R5 — No new workspace package for the tool

**Decision**: Keep tools under `tool/` with `dart:`-only (or minimal) imports.

**Why**: Avoid expanding the Melos package graph for CI glue; pure packages stay the only product libraries in P0.

## Alternatives rejected

| Alternative | Rejected because |
| ----------- | ---------------- |
| Rely solely on `melos run test` with packageFilters exec | Nested `melos` not on PATH; interactive select in non-TTY |
| Depend on `package:yaml` only for guard | Unnecessary if simple section parse covers empty/`name: version` maps |
| Transitive package_config full audit as hard fail | Dev deps pull `test`/`coverage` trees; runtime empty deps are the P0 contract |
| Shell-only gate (pwsh/bash) | Harder cross-platform parity; Spec Kit prefers pure Dart tooling |

## Assumptions

- Current green suite counts: domain 150 + sandbox_data 25 (approximate; not locked).
- Guard does not block adding pure workspace-to-workspace deps later if both ends are pure and explicitly allowed.
