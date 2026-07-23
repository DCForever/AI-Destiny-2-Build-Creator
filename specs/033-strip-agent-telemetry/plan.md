# Implementation Plan: Strip Agent Debug Telemetry

**Branch**: `033-strip-agent-telemetry` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/033-strip-agent-telemetry/spec.md`

## Summary

Delete all leftover `#region agent log` blocks that unconditionally `fetch` `http://127.0.0.1:7497/ingest/...` under `src/`. Preserve surrounding error handling and control flow. Verify with `rg` (zero matches) and the standard quality gate (typecheck, lint, test, build).

## Technical Context

**Language/Version**: TypeScript (strict), Next.js App Router
**Primary Dependencies**: Next.js, React, existing LLM clients (OpenAI-compatible + Ollama)
**Storage**: N/A (no data model changes)
**Testing**: `npm run test` (existing suite; no new product tests required for pure deletion)
**Target Platform**: Web app (Node server + browser client)
**Project Type**: Full-stack Next.js application
**Performance Goals**: Remove failed local network work on every generate path
**Constraints**: No new always-on telemetry; do not log secrets/prompts/tokens
**Scale/Scope**: 5 source files, ~9 agent-log regions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: Single vertical cleanup slice; verifiable by search + gate. **PASS**
- II. Test-First (NON-NEGOTIABLE): Deletion-only hygiene; no new behavior to TDD. Verification is `rg` + existing gate. **PASS with justified exception** (see Complexity Tracking)
- III. Green Commit Checkpoints: One implementation commit after gate green. **PASS**
- IV-V. Co-located tests / validation-first: N/A new APIs; quickstart is search + gate. **PASS**

Post-design re-check: unchanged — **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/033-strip-agent-telemetry/
├── plan.md
├── research.md
├── quickstart.md
├── contracts/
│   └── no-agent-ingest.md
├── checklists/requirements.md
├── improve/remove-agent-debug-ingest.md
├── spec.md
└── tasks.md
```

### Source Code (touch list)

```text
src/app/api/build/route.ts
src/lib/services.ts
src/lib/llm/ollamaClient.ts
src/lib/llm/openAiClient.ts
src/components/GeneratorPage.tsx
```

**Structure Decision**: Edit in place within existing Next.js `src/` layout. No new modules.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Test-first for new behavior | Feature is pure deletion of debug instrumentation | Writing failing tests that assert absence of strings is weaker than `rg` acceptance; no product behavior to specify |

## Implementation Approach

1. Inventory all `src/` matches for `#region agent log` and `7497/ingest`.
2. For each match, delete the entire region (marker comments + `fetch(...).catch(()=>{})` statement(s)), leaving adjacent try/catch/return/throw intact.
3. Re-run inventory search until zero matches.
4. Run `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`.
5. Mark improve prompt status DONE in feature copy.
6. No domain doc updates (engineering cleanup only).

## Agent context

Update `.cursor/rules/specify-rules.mdc` SPECKIT block to `specs/033-strip-agent-telemetry/plan.md` after plan artifacts land.
