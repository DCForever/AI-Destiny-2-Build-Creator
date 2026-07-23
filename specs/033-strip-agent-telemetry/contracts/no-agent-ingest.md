# Contract: No agent debug ingest under `src/`

## Invariant

Application source under `src/` MUST NOT:

1. Contain `// #region agent log` (or matching `#endregion` pairs used for agent debug).
2. Perform HTTP requests to `http://127.0.0.1:7497/ingest/...` (or any `127.0.0.1:7497` agent ingest URL).

## Preserved behavior

- Generate API error JSON and status codes remain as implemented outside deleted regions.
- LLM client throw/return behavior on fetch failure remains unchanged.
- GeneratorPage user-visible error handling remains unchanged.

## Verification

```text
rg -n "7497/ingest|#region agent log" src
→ zero matches
```

## Non-goals

- Public HTTP API schema changes
- New diagnostics endpoints
