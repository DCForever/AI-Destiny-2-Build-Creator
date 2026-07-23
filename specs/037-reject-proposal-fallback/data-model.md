# Data Model: 037 reject client proposal fallback

## StoredProposePass

| Field | Type | Notes |
|-------|------|--------|
| passId | string (uuid) | Map key |
| createdAt | ISO string | TTL prune (60m) |
| proposals | Proposal[] | Server-authored only |
| userId | number \| undefined | Creating user; required for new saves |

## Confirm request (after)

| Field | Type | Notes |
|-------|------|--------|
| acceptedIds | string[] | Resolved only against server pass |
| skippedIds | string[] | Echoed in result |

`proposals` removed from confirm body authority.
