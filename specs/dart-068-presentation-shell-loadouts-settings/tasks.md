# Tasks: DART-068 Presentation Shell / Loadouts / Settings

**Input**: Design documents from `/specs/dart-068-presentation-shell-loadouts-settings/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-068-presentation-shell-loadouts-settings`
- [x] T002 Branch `dart-068-presentation-shell-loadouts-settings` from `feature/multiplatform-dart`

## Phase 2: Pure helpers

- [x] T003 [P] Add loadout exotic resolution + tests in `packages/bungie`
- [x] T004 [P] Add `formatLastSyncLabel` / inventory online helper + tests in `packages/bungie`
- [x] T005 [P] Add catalog dense meta chips + designation chrome + manifest readiness helpers + tests in `packages/app`

## Phase 3: Shell labels/order (US1)

- [x] T006 Windows `app.dart` navLabels + destinations order/labels; update shell nav tests
- [x] T007 Jaspr `ShellHeader.routes` order/labels; update shell nav tests

## Phase 4: Catalog / sets icons + meta (US2)

- [x] T008 Windows catalog + set picker/detail: entity icons + dense meta chips
- [x] T009 Jaspr catalog rows: icons + dense meta
- [x] T010 Host tests for icon/meta keys when icon present

## Phase 5: Loadouts density (US3)

- [x] T011 Pure enrich wired into Windows loadouts controller when inventory+catalog available
- [x] T012 Loadouts UI: color bar/swatch/icon plate, exotic names, Details expand (Windows + Jaspr)
- [x] T013 Host tests for loadout chrome + expand + exotic names (pure enrich + UI keys)

## Phase 6: Settings chrome (US4)

- [x] T014 Windows Manifest READY/STALE chips; Inventory ONLINE/human last sync/Sync inventory/Refresh status
- [x] T015 Jaspr inventory ONLINE/human last sync/Refresh status parity
- [x] T016 Settings card tests

## Phase 7: Designation + variant overview (US5)

- [x] T017 Synergy designation Verb/Element chrome (Windows + Jaspr)
- [x] T018 Variant read-only icon overview strip (Windows)
- [x] T019 Tests for designation format + overview keys

## Phase 8: Finish

- [x] T020 Run package + host tests; fix failures
- [x] T021 Update roadmap / gap / fidelity / polish tracker; commit; merge to `feature/multiplatform-dart`
