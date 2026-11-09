# Research: 038-ci-pwsh-gate

## Current state

- `package.json` gate: `bash scripts/gate.sh` (Windows-hostile without Git Bash).
- `scripts/gate.sh`: typecheck → lint → test → build, `set -euo pipefail`.
- No `.github/workflows`.
- Stack: Next 16, vitest, eslint 9, better-sqlite3.
- Local Node observed: v24.15.0; `@types/node`: ^20.

## Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Gate runtime | `scripts/gate.mjs` via `node` | One entrypoint; no bash/pwsh dependency; works in npm scripts on all OS |
| Keep `gate.sh` | Yes, same sequence | Unix contributors / docs parity; optional |
| CI runner | `ubuntu-latest` only | Prompt: start simple before OS matrix |
| Node pin | `engines.node`: `>=20 <25`; CI `22` | Covers LTS 20/22 and local 24; CI stable LTS |
| CI steps | Explicit four steps (not bash gate) | Clearer logs; no bash assumption required |
| npm cache | `actions/setup-node` cache: npm | Optional simple cache in scope |
| Secrets | None | Offline tests/build |

## Alternatives rejected

- `gate:win` + keep bash `gate`: two commands; worse DX.
- `gate.ps1` only: fails on pure bash CI without pwsh.
- Multi-OS matrix: out of scope / slower.
