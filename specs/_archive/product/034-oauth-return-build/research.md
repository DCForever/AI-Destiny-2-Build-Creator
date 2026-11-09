# Research: 034-oauth-return-build

## Decision: Shared module under `src/lib/auth/`

**Choice**: `src/lib/auth/returnUrl.ts` with `DEFAULT_POST_LOGIN_PATH` + `sanitizeReturnUrl`.

**Rationale**: Login already defines private sanitize; callback duplicates default string. Shared export enables unit tests without spinning up route handlers and prevents default drift (FR-004/FR-005).

**Alternatives**: Keep private function in login and only change strings — fails single-constant + testability preference.

## Decision: Fallback `/build` not `/`

**Choice**: `/build` explicitly.

**Rationale**: Improve prompt and product home; `/` already redirects to `/build` but storing `/build` avoids an extra hop and matches README primary nav.

## Decision: No domain doc updates

**Choice**: Skip DBR/DAC/BR edits.

**Rationale**: Default post-login path is engineering UX alignment, not a new Guardian-facing product rule gate; Analyze remains reachable via explicit returnUrl.

## Decision: Debug layout unchanged

**Choice**: Leave `src/app/debug/layout.tsx` login link as-is if it already passes an explicit return path.

**Rationale**: R4 / FR-006 — only change auth login/callback defaults.
