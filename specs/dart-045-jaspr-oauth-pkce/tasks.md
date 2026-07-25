# Tasks: DART-045 Jaspr OAuth PKCE

**Input**: Design documents from `/specs/dart-045-jaspr-oauth-pkce/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `apps/web_host`. No live Bungie. No CLIENT_SECRET. No Next.

## Phase 1: Setup

- [x] T001 Create `specs/dart-045-jaspr-oauth-pkce/` docs + set `.specify/feature.json`
- [x] T002 [P] Write research.md / data-model.md / quickstart.md / checklist

---

## Phase 2: Foundational — token store + config

**Goal**: Browser token storage strategy without SQLite or secrets  
**Independent Test**: token_store_test + no_client_secret_test

- [x] T003 Add `destiny2_bungie` path dependency to `apps/web_host/pubspec.yaml`
- [x] T004 Implement `lib/auth/token_codec.dart` (encode/decode BungieTokens JSON)
- [x] T005 Implement `lib/auth/token_store.dart` (TokenStore, MemoryTokenStore, LocalStorageTokenStore)
- [x] T006 Implement `lib/auth/pending_auth_store.dart` + `lib/auth/web_oauth_config.dart` + `lib/auth/web_auth_navigator.dart`
- [x] T007 [P] Unit tests: `test/token_store_test.dart`, `test/no_client_secret_test.dart`

**Checkpoint**: Store round-trip green; secret scan green

---

## Phase 3: User Story 2 — Session + callback (P1) 🎯

**Goal**: Public+PKCE sign-in and callback exchange  
**Independent Test**: web_oauth_session_test

- [x] T008 Implement `lib/auth/web_oauth_session.dart` (restore, signIn, completeCallback, signOut)
- [x] T009 Implement `lib/pages/auth_callback_page.dart` + register `/auth/callback` in `app.dart`
- [x] T010 Wire session into `main.client.dart` and App
- [x] T011 [P] Unit tests: `test/web_oauth_session_test.dart`, callback coverage

**Checkpoint**: Mocked authorize → callback → signed-in green

---

## Phase 4: User Story 3 — Settings UI (P1)

**Goal**: Account card Sign in / Sign out / membership  
**Independent Test**: oauth_account_card_test + settings updates

- [x] T012 Implement `lib/components/oauth_account_card.dart`
- [x] T013 Update `lib/pages/settings_page.dart` (account panel; remove “Sign-in: not configured” stub)
- [x] T014 [P] Component tests: `test/oauth_account_card_test.dart`; update `settings_page_test.dart`
- [x] T015 Update `apps/web_host/README.md` for DART-045

**Checkpoint**: web_host tests green (46)

---

## Phase 5: Finish

- [x] T016 Mark tasks complete; run full `dart test` in apps/web_host
- [x] T017 Commit on `dart-045-jaspr-oauth-pkce`
- [x] T018 Merge into `feature/multiplatform-dart` (--no-edit); roadmap DART-045 done; pointer → DART-046; commit base

---

## Dependencies & Execution Order

- Setup → store/config → session/callback → Settings UI → finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs  
2. Token store + secret absence  
3. Session + callback with mocks  
4. Settings UI  
5. Merge + roadmap  
