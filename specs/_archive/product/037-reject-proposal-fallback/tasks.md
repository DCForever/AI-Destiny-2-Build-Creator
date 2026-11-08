# Tasks: 037-reject-proposal-fallback

## Phase 1: Spec Kit docs

- [x] T001 Create `specs/037-reject-proposal-fallback/` + `.specify/feature.json`
- [x] T002 Write spec/plan/research/data-model/quickstart/contracts/checklists

## Phase 2: Foundational implementation

- [x] T003 Remove `proposalsFallback` rebuild from `confirmProposals.ts`; keep 404 unknown-pass message
- [x] T004 Drop `proposals` from `confirmPassRequestSchema` and confirm route args
- [x] T005 Bind `userId` on `StoredProposePass`; set from `runProposePass` / `runGapScan` / propose route
- [x] T006 Reject confirm when pass `userId` mismatches caller
- [x] T007 Stop debug clients from sending `proposals` on confirm
- [x] T008 Update `specs/023-llm-propose/contracts/propose-confirm-contract.md`

## Phase 3: Tests (US1 + US2 + US3)

- [x] T009 [US2] Replace fallback-success test with missing-pass + malicious proposals → throw, zero synergies
- [x] T010 [US1] Keep/assert happy path confirm with server pass
- [x] T011 [US3] Assert foreign userId cannot confirm another user's pass

## Phase 4: Polish

- [x] T012 `rg` guard: no `proposalsFallback` trust path under `src`
- [x] T013 Run typecheck, lint, propose tests; fix breakages
- [x] T014 Mark improve prompt status if appropriate; commit phases
