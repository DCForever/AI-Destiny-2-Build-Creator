---
status: DONE
priority: P1
effort: S
risk: LOW
category: security
depends: []
planned_at: 799a9d6
issue: ""
---

# Remove leftover agent debug ingest telemetry

## Objective

Multiple production code paths unconditionally `fetch` a fixed local debug ingest URL (`http://127.0.0.1:7497/ingest/...`) inside `#region agent log` blocks. That leaks error messages, LLM endpoint URL/model, and client failure details to whatever listens on port 7497 and adds failed network work on every generate. After this lands, zero references to that ingest URL or agent-log regions remain under `src/`.

## Current context

Known sites (session id and UUID path are identifiers only — do not reintroduce):

- `src/app/api/build/route.ts:45-47` — catch path
- `src/lib/services.ts:131-137` — `runBuildGeneration` start + LLM config
- `src/lib/llm/ollamaClient.ts:120-132` — request start/catch
- `src/lib/llm/openAiClient.ts:187-202` — request start/catch
- `src/components/GeneratorPage.tsx:122-143` — client non-ok and catch

Example:

```ts
// src/app/api/build/route.ts:45-47
// #region agent log
fetch('http://127.0.0.1:7497/ingest/c1e77a25-...',{method:'POST',/* ... */}).catch(()=>{});
// #endregion
```

Verification: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`.

Conventions: keep normal user-facing error JSON; no new always-on telemetry. Optional future diagnostics must be server-only and env-gated (not part of this prompt unless trivial).

## Detailed instructions

### Requirements

- R1: Delete all `#region agent log` / `#endregion` blocks and their `fetch('http://127.0.0.1:7497/ingest/...')` calls under `src/`.
- R2: Preserve surrounding error handling behavior (status codes, thrown errors, UI error messages).
- R3: Do not log secrets, full prompts, or tokens as a replacement.
- R4: No new dependency on external analytics.

### Acceptance criteria

- [ ] `rg -n "7497/ingest|#region agent log" src` returns no matches
- [ ] `npm run typecheck` passes
- [ ] `npm run lint` passes
- [ ] `npm run test` passes
- [ ] `npm run build` passes

### Scope boundaries

**In scope**

- The five files listed above (and any other `src/**` hit by the same pattern)

**Out of scope**

- Redesigning LLM error UX
- Adding structured logging infrastructure
- Changing generate/analyze auth policy

### Risks and notes

- Confirm no tests assert on the ingest side effect.
- Reviewer: grepping only `src` is enough; do not leave the pattern in committed scripts if identical blocks appear outside `src` in the same cleanup pass (optional).