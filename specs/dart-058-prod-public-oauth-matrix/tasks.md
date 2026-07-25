# Tasks: DART-058 Prod Public OAuth Matrix

**Input**: Design documents from `/specs/dart-058-prod-public-oauth-matrix/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-058-prod-public-oauth-matrix`

## Phase 2: Redirect matrix (US1)

- [x] T002 [US1] Add `packages/bungie/lib/src/oauth/prod_public_oauth_matrix.dart` + export
- [x] T003 [US1] Tests `packages/bungie/test/prod_public_oauth_matrix_test.dart`
- [x] T004 [US1] Align Windows `kDefaultWindowsRedirectUri` to HTTPS matrix constant
- [x] T005 [US1] Publish `docs/multiplatform-dart-prod-public-oauth-matrix.md` (portal table + smoke)

## Phase 3: Secret scan (US2)

- [x] T006 [US2] Add `tool/client_secret_scan.dart` pure scan helpers + CLI
- [x] T007 [US2] Tests `tool/test/client_secret_scan_test.dart`; run scan green on repo clients

## Phase 4: Smoke + cutover (US3)

- [x] T008 [US3] Cross-check host OAuth defaults / hints against matrix (Windows HTTPS, web path)
- [x] T009 [US3] Update cutover checklist: RB-03 cleared, RC-AUTH PASS + evidence
- [x] T010 [US3] Close GAP-AUTH-01 in feature-gaps; update FEAT-AUTH-PUBLIC note

## Phase 5: Docs + finish

- [x] T011 Update roadmap DART-058 done; Current → DART-059
- [x] T012 Run tests: bungie matrix, client_secret_scan, cutover validator
- [ ] T013 Commit; merge `--no-edit` into `feature/multiplatform-dart`; commit base
