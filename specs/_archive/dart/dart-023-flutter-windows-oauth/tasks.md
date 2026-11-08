# Tasks: DART-023 Flutter Windows OAuth

**Input**: Design documents from `/specs/dart-023-flutter-windows-oauth/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Mocked OAuth HTTP + memory token store + fake browser. No live Bungie. No client_secret.

## Phase 1: Setup

- [x] T001 Add `destiny2_bungie`, `flutter_secure_storage`, `url_launcher` to `apps/windows_host/pubspec.yaml` and run pub get
- [x] T002 [P] Create `apps/windows_host/lib/auth/` directory modules per plan

---

## Phase 2: Foundational — token store + codec

- [x] T003 [P] Implement token JSON codec in `apps/windows_host/lib/auth/token_codec.dart`
- [x] T004 [P] Implement `TokenStore` + `MemoryTokenStore` + `SecureTokenStore` in `apps/windows_host/lib/auth/token_store.dart`
- [x] T005 [P] Implement `BrowserLauncher` + `UrlLauncherBrowser` in `apps/windows_host/lib/auth/browser_launcher.dart`
- [x] T006 [P] Implement `LoopbackCallbackServer` in `apps/windows_host/lib/auth/loopback_callback_server.dart`
- [x] T007 Implement `WindowsOAuthSession` sign-in/out in `apps/windows_host/lib/auth/windows_oauth_session.dart`
- [x] T008 Wire session into `host_bootstrap.dart` / `main.dart` / `app.dart` (client id + redirect defines)

**Checkpoint**: Library analyzes clean

---

## Phase 3: User Story 1 — Secure token storage (P1) 🎯 MVP

**Goal**: Tokens round-trip securely; not in SQLite  
**Independent Test**: `token_store_test.dart`

- [x] T009 [US1] Write token store + SQLite absence tests in `apps/windows_host/test/token_store_test.dart`
- [x] T010 [US1] Confirm US1 tests pass

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Loopback sign-in (P1)

**Goal**: Orchestrated PKCE sign-in via loopback + mock exchange  
**Independent Test**: `windows_oauth_session_test.dart`

- [x] T011 [US2] Write session sign-in success/mismatch/error tests in `apps/windows_host/test/windows_oauth_session_test.dart`
- [x] T012 [US2] Confirm US2 tests pass

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Settings UI + sign-out (P1)

**Goal**: Account card Sign in / Sign out  
**Independent Test**: widget tests

- [x] T013 [US3] Implement `oauth_account_card.dart` + update `settings_page.dart`
- [x] T014 [US3] Write/update widget tests (`oauth_account_card_test.dart`, `settings_page_test.dart`)
- [x] T015 [US3] Confirm US3 tests pass

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T016 Update `packages/README.md` Windows host row for OAuth
- [x] T017 Run `flutter test` apps/windows_host + analyze; pure graph guard
- [x] T018 Mark tasks complete; commit; merge `dart-023-flutter-windows-oauth` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-023 done, pointer → DART-024)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Token store + codec  
2. Loopback + session orchestration with mocks  
3. Settings UI + docs + merge
