# Feature Specification: GitHub Actions CI and PowerShell-friendly gate

**Feature Branch**: `038-ci-pwsh-gate`  
**Created**: 2026-07-23  
**Status**: Implemented  
**Input**: Improve prompt [`specs/ci-dx/improve/github-actions-and-pwsh-gate.md`](../ci-dx/improve/github-actions-and-pwsh-gate.md)

## Iteration Scope

**In**: GitHub Actions workflow (typecheck, lint, test, build); cross-platform local gate entrypoint; `package.json` scripts + optional `engines`; README Scripts section notes for gate + CI.

**Out**: Deploy workflows; GitHub branch-protection UI; eslint/vitest config changes; multi-OS CI matrix; domain product rules.

## User Stories

### US1 - PR/push automatic verification (P1)

**Test**: Workflow file exists and invokes the four quality steps after install.

1. Given a push or pull_request targeting default branches, When CI runs, Then checkout + Node setup + `npm ci` complete.
2. Given a green tree, When CI runs typecheck/lint/test/build (or equivalent gate), Then the job succeeds.
3. Given a failing step, When CI runs, Then the job fails (fail-fast at step boundary).

### US2 - Windows-local gate without bash (P1)

**Test**: Cross-platform gate script runs the same four npm scripts and exits non-zero on first failure.

1. Given Windows PowerShell, When `npm run gate` is invoked, Then typecheck → lint → test → build run without requiring bash.
2. Given a failing typecheck, When gate runs, Then subsequent steps are skipped and process exits non-zero.
3. Given all steps pass, When gate runs, Then a clear success message is printed.

### US3 - Documented Node pin and scripts (P2)

**Test**: Contributors can find Node version and gate/CI usage in repo docs/config.

1. Given `package.json`, When read, Then `engines.node` (or equivalent pin) documents supported Node.
2. Given README Scripts, When read, Then gate and CI are mentioned.

## Requirements

- **FR-001**: Add `.github/workflows/ci.yml` on `pull_request` and `push` to `main` (and `master` if present) running on `ubuntu-latest`.
- **FR-002**: Workflow sets up Node LTS aligned with local (20 or 22+), enables npm cache, runs `npm ci`, then typecheck, lint, test, build (directly or via gate).
- **FR-003**: Document Node via `engines` in `package.json` matching workflow `node-version`.
- **FR-004**: Add cross-platform gate implementation (`scripts/gate.mjs` preferred) that runs the four npm scripts and fails fast.
- **FR-005**: Change `package.json` `gate` script to the cross-platform entrypoint; keep `scripts/gate.sh` as a thin optional alias or leave for Unix callers.
- **FR-006**: README Scripts table documents `npm run gate` and that GitHub Actions runs the same checks on PR/push.
- **FR-007**: CI must not require Bungie secrets for unit tests/typecheck/lint/build.
- **FR-008**: No domain DBR/DAC/BR changes (DX-only).

## Success Criteria

- **SC-001**: `.github/workflows/*.yml` exists and runs typecheck, lint, test, build.
- **SC-002**: Cross-platform gate exists and fails fast on first error.
- **SC-003**: `package.json` scripts (and engines) updated.
- **SC-004**: README scripts section mentions gate + CI.
- **SC-005**: Local `npm run typecheck && npm run lint && npm run test` remains the logical equivalent of the first three gate steps.

## Assumptions

1. Default protected branch name is `main` (also listen on `master` for safety).
2. Node **22** is the pin (local agent reports v24; `@types/node` is `^20`; engines `>=20 <25` with CI on **22** is a practical LTS pin).
3. Prefer `scripts/gate.mjs` over `gate.ps1` so one `npm run gate` works on Windows, macOS, and Linux CI without pwsh or bash.
4. `ubuntu-latest` default build toolchain is enough for `better-sqlite3` native compile.
5. No secrets needed in CI for current offline unit tests.
6. Interactive clarify skipped per improve orchestration; assumptions documented here.
7. Domain docs unchanged — pure DX / CI.

## Dependencies

- Existing npm scripts: `typecheck`, `lint`, `test`, `build`.
- Existing `scripts/gate.sh` (bash reference sequence).
- Native dep `better-sqlite3` on CI image.

## Risks

- Human must enable required status checks in GitHub branch protection when ready.
- Full gate (especially `next build`) is slower on CI; no matrix yet by design.
