# Contract: LLM Propose Pass

## POST `/api/llm/propose-pass`

```json
{ "descriptions": "text describing gear/playstyle..." }
```

**200**: `{ "passId": "...", "proposals": [ ... ] }` — nothing persisted.

## POST `/api/llm/propose-pass/:passId/confirm`

```json
{ "acceptedIds": ["p1"], "skippedIds": ["p2"] }
```

**200**: `{ "created": [{ "proposalId", "synergyId" }], "skipped": ["p2"] }`

Unknown passId → 404. Synergy create errors → 400/409 via apiErrorResponse.
