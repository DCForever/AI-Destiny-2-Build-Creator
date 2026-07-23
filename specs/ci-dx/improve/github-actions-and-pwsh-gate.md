---
status: DONE
priority: P2
effort: S
risk: LOW
category: dx
depends: []
planned_at: 799a9d6
issue: ""
implemented_by: specs/038-ci-pwsh-gate
---

# Add GitHub Actions CI and a PowerShell-friendly gate

## Objective

The repo has strong local scripts (`typecheck`, `lint`, `test`, `build`) and `npm run gate` → `bash scripts/gate.sh`, but **no** `.github/workflows` CI and the gate is bash-only. On Windows (primary contributor environment) and on PRs, verification is manual. After this lands, PRs/pushes run the same gate automatically, and Windows contributors can run an equivalent gate without bash.

## Current context

- Scripts in `package.json`: `typecheck` → `tsc --noEmit`; `lint` → `eslint`; `test` → `vitest run`; `build` → `next build`; `gate` → `bash scripts/gate.sh`
- `scripts/gate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
npm run typecheck
npm run lint
npm run test
npm run build
echo "Gate passed."
```

- No `.github/workflows` directory today.
- Native module: `better-sqlite3` requires Node build toolchain on fresh CI images.
- Verification after change: the new workflow and local gate must both exercise the four steps.

## Detailed instructions

### Requirements

- R1: Add a GitHub Actions workflow (e.g. `.github/workflows/ci.yml`) on pull_request and push to default branches that checks out, sets up Node (LTS matching local, e.g. 20 or 22), `npm ci`, then runs typecheck, lint, test, and build (or `npm run gate` if bash is available on the runner).
- R2: Document Node version via `engines` in `package.json` **or** workflow `node-version` file — pick one clear pin.
- R3: Add `scripts/gate.ps1` (or `gate.mjs`) that runs the same four npm scripts with `$ErrorActionPreference = 'Stop'` / non-zero exit on failure.
- R4: Update `package.json` `gate` script so Windows works: e.g. `node scripts/gate.mjs` cross-platform, **or** keep `gate` as bash and add `gate:win` → pwsh — prefer one cross-platform entrypoint if low effort.
- R5: README Scripts table mentions CI and the gate command.
- R6: CI must install build tools as needed for `better-sqlite3` on ubuntu-latest (default compilers usually suffice).

### Acceptance criteria

- [ ] `.github/workflows/*.yml` exists and runs typecheck, lint, test, build
- [ ] Cross-platform or `gate:win` script exists and fails fast on first error
- [ ] `package.json` scripts section updated
- [ ] README scripts section mentions gate + CI
- [ ] Local `npm run typecheck && npm run lint && npm run test` still the logical equivalent

### Scope boundaries

**In scope**

- `.github/workflows/`
- `scripts/gate.sh` and/or new gate script
- `package.json` scripts (+ optional `engines`)
- `README.md` scripts section only

**Out of scope**

- Deploy workflows
- Required status checks configuration in GitHub UI (note in Risks for the human)
- Changing eslint/vitest config
- Caching strategy beyond a simple npm cache is optional

### Risks and notes

- `better-sqlite3` and Next build make CI slower; start simple before matrix OS.
- Do not commit secrets; CI needs no Bungie keys for unit tests/typecheck/lint/build if tests stay offline.
- Human: enable branch protection to require the workflow when ready.