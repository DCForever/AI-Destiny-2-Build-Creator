# Research: 041-bump-next-undici

## Baseline (main @ 350e435)
- `next` ^16.2.9 → installed 16.2.9
- `eslint-config-next` 16.2.9
- `undici` ^8.4.1 → installed 8.4.1
- `npm audit --omit=dev`: **4 high**, 0 critical
  - **next** (direct): multiple highs (middleware bypass, Server Action DoS/SSRF, rewrites SSRF, etc.) — advisory band listed through 16.3.0-preview.7; **patched stable**: **16.2.11** (Vercel July 2026 security release)
  - **undici** (direct): highs for SOCKS TLS bypass, WebSocket fragment DoS, Set-Cookie/header issues — vulnerable `8.0.0–8.4.1`; latest **8.8.0**
  - **postcss** (via next nested): highs GHSA-qx2v-qp2m-jg93, GHSA-6g55-p6wh-862q — `<=8.5.11`
  - **sharp** (optional via next): GHSA-f88m-g3jw-g9cj — `<0.35.0`; next@16.2.11 optionalDepends `sharp@^0.34.5`; next@16.3 preview uses `^0.35.3`

## Decision
- Stay on **Next 16.2.11** + matching eslint-config (not 16.3 preview) per improve R1.
- Bump **undici@8.8.0**.
- After install, re-audit. Prefer documenting residual transitive postcss/sharp if overrides risk Next image/CSS internals; try overrides only if audit still fails SC-001 and versions are API-compatible.

## undici usage
- `src/lib/llm/llmFetch.ts` imports `Agent` from `undici` for LLM HTTP — keep direct dependency.

## Residual audit (filled post-implement)
_See commit notes / updated section after install._
