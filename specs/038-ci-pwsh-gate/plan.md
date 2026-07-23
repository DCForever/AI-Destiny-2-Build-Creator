# Implementation Plan: GitHub Actions CI and PowerShell-friendly gate

**Branch**: `038-ci-pwsh-gate` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

## Summary

Add GitHub Actions CI running typecheck/lint/test/build on PR and push; replace bash-only `npm run gate` with cross-platform `node scripts/gate.mjs`; pin Node via `engines` + workflow `node-version: 22`; document in README Scripts.

## Technical Context

- Next.js 16 app; npm; vitest; eslint; better-sqlite3 native module.
- No existing `.github/workflows`.
- Windows primary contributor env (PowerShell).

## Constitution Check

PASS: DX-only; no domain rule changes; small incremental files; gate remains the local quality bar.

## Project Structure (touch list)

```
.github/workflows/ci.yml   # new
scripts/gate.mjs           # new cross-platform gate
scripts/gate.sh            # keep; optional Unix path
package.json               # gate script + engines
README.md                  # Scripts section only
specs/038-ci-pwsh-gate/*   # Spec Kit artifacts
.specify/feature.json
```

## Delivery Mapping

| Story | Delivery |
| --- | --- |
| US1 | `ci.yml`: checkout, setup-node@22 + npm cache, npm ci, four steps |
| US2 | `gate.mjs` + `package.json` `"gate": "node scripts/gate.mjs"` |
| US3 | `engines.node`, README Scripts + CI note |

## Implementation details

### gate.mjs

- Spawn `npm run <script>` sequentially with `stdio: inherit`, `shell: true` (Windows npm.cmd).
- Exit with child status on first non-zero; print "Gate passed." on success.
- Scripts order: typecheck, lint, test, build.

### ci.yml

```yaml
name: CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: npm
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm run test
      - run: npm run build
```

### package.json

```json
"gate": "node scripts/gate.mjs",
"engines": { "node": ">=20 <25" }
```

## Complexity Tracking

None.

## Risks / human follow-up

Enable branch protection required check for this workflow when ready. No secrets in CI.
