# Implementation Plan: DART-045 Jaspr Browser Public+PKCE OAuth

**Branch**: `dart-045-jaspr-oauth-pkce` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-045-jaspr-oauth-pkce/spec.md`

## Summary

Wire **Public + PKCE** sign-in on the Jaspr web host using DART-022 pure OAuth helpers. Implement browser **token storage strategy** (origin-scoped `localStorage`, never SQLite, never confidential secret), same-origin `/auth/callback` completion, and Settings account UI (Sign in / Sign out / membership). Exit: no confidential secret; sign-in path works for HTTPS loopback/prod origin redirect registration.

## Technical Context

**Language/Version**: Dart SDK ^3.10  

**Primary Dependencies**: `jaspr` / `jaspr_router` (existing web_host), `destiny2_bungie` (path), `web` package for storage/location  

**Storage**: Token store → browser `localStorage` (prod) / memory (tests); pending PKCE → `sessionStorage` / memory; **not** Drift/SQLite  

**Testing**: `dart test` + `jaspr_test` component tests in `apps/web_host` with mocks  

**Target Platform**: Browser (Jaspr client SPA); HTTPS loopback / production origin  

**Project Type**: Web host feature slice in monorepo  

**Performance Goals**: N/A (auth UX)  

**Constraints**: Pure Dart I/O only; no Node sidecar; no `CLIENT_SECRET`; soft guidance never auto-applies  

**Scale/Scope**: Auth session + Settings card + callback route only (no inventory sync UI)

## Constitution Check

- I. Small Testable Increments: US1 store → US2 session/callback → US3 Settings UI  
- II. Test-First: unit/component tests for store, session, callback, UI, secret scan  
- III. Green Commit Checkpoints: `dart test` apps/web_host green before finish-spec  
- IV–V: Co-located tests under `apps/web_host/test/`; validation on empty client id / state mismatch  

## Project Structure

### Documentation (this feature)

```text
specs/dart-045-jaspr-oauth-pkce/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code

```text
apps/web_host/
├── lib/
│   ├── auth/
│   │   ├── token_codec.dart          # JSON encode/decode BungieTokens
│   │   ├── token_store.dart          # TokenStore + Memory + LocalStorage
│   │   ├── pending_auth_store.dart   # Pending PKCE session store
│   │   ├── web_auth_navigator.dart   # location assign / query read
│   │   ├── web_oauth_config.dart     # clientId + redirectUri resolves
│   │   └── web_oauth_session.dart    # signIn / completeCallback / signOut / restore
│   ├── pages/
│   │   ├── auth_callback_page.dart
│   │   └── settings_page.dart        # + OAuth account panel
│   ├── components/
│   │   └── oauth_account_card.dart
│   ├── app.dart                      # route /auth/callback; pass session
│   └── main.client.dart              # bootstrap session + restore
└── test/
    ├── token_store_test.dart
    ├── web_oauth_session_test.dart
    ├── oauth_account_card_test.dart
    ├── auth_callback_page_test.dart
    └── no_client_secret_test.dart
```

## Implementation approach

1. Add `destiny2_bungie` dependency to `apps/web_host`.
2. Port token codec + `TokenStore` interface (web-local; mirror Windows shapes without Flutter secure storage).
3. Implement `WebOAuthSession` with injectable navigator + transport + stores.
4. Add `/auth/callback` route + Settings OAuth card.
5. Wire `main.client.dart` with dart-define config + restore.
6. Tests + README + roadmap finish.

## Complexity Tracking

None — follows established Windows OAuth host pattern adapted to browser redirect.
