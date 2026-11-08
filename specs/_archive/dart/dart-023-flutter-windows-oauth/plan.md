# Implementation Plan: DART-023 Flutter Windows OAuth

**Branch**: `dart-023-flutter-windows-oauth` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-023-flutter-windows-oauth/spec.md`

## Summary

Wire Public+PKCE (DART-022) into the Flutter Windows host: loopback callback server, system browser launch, secure token storage, sign-in/out session, and Settings account UI. Prove with host tests that the E2E path works under mocks and that tokens never land in SQLite plaintext. **No client secret.**

## Technical Context

**Language/Version**: Dart SDK ^3.5.0 / Flutter (Windows)  

**Primary Dependencies**: `destiny2_bungie` (OAuth client), `flutter_secure_storage`, `url_launcher`, existing host (`destiny2_db`, storage, manifest)  

**Storage**: OS secure storage for tokens; Drift remains free of token columns  

**Testing**: `flutter test` apps/windows_host (widget + unit); mock transport + memory token store + fake browser/loopback  

**Target Platform**: Flutter Windows desktop (first shell)  

**Project Type**: Host app feature extension  

**Performance Goals**: N/A (auth handshake)  

**Constraints**: Pure Dart I/O only (no Node sidecar); no CLIENT_SECRET; loopback bind 127.0.0.1 only  

**Scale/Scope**: Auth modules under `apps/windows_host/lib/auth/` + Settings card; no inventory sync  

## Constitution Check

- I. Small Testable Increments: US1 store → US2 loopback sign-in → US3 UI/sign-out  
- II. Test-First: Store/session/UI tests with implementation; green before finish  
- III. Green Commit Checkpoints: `flutter test` + analyze  
- IV-V: Co-located tests under `apps/windows_host/test/`  

No constitution violations requiring complexity tracking.

## Project Structure

### Documentation (this feature)

```text
specs/dart-023-flutter-windows-oauth/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/windows_host/
  pubspec.yaml                    # + destiny2_bungie, flutter_secure_storage, url_launcher
  lib/
    main.dart                     # BUNGIE_CLIENT_ID / BUNGIE_REDIRECT_URI defines
    host_bootstrap.dart           # AppServices + WindowsOAuthSession
    app.dart                      # pass session
    auth/
      token_store.dart            # TokenStore + Memory + Secure
      token_codec.dart            # JSON map BungieTokens
      browser_launcher.dart       # abstract + UrlLauncherBrowser
      loopback_callback_server.dart
      windows_oauth_session.dart  # sign-in/out orchestration
    settings/
      settings_page.dart          # account card + manifest
      oauth_account_card.dart
  test/
    token_store_test.dart
    windows_oauth_session_test.dart
    oauth_account_card_test.dart
    settings_page_test.dart       # update for OAuth chrome
```

**Structure Decision**: Host-local auth (research R3). Reuse `packages/bungie` OAuth pure client.

## Complexity Tracking

> None
