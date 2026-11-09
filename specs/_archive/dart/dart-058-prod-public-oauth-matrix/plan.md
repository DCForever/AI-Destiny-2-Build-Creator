# Implementation Plan: DART-058 Prod Public OAuth Matrix

**Branch**: `dart-058-prod-public-oauth-matrix` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-058-prod-public-oauth-matrix/spec.md`

## Summary

Publish a production Bungie **Public + PKCE** redirect matrix for all shells, align Windows default to HTTPS loopback, gate zero confidential secrets in client artifacts, document live sign-in smoke for Windows + Jaspr, and clear cutover **RB-03** / set **RC-AUTH PASS**.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: `destiny2_bungie` OAuth (DART-022), Windows loopback TLS (DART-023), Jaspr `WebOAuthConfig` (DART-045)  

**Storage**: N/A for matrix (constants); tokens remain platform secure / localStorage (not SQLite plaintext)  

**Testing**: `dart test` packages/bungie + tool; existing host OAuth session tests; secret scan CLI  

**Target Platform**: Shared package + docs; Windows/Jaspr hosts consume defaults  

**Project Type**: Multiplatform monorepo  

**Performance Goals**: N/A (config/docs/scan)  

**Constraints**: Pure Dart I/O only; no CLIENT_SECRET / SESSION_SECRET in clients; soft never auto-applies; no Node sidecar  

**Scale/Scope**: One pure matrix module + scan tool + docs + default URI fix  

## Constitution Check

- I. Small Testable Increments: US1 matrix → US2 secret scan → US3 smoke/docs/cutover  
- II. Test-First: matrix + scan tests land with implementation  
- III. Green Commit Checkpoints: package/tool tests green before merge  
- IV–V. Co-located tests; validation via exact URI match + forbidden-pattern scan  

## Project Structure

### Documentation (this feature)

```text
specs/dart-058-prod-public-oauth-matrix/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── tasks.md
└── checklists/requirements.md

docs/multiplatform-dart-prod-public-oauth-matrix.md   # ops matrix + smoke
docs/multiplatform-dart-feature-gaps.md               # GAP-AUTH-01 closed
docs/multiplatform-dart-cutover-parity-checklist.md    # RB-03 / RC-AUTH
docs/multiplatform-dart-slice-roadmap.md              # DART-058 done
```

### Source Code (touched)

```text
packages/bungie/lib/src/oauth/
  redirect_uri_config.dart          # existing PlatformRedirectUriConfig
  prod_public_oauth_matrix.dart     # NEW: prod matrix constants + helpers
packages/bungie/lib/destiny2_bungie.dart  # export matrix
packages/bungie/test/
  prod_public_oauth_matrix_test.dart
  oauth_redirect_config_test.dart   # optional align HTTPS sample

apps/windows_host/lib/
  host_bootstrap.dart               # kDefaultWindowsRedirectUri → HTTPS
  settings/oauth_account_card.dart  # hints use matrix HTTPS
apps/windows_host/test/
  windows_oauth_session_test.dart   # default HTTPS parse coverage if needed

apps/web_host/lib/auth/web_oauth_config.dart  # reference matrix path constant

tool/
  client_secret_scan.dart           # NEW: source scan gate
  test/client_secret_scan_test.dart
```

## Implementation approach

### US1 — Matrix

1. Add `ProdPublicOAuthMatrix` in `packages/bungie` with:
   - `kProdWindowsRedirectUri = 'https://127.0.0.1:8765/callback'`
   - `kProdWebOAuthCallbackPath = '/auth/callback'`
   - `webRedirectUri(origin)` → `{origin}/auth/callback`
   - `kProdAndroidRedirectUri` / `kProdIosRedirectUri` = `d2buildcreator://oauth/callback`
   - `asPlatformConfig({required String webOrigin})` → `PlatformRedirectUriConfig`
2. Flip Windows `kDefaultWindowsRedirectUri` to HTTPS constant (import or re-export matrix).
3. Publish `docs/multiplatform-dart-prod-public-oauth-matrix.md` with portal registration table.

### US2 — Secret scan

1. `tool/client_secret_scan.dart` walks client package/host `lib/` (+ selected pubspecs) for forbidden patterns:
   - assignment: `client_secret` / `CLIENT_SECRET` / `SESSION_SECRET` / `BUNGIE_CLIENT_SECRET` as values/keys
   - `fromEnvironment('BUNGIE_CLIENT_SECRET'|…)`
   - Allow documentation phrases ("Never pass CLIENT_SECRET") without `=` / `:` assignment
2. Tests for scanner pure helpers + repo green scan.

### US3 — Smoke + cutover

1. Smoke section in matrix doc: Windows + Jaspr operator steps; CI preflight = matrix tests + secret scan + existing OAuth session tests.
2. Update cutover checklist RB-03 cleared, RC-AUTH PASS.
3. Close GAP-AUTH-01; roadmap DART-058 done → Current DART-059.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
