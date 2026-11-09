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

**200**: `{ "created": [{ "proposalId", "synergyId" }], "skipped": ["p2"], "ignoredKeywords": [] }`

Unknown or foreign-user passId → 404 (no synergies written; client must re-run scan).
Synergy create errors → 400/409 via apiErrorResponse.

Confirm accepts **only** server-held proposals for `passId` bound to the authenticated user.
Client-supplied `proposals` bodies are not part of the contract and must not be trusted.
