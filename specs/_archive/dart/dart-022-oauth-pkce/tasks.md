# Tasks: DART-022 Public+PKCE OAuth Core

**Input**: Design documents from `/specs/dart-022-oauth-pkce/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Mocked HTTP required. No live Bungie. No client_secret in API.

## Phase 1: Setup

- [x] T001 Add `crypto` dependency to `packages/bungie/pubspec.yaml` and run `dart pub get`
- [x] T002 [P] Create `packages/bungie/lib/src/oauth/` directory for OAuth modules

---

## Phase 2: Foundational models

- [x] T003 [P] Implement `PkcePair` + `generatePkcePair` in `packages/bungie/lib/src/oauth/pkce.dart`
- [x] T004 [P] Implement state generate/validate in `packages/bungie/lib/src/oauth/oauth_state.dart`
- [x] T005 [P] Implement `BungieTokens` + `needsRefresh` / `isSessionExpired` in `packages/bungie/lib/src/oauth/bungie_tokens.dart`
- [x] T006 [P] Implement `PlatformRedirectUriConfig` + `OAuthRedirectPlatform` in `packages/bungie/lib/src/oauth/redirect_uri_config.dart`
- [x] T007 [P] Implement `OAuthPendingAuth` in `packages/bungie/lib/src/oauth/oauth_pending.dart`
- [x] T008 [P] Implement OAuth-specific errors in `packages/bungie/lib/src/oauth/oauth_errors.dart` (+ `BungieOAuthException` in `bungie_errors.dart`)
- [x] T009 Implement `BungieOAuthClient` (authorize URL, exchange, refresh) in `packages/bungie/lib/src/oauth/bungie_oauth_client.dart`
- [x] T010 Export OAuth API from `packages/bungie/lib/destiny2_bungie.dart`

**Checkpoint**: Library analyzes clean

---

## Phase 3: User Story 1 — PKCE authorize + CSRF (P1) 🎯 MVP

**Goal**: PKCE pair, state, authorize URL  
**Independent Test**: `oauth_pkce_test.dart`

- [x] T011 [US1] Write tests for PKCE S256, state validate, authorize URL params in `packages/bungie/test/oauth_pkce_test.dart`
- [x] T012 [US1] Confirm US1 tests pass

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Token exchange/refresh + model (P1)

**Goal**: Public token POST without client_secret; token model  
**Independent Test**: `oauth_token_test.dart`

- [x] T013 [US2] Write tests for exchange/refresh body, no secret headers, token mapping, needsRefresh/isSessionExpired in `packages/bungie/test/oauth_token_test.dart`
- [x] T014 [US2] Confirm US2 tests pass
- [x] T015 [US2] Assert package OAuth sources have no `clientSecret` / `client_secret` field definitions

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Platform redirect config (P1)

**Goal**: Per-platform redirect URI resolve  
**Independent Test**: `oauth_redirect_config_test.dart`

- [x] T016 [US3] Write tests for resolve + missing/blank URI errors in `packages/bungie/test/oauth_redirect_config_test.dart`
- [x] T017 [US3] Confirm US3 tests pass

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T018 Document OAuth in `packages/README.md`; align quickstart
- [x] T019 Run `dart test packages/bungie` + `dart analyze packages/bungie` + pure graph guard
- [x] T020 Mark all tasks complete; commit; merge `dart-022-oauth-pkce` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-022 done, pointer → DART-023)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Models + PKCE/crypto  
2. OAuth client with mock transport tests  
3. Redirect matrix + docs + merge
