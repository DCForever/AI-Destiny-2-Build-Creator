# Implementation Plan: Default OAuth return path to /build

**Branch**: `034-oauth-return-build` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

## Summary

Extract return-URL sanitization and `DEFAULT_POST_LOGIN_PATH = "/build"` into `src/lib/auth/returnUrl.ts`. Wire login + callback to the shared helper. Add unit tests for sanitize defaults and open-redirect rejection. No OAuth registration or session schema changes.

## Technical Context

- **Stack**: Next.js App Router route handlers (`src/app/api/auth/login`, `callback`)
- **Session**: iron-session fields `oauthState`, `oauthReturnUrl` (unchanged)
- **Test**: Vitest (existing `*.test.ts` colocated pattern)
- **Constraints**: Keep same-origin relative-only checks; do not weaken open-redirect protection

## Constitution / design notes

- Small pure helper; routes stay thin
- Security: reject `//`, external absolute, cross-origin resolved URLs
- Product default aligns with `/` → `/build`

## Project Structure

### Documentation

```text
specs/034-oauth-return-build/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── contracts/return-url-contract.md
├── checklists/requirements.md
├── improve/oauth-default-return-build.md
└── tasks.md
```

### Source

```text
src/lib/auth/returnUrl.ts       # NEW: DEFAULT_POST_LOGIN_PATH + sanitizeReturnUrl
src/lib/auth/returnUrl.test.ts  # NEW: unit tests
src/app/api/auth/login/route.ts # use shared sanitize
src/app/api/auth/callback/route.ts # DEFAULT_POST_LOGIN_PATH fallback
```

## Implementation approach

1. Create `returnUrl.ts` exporting:
   - `DEFAULT_POST_LOGIN_PATH = "/build"`
   - `sanitizeReturnUrl(raw: string | null, requestUrl: URL): string` (same logic as login today, fallback constant)
2. Login route: import and call shared `sanitizeReturnUrl`
3. Callback route: `session.oauthReturnUrl ?? DEFAULT_POST_LOGIN_PATH`
4. Tests: null, `/settings`, `//evil.com`, `https://evil.com`, plus `/analyze` still allowed, query preserved
5. Verify `rg` has no default `"/analyze"` in auth API routes
6. Run typecheck, lint, test

## Out of scope

- Bungie redirect_uri registration
- Removing Analyze
- Session cookie flags
- Domain DBR/DAC (pure default-path bugfix)

## Complexity Tracking

N/A — single shared helper + two call sites + tests.
