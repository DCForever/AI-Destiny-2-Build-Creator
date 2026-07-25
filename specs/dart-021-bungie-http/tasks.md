# Tasks: DART-021 Shared Bungie HTTP Client

**Input**: Design documents from `/specs/dart-021-bungie-http/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Mocked HTTP required (constitution Test-First). No live Bungie.

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create `packages/bungie/` tree (`lib/`, `lib/src/`, `test/`) per plan.md
- [x] T002 Add `packages/bungie/pubspec.yaml` (`destiny2_bungie`, SDK-only runtime, `test`/`lints` dev, `resolution: workspace`)
- [x] T003 Register `packages/bungie` in root `pubspec.yaml` `workspace:` and extend `melos.scripts.analyze` package list

---

## Phase 2: Foundational

- [x] T004 [P] Implement transport types + default HttpClient in `packages/bungie/lib/src/http_transport.dart`
- [x] T005 [P] Implement envelope parse in `packages/bungie/lib/src/bungie_envelope.dart`
- [x] T006 [P] Implement exceptions + RateLimitSignal in `packages/bungie/lib/src/bungie_errors.dart` and `rate_limit.dart`
- [x] T007 Implement `BungieHttpClient` in `packages/bungie/lib/src/bungie_http_client.dart`
- [x] T008 Barrel export `packages/bungie/lib/destiny2_bungie.dart`

**Checkpoint**: Library compiles; ready for tests

---

## Phase 3: User Story 1 — API key GET/POST (P1) 🎯 MVP

**Goal**: Platform get/post with X-API-Key and optional Bearer  
**Independent Test**: Mock transport header assertions

- [x] T009 [US1] Write tests for construction (empty key fails), GET headers (API key + Bearer), POST headers/body, success unwrap
- [x] T010 [US1] Confirm tests pass (`dart test packages/bungie`)

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Typed errors (P1)

**Goal**: HTTP + platform + parse errors  
**Independent Test**: Mock 503 / ErrorCode≠1 / bad JSON

- [x] T011 [US2] Tests for BungieHttpException, BungiePlatformException, parse failure
- [x] T012 [US2] Confirm tests pass

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Rate-limit hooks (P1)

**Goal**: Hook + throttle metadata on 429 / ThrottleSeconds  
**Independent Test**: Mock throttle responses; assert hook + exception fields

- [x] T013 [US3] Tests for onRateLimit on ThrottleSeconds and HTTP 429; no hook on clean success
- [x] T014 [US3] Confirm tests pass

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T015 Document package in `packages/README.md`; align quickstart
- [x] T016 Verify no secrets: package sources have no CLIENT_SECRET; pure graph guard still passes
- [x] T017 Run `dart pub get` + `dart test packages/bungie` + analyze; mark tasks complete
- [x] T018 Commit; merge `dart-021-bungie-http` into `feature/multiplatform-dart` (--no-edit); update `docs/multiplatform-dart-slice-roadmap.md` (DART-021 done, pointer → DART-022)

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Package skeleton + client API  
2. Mock transport tests first/with impl to green  
3. Docs + workspace wiring + merge
