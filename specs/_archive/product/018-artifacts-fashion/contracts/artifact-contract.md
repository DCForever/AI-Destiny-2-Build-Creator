# Contract: Variant Artifact Selection

## Write

`PATCH /api/user/builds/:id/variants/:variantId` accepts:

```json
{
  "artifactHash": 1234567890,
  "artifactName": "Queensfoil Censer",
  "artifactConfig": [111, 222]
}
```

- `artifactHash: null` clears selection and config.
- Unknown hash → `400` (not in manifest `artifacts` store).
- Config perk hashes SHOULD belong to that artifact’s perk grid; invalid hashes → `400`.

## Read

Variant detail includes `artifactHash`, `artifactName`, `artifactConfig`.

## Identity

Artifact-only PATCH does **not** require `identityAction`.
