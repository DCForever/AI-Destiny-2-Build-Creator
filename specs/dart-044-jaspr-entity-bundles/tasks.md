# Tasks: DART-044 Jaspr Entity Bundles

**Input**: Design documents from `/specs/dart-044-jaspr-entity-bundles/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `packages/manifest` + `apps/web_host`. No live Bungie. No CLIENT_SECRET. No Next.

## Phase 1: Setup

- [x] T001 Create `specs/dart-044-jaspr-entity-bundles/` docs + set `.specify/feature.json`
- [x] T002 [P] Write research.md / quickstart.md / checklist

---

## Phase 2: Foundational — pure bundle + web-safe IO

**Goal**: Bundle parse + MemoryEntityCache; package compiles for web consumers  
**Independent Test**: `dart test packages/manifest`

- [x] T003 Add `EntityCacheReader` + `MemoryEntityCache` in `packages/manifest/lib/src/`
- [x] T004 Add `EntityBundleDocument` parse/project in `packages/manifest/lib/src/entity_bundle.dart`
- [x] T005 Conditional text-file IO helpers; refactor `FileEntityCache` / `OfflineCatalog` off direct `dart:io`
- [x] T006 Conditional stubs for `http_client` / `isolate_rebuild` / `manifest_service` file IO so library is web-importable
- [x] T007 [P] Unit tests: `entity_bundle_test.dart` (+ OfflineCatalog from memory bundle)
- [x] T008 Export new APIs from `destiny2_manifest.dart`; StorageRoot ensureLayout conditional if needed

**Checkpoint**: packages/manifest tests green

---

## Phase 3: User Story 2 — Web Catalog (P1) 🎯

**Goal**: Offline catalog facets on Jaspr web  
**Independent Test**: `dart test` apps/web_host catalog tests

- [x] T009 Add `destiny2_manifest` dep to `apps/web_host/pubspec.yaml`
- [x] T010 Ship fixture `web/entities/prebuilt/bundle.json`
- [x] T011 Implement `WebEntityBundleLoader` + status model (injectable fetch)
- [x] T012 Implement Catalog page (query, element/ammo/exotic facets, results list, empty/error)
- [x] T013 Wire `/catalog` route + shell nav Catalog | Settings
- [x] T014 [P] Component tests for Catalog page + loader
- [x] T015 Update `apps/web_host/README.md` for DART-044

**Checkpoint**: web_host tests green (26)

---

## Phase 4: Finish

- [x] T016 Mark tasks complete; run full slice tests
- [x] T017 Commit on `dart-044-jaspr-entity-bundles`
- [x] T018 Merge into `feature/multiplatform-dart` (--no-edit); roadmap DART-044 done; pointer → DART-045; commit base

---

## Dependencies & Execution Order

- Setup → pure bundle/web-safe IO → web Catalog → finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs  
2. Pure bundle + tests  
3. Web-safe IO  
4. Web Catalog + fixture  
5. Merge + roadmap  
