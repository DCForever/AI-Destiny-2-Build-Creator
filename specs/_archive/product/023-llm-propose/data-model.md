# Data Model: LLM Propose

## ProposePass

| Field | Notes |
|-------|-------|
| passId | uuid |
| createdAt | ISO |
| proposals | Proposal[] |

## Proposal

| kind | Payload |
|------|---------|
| synergy | name?, type, subType?, description?, links[] |
| keyword | term, facet?, isNew |
| evidence | link fields + note |

## No new DB tables
