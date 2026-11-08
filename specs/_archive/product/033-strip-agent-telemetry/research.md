# Research: Strip Agent Debug Telemetry

## Decision 1: Delete whole `#region agent log` blocks

- **Decision**: Remove from `// #region agent log` through `// #endregion` inclusive, including the fire-and-forget `fetch` to `127.0.0.1:7497/ingest/...`.
- **Rationale**: Regions are self-contained side effects with `.catch(()=>{})`; deleting the whole block cannot break expression trees if regions are statement-level (confirmed by inventory).
- **Alternatives considered**:
  - Comment out only: leaves dead code and still greppable risk.
  - Gate behind env flag: out of scope; improve prompt forbids replacement always-on telemetry and optional diagnostics are future work.

## Decision 2: Scope is `src/` only for acceptance

- **Decision**: Acceptance requires zero matches under `src/`. Spec docs under `specs/` that *describe* the pattern may still mention the URL as historical context.
- **Rationale**: Matches improve prompt acceptance criterion; production bundles come from `src/`.
- **Alternatives considered**: Scrub entire repo including specs — unnecessary and would rewrite improve history.

## Decision 3: No replacement logging

- **Decision**: Do not add `console.log`, analytics, or structured logging in place of removed regions.
- **Rationale**: FR-004/FR-005; existing error returns/throws already surface failures.
- **Alternatives considered**: Server-only env-gated logger — useful later, not this prompt.

## Decision 4: Inventory (Phase 0 findings)

Confirmed sites (all same ingest UUID path):

| File | Sites | Messages |
|------|-------|----------|
| `src/app/api/build/route.ts` | 1 | `runBuildGeneration failed` |
| `src/lib/services.ts` | 2 | `pipeline start`, `llm config` |
| `src/lib/llm/ollamaClient.ts` | 2 | `llm fetch start`, `llm fetch failed` |
| `src/lib/llm/openAiClient.ts` | 2 | `llm fetch start`, `llm fetch failed` |
| `src/components/GeneratorPage.tsx` | 2 | `api non-ok response`, `client fetch threw` |

- No test files reference port 7497 or agent log regions (spot-checked).
- No NEEDS CLARIFICATION remain.

## Decision 5: Domain docs

- **Decision**: Do not edit `specs/domain-business-rules.md`, `domain-acceptance-criteria.md`, or `business-rules.md`.
- **Rationale**: No product semantics change (A3).
