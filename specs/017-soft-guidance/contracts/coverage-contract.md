# Contract: Variant Coverage

**Feature**: 017-soft-guidance

## GET `/api/user/builds/:id/variants/:variantId/coverage`

```json
{
  "coverage": {
    "synergies": [
      {
        "synergyId": "...",
        "name": "...",
        "tier": "weak",
        "matchedLinks": [{ "kind": "weapon", "displayName": "..." }],
        "unmatchedLinks": [{ "kind": "weapon_perk", "displayName": "..." }],
        "hint": "Add a matching perk to close this synergy."
      }
    ],
    "setBonuses": [
      {
        "setName": "Field-Tested",
        "pieceCount": 2,
        "status": "active",
        "activeBonuses": ["2pc"],
        "supportedSynergyIds": ["..."],
        "hint": null
      }
    ],
    "elementMismatches": [
      {
        "slot": "special",
        "weaponElement": "Solar",
        "subclassElement": "Void",
        "hint": "Special is Solar; subclass is Void."
      }
    ]
  }
}
```

No `softStats` field in this slice. Soft-only; never used as a save gate.
