# Tasks: DART-069 Nest Flutter Workspace

**Input**: Design documents from `/specs/dart-069-nest-flutter-workspace/`  
**Prerequisites**: plan.md, spec.md, research.md, contracts/workspace-layout.md, quickstart.md

## Phase 1: Setup

- [x] T001 Confirm branch `044-nest-flutter-workspace` and feature dir `specs/dart-069-nest-flutter-workspace/`
- [x] T002 [P] Snapshot current layout (list top-level packages/, apps/, tool/, pubspec.yaml) for rollback notes in specs/dart-069-nest-flutter-workspace/quickstart.md if needed

## Phase 2: Foundational (blocking)

- [x] T003 Add/extend failing tests for monorepo-root → flutter workspace resolution in tool/test (pure_package_graph_guard_test.dart and/or client_secret_scan_test.dart patterns)
- [x] T004 Create `flutter/` directory and `git mv` packages/, apps/, tool/, pubspec.yaml, pubspec.lock, melos.yaml, analysis_options.yaml, and workspace .iml into flutter/
- [x] T005 Implement findWorkspaceRoot dual resolution (parent walk + flutter/ child) in flutter/tool/pure_package_graph_guard.dart and align flutter/tool/client_secret_scan.dart findWorkspaceRoot
- [x] T006 Update root .gitignore for flutter/ packages locks and generated paths
- [x] T007 Run `dart pub get` in flutter/ and fix any resolution issues
- [x] T008 Run pure/P0 gate from flutter/ (`dart run tool/p0_parity_gate.dart`) and tool tests

## Phase 3: User Story 1 — Contributor finds and runs stack (P1)

**Goal**: Live tree only under flutter/; install + gate work  
**Independent test**: quickstart layout + dart pub get + p0 gate

- [x] T009 [US1] Verify monorepo root has no live packages/ or apps/ source trees
- [x] T010 [US1] Update .vscode/launch.json cwd values to flutter\\apps\\... and flutter\\packages\\...
- [x] T011 [US1] Update root README.md multiplatform section to point at flutter/

## Phase 4: User Story 2 — Automation and gates (P1)

**Goal**: Root detection from monorepo root and flutter/  
**Independent test**: tool tests + gate

- [x] T012 [US2] Ensure all tool findWorkspaceRoot call sites share correct behavior (inventory/cutover gates under flutter/tool/)
- [x] T013 [US2] Run dart test on flutter/tool/test and p0 gate; confirm pass from monorepo root invocation pattern if supported

## Phase 5: User Story 3 — Docs and onboarding (P2)

**Goal**: Operational docs match nested layout  
**Independent test**: README + packages README + key docs

- [x] T014 [P] [US3] Update flutter/packages/README.md layout paths and run instructions (cd flutter)
- [x] T015 [P] [US3] Add note to docs/multiplatform-dart-port-decisions.md about flutter/ workspace root
- [x] T016 [P] [US3] Update critical docs/multiplatform-* operational paths (cutover checklist, dual-run runbook) for cwd flutter/

## Phase 6: Polish

- [x] T017 npm run typecheck (or npm test) at monorepo root
- [x] T018 Mark spec status Done-ready; update ProjectTracker log with final feature path specs/dart-069-nest-flutter-workspace
- [x] T019 Remove stale root .dart_tool if present after move (untracked cleanup)

## Dependencies

- Phase 2 before US1–US3
- T003 before T005 (test-first)
- T004 before T007/T008
- US3 can parallelize T014–T016 after foundational

## Parallel examples

- After T008: T010 + T011 + T014 + T015
- T014, T015, T016 in parallel

## MVP

T001–T011 + T017 gate smoke
