# Research: DART-001 Domain Foundation

**Date**: 2026-07-24

## Decisions

### R1 — Melos 7+ + Dart pub workspace

**Decision**: Use Melos for scripts/`melos bootstrap` ergonomics and a root `pubspec.yaml` with Dart workspace members for resolution. Melos **7+** stores scripts under root `pubspec.yaml` → `melos:` (legacy full `melos.yaml` is obsolete; a pointer file remains).

**Rationale**: Roadmap exit criteria name Melos; Dart 3 workspaces give reliable local resolution without inventing a custom runner.

**Alternatives rejected**:
- Nested git submodule for Dart only — splits history from multiplatform integration branch.
- Flutter-only multi-package without Melos — weaker multi-package scripts for CI until apps exist.
- Melos 6 `melos.yaml`-only layout — incompatible with Melos 7 workspace migration.


### R2 — Package name `destiny2_domain`

**Decision**: Directory `packages/domain`, package name `destiny2_domain`.

**Rationale**: Avoids generic pub name collisions; short path for humans.

### R3 — No apps this slice

**Decision**: Do not create `apps/` Flutter or Jaspr projects.

**Rationale**: Explicit roadmap exit criteria and DART-001 scope boundary.

### R4 — Domain purity

**Decision**: Runtime deps = SDK only. Dev deps may include `test` and workspace tooling only.

**Rationale**: Port decisions Phase 0: zero IO/UI in domain packages.

## Open items deferred

- Dependency lint automation (graph guard) → DART-011
- Models/freezed → DART-002
