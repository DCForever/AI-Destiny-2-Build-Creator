# Implementation Plan: DART-021 Shared Bungie HTTP Client

**Branch**: `dart-021-bungie-http` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-021-bungie-http/spec.md`

## Summary

Add workspace package **`packages/bungie`** (`destiny2_bungie`): a shared Bungie Platform HTTP client with host-injected public API key (`X-API-Key`), optional Bearer auth, envelope parse + typed errors, and rate-limit hooks. Unit-tested via injectable transport; no secrets in package.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: SDK only at runtime (`dart:convert`, `dart:io` for default transport). No Flutter/Jaspr/Drift.  
**HTTP**: Injectable `BungieHttpTransport`; default `HttpClient` wrapper (same approach as `destiny2_manifest` http_client). **No** `package:http` required.  
**Storage**: N/A (stateless client)  
**Testing**: `dart test packages/bungie` with mock transport  
**Target Platform**: Pure Dart library for Flutter Windows / mobile / Jaspr hosts (P2+)  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies  
**Scale/Scope**: Shared low-level client only — not profile/sync/OAuth/equip

## Constitution Check

- I. Small Testable Increments: client headers → errors → rate-limit hooks.
- II. Test-First: co-land mock-HTTP tests with implementation.
- III. Green Commit Checkpoints: `dart test packages/bungie`.
- IV-V. Co-located tests under `packages/bungie/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-021-bungie-http/
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
  pubspec.yaml                 # destiny2_bungie
  lib/
    destiny2_bungie.dart       # barrel
    src/
      bungie_http_client.dart  # BungieHttpClient get/post
      bungie_envelope.dart     # parse envelope
      bungie_errors.dart       # typed exceptions
      rate_limit.dart          # RateLimitSignal + hook typedef
      http_transport.dart      # transport typedef + default HttpClient
  test/
    bungie_http_client_test.dart
```

### Workspace wiring

- Root `pubspec.yaml` `workspace:` + `melos.scripts.analyze` include `packages/bungie`
- `packages/README.md` documents package

## Implementation approach

1. Package skeleton + pubspec + workspace registration.
2. Transport typedef + default `dart:io` implementation.
3. Envelope parser + exception types + RateLimitSignal.
4. `BungieHttpClient`: headers, get/post, unwrap Response, invoke rate-limit hooks.
5. Unit tests with mock transport (headers, success, platform error, HTTP error, 429/throttle hook).
6. Docs + README; run tests; pure graph guard still green.

## Structure Decision

**New package** `destiny2_bungie` (not folded into manifest). Manifest download stays specialized; profile/sync/OAuth/equip will share this client. Keeps secrets out and avoids pulling inventory/OAuth into manifest.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Separate package | Shared by DART-022+ without coupling to manifest IO | Putting client only in manifest would force OAuth/sync to depend on entity stores |
