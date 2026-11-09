# Research: DART-069 Nest Flutter Workspace

## R1 — What moves under `flutter/`

**Decision**: Entire Dart multiplatform workspace: `packages/`, `apps/` (all three hosts), `tool/`, root `pubspec.yaml` + lock, `melos.yaml`, `analysis_options.yaml`, workspace `.iml` if present.

**Rationale**: One Melos/pub workspace; Jaspr `web_host` shares path deps into packages even though it is not a workspace member.

**Alternatives considered**:
- Only Flutter hosts + `ui_flutter` — rejected; splits workspace and confuses contributors.
- Rename folder `dart/` — rejected; user asked for `flutter/`.

## R2 — Workspace root detection

**Decision**: `findWorkspaceRoot` must (1) walk parents for a `pubspec.yaml` that is the destiny2 workspace (existing), and (2) if current dir is monorepo root with `flutter/pubspec.yaml` workspace, return `flutter/`. Prefer checking `flutter/` child when the current directory’s pubspec is *not* the workspace but a child `flutter/` is.

**Rationale**: After move, monorepo root has no workspace pubspec; contributors and agents often start at repo root.

**Alternatives considered**:
- Require always `cd flutter` only — insufficient for FR-007.
- Symlink packages at root — messy on Windows.

## R3 — Docs/specs path rewrite scope

**Decision**: Required: README multiplatform blurb, `flutter/packages/README.md`, `.vscode/launch.json`, `.gitignore`, tool path lists that hardcode monorepo-root-relative paths, port decisions doc note. Best-effort bulk replace in `docs/multiplatform-*` and active gate quickstarts. Historical `specs/dart-*` bulk rewrite optional follow-up if time; not blocking if operational paths work.

**Rationale**: Spec assumes operational correctness first.

## R4 — Command convention

**Decision**: Document `cd flutter` then `dart pub get` / `dart run tool/…`. Hosts: `cd flutter/apps/<host>`.

**Rationale**: Matches pub workspace root after move; avoids inventing root wrapper scripts in MVP.

## R5 — Git strategy

**Decision**: `git mv` trees and config files; delete stale root `.dart_tool` if untracked; regenerate with `dart pub get` under `flutter/`.

**Rationale**: History preservation; clean caches.
