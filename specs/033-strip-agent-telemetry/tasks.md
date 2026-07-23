# Tasks: Strip Agent Debug Telemetry

**Input**: Design documents from `specs/033-strip-agent-telemetry/`  
**Prerequisites**: plan.md, spec.md, research.md, contracts/, quickstart.md

## Phase 1: Setup

- [x] T001 Confirm inventory with `rg -n "7497/ingest|#region agent log" src` and record hit files under `src/`

## Phase 2: Foundational

- [x] T002 [P] [US1] Remove agent log region(s) from `src/app/api/build/route.ts` preserving catch return JSON
- [x] T003 [P] [US1] Remove agent log region(s) from `src/lib/services.ts` in `runBuildGeneration`
- [x] T004 [P] [US1] Remove agent log region(s) from `src/lib/llm/ollamaClient.ts` request start/catch
- [x] T005 [P] [US1] Remove agent log region(s) from `src/lib/llm/openAiClient.ts` request start/catch
- [x] T006 [P] [US1] Remove agent log region(s) from `src/components/GeneratorPage.tsx` non-ok and catch paths

## Phase 3: User Story 2 — Developer verification (P1)

**Goal**: Zero matches under `src/`; quality gate green  
**Independent test**: quickstart.md steps 1–2

- [x] T007 [US2] Re-run `rg -n "7497/ingest|#region agent log" src` and confirm zero matches
- [x] T008 [US2] Run `npm run typecheck` and fix any breakage from deletions
- [x] T009 [US2] Run `npm run lint` and fix any breakage from deletions
- [x] T010 [US2] Run `npm run test` and fix any breakage from deletions
- [x] T011 [US2] Run `npm run build` and fix any breakage from deletions

## Phase 4: User Story 3 — Error paths preserved (P1)

**Goal**: Catch/return/throw structure intact after region removal  
**Independent test**: Code review of five files; typecheck covers structure

- [x] T012 [US3] Spot-check preserved control flow in the five edited files (throws, status codes, UI `setState` errors)

## Phase 5: Polish

- [x] T013 Mark improve prompt status `DONE` in `specs/033-strip-agent-telemetry/improve/remove-agent-debug-ingest.md`
- [x] T014 Mark all tasks complete in `specs/033-strip-agent-telemetry/tasks.md` and commit implementation

## Dependencies

- T001 before T002–T006
- T002–T006 before T007–T011
- T007–T012 before T013–T014
- T002–T006 are parallel (different files)

## Parallel example

```text
T002 route.ts | T003 services.ts | T004 ollama | T005 openai | T006 GeneratorPage
```

## Implementation strategy

MVP = delete all regions + rg clean + typecheck/lint/test. Build if time allows. No domain doc edits.
