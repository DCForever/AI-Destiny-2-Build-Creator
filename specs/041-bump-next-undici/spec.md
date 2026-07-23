# Feature Specification: Bump next + undici (audit highs)
**Branch**: 041-bump-next-undici | **Created**: 2026-07-23 | **Status**: Active
**Input**: `specs/deps-security/improve/bump-next-undici-audit.md`

## Scope
**In**: Upgrade direct `next` / paired `eslint-config-next` and `undici` to patched releases; update lockfile; minimal compile/runtime fixes; document residual prod audit highs if any.
**Out**: Zod/drizzle majors; better-sqlite3 removal; Finish/Build feature work; disabling npm audit.

## Stories
### US1 Clear direct high advisories (P1)
Install patched `next` (16.2.x security line) and `undici` so direct dependency highs are resolved; align `eslint-config-next`.

### US2 Verify gate (P1)
`typecheck`, `lint`, `test`, and `build` pass after the bump; Node runtime API routes remain viable with better-sqlite3.

### US3 Residual audit transparency (P2)
Re-run `npm audit --omit=dev`; if high/critical remain (e.g. transitive postcss/sharp via Next), document advisory IDs and why accepted or overridden.

## Requirements
- FR-001 Upgrade `next` within Next 16 to a release that patches current Next high advisories (target `16.2.11` Active LTS security release unless newer stable is required).
- FR-002 Align `eslint-config-next` with the same Next minor/patch line.
- FR-003 Upgrade `undici` to a release outside vulnerable `8.0.0–8.4.1` (target `^8.8.0`).
- FR-004 Do not intentionally jump React major unless Next peer deps force it.
- FR-005 Commit lockfile with upgrades; prefer real worktree `npm install` when lockfile changes (not only main junction).
- FR-006 Fix only typecheck/build breaks caused by the bump.
- FR-007 Keep `runtime = "nodejs"` on DB API routes; do not move them to Edge.
- FR-008 Document residual high/critical after `--omit=dev` with GHSA IDs.

## Success
- SC-001 `npm audit --omit=dev` has 0 high and 0 critical, or residuals listed with GHSA IDs in research/spec notes.
- SC-002 `npm run typecheck`, `lint`, `test`, and `build` pass.
- SC-003 Lockfile + package.json committed on branch `041-bump-next-undici`.
