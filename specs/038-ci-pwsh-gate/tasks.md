# Tasks: GitHub Actions CI and PowerShell-friendly gate

- [x] T001 Write spec.md, research.md, plan.md, tasks.md, .specify/feature.json
- [x] T002 Add `scripts/gate.mjs` (fail-fast four-step gate)
- [x] T003 Update `package.json` gate script + engines.node
- [x] T004 Add `.github/workflows/ci.yml`
- [x] T005 Update README Scripts section (gate + CI)
- [x] T006 Keep `scripts/gate.sh` aligned (same four steps)
- [x] T007 Run typecheck, lint, test; fix breakages
- [x] T008 Mark improve prompt status / feature complete notes

## Verification notes (2026-07-23)

- `npm run typecheck`: PASS
- `npm run lint`: PASS (3 pre-existing warnings)
- `npm run test`: 1311 passed, 15 failed — all `EntityCache: no version is set` in sets/builds/optimizer tests; **pre-existing**, not introduced by this DX change
- Implementation files: workflow, gate.mjs, package.json engines/scripts, README Scripts only
