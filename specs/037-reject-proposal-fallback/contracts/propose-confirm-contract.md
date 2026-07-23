# Contract: LLM Propose Pass Confirm (037 delta)

Supersedes client-proposals fallback behavior documented historically under `specs/023-llm-propose/contracts/propose-confirm-contract.md`.

## POST `/api/llm/propose-pass/:passId/confirm`

Auth required.

```json
{ "acceptedIds": ["p1"], "skippedIds": ["p2"] }
```

- **200**: `{ "created": [{ "proposalId", "synergyId" }], "skipped": ["p2"], "ignoredKeywords": [] }`
- **404**: Unknown or foreign-user passId. No synergies written. Client must re-run scan.
- **400**: Invalid JSON / schema.

`proposals` on the confirm body is **not** accepted as authority (stripped from schema). Only server-held proposals for `passId` (bound to the authenticated user) may be confirmed.
