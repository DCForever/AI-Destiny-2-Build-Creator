---
status: DONE
priority: P2
effort: S
risk: MED
category: migration
depends: []
planned_at: 799a9d6
issue: ""
---

# Clear high-severity npm audit findings on Next and undici

## Objective

`npm audit` reports **high** severity issues on production dependencies in the current tree, notably **next** (multiple advisories in the 16.x line) and **undici** (`^8.4.1`), plus transitive **postcss** / **sharp** via Next. After this lands, `npm audit --omit=dev` reports zero high/critical findings (or only accepted documented exceptions), and `npm run gate` still passes.

## Current context

- `package.json` dependencies (at planning SHA): `next` `^16.2.9`, `undici` `^8.4.1`, `react`/`react-dom` `19.2.4`, etc.
- AGENTS.md: this is Next with breaking changes — read `node_modules/next/dist/docs/` before API changes.
- App uses App Router, `next.config.ts`, iron-session, better-sqlite3 (Node runtime on API routes).
- Verification: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` (full gate).

Audit snapshot from advisor run (not exhaustive forever): high on next, undici, postcss, sharp; no critical; moderate noise in devDeps acceptable if documented.

## Detailed instructions

### Requirements

- R1: Upgrade `next` (and `eslint-config-next` if paired) to a patched release that clears current high advisories applicable to this app, within Next 16 unless a major is unavoidable and justified.
- R2: Upgrade `undici` to a patched release clearing high advisories, or remove the direct dependency if unused and only pulled transitively with a safe version.
- R3: Run `npm audit --omit=dev` after lockfile update; high/critical must be zero or listed in the PR with why false-positive / unreachable for local-first single-user.
- R4: No intentional React major jump in this prompt unless required by Next peer deps.
- R5: Fix any typecheck/build breaks from Next patch notes; do not drive product feature work.
- R6: Keep `runtime = "nodejs"` API routes working with better-sqlite3.

### Acceptance criteria

- [ ] `npm audit --omit=dev` shows 0 high and 0 critical (or PR documents residual with advisory IDs)
- [ ] `npm run typecheck` passes
- [ ] `npm run lint` passes
- [ ] `npm run test` passes
- [ ] `npm run build` passes
- [ ] Lockfile committed with the upgrades

### Scope boundaries

**In scope**

- `package.json` / `package-lock.json`
- Minimal code fixes required by upgraded Next/undici types or imports
- `eslint-config-next` version alignment

**Out of scope**

- Zod/drizzle major migrations
- Removing better-sqlite3
- Feature work on Build/Finish UI
- Accepting audit noise by disabling audit entirely

### Risks and notes

- Next middleware/proxy advisories may or may not apply to this app’s surface — still prefer patched releases.
- After upgrade, skim Next release notes for App Router deprecations (AGENTS.md).
- Reviewer: confirm no accidental introduction of Edge runtime on DB routes.