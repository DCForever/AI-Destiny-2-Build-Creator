# Tasks: 041-bump-next-undici

**Input**: spec.md, plan.md, improve prompt `specs/deps-security/improve/bump-next-undici-audit.md`

## Phase 1: Specify
- [X] T001 Write `feature.json`, `spec.md`, `plan.md`, `tasks.md`, `research.md` under `specs/041-bump-next-undici/`

## Phase 2: Implement bump
- [ ] T002 Update `package.json`: `next` + `eslint-config-next` → 16.2.11; `undici` → ^8.8.0
- [ ] T003 Replace worktree `node_modules` junction with real `npm install` and refresh `package-lock.json`
- [ ] T004 Run `npm audit --omit=dev`; apply safe overrides or document residual highs (GHSA IDs)
- [ ] T005 Fix any typecheck/build breaks from upgraded packages (minimal)

## Phase 3: Verify
- [ ] T006 `npm run typecheck`
- [ ] T007 `npm run lint`
- [ ] T008 `npm run test`
- [ ] T009 `npm run build`
- [ ] T010 Commit with Co-Authored-By: Oz <oz-agent@warp.dev>; mark improve status if appropriate
