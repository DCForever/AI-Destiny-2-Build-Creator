# Implementation Plan: DART-022 Public+PKCE OAuth Core

**Branch**: `dart-022-oauth-pkce` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-022-oauth-pkce/spec.md`

## Summary

Add Public+PKCE (S256) authorize URL building, CSRF state helpers, token exchange/refresh, `BungieTokens` model, and platform redirect URI configuration to `packages/bungie`, reusing DART-021 injectable HTTP transport. **No `client_secret` fields.** Unit tests use mocked transport only.

## Technical Context

**Language/Version**: Dart SDK ^3.5.0  

**Primary Dependencies**: Existing `destiny2_bungie`; add `crypto` for SHA-256 PKCE  

**Storage**: N/A (token persistence is DART-023)  

**Testing**: `dart test packages/bungie` with mock `BungieHttpTransport`  

**Target Platform**: Pure Dart library used by Flutter/Jaspr hosts later  

**Project Type**: Shared library package extension  

**Performance Goals**: N/A (auth handshake, not hot path)  

**Constraints**: No CLIENT_SECRET; no Node sidecar; no live Bungie in CI  

**Scale/Scope**: One package area; ~authorize/token/refresh + config only  

## Constitution Check

- I. Small Testable Increments: US1 authorize/state → US2 tokens → US3 redirect config  
- II. Test-First: OAuth tests written with implementation; green before finish  
- III. Green Commit Checkpoints: `dart test packages/bungie` + analyze  
- IV-V: Co-located tests under `packages/bungie/test/`; validation on empty client id / blank redirect  

No constitution violations requiring complexity tracking.

## Project Structure

### Documentation (this feature)

```text
specs/dart-022-oauth-pkce/
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
packages/bungie/
  pubspec.yaml                 # + crypto dependency
  lib/
    destiny2_bungie.dart       # export oauth/*
    src/
      oauth/
        pkce.dart              # PkcePair + generate
        oauth_state.dart       # state generate/validate
        bungie_tokens.dart     # BungieTokens + needsRefresh/isSessionExpired
        redirect_uri_config.dart
        oauth_pending.dart     # OAuthPendingAuth
        bungie_oauth_client.dart
        oauth_errors.dart
  test/
    oauth_pkce_test.dart
    oauth_token_test.dart
    oauth_redirect_config_test.dart
```

**Structure Decision**: Extend `packages/bungie` (research R1). No new workspace package.

## Complexity Tracking

> None
