# Contract: Soft Stat Warnings (Coverage)

`GET …/variants/:variantId/coverage` includes:

```json
{
  "coverage": {
    "synergies": [],
    "setBonuses": [],
    "elementMismatches": [],
    "targets": { "Health": 100 },
    "statEstimate": { "Health": 72, "incomplete": true },
    "softStats": [
      {
        "stat": "Health",
        "target": 100,
        "estimate": 72,
        "hint": "Health estimate 72 is below target 100."
      }
    ]
  }
}
```

- `softStats` only lists below-target rows.
- No hard-block on save from these rows.
