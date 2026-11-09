# Plan: 041-bump-next-undici

## Approach
1. Spec Kit docs under `specs/041-bump-next-undici/`.
2. Bump `next` + `eslint-config-next` to `16.2.11` (July 2026 security release for 16.2 Active LTS).
3. Bump `undici` to `^8.8.0` (clears SOCKS/WebSocket/header highs on 8.0.0–8.4.1).
4. Replace worktree `node_modules` junction with a real install so lockfile resolves locally.
5. Optionally apply npm `overrides` for transitive `postcss` / `sharp` if still high after Next patch and overrides are safe; otherwise document residuals.
6. Run typecheck → lint → test → build; fix only breakages from the bump.
7. Commit specs + package changes with Co-Authored-By.

## Technical notes
- App: App Router, `next.config.ts`, iron-session, better-sqlite3 on Node API routes.
- Direct undici consumer: `src/lib/llm/llmFetch.ts` (Agent / fetch).
- AGENTS.md: skim `node_modules/next/dist/docs/` only if APIs break.
- Avoid Next 16.3 preview for this slice unless 16.2.11 cannot clear Next package highs (npm advisory range may still list broad bands; verify post-install audit).

## Risks
- Nested `next/node_modules/postcss` and optional `sharp` may remain high on 16.2.11; overrides can break Next internals.
- Real install on Windows may rebuild better-sqlite3/native modules — timeboxed.
- Junction removal must not delete main repo `node_modules` (junction target).
