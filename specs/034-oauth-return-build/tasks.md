# Tasks: Default OAuth return path to /build

**Input**: [plan.md](./plan.md) + [spec.md](./spec.md)
**Prerequisites**: Specify complete

## Phase 1: Setup

- [ ] T001 Create `src/lib/auth/returnUrl.ts` exporting `DEFAULT_POST_LOGIN_PATH` and `sanitizeReturnUrl` per contracts/return-url-contract.md

## Phase 2: Foundational

- [ ] T002 [P] Add `src/lib/auth/returnUrl.test.ts` covering null→/build, /settings→/settings, //evil.com→/build, https://evil.com→/build, /analyze allowed, query preserved

## Phase 3: User Story 1–3 (P1) — Routes

- [ ] T003 [US1] Update `src/app/api/auth/login/route.ts` to import shared `sanitizeReturnUrl` (remove local copy)
- [ ] T004 [US1] Update `src/app/api/auth/callback/route.ts` to use `DEFAULT_POST_LOGIN_PATH` instead of `"/analyze"`
- [ ] T005 [US3] Confirm `rg -n 'return "/analyze"|\\?\\? "/analyze"' src/app/api/auth` has no matches

## Phase 4: Polish

- [ ] T006 Run `npm run typecheck`, `npm run lint`, `npm run test`; fix regressions
- [ ] T007 Mark improve prompt status DONE in `specs/034-oauth-return-build/improve/oauth-default-return-build.md` and `specs/auth-return-path/improve/oauth-default-return-build.md`

## Dependencies

- T001 before T002–T004
- T003/T004 before T005–T006

## Implementation Strategy

MVP = T001–T006: shared default `/build`, routes wired, tests green.
