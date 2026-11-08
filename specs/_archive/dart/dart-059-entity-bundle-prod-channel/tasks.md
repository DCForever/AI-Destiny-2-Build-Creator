# Tasks: DART-059 Entity Bundle Prod Channel

**Input**: Design documents from `/specs/dart-059-entity-bundle-prod-channel/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-059-entity-bundle-prod-channel`

## Phase 2: Channel types (US1)

- [x] T002 [US1] Add `packages/manifest/lib/src/entity_bundle_channel.dart` + export from `destiny2_manifest.dart`
- [x] T003 [US1] Tests `packages/manifest/test/entity_bundle_channel_test.dart`
- [x] T004 [US1] Publish `docs/multiplatform-dart-entity-bundle-channel.md` (hybrid + versioning)

## Phase 3: Loader + prod assets (US2)

- [x] T005 [US2] Ship `web/entities/channel.json` + `web/entities/prod/bundle.json`
- [x] T006 [US2] Channel-aware `WebEntityBundleLoader` (ordered candidates, loadSource, defaults)
- [x] T007 [US2] Extend `entity_bundle_loader_test.dart` for prod + CDN fallback
- [x] T008 [US2] Wire `main.client.dart` defaults; update Settings/README copy

## Phase 4: Offline compose + cutover (US3)

- [x] T009 [US3] Assert no Next manifest API in entity load path; update OPFS/limits + port-decisions open item
- [x] T010 [US3] Update cutover checklist: RB-05 cleared, RC-WEB-DATA PASS + evidence
- [x] T011 [US3] Close GAP-WEB-02 in feature-gaps; update FEAT-DATA-MANIFEST note

## Phase 5: Docs + finish

- [x] T012 Update roadmap DART-059 done; Current → DART-060
- [x] T013 Run tests: manifest channel, web loader, cutover validator
- [x] T014 Commit; merge `--no-edit` into `feature/multiplatform-dart`; commit base
