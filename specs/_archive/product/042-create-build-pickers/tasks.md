# Tasks: Create Build Search Pickers

**Input**: Design documents from `/specs/042-create-build-pickers/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup

- [x] T001 Confirm feature branch `042-create-build-pickers` and mockup at `docs/ui-mocks/create-build-search-pickers.html`

## Phase 2: Foundational

- [x] T002 [P] Add failing tests for exotic armor group/sort in `src/lib/manifest/exoticArmorSearchGroups.test.ts`
- [x] T003 Implement `groupAndSortExoticArmorSearchResults` in `src/lib/manifest/exoticArmorSearchGroups.ts`
- [x] T004 [P] Add failing route tests for batch by-target in `src/app/api/user/synergies/by-target/route.test.ts` (create if missing)
- [x] T005 Implement batch reverse-lookup service + extend `src/app/api/user/synergies/by-target/route.ts`

## Phase 3: User Story 1 — Collapse search after pick (P1)

**Goal**: Single-select hides search chrome when selected
**Independent Test**: Pick super/exotic → only hotspot+Clear; Clear restores search

- [x] T006 [US1] Collapse single-select search chrome in `src/components/lookups/ManifestSearchPicker.tsx`

## Phase 4: User Story 2 — Class/subclass scope (P1)

**Goal**: Exotic class-scoped; super class+subclass scoped like debug
**Independent Test**: Titan super browse excludes other classes; exotic limited to class

- [x] T007 [US2] Wire super picker scope (classType/element/subclass) in `src/components/build/CreateBuildPanel.tsx`
- [x] T008 [US2] Wire super picker scope in `src/components/build/BuildEditPanel.tsx`
- [x] T009 [US2] Ensure ManifestSearchPicker sends `element` when provided in `src/components/lookups/ManifestSearchPicker.tsx`

## Phase 5: User Story 3 — Exotic groups + synergy chips (P1)

**Goal**: Group by slot, sort by name, show library synergies on rows
**Independent Test**: Browse Warlock exotics — slot headers, A–Z, chips on linked items

- [x] T010 [US3] Render exotic armor groups in `src/components/lookups/ManifestSearchPicker.tsx`
- [x] T011 [US3] Fetch batch synergies after exotic results and show chips on rows in `src/components/lookups/ManifestSearchPicker.tsx`
- [x] T012 [US3] Pass `slot` through ManifestPick typing/usage in `src/components/lookups/ManifestSearchPicker.tsx`

## Phase 6: Polish

- [x] T013 Run `npm run gate` and fix failures
- [x] T014 Brief note in `specs/042-create-build-pickers/quickstart.md` if validation steps change

## Dependencies

- T002→T003; T004→T005 before T011
- T006 independent of grouping
- T007–T009 after T006 preferred (same files)
- T010–T012 after T003 and T005

## MVP

T001–T006 (collapse) delivers immediate UX value; then scope; then exotic groups+synergies.
